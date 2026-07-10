import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mood_theme.dart';
import '../../core/utils/moment_date_groups.dart';
import '../../core/utils/moment_tags.dart';
import '../../data/models/growth_tag_models.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../design_system/healing_jelly_button.dart';
import '../../design_system/island_decorations.dart';
import '../../providers/app_providers.dart';
import '../../providers/growth_tag_provider.dart';
import '../../providers/story_day_provider.dart';
import '../more/widgets/more_subpage_header.dart';

Future<bool?> openEditMomentTagsPage(
  BuildContext context, {
  required DailyMomentModel moment,
}) {
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
  List<GrowthTagCategoryModel>? _editableCatalog;

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

  List<GrowthTagCategoryModel> _visibleCatalog(
    List<GrowthTagCategoryModel> catalog,
  ) {
    return catalog
        .where((category) =>
            category.isActive &&
            category.id != 'life' &&
            category.label != '生活')
        .toList(growable: false);
  }

  void _ensureEditableCatalog(List<GrowthTagCategoryModel> catalog) {
    _editableCatalog ??= _visibleCatalog(catalog);
    if (_primary == '生活') {
      GrowthTagCategoryModel? match;
      for (final category
          in _editableCatalog ?? const <GrowthTagCategoryModel>[]) {
        if (category.tags.any((tag) => _secondary.contains(tag.label))) {
          match = category;
          break;
        }
      }
      final selected = match;
      _primary = selected?.label;
      if (selected != null) {
        _secondary.removeWhere(
          (tag) => !selected.tags.any((candidate) => candidate.label == tag),
        );
      }
    }
  }

  Future<void> _persistEditableCatalog() async {
    final catalog = _editableCatalog;
    if (catalog == null) return;
    await ref.read(userAppPreferencesSyncProvider).saveCustomGrowthTagCatalog(
          catalog.map((category) => category.toJson()).toList(),
        );
    ref.invalidate(growthTagCatalogProvider);
    await ref.read(profileProvider.notifier).refresh();
  }

  String _customId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<String?> _askTagLabel(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '比如：松了一口气、被理解、还有点担心'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('加入感受'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _addSecondaryTag(GrowthTagCategoryModel category) async {
    final label = await _askTagLabel('写下自己的感受');
    if (label == null || !mounted) return;
    if (category.tags.any((tag) => tag.label == label)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这个感受已经在列表里了')),
      );
      return;
    }
    setState(() {
      _editableCatalog = [
        for (final item in _editableCatalog ?? const <GrowthTagCategoryModel>[])
          if (item.id == category.id)
            item.copyWith(tags: [
              ...item.tags,
              GrowthTagModel(
                id: _customId('${item.id}_tag'),
                categoryId: item.id,
                label: label,
                sortOrder: (item.tags.length + 1) * 10,
                isActive: true,
              ),
            ])
          else
            item,
      ];
      _secondary.add(label);
    });
    await _persistEditableCatalog();
  }

  Future<void> _submit() async {
    if (_primary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择这段日常的成长方向')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(momentRepositoryProvider).updateMomentTags(
            id: widget.moment.id,
            primaryTag: _primary!,
            secondaryTags: _secondary.toList(),
            aiEmotion: _aiEmotion,
          );
      await refreshAfterMomentMutation(
        ref,
        momentDay: momentCalendarDate(widget.moment),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('星屿记住了这段感受')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('暂时没保存成功，请稍后再试：$e')),
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
              _ensureEditableCatalog(catalog);
              final effectiveCatalog =
                  _editableCatalog ?? _visibleCatalog(catalog);
              return Column(
                children: [
                  MoreSubpageHeader(
                    title: '补充今日感受',
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
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        _PageIntroCard(palette: palette),
                        const SizedBox(height: 14),
                        _GrowthDirectionCard(
                          palette: palette,
                          currentLabel: _primary,
                          catalog: effectiveCatalog,
                          onSelect: (category) {
                            setState(() {
                              _primary = category.label;
                              _secondary.removeWhere(
                                (tag) => !category.tags.any(
                                  (candidate) =>
                                      candidate.isActive &&
                                      candidate.label == tag,
                                ),
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _CurrentMomentTagsPreview(
                          palette: palette,
                          tags: _secondary.toList(),
                        ),
                        const SizedBox(height: 14),
                        Builder(
                          builder: (context) {
                            final category =
                                _categoryFor(effectiveCatalog, _primary);
                            if (category == null) {
                              return Text(
                                '先选择这段日常的成长方向，再补充心情感受',
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
                            return _FeelingSuggestionSection(
                              palette: palette,
                              color: color,
                              tags: category.tags
                                  .where((tag) => tag.isActive)
                                  .toList(),
                              selected: _secondary,
                              onToggle: (label) {
                                setState(() {
                                  if (_secondary.contains(label)) {
                                    _secondary.remove(label);
                                  } else {
                                    _secondary.add(label);
                                  }
                                });
                              },
                              onAddCustom: () => _addSecondaryTag(category),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _SubmitFooter(
                    palette: palette,
                    saving: _saving,
                    onSubmit: _submit,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditableTagChip extends StatelessWidget {
  const _EditableTagChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      selected: selected,
      onPressed: onTap,
      selectedColor: color.withValues(alpha: 0.22),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(
        color: selected ? color : color.withValues(alpha: 0.42),
        width: selected ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        color: selected ? color : _EditMomentTagsPageState._onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _PageIntroCard extends StatelessWidget {
  const _PageIntroCard({required this.palette});

  final MoodPalette palette;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: palette.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '让星屿更懂这段日常，也让之后的回顾更贴近你。',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: palette.primary.withValues(alpha: 0.76),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthDirectionCard extends StatelessWidget {
  const _GrowthDirectionCard({
    required this.palette,
    required this.currentLabel,
    required this.catalog,
    required this.onSelect,
  });

  final MoodPalette palette;
  final String? currentLabel;
  final List<GrowthTagCategoryModel> catalog;
  final ValueChanged<GrowthTagCategoryModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '这段日常放在',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentLabel == null
                ? '选择一个成长方向，星屿会把它整理到对应小岛。'
                : '$currentLabel · 星屿会把它整理到这个成长方向里',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: palette.primary.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in catalog)
                _EditableTagChip(
                  label: category.label,
                  color: parseHexColor(
                    category.color,
                    fallback: palette.accent,
                  ),
                  selected: currentLabel == category.label,
                  onTap: () => onSelect(category),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentMomentTagsPreview extends StatelessWidget {
  const _CurrentMomentTagsPreview({
    required this.palette,
    required this.tags,
  });

  final MoodPalette palette;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visible = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty && tag != '生活')
        .toList();
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '心情感受',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            Text(
              '还没有补充感受，可以从下方选择几个最贴近你的词。',
              style: TextStyle(
                fontSize: 12,
                color: palette.primary.withValues(alpha: 0.55),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in visible)
                  _PlainTagPill(
                    label: tag,
                    color: palette.accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeelingSuggestionSection extends StatelessWidget {
  const _FeelingSuggestionSection({
    required this.palette,
    required this.color,
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.onAddCustom,
  });

  final MoodPalette palette;
  final Color color;
  final List<GrowthTagModel> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    return IslandGlassCard(
      palette: palette,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '再补充一点感受',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _EditMomentTagsPageState._onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '可以多选，也可以写下自己的词。',
            style: TextStyle(
              fontSize: 12,
              color: _EditMomentTagsPageState._onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                _EditableTagChip(
                  label: tag.label,
                  color: color,
                  selected: selected.contains(tag.label),
                  onTap: () => onToggle(tag.label),
                ),
              ActionChip(
                avatar: Icon(Icons.edit_rounded, size: 16, color: color),
                label: const Text('写下自己的感受'),
                onPressed: onAddCustom,
                backgroundColor: color.withValues(alpha: 0.10),
                side: BorderSide(color: color.withValues(alpha: 0.36)),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color.lerp(color, const Color(0xFF1A2332), 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlainTagPill extends StatelessWidget {
  const _PlainTagPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color.lerp(color, const Color(0xFF1A2332), 0.35),
          ),
        ),
      ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: saving
          ? HealingJellyPillButton(
              onPressed: null,
              label: '保存中…',
              tone: HealingJellyTone.fromPalette(palette),
              expanded: true,
              height: 50,
              showGlow: false,
            )
          : HealingJellyPillButton(
              onPressed: onSubmit,
              label: '保存感受',
              tone: HealingJellyTone.fromPalette(palette),
              expanded: true,
              height: 50,
              showGlow: false,
            ),
    );
  }
}
