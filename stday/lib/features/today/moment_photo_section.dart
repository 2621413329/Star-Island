import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/moment_limits.dart';
import '../../core/theme/mood_theme.dart';
import '../../data/models/profile_models.dart';
import '../../design_system/pressable_feedback.dart';

/// 本地待上传或已保存的故事照片。
class MomentPhotoDraft {
  const MomentPhotoDraft.local(this.file)
      : id = null,
        urlPath = null;

  const MomentPhotoDraft.remote({
    required this.id,
    required this.urlPath,
  }) : file = null;

  final String? id;
  final XFile? file;
  final String? urlPath;

  bool get isLocal => file != null;

  factory MomentPhotoDraft.fromModel(MomentPhotoModel photo) {
    return MomentPhotoDraft.remote(id: photo.id, urlPath: photo.urlPath);
  }
}

String momentPhotoFullUrl(String urlPath) {
  if (urlPath.startsWith('http://') || urlPath.startsWith('https://')) {
    return urlPath;
  }
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  final path = urlPath.startsWith('/') ? urlPath : '/$urlPath';
  return '$base$path';
}

class MomentPhotoSection extends StatelessWidget {
  const MomentPhotoSection({
    super.key,
    required this.palette,
    required this.photos,
    required this.onChanged,
    this.enabled = true,
  });

  final MoodPalette palette;
  final List<MomentPhotoDraft> photos;
  final ValueChanged<List<MomentPhotoDraft>> onChanged;
  final bool enabled;

  static final _picker = ImagePicker();

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (!enabled) return;
    if (photos.length >= momentMaxPhotos) {
      _showSnack(context, '每条故事最多添加 $momentMaxPhotos 张照片');
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (file == null) return;
      onChanged([...photos, MomentPhotoDraft.local(file)]);
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, '选择照片失败：$e');
      }
    }
  }

  void _removeAt(int index) {
    if (!enabled) return;
    final next = [...photos]..removeAt(index);
    onChanged(next);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '添加照片',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.primary.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${photos.length}/$momentMaxPhotos',
              style: TextStyle(
                fontSize: 12,
                color: palette.primary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '照片仅作记录保存，不参与 AI 文字分析',
          style: TextStyle(
            fontSize: 11,
            color: palette.primary.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < photos.length; i++)
              _PhotoTile(
                draft: photos[i],
                onRemove: enabled ? () => _removeAt(i) : null,
              ),
            if (enabled && photos.length < momentMaxPhotos) ...[
              _AddPhotoButton(
                palette: palette,
                icon: Icons.photo_library_outlined,
                label: '相册',
                onTap: () => _pick(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                _AddPhotoButton(
                  palette: palette,
                  icon: Icons.photo_camera_outlined,
                  label: '拍摄',
                  onTap: () => _pick(context, ImageSource.camera),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.draft, this.onRemove});

  final MomentPhotoDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: draft.isLocal
              ? _LocalPhotoPreview(file: draft.file!)
              : Image.network(
                  momentPhotoFullUrl(draft.urlPath!),
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _brokenImage(),
                ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _brokenImage() {
    return Container(
      width: 78,
      height: 78,
      color: const Color(0xFFECEFF1),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 24),
    );
  }
}

class _LocalPhotoPreview extends StatelessWidget {
  const _LocalPhotoPreview({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
          );
        }
        if (snapshot.hasError) {
          return Container(
            width: 78,
            height: 78,
            color: const Color(0xFFECEFF1),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, size: 24),
          );
        }
        return Container(
          width: 78,
          height: 78,
          color: const Color(0xFFECEFF1),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final MoodPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableFeedback(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: palette.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: palette.accent),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.accent.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
