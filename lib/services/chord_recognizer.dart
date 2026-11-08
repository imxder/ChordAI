import 'package:record/record.dart';

import '../models/chord_prediction.dart';

/// Interface comum entre o reconhecimento de acordes via servidor
/// (ChordRecognitionService) e no aparelho (OnDeviceChordService), pra uma
/// tela usar qualquer um dos dois sem mudar mais nada além de qual
/// instanciar.
abstract class ChordRecognizer {
  bool get isRunning;

  Future<bool> hasPermission();

  Future<List<InputDevice>> listInputDevices();

  void selectDevice(InputDevice? device);

  /// [serverUrl] é ignorado pela implementação no aparelho.
  Future<void> start({
    String? serverUrl,
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  });

  Future<void> stop();

  Future<void> dispose();
}
