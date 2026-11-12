import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'motion.dart';

/// One part of a bar or donut: its size and colour.
class ChartPart {
  const ChartPart(this.value, this.color);
  final double value;
  final Color color;
}

/// One bar: a label under it and one or more stacked parts.
class BarDatum {
  const BarDatum(this.label, this.parts, {this.highlight = false});
  final String label;
  final List<ChartPart> parts;
  final bool highlight;
  double get total => parts.fold(0, (a, p) => a + p.value);
}

/// Shared driver for charts that draw in, then glide between data sets.
mixin _DrawIn<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController drawIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      drawIn.value = 1;
    } else if (drawIn.status == AnimationStatus.dismissed) {
      drawIn.forward();
    }
  }

  void replay() {
    if (Motion.reduced(context)) {
      drawIn.value = 1;
    } else {
      drawIn.forward(from: 0);
    }
  }

  @override
  void dispose() {
    drawIn.dispose();
    super.dispose();
  }
}

/// Stacked bar chart that grows its bars in, one after another. The whole
/// chart is a single screen-reader node whose label lists every bar, built
/// by [describe].
class AnimatedBarChart extends StatefulWidget {
  const AnimatedBarChart({
    super.key,
    required this.bars,
    required this.valueLabel,
    required this.semanticsLabel,
    this.height = 170,
  });

