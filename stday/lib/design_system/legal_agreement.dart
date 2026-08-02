import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/legal/legal_documents.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';
import '../features/legal/legal_document_page.dart';

/// 打开完整法律文档页（优先路由，失败则 Navigator push）。
Future<void> openLegalDocument(
  BuildContext context,
  LegalDocument document,
) async {
  final path =
      document.id == privacyPolicy.id ? '/legal/privacy' : '/legal/terms';
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    await router.push(path);
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LegalDocumentPage(document: document),
    ),
  );
}

/// 兼容旧调用：改为打开完整页面，满足「可打开的页面」审核要求。
Future<void> showLegalDocumentSheet(
  BuildContext context,
  LegalDocument document,
) {
  return openLegalDocument(context, document);
}

/// 登录/注册页协议勾选行。
class LegalConsentRow extends StatelessWidget {
  const LegalConsentRow({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.palette,
    this.showError = false,
    this.errorText,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final MoodPalette palette;
  final bool showError;
  final String? errorText;

  static const defaultErrorText = '请先阅读并同意正式《用户协议》和《隐私政策》';

  @override
  Widget build(BuildContext context) {
    final linkStyle = appTextStyle(
      fontSize: 13,
      color: palette.accent,
      fontWeight: FontWeight.w600,
    ).copyWith(
      decoration: TextDecoration.underline,
      decorationColor: palette.accent,
    );
    final bodyStyle = appTextStyle(
      fontSize: 13,
      height: 1.45,
      color: const Color(0xFF5D4E44),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: showError
                ? Colors.redAccent.withValues(alpha: 0.06)
                : palette.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showError
                  ? Colors.redAccent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: checked,
                  activeColor: palette.accent,
                  side: BorderSide(
                    color: showError
                        ? Colors.redAccent.withValues(alpha: 0.7)
                        : palette.primary.withValues(alpha: 0.35),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) => onChanged(value ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('我已阅读并同意', style: bodyStyle),
                      _LegalLink(
                        label: '《用户协议》',
                        style: linkStyle,
                        onTap: () => openLegalDocument(
                          context,
                          userAgreement,
                        ),
                      ),
                      Text('和', style: bodyStyle),
                      _LegalLink(
                        label: '《隐私政策》',
                        style: linkStyle,
                        onTap: () => openLegalDocument(
                          context,
                          privacyPolicy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          Text(
            errorText ?? defaultErrorText,
            style: appTextStyle(
              fontSize: 12,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: style),
    );
  }
}
