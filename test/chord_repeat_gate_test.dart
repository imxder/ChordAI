import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/models/chord_repeat_gate.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/chord_recognizer_factory.dart';
import 'package:chordai/services/on_device_chord_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

const _em = ChordPrediction(status: 'ok', chord: 'Em', confidence: 0.9);
const _am = ChordPrediction(status: 'ok', chord: 'Am', confidence: 0.9);
const _silencio = ChordPrediction(status: 'silence');
const _naoReconheci = ChordPrediction(status: 'unknown', confidence: 0.3);

int _acertos(List<ChordPrediction> leituras) {
  final gate = ChordRepeatGate('Em');
  var acertos = 0;
  for (final leitura in leituras) {
    switch (gate.process(leitura)) {
      case ChordRepeatEvent.hit:
        acertos++;
      case ChordRepeatEvent.miss:
        acertos = 0;
      default:
    }
  }
  return acertos;
}

class _MicQueOuve implements ChordRecognizer {
  void Function(ChordPrediction)? ouvir;
  @override
  bool isRunning = false;
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
    isRunning = true;
    ouvir = onPrediction;
  }

  @override
  Future<void> stop() async => isRunning = false;
  @override
  Future<void> dispose() async {}
}

void main() {
  group('regra do treino de acorde', () {
    test('Em, Em, Em sem nada no meio conta 1', () {
      expect(_acertos([_em, _em, _em]), 1);
    });

    test('Em, silêncio, Em, silêncio, Em conta 3', () {
      expect(_acertos([_em, _silencio, _em, _silencio, _em]), 3);
    });

    test('Em, não reconheci, Em conta 2', () {
      expect(_acertos([_em, _naoReconheci, _em]), 2);
    });

    test('acorde errado no meio zera', () {
      expect(_acertos([_em, _silencio, _em, _am]), 0);
      expect(_acertos([_em, _silencio, _em, _am, _em]), 1);
    });

    test(
      'silêncio ou não reconheci antes do primeiro acerto não fazem nada',
      () {
        final gate = ChordRepeatGate('Em');
        expect(gate.process(_silencio), ChordRepeatEvent.none);
        expect(gate.process(_naoReconheci), ChordRepeatEvent.none);
        expect(gate.process(_em), ChordRepeatEvent.hit);
        expect(gate.process(_em), ChordRepeatEvent.stillRinging);
        expect(gate.process(_silencio), ChordRepeatEvent.released);
      },
    );

    testWidgets('o treino recebe as leituras pelo ChordStabilizer', (
      tester,
    ) async {
      mockPlatform();
      final reconhecedor = createChordRecognizer();
      expect(reconhecedor, isA<OnDeviceChordService>());
      expect((reconhecedor as OnDeviceChordService).rawReadings, isFalse);
    });
  });

  group('tela de treino', () {
    setUp(() async {
      mockPlatform();
      await appState.loadProgress();
    });

    Future<_MicQueOuve> abrir(WidgetTester tester) async {
      final mic = _MicQueOuve();
      await tester.pumpWidget(
        appUnderTest(ChordPracticeScreen(chord: 'Em', recognizer: mic)),
      );
      await tester.tap(find.text('Começar'));
      await settle(tester);
      return mic;
    }

    testWidgets('tocar uma vez e deixar soando conta só 1', (tester) async {
      final mic = await abrir(tester);
      for (var i = 0; i < 6; i++) {
        mic.ouvir!(_em);
        await tester.pump();
      }
      expect(find.text('Acertos seguidos: 1 de 3'), findsOneWidget);
      expect(
        find.text('Certo! Abafe as cordas e toque de novo'),
        findsOneWidget,
      );
      expect(appState.isChordLearned('Em'), isFalse);
    });

    testWidgets('com silêncio entre as batidas chega a 3 e aprende', (
      tester,
    ) async {
      final mic = await abrir(tester);
      for (final leitura in [_em, _silencio, _em, _silencio, _em]) {
        mic.ouvir!(leitura);
        await tester.pump();
      }
      expect(find.text('Acertos seguidos: 3 de 3'), findsOneWidget);
      expect(appState.isChordLearned('Em'), isTrue);
    });

    testWidgets('depois de abafar, a tela pede pra tocar de novo', (
      tester,
    ) async {
      final mic = await abrir(tester);
      mic.ouvir!(_em);
      await tester.pump();
      mic.ouvir!(_silencio);
      await tester.pump();
      expect(find.text('Agora toque de novo'), findsOneWidget);
    });
  });
}
