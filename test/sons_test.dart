import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/chord_list_screen.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/app_sounds.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/widgets/metronome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

const _em = ChordPrediction(status: 'ok', chord: 'Em', confidence: 0.9);
const _am = ChordPrediction(status: 'ok', chord: 'Am', confidence: 0.9);
const _silencio = ChordPrediction(status: 'silence');

void main() {
  late FakeSoundOutput sons;

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
    sons = useFakeSounds();
  });

  tearDown(() => appSounds = AppSounds(output: FakeSoundOutput()));

  Future<void> metronomo(WidgetTester tester, int batidas) async {
    await tester.pumpWidget(
      appUnderTest(Metronome(running: true, bpm: 120, onBeat: () {})),
    );
    for (var i = 0; i < batidas; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('metrônomo toca o clique forte no tempo 1 de cada compasso', (
    tester,
  ) async {
    await metronomo(tester, 8);
    expect(sons.played, [
      AppSound.clickStrong,
      AppSound.click,
      AppSound.click,
      AppSound.click,
      AppSound.clickStrong,
      AppSound.click,
      AppSound.click,
      AppSound.click,
    ]);
  });

  testWidgets('metrônomo começa no tempo 1 de novo quando para e volta', (
    tester,
  ) async {
    await metronomo(tester, 2);
    await tester.pumpWidget(
      appUnderTest(Metronome(running: false, bpm: 120, onBeat: () {})),
    );
    await metronomo(tester, 1);
    expect(sons.played, [
      AppSound.clickStrong,
      AppSound.click,
      AppSound.clickStrong,
    ]);
  });

  testWidgets('com Sons desligado o metrônomo não toca', (tester) async {
    await appState.setSoundsEnabled(false);
    await metronomo(tester, 4);
    expect(sons.played, isEmpty);
  });

  group('treino do acorde', () {
    Future<MicQueOuve> abrir(WidgetTester tester) async {
      final mic = MicQueOuve();
      await tester.pumpWidget(
        appUnderTest(ChordPracticeScreen(chord: 'Em', recognizer: mic)),
      );
      await tester.tap(find.text('Começar'));
      await settle(tester);
      return mic;
    }

    Future<void> ouvir(
      WidgetTester tester,
      MicQueOuve mic,
      List<ChordPrediction> leituras,
    ) async {
      for (final leitura in leituras) {
        mic.ouvir!(leitura);
        await tester.pump();
      }
    }

    testWidgets('acorde aprendido toca uma vez só', (tester) async {
      final mic = await abrir(tester);
      await ouvir(tester, mic, [_em, _silencio, _em, _silencio, _em]);
      expect(appState.isChordLearned('Em'), isTrue);
      expect(sons.played, [AppSound.chordLearned]);

      await tester.tap(find.byKey(const ValueKey('treinar de novo')));
      await settle(tester);
      await ouvir(tester, mic, [_em, _silencio, _em, _silencio, _em]);
      expect(find.text('Acertos seguidos: 3 de 3'), findsOneWidget);
      expect(sons.played, [AppSound.chordLearned]);
    });

    testWidgets('ignora as leituras logo depois do som de aprendido', (
      tester,
    ) async {
      final mic = await abrir(tester);
      await ouvir(tester, mic, [_em, _silencio, _em, _silencio, _em]);
      await ouvir(tester, mic, [_am]);
      expect(find.text('Ouvi Am. Tente de novo'), findsNothing);
      expect(
        find.text('Em entrou nos seus acordes aprendidos'),
        findsOneWidget,
      );

      await tester.pump(learnedSoundEcho);
      await ouvir(tester, mic, [_am]);
      expect(find.text('Ouvi Am. Tente de novo'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'depois de aprender, o microfone para e o botão leva aos acordes',
      (tester) async {
        final mic = await abrir(tester);
        await ouvir(tester, mic, [_em, _silencio, _em, _silencio, _em]);
        await settle(tester);
        expect(mic.isRunning, isFalse);
        expect(find.text('Começar'), findsNothing);
        expect(find.text('Parar'), findsNothing);
        expect(find.byKey(const ValueKey('ver meus acordes')), findsOneWidget);
        expect(find.byKey(const ValueKey('treinar de novo')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('treinar de novo')));
        await settle(tester);
        expect(mic.isRunning, isTrue);
        expect(find.text('Parar'), findsOneWidget);
        expect(find.text('Acertos seguidos: 0 de 3'), findsOneWidget);
      },
    );

    testWidgets('acorde que já estava aprendido continua com Começar', (
      tester,
    ) async {
      appState.registerChordHits('Em', 3);
      await abrir(tester);
      expect(find.text('Parar'), findsOneWidget);
      expect(find.byKey(const ValueKey('ver meus acordes')), findsNothing);
    });

    testWidgets('Ver meus acordes volta pra aba Acordes', (tester) async {
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await settle(tester);
      final mic = MicQueOuve();
      final navegador = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navegador.push(
        MaterialPageRoute<void>(
          builder: (_) => ChordPracticeScreen(chord: 'Em', recognizer: mic),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Começar'));
      await settle(tester);
      await ouvir(tester, mic, [_em, _silencio, _em, _silencio, _em]);
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('ver meus acordes')));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(navegador.canPop(), isFalse);
      final abas = tester.widget<IndexedStack>(find.byType(IndexedStack).first);
      expect(abas.index, 1);
      expect(find.byType(ChordListScreen).hitTestable(), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('com Sons desligado o aprendido não toca', (tester) async {
      await appState.setSoundsEnabled(false);
      final mic = await abrir(tester);
      await ouvir(tester, mic, [_em, _silencio, _em, _silencio, _em]);
      expect(appState.isChordLearned('Em'), isTrue);
      expect(sons.played, isEmpty);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('afinador', () {
    Future<AfinadorQueOuve> abrir(WidgetTester tester) async {
      final afinador = AfinadorQueOuve();
      await tester.pumpWidget(appUnderTest(TunerScreen(service: afinador)));
      await settle(tester);
      return afinador;
    }

    testWidgets('toca uma vez por entrada na afinação', (tester) async {
      final afinador = await abrir(tester);
      afinador.ouvir(110.0);
      afinador.ouvir(110.0);
      await tester.pump();
      expect(sons.played, [AppSound.inTune]);

      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 5; i++) {
        afinador.ouvir(110.0);
      }
      await tester.pump();
      expect(sons.played, [AppSound.inTune]);

      afinador.ouvir(104.0);
      afinador.ouvir(110.0);
      afinador.ouvir(110.0);
      await tester.pump();
      expect(sons.played, [AppSound.inTune, AppSound.inTune]);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('o ponteiro não se mexe logo depois do ding', (tester) async {
      final afinador = await abrir(tester);
      afinador.ouvir(110.0);
      afinador.ouvir(110.0);
      await tester.pump();
      expect(find.text('Afinada'), findsOneWidget);

      afinador.ouvir(104.0);
      await tester.pump();
      expect(find.text('Afinada'), findsOneWidget);

      await tester.pump(inTuneSoundEcho);
      afinador.ouvir(104.0);
      await tester.pump();
      expect(find.text('Afinada'), findsNothing);
    });

    testWidgets('com Sons desligado o afinado não toca', (tester) async {
      await appState.setSoundsEnabled(false);
      final afinador = await abrir(tester);
      afinador.ouvir(110.0);
      afinador.ouvir(110.0);
      await tester.pump();
      expect(find.text('Afinada'), findsOneWidget);
      expect(sons.played, isEmpty);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  testWidgets('a linha Sons nos Ajustes liga, desliga e fica salva', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const SettingsScreen()));
    await settle(tester);
    expect(appState.soundsEnabled, isTrue);

    final linha = find.byKey(const ValueKey('sons'));
    await tester.ensureVisible(linha);
    await settle(tester);
    await tester.tap(linha);
    await settle(tester);
    expect(appState.soundsEnabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('app_sounds'), isFalse);

    await appState.loadProgress();
    expect(appState.soundsEnabled, isFalse);
  });

  test('o iPhone só liga o som quando o microfone liga', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(appSounds.prepareAtLaunch, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(appSounds.prepareAtLaunch, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('o som é preparado quando o microfone liga', (tester) async {
    final afinador = AfinadorQueOuve();
    await tester.pumpWidget(appUnderTest(TunerScreen(service: afinador)));
    await settle(tester);
    expect(sons.prepared, 1);
  });
}
