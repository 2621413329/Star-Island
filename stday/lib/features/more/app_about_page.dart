import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/legal/legal_documents.dart';
import '../../core/legal/legal_urls.dart';
import '../../core/theme/app_fonts.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/legal_agreement.dart';
import '../../providers/app_providers.dart';
import 'widgets/more_subpage_header.dart';

const _hideAboutMenuKey = 'hide_app_about_menu_entry';

/// 是否在「更多」页隐藏「应用说明」入口。
Future<bool> isAppAboutMenuHidden() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool(_hideAboutMenuKey) ?? false;
}

Future<void> setAppAboutMenuHidden(bool hidden) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool(_hideAboutMenuKey, hidden);
}

class AppAboutPage extends ConsumerWidget {
  const AppAboutPage({super.key});

  static const _sections = [
    _AboutSection(
      title: '产品介绍',
      body: '星屿（成长小岛）是一款正式上线的温暖陪伴型成长记录应用。'
          '您可用简短日常记录生活与感受，AI 伙伴会协助理解情绪、整理成长标签，'
          '并将这些记录呈现在会随您变化的小岛上。',
      accent: Color(0xFF5A9A6E),
    ),
    _AboutSection(
      title: '主要功能',
      body: '· 记录今日日常与心情\n'
          '· 为日常添加成长标签、照片与语音\n'
          '· 在成长轨迹中查看心情与标签统计\n'
          '· 设置本地提醒，按时收到温馨推送\n'
          '· 观察小岛随记录逐渐繁荣，并同步天气变化\n'
          '· 开通星屿会员，解锁更多成长与陪伴能力',
      accent: Color(0xFF4A8FB8),
    ),
    _AboutSection(
      title: 'AI 与内容说明',
      body: 'AI 会基于您主动输入的文字等内容推断情绪与标签，帮助更快完成记录；'
          '照片主要用于个人保存与回顾。AI 生成结果均可手动修改，'
          '仅供个人参考，不构成医疗、心理咨询或其他专业意见。',
      accent: Color(0xFF7E6DB7),
    ),
    _AboutSection(
      title: '隐私与数据保护',
      body: '您的日常记录默认仅供本人查看，数据用于提供个人回顾与成长记录服务。'
          '我们不会将您的私人日记内容用于对外展示或营销推广。'
          '完整规则请阅读《隐私政策》与《用户协议》。',
      accent: Color(0xFFC9A227),
    ),
    _AboutSection(
      title: '联系我们',
      body: '如您对产品功能、会员订阅、账号安全或个人信息处理有疑问，'
          '请通过本页下方的《用户协议》《隐私政策》了解规则，'
          '或在应用内相关页面继续使用与反馈。我们会在合理期限内予以处理。',
      accent: Color(0xFF8C6B4F),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(moodPaletteProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoreSubpageHeader(title: '应用说明'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Text(
                      '星屿 · 正式版应用说明',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3D3229),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '记录真实感受，见证小岛与自身一起成长。\n'
                      '法律文档更新日期：$legalDocumentsUpdatedAt',
                      textAlign: TextAlign.center,
                      style: appTextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: palette.primary.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 20),
                    IslandGlassCard(
                      palette: palette,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                      child: Column(
                        children: [
                          for (var i = 0; i < _sections.length; i++) ...[
                            _AboutSectionBlock(section: _sections[i]),
                            if (i < _sections.length - 1)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                child: Divider(
                                  height: 1,
                                  color:
                                      palette.primary.withValues(alpha: 0.08),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    IslandGlassCard(
                      palette: palette,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('用户协议 / Terms of Use'),
                            subtitle: Text(
                              LegalUrls.termsOfUse,
                              style: appTextStyle(fontSize: 11),
                            ),
                            leading: Icon(Icons.article_outlined,
                                color: palette.primary),
                            trailing: const Icon(Icons.open_in_browser_rounded),
                            onTap: () =>
                                openLegalDocument(context, userAgreement),
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: palette.primary.withValues(alpha: 0.08),
                          ),
                          ListTile(
                            title: const Text('隐私政策 / Privacy Policy'),
                            subtitle: Text(
                              LegalUrls.privacyPolicy,
                              style: appTextStyle(fontSize: 11),
                            ),
                            leading: Icon(Icons.privacy_tip_outlined,
                                color: palette.primary),
                            trailing: const Icon(Icons.open_in_browser_rounded),
                            onTap: () =>
                                openLegalDocument(context, privacyPolicy),
                          ),
                        ],
                      ),
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

class _AboutSection {
  const _AboutSection({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;
}

class _AboutSectionBlock extends StatelessWidget {
  const _AboutSectionBlock({required this.section});

  final _AboutSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: section.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: appTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: section.accent,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.body,
                style: appTextStyle(
                  fontSize: 14,
                  height: 1.65,
                  color: const Color(0xFF5A4E44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
