import 'package:flutter/widgets.dart';

import '../../../world/island/painted_island_asset.dart';
import '../../../world/island/painted_island_pits.dart';

/// 副岛主题小物。同一块岛坯上只换这几件道具，不改岸线。
class StoryIslandThemeLayer extends StatelessWidget {
  const StoryIslandThemeLayer({
    super.key,
    required this.categoryId,
    required this.viewportSize,
  });

  final String categoryId;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final props = PaintedIslandPits.themeProps(categoryId);
    if (props.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (final prop in props) _prop(prop),
      ],
    );
  }

  Widget _prop(StoryIslandThemeProp prop) {
    final foot = PaintedIslandAsset.plateToCanvas(prop.plate, viewportSize);
    final h = viewportSize.shortestSide * 0.065;
    return Positioned(
      left: foot.dx - h / 2,
      top: foot.dy - h,
      width: h,
      height: h,
      child: Image.asset(
        'assets/images/${prop.asset}',
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
