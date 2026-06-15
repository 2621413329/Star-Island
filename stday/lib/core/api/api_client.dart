import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../config/app_config.dart';

import '../../providers/auth_provider.dart';

import 'api_session.dart';



final dioProvider = Provider<Dio>((ref) {

  registerForceRelogin(() async {

    if (ref.read(authProvider).isLoggedIn) {

      await ref.read(authProvider.notifier).logout();

    }

  });



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

        final message = body['message'] as String? ?? e.message ?? '请求失败';

        throw ApiException(message, code);

      }

      throw ApiException(e.message ?? '网络连接失败', statusCode);

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

      return '连接后端超时（$base）。请确认：1) 后端已用 backend/run_dev.ps1 启动（需监听 0.0.0.0:9000）；2) 手机与电脑在同一局域网；3) Windows 防火墙已放行 9000 端口';

    case DioExceptionType.connectionError:

      return '无法连接后端（$base）。请确认后端已启动且监听 0.0.0.0:9000，API 地址与打包命令中的 API_BASE_URL 一致';

    default:

      return e.message ?? '网络连接失败（$base）';

  }

}


