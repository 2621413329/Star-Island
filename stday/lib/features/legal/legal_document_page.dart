import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/legal/legal_documents.dart';
import '../../core/legal/legal_urls.dart';
import '../../core/theme/app_fonts.dart';
import '../../design_system/app_feedback.dart';
import '../../design_system/island_chip.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../more/widgets/more_subpage_header.dart';

/// 全屏法律文档页（用户协议 / 隐私政策）。
///
/// 审核要求「可打开」的隐私政策与 Terms of Use 链接时，使用本页而非底部弹层。
class LegalDocumentPage extends ConsumerWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  String get _publicUrl => document.id == privacyPolicy.id
      ? LegalUrls.privacyPolicy
      : LegalUrls.termsOfUse;

  String get _englishTitle => document.id == privacyPolicy.id
      ? 'Privacy Policy'
      : 'Terms of Use (EULA)';

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _publicUrl));
    if (!context.mounted) return;
    AppFeedback.showWeak(context, '已复制可打开链接');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            children: [
              MoreSubpageHeader(title: document.title),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                    const SizedBox(height: 6),
                    Text(
                      _englishTitle,
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '更新日期：${document.updatedAt}',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8C7B6B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IslandGlassCard(
                      palette: palette,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '可打开的网页链接',
                              style: appTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              _publicUrl,
                              style: appTextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _copyLink(context),
                                icon: const Icon(Icons.link_rounded, size: 18),
                                label: const Text('复制链接'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IslandGlassCard(
                      palette: palette,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final section in document.sections) ...[
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
                              const SizedBox(height: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IslandPrimaryAction(
                      label: '我已阅读',
                      palette: palette,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
