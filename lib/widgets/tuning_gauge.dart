import 'dart:math';

import 'package:flutter/material.dart';

class TuningGauge extends StatelessWidget {
  final double cents;
  final Color color;
  final bool active;

  const TuningGauge({
    super.key,
    required this.cents,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 150,
      child: CustomPaint(
        painter: _TuningGaugePainter(
          cents: cents.clamp(-50, 50),
          color: active ? color : Theme.of(context).colorScheme.outlineVariant,
          tickColor: Theme.of(context).colorScheme.outlineVariant,
          majorTickColor: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _TuningGaugePainter extends CustomPainter {
  final double cents;
  final Color color;
  final Color tickColor;
  final Color majorTickColor;

  _TuningGaugePainter({
    required this.cents,
    required this.color,
    required this.tickColor,
    required this.majorTickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final outerRadius = size.width / 2 - 6;

    for (var i = -9; i <= 9; i++) {
      final angleDeg = i * 10.0;
      final angle = angleDeg * pi / 180;
      final isMajor = i % 3 == 0;
      final tickLength = isMajor ? 12.0 : 7.0;
      final start = center +
          Offset(
            (outerRadius - tickLength) * sin(angle),
            -(outerRadius - tickLength) * cos(angle),
          );
      final end = center +
          Offset(outerRadius * sin(angle), -outerRadius * cos(angle));
      final paint = Paint()
        ..color = isMajor ? majorTickColor : tickColor
        ..strokeWidth = isMajor ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }

    final needleAngle = (cents / 50) * (pi / 2);
    final needleLength = outerRadius - 22;
    final needleEnd = center +
        Offset(
          needleLength * sin(needleAngle),
          -needleLength * cos(needleAngle),
        );
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TuningGaugePainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.color != color;
  }
}
