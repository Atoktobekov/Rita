import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/palette.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 104,
    this.stroke = 11,
    this.fontSize = 24,
    this.child,
  });

  final int percent;
  final double size;
  final double stroke;
  final double fontSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Выполнено $percent процентов',
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          percent / 100,
          stroke,
          AppPalette.of(context).ink,
        ),
        child: Center(
          child:
              child ??
              Text(
                '$percent%',
                style: TextStyle(fontSize: fontSize, height: 1.33),
              ),
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value, this.stroke, this.color);

  final Color color;
  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(rect, paint..color = color.withValues(alpha: .12));
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      value != old.value || stroke != old.stroke || color != old.color;
}
