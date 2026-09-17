import 'package:flutter/material.dart';

import '../models/chord_diagrams.dart';

enum ChordMatchState { neutral, correct, incorrect }

class GuitarNeck extends StatelessWidget {
  final String? chord;
  final ChordMatchState matchState;

  const GuitarNeck({
    super.key,
    this.chord,
    this.matchState = ChordMatchState.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final fingering = chord == null ? null : chordFingerings[chord];
    return AspectRatio(
      aspectRatio: 0.8,
      child: CustomPaint(
        painter: _GuitarNeckPainter(
          fingering: fingering,
          matchState: matchState,
        ),
      ),
    );
  }
}

class _GuitarNeckPainter extends CustomPainter {
  final List<int?>? fingering;
  final ChordMatchState matchState;

  _GuitarNeckPainter({required this.fingering, required this.matchState});

  static const _strings = 6;
  static const _frets = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 1.5;
    final nutPaint = Paint()
      ..color = Colors.grey.shade900
      ..strokeWidth = 4;

    final left = size.width * 0.1;
    final right = size.width * 0.9;
    final top = size.height * 0.15;
    final bottom = size.height * 0.95;
    final stringGap = (right - left) / (_strings - 1);
    final fretGap = (bottom - top) / _frets;

    for (var f = 0; f <= _frets; f++) {
      final y = top + fretGap * f;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        f == 0 ? nutPaint : linePaint,
      );
    }
    for (var s = 0; s < _strings; s++) {
      final x = left + stringGap * s;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), linePaint);
    }

    final dotColor = switch (matchState) {
      ChordMatchState.correct => Colors.green,
      ChordMatchState.incorrect => Colors.red,
      ChordMatchState.neutral => Colors.deepPurple,
    };
    final dotPaint = Paint()..color = dotColor;
    final labelStyle = TextStyle(
      color: Colors.grey.shade800,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final frets = fingering;
    if (frets != null) {
      for (var s = 0; s < _strings && s < frets.length; s++) {
        final fret = frets[s];
        final x = left + stringGap * s;
        if (fret == null) {
          _drawLabel(canvas, 'x', Offset(x, top - fretGap * 0.6), labelStyle);
        } else if (fret == 0) {
          _drawLabel(canvas, 'o', Offset(x, top - fretGap * 0.6), labelStyle);
        } else {
          final y = top + fretGap * (fret - 0.5);
          canvas.drawCircle(Offset(x, y), stringGap * 0.28, dotPaint);
        }
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GuitarNeckPainter oldDelegate) {
    return oldDelegate.fingering != fingering ||
        oldDelegate.matchState != matchState;
  }
}
