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
    throw ApiException(e.message ?? '网络连接失败');
  }
}
