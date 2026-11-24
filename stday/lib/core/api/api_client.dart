import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_session.dart';

/// 面向用户的网络异常提示（不暴露后端地址与技术细节）。
const networkErrorMessage = '网络异常请稍后重试';

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
        if (options.data is FormData) {
          // 默认 application/json 不能带上 multipart 边界，上传会被网关拒掉。
          options.headers.remove(Headers.contentTypeHeader);
        }
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

int? apiCodeOf(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

/// 把 Dio 响应体收成接口约定的 `{code, message, data}`。
///
/// 网关有时把 JSON 当成纯文本返回；这类正文仍应展示服务端文案，
/// 而不是一律说成网络错误。HTML 错误页返回 null。
Map<String, dynamic>? tryParseApiBody(dynamic body) {
  if (body is Map<String, dynamic>) return body;
  if (body is Map) {
    return body.map((key, value) => MapEntry('$key', value));
  }
  if (body is! String) return null;
  final trimmed = body.trim();
  if (trimmed.length > 20000 || !trimmed.startsWith('{')) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } catch (_) {
    return null;
  }
  return null;
}

String apiMessageOf(Map<String, dynamic> body, {String fallback = '请求失败'}) {
  final raw = body['message'];
  if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  return fallback;
}

Future<T> unwrap<T>(
    Future<Response<dynamic>> call, T Function(dynamic json) parse) async {
  try {
    final response = await call;
    final body = tryParseApiBody(response.data);
    if (body == null) {
      throw ApiException('响应格式错误');
    }
    final code = apiCodeOf(body['code']) ?? 500;
    final message = apiMessageOf(body);
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
      final body = tryParseApiBody(response.data);
      if (body != null) {
        throw ApiException(
          apiMessageOf(body),
          apiCodeOf(body['code']) ?? statusCode,
        );
      }
      throw ApiException(networkErrorMessage, statusCode);
    }

    final kind = e.type;
    if (kind == DioExceptionType.connectionTimeout ||
        kind == DioExceptionType.sendTimeout ||
        kind == DioExceptionType.receiveTimeout ||
        kind == DioExceptionType.connectionError) {
      throw ApiException(networkErrorMessage);
    }

    throw ApiException(networkErrorMessage);
  }
}
