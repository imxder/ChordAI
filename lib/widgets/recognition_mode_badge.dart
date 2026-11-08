import 'package:flutter/material.dart';

import '../state/app_state.dart';

/// Indicador discreto de qual modo de reconhecimento está ativo (No
/// aparelho / Servidor), pra facilitar comparar os dois nos testes.
class RecognitionModeBadge extends StatelessWidget {
  const RecognitionModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      appState.chordRecognitionMode.label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
