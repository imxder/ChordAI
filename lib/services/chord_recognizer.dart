import 'package:record/record.dart';

import '../models/chord_prediction.dart';

/// O que uma tela precisa de quem reconhece acordes. No app quem faz isso é
/// o OnDeviceChordService; nos testes entram reconhecedores falsos, que
/// fingem ouvir acordes sem carregar o modelo.
abstract class ChordRecognizer {
  bool get isRunning;

  Future<bool> hasPermission();

  Future<List<InputDevice>> listInputDevices();

  void selectDevice(InputDevice? device);

  Future<void> start({
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  });

  Future<void> stop();

  Future<void> dispose();
}
