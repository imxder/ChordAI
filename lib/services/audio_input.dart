import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../state/app_state.dart';

/// Só no Windows e no Mac dá pra escolher a entrada de áudio, porque no
/// computador é comum ter mais de uma (microfone, interface, webcam). No
/// celular o app sempre usa a entrada padrão do sistema, como antes.
bool get canChooseAudioInput =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// A entrada escolhida nas Configurações, se ela ainda estiver conectada.
///
/// Devolve `null` (entrada padrão do sistema) no celular, quando nada foi
/// escolhido, ou quando a entrada salva foi desconectada: gravar pedindo um
/// id que não existe mais falha, então nesse caso usa a padrão.
Future<InputDevice?> chosenInputDevice(AudioRecorder recorder) async {
  final savedId = appState.inputDeviceId;
  if (!canChooseAudioInput || savedId == null) return null;
  final devices = await recorder.listInputDevices();
  for (final device in devices) {
    if (device.id == savedId) return device;
  }
  return null;
}
