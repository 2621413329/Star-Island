import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_session.dart';

/// 面向用户的网络异常提示（不暴露后端地址与技术细节）。
const networkErrorMessage = '网络错误，请联系管理页';

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
        final token = readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        await forceReloginIfNeeded(statusCode: error.response?.statusCode);
        handler.next(error);
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

Future<T> unwrap<T>(
    Future<Response<dynamic>> call, T Function(dynamic json) parse) async {
  try {
    final response = await call;
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('响应格式错误');
    }
    final code = body['code'] as int? ?? 500;
    final message = body['message'] as String? ?? '请求失败';
    if (code != 200) {
      await forceReloginIfNeeded(statusCode: code);
      throw ApiException(message, code);
    }
    return parse(body['data']);
  } on DioException catch (e) {
    final response = e.response;
    final statusCode = response?.statusCode;
    await forceReloginIfNeeded(statusCode: statusCode);

    if (response != null) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final code = body['code'] as int? ?? statusCode;
        final message = body['message'] as String? ?? '请求失败';
        throw ApiException(message, code);
      }
      throw ApiException(networkErrorMessage, statusCode);
    }

    throw ApiException(networkErrorMessage);
  }
}
