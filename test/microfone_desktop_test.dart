import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/screens/practice_session_screen.dart';
import 'package:chordai/screens/recognize_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/audio_input.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/tuner_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

/// Reconhecedor falso que guarda o onError pra o teste simular o problema.
class _MicFalso implements ChordRecognizer {
  void Function(Object error)? onError;
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
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) async {
    this.onError = onError;
    _rodando = true;
  }

  @override
  Future<void> stop() async => _rodando = false;

  @override
  Future<void> dispose() => stop();
}

/// Afinador falso que guarda os callbacks pra o teste simular o áudio.
class _AfinadorFalso extends TunerService {
  int ligou = 0;
  void Function(double? frequency)? onPitch;
  void Function(MicrophoneProblem problem)? onProblem;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(
    void Function(double? frequency) onPitch, {
    void Function(MicrophoneProblem problem)? onProblem,
  }) async {
    ligou++;
    this.onPitch = onPitch;
    this.onProblem = onProblem;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Id do último AudioRecorder criado: o plugin manda os eventos dele num canal
/// com esse id no nome.
String? _idDoGravador;

/// O que o plugin mandaria pelo canal de eventos do gravador.
MockStreamHandlerEventSink? _eventos;

void _simularPlugin() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async {
      if (call.method == 'create') {
        _idDoGravador = (call.arguments as Map)['recorderId'] as String;
        messenger.setMockStreamHandler(
          EventChannel('com.llfbandit.record/events/$_idDoGravador'),
          MockStreamHandler.inline(
            onListen: (_, sink) {
              _eventos = sink;
            },
          ),
        );
      }
      return null;
    },
  );
}

