import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GuitarPartsDrawing extends StatelessWidget {
  const GuitarPartsDrawing({super.key});

  static const asset = 'assets/images/violao.png';
  static const _imageSize = Size(613, 1478);

  static const parts = [
    ('Tarraxas', Offset(356, 60)),
    ('Cabeça', Offset(276, 125)),
    ('Pestana', Offset(320, 212)),
    ('Casa', Offset(300, 236)),
    ('Trastes', Offset(321, 306)),
    ('Braço', Offset(331, 650)),
    ('Boca', Offset(370, 930)),
    ('Cavalete', Offset(412, 1145)),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      image: true,
      label:
          'Violão com as partes: ${parts.map((p) => p.$1).join(', ')}, e as '
          'cordas da 6ª à 1ª',
      child: ExcludeSemantics(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AspectRatio(
              aspectRatio: 0.8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final image = Rect.fromLTWH(
                    constraints.maxWidth * 0.08,
                    0,
                    height * _imageSize.width / _imageSize.height,
                    height,
                  );
                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: image,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          color: colorScheme.onSurface,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LabelsPainter(
                            image: image,
                            line: colorScheme.onSurfaceVariant,
                            dot: colorScheme.primary,
                            label: textTheme.bodyMedium!.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            small: textTheme.bodySmall!.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: fontChord,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelsPainter extends CustomPainter {
  final Rect image;
  final Color line;
  final Color dot;
  final TextStyle label;
  final TextStyle small;

  _LabelsPainter({
    required this.image,
    required this.line,
    required this.dot,
    required this.label,
    required this.small,
  });

  Offset _at(Offset original) => Offset(
    image.left +
        original.dx / GuitarPartsDrawing._imageSize.width * image.width,
    image.top +
        original.dy / GuitarPartsDrawing._imageSize.height * image.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = line.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = dot;
    final labelX = image.right + max(16.0, size.width * 0.06);
    final gap = label.fontSize! * 1.7;
    var lastY = double.negativeInfinity;
    for (final (text, point) in GuitarPartsDrawing.parts) {
      final target = _at(point);
      final labelY = max(target.dy, lastY + gap);
      lastY = labelY;
      canvas.drawLine(target, Offset(labelX - 6, labelY), linePaint);
      canvas.drawCircle(target, 3, dotPaint);
      _text(canvas, text, Offset(labelX, labelY), label, alignLeft: true);
    }
    _text(canvas, '6ª', _at(const Offset(215, 250)), small);
    _text(canvas, '1ª', _at(const Offset(352, 250)), small);
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
  bool shouldRepaint(_LabelsPainter old) =>
      old.image != image ||
      old.line != line ||
      old.dot != dot ||
      old.label != label ||
      old.small != small;
}
