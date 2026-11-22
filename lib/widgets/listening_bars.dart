import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// As seis barras do ícone do app, que sobem com o volume do microfone.
/// Sem [level] (modo servidor, que grava em arquivo) ficam paradas.
class ListeningBars extends StatelessWidget {
  final ValueListenable<double>? level;
  final Color color;
  final double size;

  const ListeningBars({
    super.key,
    required this.color,
    this.level,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final bars = level;
    if (bars == null) {
      return _paint(0.6);
    }
    return ValueListenableBuilder<double>(
      valueListenable: bars,
      builder: (context, value, _) => _paint(value),
    );
  }

  Widget _paint(double value) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size * 1.1,
        height: size,
        child: CustomPaint(painter: _BarsPainter(value, color)),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  static const _heights = [0.5, 0.78, 1.0, 0.93, 0.7, 0.43];

  final double level;
  final Color color;

  _BarsPainter(this.level, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _heights.length;
    final width = step * 0.55;
    final paint = Paint()..color = color;
    final scale = 0.22 + 0.78 * level;
    for (var i = 0; i < _heights.length; i++) {
      final h = size.height * _heights[i] * scale;
      final x = step * i + (step - width) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, width, h),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.level != level || old.color != color;
}
