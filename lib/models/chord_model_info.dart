import 'dart:convert';

import 'package:flutter/services.dart';

/// Metadados do modelo TFLite de reconhecimento de acordes (ver
/// ChordAI-backend/export/model_info.json e labels.json). Carregados dos
/// assets em vez de hardcoded, pra acompanhar automaticamente se o backend
/// gerar uma versão nova do modelo com limiares diferentes.
class ChordModelInfo {
  final int sampleRate;
  final int inputSamples;
  final double confidenceThreshold;
  final double silenceRmsThreshold;
  final List<String> labels;
  final String noneLabel;

  const ChordModelInfo({
    required this.sampleRate,
    required this.inputSamples,
    required this.confidenceThreshold,
    required this.silenceRmsThreshold,
    required this.labels,
    required this.noneLabel,
  });

  static Future<ChordModelInfo> load() async {
    final infoJson = jsonDecode(
      await rootBundle.loadString('assets/models/model_info.json'),
    ) as Map<String, dynamic>;
    final labelsJson =
        jsonDecode(await rootBundle.loadString('assets/models/labels.json'))
            as List<dynamic>;

    return ChordModelInfo(
      sampleRate: infoJson['sample_rate'] as int,
      inputSamples: infoJson['input_samples'] as int,
      confidenceThreshold: (infoJson['confidence_threshold'] as num).toDouble(),
      silenceRmsThreshold: (infoJson['silence_rms_threshold'] as num).toDouble(),
      labels: labelsJson.cast<String>(),
      noneLabel: infoJson['none_label'] as String,
    );
  }
}
