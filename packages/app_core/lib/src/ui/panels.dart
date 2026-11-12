import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';
import 'motion.dart';

/// The big gradient card at the top of a screen. Soft rings drift in the
/// corner while ambient motion is on.
class BrandPanel extends StatefulWidget {
  const BrandPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.margin});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  State<BrandPanel> createState() => _BrandPanelState();
}

class _BrandPanelState extends State<BrandPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.ambient && !Motion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return Container(
      margin: widget.margin ?? const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: brand.linear,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: brand.gradient.last.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CustomPaint(
          painter: _RingsPainter(_c, brand.onBrand),
          child: Padding(
            padding: widget.padding,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: brand.onBrand),
              child: IconTheme.merge(
                data: IconThemeData(color: brand.onBrand),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.anim, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final a = anim.value * 2 * math.pi;
    final c1 = Offset(size.width * 0.92 + 10 * math.cos(a), size.height * 0.08 + 8 * math.sin(a));
    final c2 = Offset(size.width * 0.78 - 12 * math.sin(a), size.height * 1.05 + 6 * math.cos(a));
    for (final (c, r) in [(c1, size.height * 0.7), (c2, size.height * 0.5)]) {
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.07));
      canvas.drawCircle(
        c,
        r * 0.62,
        Paint()
          ..color = color.withValues(alpha: 0.09)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}

/// A small label in a tinted pill, for chips like "1h 30m overtime".
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, this.icon, this.color, this.onBrand = false, this.textKey});
  final String text;
  final IconData? icon;
  final Color? color;
  final bool onBrand;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);
    final fg = onBrand ? brand.onBrand : (color ?? scheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: onBrand ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
          Text(
            text,
            key: textKey,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A rounded square icon on a soft gradient, used as list leading art.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = 44});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.1)],
        ),
      ),
      child: Icon(icon, color: c, size: size * 0.52),
    );
  }
}

/// Section title with an optional trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(20, 16, 16, 6)});
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
        ?trailing,
      ],
    ),
  );
}
