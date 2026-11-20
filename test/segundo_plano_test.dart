import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/screens/free_practice_screen.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/practice_session_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/audio_input.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/tuner_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

/// Reconhecedor que só conta quantas vezes o microfone ligou e desligou.
class _MicFalso implements ChordRecognizer {
  int ligou = 0;
  int desligou = 0;
  bool _rodando = false;

  @override
  bool get isRunning => _rodando;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<List<InputDevice>> listInputDevices() async => const [];

  @override
  void selectDevice(InputDevice? device) {}

  @override
  Future<void> start({
    String? serverUrl,
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) async {
    ligou++;
    _rodando = true;
  }

  @override
  Future<void> stop() async {
    if (_rodando) desligou++;
    _rodando = false;
  }

  @override
  Future<void> dispose() => stop();
}

/// Afinador que só conta quantas vezes o microfone ligou e desligou.
class _AfinadorFalso extends TunerService {
  int ligou = 0;
  bool rodando = false;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(
    void Function(double? frequency) onPitch, {
    void Function(MicrophoneProblem problem)? onProblem,
  }) async {
    ligou++;
    rodando = true;
  }

  @override
  Future<void> stop() async => rodando = false;

  @override
  Future<void> dispose() => stop();
}

/// O app vai pra segundo plano (ou o celular bloqueia): o sistema passa por
/// inactive e depois hidden.
Future<void> _esconder(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  await tester.pump();
}

Future<void> _mostrar(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  testWidgets('tocar junto pausa escondido e continua quando o app volta', (
    tester,
  ) async {
    setScreen(tester, const Size(500, 1200));
    final mic = _MicFalso();
    final cifra = parseCifra('Tempo: 100\nAm  G\nletra\n', title: 'x');
    await tester.pumpWidget(
      appUnderTest(
        LyricPlayerScreen(sheet: cifra, serverUrl: 'http://x', recognizer: mic),
      ),
    );
    await tester.tap(find.text('Começar'));
    await tester.pump();
    expect(mic.ligou, 1);
    expect(appState.sessionStatus, SessionStatus.running);

    await _esconder(tester);
    expect(mic.isRunning, isFalse, reason: 'microfone desligado escondido');
    expect(
      appState.sessionStatus,
      SessionStatus.running,
      reason: 'a música só pausa, não acaba',
    );

    await _mostrar(tester);
    expect(mic.ligou, 2, reason: 'o microfone liga de novo');
    expect(mic.isRunning, isTrue);

    await tester.tap(find.text('Parar'));
    await tester.pump();
  });

  testWidgets('tocar junto parado não liga o microfone quando o app volta', (
    tester,
  ) async {
    setScreen(tester, const Size(500, 1200));
    final mic = _MicFalso();
    final cifra = parseCifra('Tempo: 100\nAm  G\nletra\n', title: 'x');
    await tester.pumpWidget(
      appUnderTest(
        LyricPlayerScreen(sheet: cifra, serverUrl: 'http://x', recognizer: mic),
      ),
    );
    await _esconder(tester);
    await _mostrar(tester);
    expect(mic.ligou, 0);
  });

  testWidgets('afinador pergunta a permissão de novo quando o app volta', (
    tester,
  ) async {
    var perguntas = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (call) async {
            if (call.method == 'hasPermission') {
              perguntas++;
              return false;
            }
            return null;
          },
        );
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);
    expect(perguntas, 1);
    expect(
      find.text('O afinador precisa de acesso ao microfone'),
      findsOneWidget,
    );

    await _esconder(tester);
    await _mostrar(tester);
    await settle(tester);
    expect(
      perguntas,
      2,
      reason: 'se a pessoa liberou nas Configurações, o afinador já funciona',
    );
  });

  testWidgets('afinador desliga escondido e liga sozinho quando o app volta', (
    tester,
  ) async {
    final afinador = _AfinadorFalso();
    await tester.pumpWidget(appUnderTest(TunerScreen(service: afinador)));
    await settle(tester);
    expect(afinador.rodando, isTrue);

    await _esconder(tester);
    expect(afinador.rodando, isFalse);

    await _mostrar(tester);
    await settle(tester);
    expect(afinador.ligou, 2);
    expect(afinador.rodando, isTrue);
  });

  testWidgets('reconhecer acorde para escondido e fica parado na volta', (
    tester,
  ) async {
    final mic = _MicFalso();
    await tester.pumpWidget(
      appUnderTest(FreePracticeScreen(serverUrl: 'http://x', recognizer: mic)),
    );
    await tester.tap(find.text('Ouvir'));
    await settle(tester);
    expect(mic.isRunning, isTrue);

    await _esconder(tester);
    await settle(tester);
    expect(mic.isRunning, isFalse);

    // Escondido o Flutter não desenha a tela; o botão só aparece na volta.
    await _mostrar(tester);
    await settle(tester);
    expect(mic.ligou, 1, reason: 'só volta a ouvir se a pessoa tocar em Ouvir');
    expect(find.text('Ouvir'), findsOneWidget);
  });

  testWidgets('testar acorde para escondido', (tester) async {
    final mic = _MicFalso();
    await tester.pumpWidget(
      appUnderTest(
        ChordPracticeScreen(serverUrl: 'http://x', chord: 'C', recognizer: mic),
      ),
    );
    await tester.tap(find.text('Começar'));
    await settle(tester);
    expect(mic.isRunning, isTrue);

    await _esconder(tester);
    await settle(tester);
    expect(mic.isRunning, isFalse);

    await _mostrar(tester);
    await settle(tester);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('sequências param o treino escondido', (tester) async {
    setScreen(tester, const Size(500, 1200));
    final mic = _MicFalso();
    await tester.pumpWidget(
      appUnderTest(
        PracticeSessionScreen(serverUrl: 'http://x', recognizer: mic),
      ),
    );
    // As sequências vêm dos assets: espera carregar.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await settle(tester);
    await tester.tap(find.text('Começar'));
    await settle(tester);
    expect(mic.isRunning, isTrue);
    expect(appState.sessionStatus, SessionStatus.running);

    await _esconder(tester);
    await settle(tester);
    expect(mic.isRunning, isFalse);
    expect(appState.sessionStatus, SessionStatus.idle);
  });
}
