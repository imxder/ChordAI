import '../state/app_state.dart';
import 'chord_recognizer.dart';
import 'on_device_chord_service.dart';

ChordRecognizer createChordRecognizer({bool rawReadings = false}) {
  return OnDeviceChordService(
    () => appState.onDeviceModel,
    rawReadings: rawReadings,
  );
}

/// Mensagem a mostrar quando o reconhecimento falha.
const chordRecognitionErrorMessage =
    'Não consegui reconhecer o acorde no aparelho.';
