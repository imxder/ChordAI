import 'package:flutter/material.dart';

import '../models/chord_recognition_mode.dart';
import '../models/on_device_model.dart';
import '../state/app_state.dart';

String recognitionModeLabel() {
  final mode = appState.chordRecognitionMode;
  return mode == ChordRecognitionMode.onDevice &&
          appState.onDeviceModel != OnDeviceModel.v3
      ? '${mode.label} · ${appState.onDeviceModel.label}'
      : mode.label;
}

class RecognitionModeBadge extends StatelessWidget {
  const RecognitionModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Reconhecendo: ${recognitionModeLabel()}',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