/// Liga a observação num gravador novo e devolve os problemas avisados.
Future<List<MicrophoneProblem>> _observar() async {
  final avisos = <MicrophoneProblem>[];
  final recorder = AudioRecorder();
  addTearDown(recorder.dispose);
  final watch = watchMicrophone(recorder, avisos.add);
  expect(watch, isNotNull);
  addTearDown(() => watch?.cancel());
  // O gravador se registra no plugin e só depois começa a ouvir os eventos.
  for (var i = 0; i < 100 && _eventos == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(_eventos, isNotNull, reason: 'o app começou a ouvir os eventos');
  return avisos;
}

/// Dá tempo dos eventos simulados chegarem no app.
Future<void> _esperarEventos() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
    _idDoGravador = null;
    _eventos = null;
    _simularPlugin();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('acesso negado (0x80070005) é o microfone bloqueado', () {
    expect(
      MicrophoneProblem.fromError('Capture failed (0x80070005).'),
      MicrophoneProblem.blocked,
    );
    expect(
      MicrophoneProblem.fromError('Capture failed (0x88890004).'),
      MicrophoneProblem.failed,
    );
    expect(MicrophoneProblem.fromError(null), MicrophoneProblem.failed);
  });

  test('a mensagem do bloqueio diz onde liberar', () {
    expect(
      MicrophoneProblem.blocked.message,
      contains('Privacidade e segurança → Microfone'),
    );
  });

  test('no celular não observa nada', () {
    for (final celular in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = celular;
      expect(watchMicrophone(AudioRecorder(), (_) {}), isNull);
    }
  });

  group('no Windows', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.windows);

    test(
      'gravação parada com acesso negado avisa o bloqueio uma vez',
      () async {
        final avisos = await _observar();
        final parada = {
          'state': RecordState.stop.index,
          'reason': 'error',
          'error': 'Capture failed (0x80070005).',
        };
        _eventos!.success(parada);
        _eventos!.success(parada);
        await _esperarEventos();
        expect(avisos, [MicrophoneProblem.blocked]);
      },
    );

    test('gravação pausada pelo plugin é a entrada desconectada', () async {
      final avisos = await _observar();
      _eventos!.success(RecordState.pause.index);
      await _esperarEventos();
      expect(avisos, [MicrophoneProblem.disconnected]);
    });

    test('parada por troca de entrada também é desconexão', () async {
      final avisos = await _observar();
      _eventos!.success({
        'state': RecordState.stop.index,
        'reason': 'routeChange',
      });
      await _esperarEventos();
      expect(avisos, [MicrophoneProblem.disconnected]);
    });

    test('parar normal não é problema', () async {
      final avisos = await _observar();
      _eventos!.success({'state': RecordState.stop.index, 'reason': 'stop'});
      _eventos!.success({
        'state': RecordState.stop.index,
        'reason': 'interruption',
      });
      await _esperarEventos();
      expect(avisos, isEmpty);
    });
  });

  group('telas', () {
    testWidgets('reconhecer acorde volta pro Ouvir e diz onde liberar', (
      tester,
    ) async {
      final mic = _MicFalso();
      await tester.pumpWidget(appUnderTest(RecognizeScreen(recognizer: mic)));
      await tester.tap(find.text('Ouvir'));
      await settle(tester);
      expect(find.text('Parar'), findsOneWidget);

      mic.onError!(MicrophoneProblem.blocked);
      await settle(tester);
      expect(find.text(MicrophoneProblem.blocked.message), findsOneWidget);
      expect(find.text('Ouvir'), findsOneWidget);
    });

    testWidgets('testar acorde para quando a entrada some', (tester) async {
      final mic = _MicFalso();
      await tester.pumpWidget(
        appUnderTest(ChordPracticeScreen(chord: 'C', recognizer: mic)),
      );
      await tester.tap(find.text('Começar'));
      await settle(tester);
      mic.onError!(MicrophoneProblem.disconnected);
      await settle(tester);
      expect(find.text(MicrophoneProblem.disconnected.message), findsOneWidget);
      expect(mic.isRunning, isFalse);
      expect(find.text('Começar'), findsOneWidget);
    });

    testWidgets('sequências param o treino quando a entrada some', (
      tester,
    ) async {
      setScreen(tester, const Size(500, 1200));
      final mic = _MicFalso();
      await tester.pumpWidget(
        appUnderTest(PracticeSessionScreen(recognizer: mic)),
      );
      await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
      await settle(tester);
      await tester.tap(find.text('Começar'));
      await settle(tester);
      expect(appState.sessionStatus, SessionStatus.running);

      mic.onError!(MicrophoneProblem.disconnected);
      await settle(tester);
      expect(appState.sessionStatus, SessionStatus.idle);
      expect(find.text(MicrophoneProblem.disconnected.message), findsOneWidget);
    });

    testWidgets('outro erro continua com a mensagem de antes', (tester) async {
      final mic = _MicFalso();
      await tester.pumpWidget(appUnderTest(RecognizeScreen(recognizer: mic)));
      await tester.tap(find.text('Ouvir'));
      await settle(tester);
      mic.onError!(StateError('qualquer'));
      await settle(tester);
      expect(
        find.text('Não consegui reconhecer o acorde no aparelho.'),
        findsOneWidget,
      );
    });

    testWidgets('afinador mostra onde liberar e tenta de novo sozinho', (
      tester,
    ) async {
      final afinador = _AfinadorFalso();
      await tester.pumpWidget(appUnderTest(TunerScreen(service: afinador)));
      await settle(tester);
      expect(afinador.ligou, 1);

      afinador.onProblem!(MicrophoneProblem.blocked);
      await tester.pump();
      expect(find.text(MicrophoneProblem.blocked.message), findsOneWidget);

      // Depois de 3 s liga de novo; quando o áudio chega, a mensagem some.
      await tester.pump(const Duration(seconds: 3));
      expect(afinador.ligou, 2);
      afinador.onPitch!(null);
      await tester.pump();
      expect(find.text(MicrophoneProblem.blocked.message), findsNothing);
      expect(find.text('Toque uma corda solta'), findsOneWidget);
    });
  });
}
