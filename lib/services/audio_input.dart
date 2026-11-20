import 'dart:async';

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

/// O que pode dar errado com o microfone no computador depois que a gravação
/// já começou. O Windows não avisa antes: o `record` sempre diz que tem
/// permissão, e a gravação começa e para na hora.
enum MicrophoneProblem {
  /// Configurações → Privacidade bloqueou o microfone pros apps da área de
  /// trabalho. O Windows encerra a gravação com o erro 0x80070005 (acesso
  /// negado).
  blocked(
    'O Windows está bloqueando o microfone. Libere em Configurações → '
    'Privacidade e segurança → Microfone, na opção "Permitir que aplicativos '
    'da área de trabalho acessem o microfone".',
  ),

  /// A entrada foi desconectada no meio da gravação (cabo USB puxado). O
  /// `record` pausa a gravação esperando a entrada voltar.
  disconnected(
    'A entrada de áudio foi desconectada. Conecte de novo e comece outra vez.',
  ),

  /// Qualquer outro erro que o Windows mande.
  failed(
    'O microfone parou de responder. Confira a entrada de áudio e comece '
    'outra vez.',
  );

  const MicrophoneProblem(this.message);

  /// Texto que a tela mostra.
  final String message;

  /// Traduz o erro que o `record` manda quando a gravação para sozinha.
  static MicrophoneProblem fromError(String? error) =>
      error != null && error.contains('0x80070005') ? blocked : failed;
}

/// Fica de olho numa gravação que já começou e chama [onProblem] uma vez se
/// ela parar sozinha. Só no Windows e no Mac: no celular devolve `null` e
/// nada muda.
MicrophoneWatch? watchMicrophone(
  AudioRecorder recorder,
  void Function(MicrophoneProblem problem) onProblem,
) {
  if (!canChooseAudioInput) return null;
  return MicrophoneWatch._(recorder, onProblem);
}

class MicrophoneWatch {
  MicrophoneWatch._(AudioRecorder recorder, this._onProblem) {
    _stopped = recorder.onStopped().listen((stop) {
      switch (stop.reason) {
        case RecordStopReason.error:
          _report(MicrophoneProblem.fromError(stop.error));
        case RecordStopReason.routeChange:
          _report(MicrophoneProblem.disconnected);
        case RecordStopReason.stop:
        case RecordStopReason.interruption:
          break;
      }
    });
    // O app nunca pausa a gravação; quem pausa é o `record`, quando a
    // entrada some.
    _state = recorder.onStateChanged().listen((state) {
      if (state == RecordState.pause) _report(MicrophoneProblem.disconnected);
    });
  }

  final void Function(MicrophoneProblem problem) _onProblem;
  late final StreamSubscription<RecordStop> _stopped;
  late final StreamSubscription<RecordState> _state;
  bool _reported = false;

  void _report(MicrophoneProblem problem) {
    if (_reported) return;
    _reported = true;
    _onProblem(problem);
  }

  /// Parar de observar. Chame antes de parar a gravação, senão o próprio
  /// stop vira aviso.
  Future<void> cancel() async {
    _reported = true;
    await _stopped.cancel();
    await _state.cancel();
  }
}
