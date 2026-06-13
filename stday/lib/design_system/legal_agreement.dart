import 'package:flutter/material.dart';

import '../core/legal/legal_documents.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/mood_theme.dart';
import 'island_chip.dart';

Future<void> showLegalDocumentSheet(
  BuildContext context,
  LegalDocument document,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LegalDocumentSheet(document: document),
  );
}

class _LegalDocumentSheet extends StatelessWidget {
  const _LegalDocumentSheet({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    const palette = defaultPalette;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      document.title,
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '更新日期：${document.updatedAt}',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8C7B6B),
                      ),
                    ),
                    for (final section in document.sections) ...[
                      const SizedBox(height: 16),
                      Text(
                        section.heading,
                        style: appTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5D4E44),
                        ),
                      ),
                      for (final paragraph in section.paragraphs) ...[
                        const SizedBox(height: 8),
                        Text(
                          paragraph,
                          style: appTextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: const Color(0xFF8C7B6B),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: IslandPrimaryAction(
                label: '我已阅读',
                palette: palette,
                height: 44,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

  static const defaultErrorText = '请先阅读并同意《用户协议》和《隐私政策》';

  @override
  Widget build(BuildContext context) {
    final linkStyle = appTextStyle(
      fontSize: 13,
      color: palette.accent,
      fontWeight: FontWeight.w600,
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
                        onTap: () => showLegalDocumentSheet(
                          context,
                          userAgreement,
                        ),
                      ),
                      Text('和', style: bodyStyle),
                      _LegalLink(
                        label: '《隐私政策》',
                        style: linkStyle,
                        onTap: () => showLegalDocumentSheet(
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
