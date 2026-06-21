import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/utils/moment_tags.dart';
import '../../data/models/growth_tag_models.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/island_decorations.dart';
import '../../design_system/moment_tag_chips.dart';
import '../../providers/app_providers.dart';
import '../../providers/growth_tag_provider.dart';
import '../../providers/mood_status_provider.dart';
import '../../providers/story_day_provider.dart';
import '../more/widgets/more_subpage_header.dart';

Future<bool?> openEditMomentTagsPage(
  BuildContext context, {
  required DailyMomentModel moment,
}) {
  if (!isMomentToday(moment)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('仅今日日常可以修改标签')),
    );
    return Future.value(false);
  }
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditMomentTagsPage(moment: moment),
    ),
  );
}

class EditMomentTagsPage extends ConsumerStatefulWidget {
  const EditMomentTagsPage({super.key, required this.moment});

  final DailyMomentModel moment;

  @override
  ConsumerState<EditMomentTagsPage> createState() => _EditMomentTagsPageState();
}

class _EditMomentTagsPageState extends ConsumerState<EditMomentTagsPage> {
  static const _onSurface = Color(0xFF3D3229);
  static const _onSurfaceVariant = Color(0xFF6B5E54);

  String? _primary;
  final Set<String> _secondary = {};
  String? _aiEmotion;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _primary = momentPrimaryCategory(widget.moment);
    _secondary.addAll(momentSecondaryTags(widget.moment));
    _aiEmotion = momentAiEmotionLabel(widget.moment);
  }

  GrowthTagCategoryModel? _categoryFor(
    List<GrowthTagCategoryModel> catalog,
    String? label,
  ) {
    if (label == null) return null;
    return findCategoryByLabel(catalog, label);
  }

  Future<void> _submit(List<GrowthTagCategoryModel> catalog) async {
    if (_primary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择一级标签')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(appRepositoryProvider).updateMomentTags(
            id: widget.moment.id,
            primaryTag: _primary!,
            secondaryTags: _secondary.toList(),
            aiEmotion: _aiEmotion,
          );
      ref.invalidate(todayMomentsProvider);
      ref.invalidate(storyDayViewProvider);
      ref.invalidate(moodStatusViewProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(moodPaletteProvider);
    final catalogAsync = ref.watch(growthTagCatalogProvider);

    return Scaffold(
      body: IslandScaffold(
        palette: palette,
        child: SafeArea(
          child: catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('标签库加载失败：$e')),
            data: (catalog) {
              if (catalog.isEmpty) {
                return Center(
                  child: Text(
                    '标签库暂不可用，请检查网络后重试',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.7),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  MoreSubpageHeader(
                    title: '编辑标签',
                    actions: [
                      if (_saving)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      children: [
                        Text(
                          '预览',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        IslandGlassCard(
                          palette: palette,
                          padding: const EdgeInsets.all(14),
                          child: MomentTagChipRow(
                            moment: _previewMoment(),
                            palette: palette,
                            maxSecondary: 6,
                            showGrowthPoints: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '一级标签',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in catalog)
                              if (category.isActive)
                                MomentTagChip(
                                  label: category.label,
                                  color: parseHexColor(
                                    category.color,
                                    fallback: palette.accent,
                                  ),
                                  selected: _primary == category.label,
                                  onTap: () {
                                    setState(() {
                                      _primary = category.label;
                                      _secondary.removeWhere(
                                        (tag) => !category.tags.any(
                                          (t) => t.isActive && t.label == tag,
                                        ),
                                      );
                                    });
                                  },
                                ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '二级标签',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '可多选，仅展示标签库内选项',
                          style: TextStyle(
                            fontSize: 12,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            final category = _categoryFor(catalog, _primary);
                            if (category == null) {
                              return Text(
                                '请先选择一级标签',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.primary.withValues(alpha: 0.6),
                                ),
                              );
                            }
                            final color = parseHexColor(
                              category.color,
                              fallback: palette.accent,
                            );
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final tag in category.tags)
                                  if (tag.isActive)
                                    MomentTagChip(
                                      label: tag.label,
                                      color: color,
                                      selected: _secondary.contains(tag.label),
                                      onTap: () {
                                        setState(() {
                                          if (_secondary.contains(tag.label)) {
                                            _secondary.remove(tag.label);
                                          } else {
                                            _secondary.add(tag.label);
                                          }
                                        });
                                      },
                                    ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'AI 感受',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in emotionLabelsFromCatalog(catalog))
                              MomentTagChip(
                                label: label,
                                color: palette.primary,
                                selected: _aiEmotion == label,
                                onTap: () => setState(
                                  () => _aiEmotion =
                                      _aiEmotion == label ? null : label,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _SubmitFooter(
                    palette: palette,
                    saving: _saving,
                    onSubmit: () => _submit(catalog),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  DailyMomentModel _previewMoment() {
    return DailyMomentModel(
      id: widget.moment.id,
      eventTags: [
        if (_primary != null) _primary!,
        ..._secondary,
      ],
      emotionTag: widget.moment.emotionTag,
      primaryTag: _primary,
      secondaryTags: _secondary.toList(),
      growthPoints: const [],
      aiEmotion: _aiEmotion,
      note: widget.moment.note,
      clientEventId: widget.moment.clientEventId,
      companionScene: widget.moment.companionScene,
      companionPose: widget.moment.companionPose,
      visualPayload: widget.moment.visualPayload,
      momentDate: widget.moment.momentDate,
      createdAt: widget.moment.createdAt,
    );
  }
}

class _SubmitFooter extends StatelessWidget {
  const _SubmitFooter({
    required this.palette,
    required this.saving,
    required this.onSubmit,
  });

  final MoodPalette palette;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: palette.primary.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: saving ? null : onSubmit,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: palette.accent,
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '保存标签',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
