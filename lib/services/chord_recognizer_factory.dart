import '../models/chord_recognition_mode.dart';
import 'chord_recognition_service.dart';
import 'chord_recognizer.dart';
import 'on_device_chord_service.dart';

ChordRecognizer createChordRecognizer(ChordRecognitionMode mode) {
  switch (mode) {
    case ChordRecognitionMode.server:
      return ChordRecognitionService();
    case ChordRecognitionMode.onDevice:
      return OnDeviceChordService();
  }
}

/// Mensagem a mostrar quando o serviço de reconhecimento falha — no modo
/// servidor, sugere trocar pro aparelho em vez de trocar sozinho.
String chordRecognitionErrorMessage(ChordRecognitionMode mode) {
  switch (mode) {
    case ChordRecognitionMode.server:
      return 'Não consegui falar com o servidor. Em Configurações, você '
          'pode trocar o reconhecimento de acordes para "No aparelho".';
    case ChordRecognitionMode.onDevice:
      return 'Não consegui reconhecer o acorde no aparelho.';
  }
}
