import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';

/// Desenho das seis cordas na afinação padrão, no mesmo sentido dos diagramas
/// de acorde e das casinhas do afinador: a 6ª (mais grossa) na esquerda e a
/// 1ª (mais fina) na direita. A grossura de cada traço muda pra mostrar qual
/// corda é mais grossa.
class StringsIllustration extends StatelessWidget {
  const StringsIllustration({super.key});

  static const _notes = ['E', 'A', 'D', 'G', 'B', 'E'];
  static const _names = ['Mi', 'Lá', 'Ré', 'Sol', 'Si', 'Mi'];

  /// Grossura do traço, da 6ª pra 1ª.
  static const _widths = [4.0, 3.4, 2.8, 2.0, 1.5, 1.1];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label:
          'Desenho das seis cordas. Da esquerda pra direita: 6ª corda, Mi, a '
          'mais grossa; 5ª, Lá; 4ª, Ré; 3ª, Sol; 2ª, Si; 1ª, Mi, a mais fina.',
      excludeSemantics: true,
      child: Material(
        color: context.tokens.cell,
        borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 6; i++)
                    Expanded(
                      child: Column(
                        children: [
                          Text('${6 - i}ª', style: textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Container(
                            width: _widths[i],
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _notes[i],
                            style: const TextStyle(
                              fontFamily: fontChord,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          Text(_names[i], style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('mais grossa', style: textTheme.bodySmall),
                  Text('mais fina', style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
