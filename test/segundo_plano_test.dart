import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/cifra_parser.dart';
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
}
