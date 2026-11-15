import 'package:flutter/material.dart';

import '../models/chord_recognition_mode.dart';
import '../models/on_device_model.dart';
import '../state/app_state.dart';

/// Indicador discreto de qual modo de reconhecimento está ativo (No
/// aparelho / Servidor), pra facilitar comparar os dois nos testes.
class RecognitionModeBadge extends StatelessWidget {
  const RecognitionModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = appState.chordRecognitionMode;
    final label =
        mode == ChordRecognitionMode.onDevice &&
            appState.onDeviceModel != OnDeviceModel.v3
        ? '${mode.label} · ${appState.onDeviceModel.label}'
        : mode.label;
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
