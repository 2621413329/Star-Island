import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../../providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Future<T> unwrap<T>(Future<Response<dynamic>> call, T Function(dynamic json) parse) async {
  try {
    final response = await call;
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('响应格式错误');
    }
    final code = body['code'] as int? ?? 500;
    final message = body['message'] as String? ?? '请求失败';
    if (code != 200) {
      throw ApiException(message, code);
    }
    return parse(body['data']);
  } on DioException catch (e) {
    final response = e.response;
    if (response != null) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        throw ApiException(
          body['message'] as String? ?? e.message ?? '请求失败',
          body['code'] as int? ?? response.statusCode,
        );
      }
      throw ApiException(e.message ?? '网络连接失败', response.statusCode);
    }
    throw ApiException(_dioTransportMessage(e));
  }
}

String _dioTransportMessage(DioException e) {
  final base = AppConfig.apiBaseUrl;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '连接后端超时（$base）。常见原因：8000 端口被多个旧进程占用，请用 backend/run_dev.ps1 重启后端';
    case DioExceptionType.connectionError:
      return '无法连接后端（$base）。请确认后端已启动，且教师端 API 地址与启动命令一致';
    default:
      return e.message ?? '网络连接失败（$base）';
  }
}
