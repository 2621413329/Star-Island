import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../data/models/polaroid_models.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/repositories/app_repository.dart';
import '../../today/moment_detail_page.dart';
import 'polaroid_card.dart';
import 'polaroid_share.dart';
import 'polaroid_skin.dart';
import 'polaroid_spread.dart';

class PolaroidAlbumPage extends ConsumerStatefulWidget {
  const PolaroidAlbumPage({
    super.key,
    required this.islandId,
    required this.initial,
    this.scene = PolaroidScene.fallback,
  });

  final String islandId;
  final List<PolaroidCardModel> initial;
  final PolaroidScene scene;

  @override
  ConsumerState<PolaroidAlbumPage> createState() => _PolaroidAlbumPageState();
}

class _PolaroidAlbumPageState extends ConsumerState<PolaroidAlbumPage>
    with TickerProviderStateMixin {
  final List<PolaroidCardModel> _cards = [];
  Timer? _poll;
  int _polls = 0;
  bool _viewing = false;
  int _pageIndex = 0;
  PageController? _page;
  var _enterStarted = false;
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    _cards.addAll(widget.initial);
    _schedulePoll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enterStarted) return;
    _enterStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      return;
    }
    _enter.forward();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _page?.dispose();
    _enter.dispose();
    _zoom.dispose();
    super.dispose();
  }

  PolaroidCardModel? get _polling {
    if (_cards.isEmpty) return null;
    if (_viewing) return _cards[_pageIndex.clamp(0, _cards.length - 1)];
    for (final card in _cards) {
      if (card.isDeveloping) return card;
    }
    return null;
  }

  void _schedulePoll() {
    _poll?.cancel();
    final current = _polling;
    if (current == null || !current.isDeveloping) return;
    _polls = 0;
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refreshCurrent());
  }

  Future<void> _refreshCurrent() async {
    final current = _polling;
    if (current == null || !mounted) return;
    _polls += 1;
    if (_polls > 12 || !current.isDeveloping) {
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

  void _openViewer(int index) {
    _page?.dispose();
    _page = PageController(initialPage: index);
    setState(() {
      _viewing = true;
      _pageIndex = index;
    });
    _schedulePoll();
    if (MediaQuery.disableAnimationsOf(context)) {
      _zoom.value = 1;
      return;
    }
    _zoom.forward(from: 0);
  }

  void _closeViewer() {
    setState(() => _viewing = false);
    _schedulePoll();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final ink = scene.ink;
    final muted = ink.withValues(alpha: 0.72);
    final card = _viewing && _cards.isNotEmpty
        ? _cards[_pageIndex.clamp(0, _cards.length - 1)]
        : null;
    final title = (card ?? (_cards.isNotEmpty ? _cards.first : null))
                ?.islandName
                .trim()
                .isNotEmpty ==
            true
        ? (card ?? _cards.first).islandName
        : '拍立得';
    return PopScope(
      canPop: !_viewing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _viewing) _closeViewer();
      },
      child: Scaffold(
        backgroundColor: scene.skyBottom,
        appBar: AppBar(
          backgroundColor: scene.skyTop.withValues(alpha: 0.92),
          foregroundColor: ink,
          elevation: 0,
          title: Text(title, style: appTextStyle(color: ink)),
          actions: [
            if (card != null)
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: '分享正面',
                  onPressed: () => sharePolaroidFront(
                    buttonContext,
                    card,
                    scene: scene,
                  ),
                  icon: const Icon(Icons.ios_share),
                ),
              ),
          ],
        ),
        body: PolaroidThemeWall(
          scene: scene,
          child: _cards.isEmpty
              ? Center(
                  child: Text(
                    '这座岛还没有被拍下',
                    style: appTextStyle(color: ink),
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: _viewing ? _viewer() : _spread()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                      child: Text(
                        _viewing ? _viewerHint() : _spreadHint(),
                        textAlign: TextAlign.center,
                        style: appTextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _spreadHint() {
    if (_cards.length > 2) return '左右滑动看这些照片，点一张放大';
    return '点一张放大';
  }

  String _viewerHint() {
    if (_cards.length > 1) return '左右滑动换一张，点一下翻到背面';
    return '点一下翻到背面';
  }

  Widget _spread() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final board = PolaroidSpread.boardSize(
          count: _cards.length,
          viewportWidth: constraints.maxWidth,
        );
        final slots = PolaroidSpread.slots(_cards.length, board);
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(board.width, constraints.maxWidth),
              height: board.height,
              child: AnimatedBuilder(
                animation: _enter,
                builder: (context, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < _cards.length; i++)
                        Positioned(
                          left: slots[i].left,
                          top: slots[i].top,
                          width: PolaroidSpread.cardWidth,
                          child: _spreadCard(i, slots[i].angle),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _spreadCard(int index, double angle) {
    final card = _cards[index];
    final reduce = MediaQuery.disableAnimationsOf(context);
    final start = (index * 0.07).clamp(0.0, 0.55);
    final end = (start + 0.5).clamp(0.2, 1.0);
    final t = reduce
        ? 1.0
        : Interval(start, end, curve: Curves.easeOutCubic).transform(_enter.value);
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(-28 * (1 - t), 120 * (1 - t)),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 0.35 + 0.65 * t,
            child: GestureDetector(
              key: Key('polaroid-spread-${card.id}'),
              onTap: () => _openViewer(index),
              child: PolaroidFace(
                card: card,
                showBack: false,
                scene: widget.scene,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewer() {
    final page = _page;
    if (page == null) return const SizedBox.shrink();
    final zoom = CurvedAnimation(parent: _zoom, curve: Curves.easeOutCubic);
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          '${_pageIndex + 1} / ${_cards.length}',
          style: appTextStyle(color: widget.scene.ink.withValues(alpha: 0.72), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.72, end: 1).animate(zoom),
            child: PageView.builder(
              key: const Key('polaroid-viewer'),
              controller: page,
              itemCount: _cards.length,
              onPageChanged: (index) {
                setState(() => _pageIndex = index);
                _schedulePoll();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: PolaroidCard(
                        key: ValueKey(_cards[index].id),
                        card: _cards[index],
                        scene: widget.scene,
                        onOpenMoment: _openMoment,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
