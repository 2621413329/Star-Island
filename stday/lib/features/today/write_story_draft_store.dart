import 'moment_photo_section.dart';

/// 记录页未提交时暂存草稿，再次打开「录入心情」时恢复。
class WriteStoryDraftStore {
  WriteStoryDraftStore._();

  static String _note = '';
  static List<MomentPhotoDraft> _photos = const [];

  static bool get hasDraft => _note.trim().isNotEmpty || _photos.isNotEmpty;

  static void save({
    required String note,
    required List<MomentPhotoDraft> photos,
  }) {
    _note = note;
    _photos = List<MomentPhotoDraft>.from(photos);
  }

  static ({String note, List<MomentPhotoDraft> photos})? peek() {
    if (!hasDraft) return null;
    return (note: _note, photos: List<MomentPhotoDraft>.from(_photos));
  }

  static void clear() {
    _note = '';
    _photos = const [];
  }
}
