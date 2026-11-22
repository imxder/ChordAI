import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// O violão em pé, de frente, com o nome das partes. Fica na mesma posição
/// do diagrama de acorde (GuitarNeck): cabeça em cima e a 6ª corda à
/// esquerda.
class GuitarPartsDrawing extends StatelessWidget {
  const GuitarPartsDrawing({super.key});

  static const parts = [
    'Cabeça',
    'Tarraxas',
    'Pestana',
    'Braço',
    'Trastes',
    'Casa',
    'Boca',
    'Cavalete',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    return Semantics(
      image: true,
      label:
          'Desenho do violão com as partes: ${parts.join(', ')}, e as cordas '
          'da 6ª à 1ª',
      child: ExcludeSemantics(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AspectRatio(
              aspectRatio: 0.78,
              child: CustomPaint(
                painter: _GuitarPartsPainter(
                  line: colorScheme.onSurface,
                  fill: context.tokens.cell,
                  accent: colorScheme.primary,
                  label: textStyle.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  small: textStyle.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: fontChord,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuitarPartsPainter extends CustomPainter {
  final Color line;
  final Color fill;
  final Color accent;
  final TextStyle label;
  final TextStyle small;

  _GuitarPartsPainter({
    required this.line,
    required this.fill,
    required this.accent,
    required this.label,
    required this.small,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.3;
    final stroke = max(1.2, w * 0.005);
    final outline = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final body = Paint()..color = fill;
    final thin = Paint()
      ..color = line.withValues(alpha: 0.55)
      ..strokeWidth = max(0.8, stroke * 0.6);

    final neckHalf = w * 0.065;
    final headTop = h * 0.02;
    final nutY = h * 0.15;
    final bodyTop = h * 0.5;
    final bridgeY = h * 0.86;

    final head = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - neckHalf * 1.35, headTop, cx + neckHalf * 1.35, nutY),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(head, body);
    canvas.drawRRect(head, outline);

    final tunerR = w * 0.016;
    final tunerYs = [
      0.25,
      0.5,
      0.75,
    ].map((t) => headTop + (nutY - headTop) * t);
    final tuners = <Offset>[];
    for (final y in tunerYs) {
      for (final side in [-1, 1]) {
        final c = Offset(cx + side * (neckHalf * 1.35 + tunerR * 1.6), y);
        tuners.add(c);
        canvas.drawLine(Offset(cx + side * neckHalf * 1.35, y), c, outline);
        canvas.drawCircle(c, tunerR, body);
        canvas.drawCircle(c, tunerR, outline);
      }
    }

    final bodyPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, bodyTop + h * 0.1),
          width: w * 0.42,
          height: h * 0.24,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.8),
          width: w * 0.54,
          height: h * 0.34,
        ),
      );
    final bodyShape = Path.combine(
      PathOperation.union,
      bodyPath,
      Path()..addRect(
        Rect.fromLTRB(cx - w * 0.19, bodyTop + h * 0.1, cx + w * 0.19, h * 0.8),
      ),
    );
    canvas.drawPath(bodyShape, body);
    canvas.drawPath(bodyShape, outline);

    final soundhole = Offset(cx, h * 0.66);
    canvas.drawCircle(soundhole, w * 0.07, Paint()..color = line);

    final neck = Rect.fromLTRB(
      cx - neckHalf,
      nutY,
      cx + neckHalf,
      bodyTop + h * 0.03,
    );
    canvas.drawRect(neck, body);
    canvas.drawRect(neck, outline);

    final fretYs = <double>[];
    var gap = (neck.bottom - nutY) / 5.2;
    var y = nutY;
    for (var i = 0; i < 6; i++) {
      y += gap;
      if (y > neck.bottom - 2) break;
      fretYs.add(y);
      gap *= 0.94;
    }
    for (final fy in fretYs) {
      canvas.drawLine(Offset(neck.left, fy), Offset(neck.right, fy), outline);
    }

    final casa = Rect.fromLTRB(neck.left, fretYs[0], neck.right, fretYs[1]);
    canvas.drawRect(casa, Paint()..color = accent.withValues(alpha: 0.28));

    canvas.drawLine(
      Offset(neck.left - stroke, nutY),
      Offset(neck.right + stroke, nutY),
      Paint()
        ..color = line
        ..strokeWidth = stroke * 3.5,
    );

    final bridge = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, bridgeY),
        width: w * 0.2,
        height: h * 0.03,
      ),
      Radius.circular(w * 0.01),
    );
    canvas.drawRRect(bridge, Paint()..color = line);

    final stringXs = [
      for (var s = 0; s < 6; s++) cx - neckHalf * 0.75 + neckHalf * 1.5 * s / 5,
    ];
    for (final x in stringXs) {
      canvas.drawLine(Offset(x, nutY), Offset(x, bridgeY), thin);
    }

    _text(
      canvas,
      '6ª',
      Offset(stringXs.first - w * 0.03, bridgeY + h * 0.035),
      small,
    );
    _text(
      canvas,
      '1ª',
      Offset(stringXs.last + w * 0.03, bridgeY + h * 0.035),
      small,
    );

    final labelX = w * 0.62;
    void callout(String text, Offset target, double labelY) {
      final end = Offset(labelX - w * 0.02, labelY);
      canvas.drawLine(target, end, thin);
      canvas.drawCircle(target, max(2.0, w * 0.007), Paint()..color = accent);
      _text(canvas, text, Offset(labelX, labelY), label, alignLeft: true);
    }

    callout(
      'Cabeça',
      Offset(cx + neckHalf * 0.6, headTop + (nutY - headTop) * 0.1),
      h * 0.03,
    );
    callout('Tarraxas', tuners[1], h * 0.09);
    callout('Pestana', Offset(neck.right, nutY), h * 0.16);
    callout('Casa', casa.center.translate(neckHalf * 0.5, 0), h * 0.23);
    callout('Trastes', Offset(neck.right, fretYs[2]), h * 0.3);
    callout(
      'Braço',
      Offset(neck.right, (fretYs[3] + neck.bottom) / 2),
      h * 0.39,
    );
    callout('Boca', soundhole.translate(w * 0.07, 0), h * 0.6);
    callout('Cavalete', Offset(cx + w * 0.1, bridgeY), h * 0.86);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style, {
    bool alignLeft = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignLeft ? 0.0 : painter.width / 2;
    painter.paint(canvas, at - Offset(dx, painter.height / 2));
  }

  @override
  bool shouldRepaint(_GuitarPartsPainter old) =>
      old.line != line ||
      old.fill != fill ||
      old.accent != accent ||
      old.label != label ||
      old.small != small;
}
