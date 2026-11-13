import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';
import 'brand.dart';
import 'scene.dart';

/// The app's logo tile, the same artwork as the launcher icon, in motion:
/// it plays its intro when it appears and idles in a slow loop. Holds still
/// when the system asks for reduced motion.
class BrandLogo extends ConsumerWidget {
  const BrandLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final logo = config.logo;
    if (logo == null) {
      return Container(
        width: size * 0.36,
        height: size * 0.36,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: BrandColors.of(context).linear),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.23),
        child: AnimatedScene(
          paint: logo,
          intro: const Duration(milliseconds: 1400),
          loop: const Duration(seconds: 6),
          label: '${config.appName} logo',
        ),
      ),
    );
  }
}

/// Runs [draw] on a 512x512 grid scaled to [size], the grid the logo SVGs in
/// brand/ use, so the in-app logo and the launcher icon match.
void onLogoGrid(Canvas c, Size size, void Function(Canvas c) draw) {
  c.save();
  c.scale(size.width / 512, size.height / 512);
  draw(c);
  c.restore();
}
