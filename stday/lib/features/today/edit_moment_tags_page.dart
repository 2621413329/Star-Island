import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mood_theme.dart';
import '../../core/layout/main_shell_insets.dart';
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
      _primary = null;
      _secondary.clear();
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
          decoration: const InputDecoration(hintText: '请输入标签名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _addPrimaryTag(MoodPalette palette) async {
    final label = await _askTagLabel('新增一级标签');
    if (label == null || !mounted) return;
    final catalog = [...?_editableCatalog];
    if (catalog.any((category) => category.label == label)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('一级标签已存在')),
      );
      return;
    }
    setState(() {
      _editableCatalog = [
        ...catalog,
        GrowthTagCategoryModel(
          id: _customId('custom_category'),
          label: label,
          icon: 'label',
          color: _colorToHex(palette.accent),
          sortOrder: (catalog.length + 1) * 10,
          isActive: true,
          tags: const [],
        ),
      ];
      _primary = label;
      _secondary.clear();
    });
    await _persistEditableCatalog();
  }

  Future<void> _deletePrimaryTag(GrowthTagCategoryModel category) async {
    setState(() {
      _editableCatalog = [
        for (final item in _editableCatalog ?? const <GrowthTagCategoryModel>[])
          if (item.id != category.id) item,
      ];
      if (_primary == category.label) {
        _primary = null;
        _secondary.clear();
      }
    });
    await _persistEditableCatalog();
  }

  Future<void> _addSecondaryTag(GrowthTagCategoryModel category) async {
    final label = await _askTagLabel('新增二级标签');
    if (label == null || !mounted) return;
    if (category.tags.any((tag) => tag.label == label)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('二级标签已存在')),
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

  Future<void> _deleteSecondaryTag(
    GrowthTagCategoryModel category,
    GrowthTagModel tag,
  ) async {
    setState(() {
      _editableCatalog = [
        for (final item in _editableCatalog ?? const <GrowthTagCategoryModel>[])
          if (item.id == category.id)
            item.copyWith(
              tags: [
                for (final existing in item.tags)
                  if (existing.id != tag.id) existing,
              ],
            )
          else
            item,
      ];
      _secondary.remove(tag.label);
    });
    await _persistEditableCatalog();
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
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
              _ensureEditableCatalog(catalog);
              final effectiveCatalog =
                  _editableCatalog ?? _visibleCatalog(catalog);
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
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        16 + MainShellInsets.bottom(context),
                      ),
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '一级标签',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _onSurface,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _addPrimaryTag(palette),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('添加'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in effectiveCatalog)
                              _EditableTagChip(
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
                                onDelete: () => _deletePrimaryTag(category),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '二级标签',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _onSurface,
                                ),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final category =
                                    _categoryFor(effectiveCatalog, _primary);
                                return TextButton.icon(
                                  onPressed: category == null
                                      ? null
                                      : () => _addSecondaryTag(category),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('添加'),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '可多选，新增或删除仅影响当前账号',
                          style: TextStyle(
                            fontSize: 12,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            final category =
                                _categoryFor(effectiveCatalog, _primary);
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
                                    _EditableTagChip(
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
                                      onDelete: () =>
                                          _deleteSecondaryTag(category, tag),
                                    ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _SubmitFooter(
                    palette: palette,
                    saving: _saving,
                    onSubmit: () => _submit(effectiveCatalog),
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
    required this.onDelete,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      selected: selected,
      onPressed: onTap,
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close_rounded, size: 16),
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
        8 + MainShellInsets.bottom(context),
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
              label: '保存标签',
              tone: HealingJellyTone.fromPalette(palette),
              expanded: true,
              height: 50,
              showGlow: false,
            ),
    );
  }
}