  final List<BarDatum> bars;
  final String Function(double) valueLabel;
  final String semanticsLabel;
  final double height;

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> with SingleTickerProviderStateMixin, _DrawIn {
  List<double> _from = const [];

  @override
  void didUpdateWidget(AnimatedBarChart old) {
    super.didUpdateWidget(old);
    final oldTotals = [for (final b in old.bars) b.total];
    final newTotals = [for (final b in widget.bars) b.total];
    if (oldTotals.length != newTotals.length || !_listEq(oldTotals, newTotals)) {
      // Glide from what is on screen now.
      final t = drawIn.value;
      _from = [for (var i = 0; i < oldTotals.length; i++) _shown(i, oldTotals, _from, t)];
      replay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: drawIn,
            builder: (_, _) => CustomPaint(
              size: Size.infinite,
              painter: _BarPainter(
                bars: widget.bars,
                from: _from,
                t: drawIn.value,
                valueLabel: widget.valueLabel,
                textStyle: theme.textTheme.labelSmall!,
                labelColor: theme.colorScheme.onSurfaceVariant,
                strongColor: theme.colorScheme.onSurface,
                gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _shown(int i, List<double> to, List<double> from, double t) {
  final f = i < from.length ? from[i] : 0.0;
  return ui.lerpDouble(f, to[i], t)!;
}

bool _listEq(List<double> a, List<double> b) {
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 1e-9) return false;
  }
  return true;
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.bars,
    required this.from,
    required this.t,
    required this.valueLabel,
    required this.textStyle,
    required this.labelColor,
    required this.strongColor,
    required this.gridColor,
  });

  final List<BarDatum> bars;
  final List<double> from;
  final double t;
  final String Function(double) valueLabel;
  final TextStyle textStyle;
  final Color labelColor;
  final Color strongColor;
  final Color gridColor;

  TextPainter _text(String s, Color c, {bool bold = false}) => TextPainter(
    text: TextSpan(
      text: s,
      style: textStyle.copyWith(color: c, fontWeight: bold ? FontWeight.w700 : null),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const labelH = 18.0, topPad = 18.0;
    final chartH = size.height - labelH - topPad;
    final maxV = bars.fold<double>(0, (m, b) => math.max(m, b.total));
    final scale = maxV <= 0 ? 0.0 : chartH / maxV;
    final slot = size.width / bars.length;
    final barW = math.min(30.0, slot * 0.56);
    final base = topPad + chartH;

    for (var g = 1; g <= 3; g++) {
      final y = base - chartH * g / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1.5,
    );

    final totals = [for (final b in bars) b.total];
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = slot * (i + 0.5);
      // Each bar starts a little after the one before it.
      final local = phase(t, i * 0.06, 0.55 + i * 0.06, Curves.easeOutBack);
      final shownTotal = ui.lerpDouble(i < from.length ? from[i] : 0, totals[i], local)!.clamp(0.0, double.infinity);
      final ratio = totals[i] == 0 ? 0.0 : shownTotal / totals[i];
      var top = base;
      for (var p = 0; p < b.parts.length; p++) {
        final h = b.parts[p].value * ratio * scale;
        if (h <= 0) continue;
        final rect = Rect.fromLTWH(cx - barW / 2, top - h, barW, h);
        final isTop = b.parts.skip(p + 1).every((q) => q.value <= 0);
        final rr = RRect.fromRectAndCorners(
          rect,
          topLeft: isTop ? const Radius.circular(8) : Radius.zero,
          topRight: isTop ? const Radius.circular(8) : Radius.zero,
          bottomLeft: p == 0 ? const Radius.circular(3) : Radius.zero,
          bottomRight: p == 0 ? const Radius.circular(3) : Radius.zero,
        );
        canvas.drawRRect(
          rr,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [b.parts[p].color, Color.lerp(b.parts[p].color, Colors.black, 0.18)!],
            ).createShader(rect),
        );
        top -= h;
      }
      final day = _text(b.label, b.highlight ? strongColor : labelColor, bold: b.highlight);
      day.paint(canvas, Offset(cx - day.width / 2, base + 4));
      if (totals[i] > 0) {
        final v = _text(valueLabel(totals[i]), strongColor.withValues(alpha: phase(t, 0.5 + i * 0.05, 1)));
        v.paint(canvas, Offset(cx - v.width / 2, top - v.height - 2));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => true;
}

/// Line chart that traces itself left to right with a glowing head.
class AnimatedLineChart extends StatefulWidget {
  const AnimatedLineChart({
    super.key,
    required this.points,
    required this.semanticsLabel,
    required this.valueLabel,
    required this.color,
    this.height = 160,
  });

  /// (label under the point, value).
  final List<(String, double)> points;
  final String semanticsLabel;
  final String Function(double) valueLabel;
  final Color color;
  final double height;

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart> with SingleTickerProviderStateMixin, _DrawIn {
  @override
  void didUpdateWidget(AnimatedLineChart old) {
    super.didUpdateWidget(old);
    if (old.points.length != widget.points.length ||
        !_listEq([for (final p in old.points) p.$2], [for (final p in widget.points) p.$2])) {
      replay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: drawIn,
            builder: (_, _) => CustomPaint(
              size: Size.infinite,
              painter: _LinePainter(
                points: widget.points,
                t: drawIn.value,
                color: widget.color,
                valueLabel: widget.valueLabel,
                textStyle: theme.textTheme.labelSmall!,
                labelColor: theme.colorScheme.onSurfaceVariant,
                surface: theme.colorScheme.surface,
                gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.t,
    required this.color,
    required this.valueLabel,
    required this.textStyle,
    required this.labelColor,
    required this.surface,
    required this.gridColor,
  });

  final List<(String, double)> points;
  final double t;
  final Color color;
  final String Function(double) valueLabel;
  final TextStyle textStyle;
  final Color labelColor;
  final Color surface;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const labelH = 18.0, pad = 22.0;
    final h = size.height - labelH - pad * 2;
    final values = [for (final p in points) p.$2];
    var lo = values.reduce(math.min), hi = values.reduce(math.max);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final span = hi - lo;
    final dx = points.length == 1 ? 0.0 : (size.width - 40) / (points.length - 1);
    Offset at(int i) => Offset(20 + dx * i, pad + h * (1 - (values[i] - lo) / span));

    for (var g = 0; g <= 2; g++) {
      final y = pad + h * g / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      final a = at(i - 1), b = at(i);
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final progress = Curves.easeInOutCubic.transform(t);
    final metric = path.computeMetrics().firstOrNull;
    final drawn = metric == null ? path : metric.extractPath(0, metric.length * progress);

    // Area under the drawn part.
    if (metric != null && progress > 0) {
      final head = metric.getTangentForOffset(metric.length * progress)!.position;
      final area = Path.from(drawn)
        ..lineTo(head.dx, pad + h)
        ..lineTo(at(0).dx, pad + h)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, pad, size.width, h)),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < points.length; i++) {
      final shownAt = points.length == 1 ? 0.0 : i / (points.length - 1);
      if (progress + 1e-6 < shownAt) continue;
      final o = at(i);
      canvas.drawCircle(o, 6, Paint()..color = surface);
      canvas.drawCircle(o, 4, Paint()..color = color);
      final lbl = TextPainter(
        text: TextSpan(
          text: points[i].$1,
          style: textStyle.copyWith(color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lbl.paint(canvas, Offset(o.dx - lbl.width / 2, size.height - labelH + 2));
      final v = TextPainter(
        text: TextSpan(
          text: valueLabel(values[i]),
          style: textStyle.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final above = i == 0 || values[i] >= values[i - 1];
      v.paint(canvas, Offset((o.dx - v.width / 2).clamp(0, size.width - v.width), above ? o.dy - 22 : o.dy + 8));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

/// Ring chart that sweeps its parts in around the circle; [center] sits in
/// the hole.
class AnimatedDonut extends StatefulWidget {
  const AnimatedDonut({
    super.key,
    required this.parts,
    required this.semanticsLabel,
    this.center,
    this.size = 180,
    this.thickness = 22,
  });

  final List<ChartPart> parts;
  final String semanticsLabel;
  final Widget? center;
  final double size;
  final double thickness;

  @override
  State<AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<AnimatedDonut> with SingleTickerProviderStateMixin, _DrawIn {
  @override
  void didUpdateWidget(AnimatedDonut old) {
    super.didUpdateWidget(old);
    if (!_listEq([for (final p in old.parts) p.value], [for (final p in widget.parts) p.value]) ||
        old.parts.length != widget.parts.length) {
      replay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: AnimatedBuilder(
                animation: drawIn,
                builder: (_, _) => CustomPaint(
                  size: Size.square(widget.size),
                  painter: _DonutPainter(widget.parts, drawIn.value, widget.thickness, track),
                ),
              ),
            ),
            ?widget.center,
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.parts, this.t, this.thickness, this.track);
  final List<ChartPart> parts;
  final double t;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(thickness / 2 + 2);
    canvas.drawArc(
      ring,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
    final total = parts.fold<double>(0, (a, p) => a + p.value);
    if (total <= 0) return;
    final sweepAll = 2 * math.pi * Curves.easeInOutCubic.transform(t);
    const gap = 0.035;
    var start = -math.pi / 2;
    for (final p in parts) {
      if (p.value <= 0) continue;
      final full = 2 * math.pi * p.value / total;
      final end = math.min(start + full, -math.pi / 2 + sweepAll);
      if (end <= start) break;
      final sweep = math.max(0.0, end - start - (parts.length > 1 ? gap : 0));
      canvas.drawArc(
        ring,
        start,
        sweep,
        false,
        Paint()
          ..color = p.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = parts.length > 1 ? StrokeCap.butt : StrokeCap.round,
      );
      start += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// A rounded horizontal bar split into coloured parts that fill in from the
/// left, for showing how a total divides up.
class AnimatedSplitBar extends StatefulWidget {
  const AnimatedSplitBar({super.key, required this.parts, required this.semanticsLabel, this.height = 14});
  final List<ChartPart> parts;
  final String semanticsLabel;
  final double height;

  @override
  State<AnimatedSplitBar> createState() => _AnimatedSplitBarState();
}

class _AnimatedSplitBarState extends State<AnimatedSplitBar> with SingleTickerProviderStateMixin, _DrawIn {
  @override
  void didUpdateWidget(AnimatedSplitBar old) {
    super.didUpdateWidget(old);
    if (!_listEq([for (final p in old.parts) p.value], [for (final p in widget.parts) p.value]) ||
        old.parts.length != widget.parts.length) {
      replay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: drawIn,
            builder: (_, _) => CustomPaint(painter: _SplitPainter(widget.parts, drawIn.value, track)),
          ),
        ),
      ),
    );
  }
}

class _SplitPainter extends CustomPainter {
  _SplitPainter(this.parts, this.t, this.track);
  final List<ChartPart> parts;
  final double t;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final whole = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(whole, Paint()..color = track);
    final total = parts.fold<double>(0, (a, p) => a + p.value);
    if (total <= 0) return;
    canvas.save();
    canvas.clipRRect(whole);
    final reach = size.width * Curves.easeOutCubic.transform(t);
    var x = 0.0;
    for (final p in parts) {
      final w = size.width * p.value / total;
      final right = math.min(x + w, reach);
      if (right > x) canvas.drawRect(Rect.fromLTRB(x, 0, right, size.height), Paint()..color = p.color);
      x += w;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplitPainter old) => true;
}
