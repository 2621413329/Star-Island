import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../data/models/polaroid_models.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/repositories/app_repository.dart';
import '../../today/moment_detail_page.dart';
import 'polaroid_card.dart';
import 'polaroid_share.dart';

class PolaroidAlbumPage extends ConsumerStatefulWidget {
  const PolaroidAlbumPage({
    super.key,
    required this.islandId,
    required this.initial,
  });

  final String islandId;
  final List<PolaroidCardModel> initial;

  @override
  ConsumerState<PolaroidAlbumPage> createState() => _PolaroidAlbumPageState();
}

class _PolaroidAlbumPageState extends ConsumerState<PolaroidAlbumPage> {
  final List<PolaroidCardModel> _cards = [];
  int _index = 0;
  Timer? _poll;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    _cards.addAll(widget.initial);
    _schedulePoll();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  PolaroidCardModel? get _current =>
      _cards.isEmpty ? null : _cards[_index.clamp(0, _cards.length - 1)];

  void _schedulePoll() {
    _poll?.cancel();
    final current = _current;
    if (current == null || !current.isDeveloping) return;
    _polls = 0;
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refreshCurrent());
  }

  Future<void> _refreshCurrent() async {
    final current = _current;
    if (current == null || !mounted) return;
    _polls += 1;
    if (_polls > 8 || !current.isDeveloping) {
      _poll?.cancel();
      return;
    }
    try {
      final fresh = await ref
          .read(storyIslandRepositoryProvider)
          .fetchPolaroid(current.id);
      if (!mounted) return;
      setState(() {
        final index = _cards.indexWhere((item) => item.id == fresh.id);
        if (index >= 0) _cards[index] = fresh;
      });
      if (!fresh.isDeveloping) _poll?.cancel();
    } catch (_) {
      _poll?.cancel();
    }
  }

  Future<void> _openMoment(PolaroidSourceMoment source) async {
    try {
      final moments = await ref
          .read(momentRepositoryProvider)
          .listRecentMoments(days: 365);
      DailyMomentModel? found;
      for (final moment in moments) {
        if (moment.id == source.id) {
          found = moment;
          break;
        }
      }
      if (!mounted || found == null) return;
      await openMomentDetailPage(context, moment: found);
    } catch (_) {}
  }

  void _step(int delta) {
    setState(() => _index = (_index + delta).clamp(0, _cards.length - 1));
    _schedulePoll();
  }

  @override
  Widget build(BuildContext context) {
    final card = _current;
    final title = card?.islandName.trim().isNotEmpty == true
        ? card!.islandName
        : '拍立得';
    return Scaffold(
      backgroundColor: const Color(0xFF1C1916),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1916),
        foregroundColor: const Color(0xFFF7F1E6),
        title: Text(title, style: appTextStyle(color: const Color(0xFFF7F1E6))),
        actions: [
          if (card != null)
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: '分享正面',
                onPressed: () => sharePolaroidFront(buttonContext, card),
                icon: const Icon(Icons.ios_share),
              ),
            ),
        ],
      ),
      body: card == null
          ? Center(
              child: Text(
                '这座岛还没有被拍下',
                style: appTextStyle(color: const Color(0xFFF7F1E6)),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  '${_index + 1} / ${_cards.length}',
                  style: appTextStyle(color: const Color(0xFFD9CBB8), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: PolaroidCard(
                          key: ValueKey(card.id),
                          card: card,
                          onNext: _index < _cards.length - 1
                              ? () => _step(1)
                              : null,
                          onPrevious: _index > 0 ? () => _step(-1) : null,
                          onOpenMoment: _openMoment,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Text(
                    '点一下或横向滑动翻面，纵向滑动翻到另一张',
                    textAlign: TextAlign.center,
                    style: appTextStyle(color: const Color(0xFFD9CBB8), fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }
}
