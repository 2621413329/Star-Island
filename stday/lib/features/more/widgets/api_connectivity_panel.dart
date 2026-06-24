import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_fonts.dart';

/// 应用说明页底部：展示编译期 API 地址并一键探测 /health。
class ApiConnectivityPanel extends StatefulWidget {
  const ApiConnectivityPanel({super.key, required this.palette});

  final Color palette;

  @override
  State<ApiConnectivityPanel> createState() => _ApiConnectivityPanelState();
}

class _ApiConnectivityPanelState extends State<ApiConnectivityPanel> {
  bool _checking = false;
  String? _result;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _result = null;
    });

    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final response = await dio.get<Map<String, dynamic>>('$base/health');
      final body = response.data;
      final ok = body?['code'] == 200;
      setState(() {
        _result = ok ? '连接正常' : '服务响应异常（code=${body?['code']}）';
      });
    } on DioException catch (e) {
      final detail = switch (e.type) {
        DioExceptionType.connectionTimeout => '连接超时',
        DioExceptionType.receiveTimeout => '响应超时',
        DioExceptionType.connectionError => '无法连接服务器',
        _ => e.message ?? '网络异常',
      };
      setState(() {
        _result = '失败：$detail';
      });
    } catch (e) {
      setState(() {
        _result = '失败：$e';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiUrl = AppConfig.apiBaseUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          '服务器连接',
          style: appTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: widget.palette.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          apiUrl,
          style: appTextStyle(
            fontSize: 12,
            height: 1.45,
            color: const Color(0xFF6B5E54),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _checking ? null : _check,
            icon: _checking
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.palette.primary,
                    ),
                  )
                : const Icon(Icons.wifi_tethering_outlined, size: 18),
            label: Text(_checking ? '检测中…' : '检测连接'),
          ),
        ),
        if (_result != null)
          Text(
            _result!,
            style: appTextStyle(
              fontSize: 12,
              color: _result!.startsWith('连接正常')
                  ? const Color(0xFF3D7A52)
                  : const Color(0xFFB45309),
            ),
          ),
      ],
    );
  }
}
