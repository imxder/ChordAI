import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/lyric_sheet_list_screen.dart';
import 'package:chordai/services/app_sounds.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/widgets/metronome.dart';
import 'package:chordai/widgets/practice_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

final _cifra = parseCifra('Tempo: 120\n[Intro]\nAm  G\n', title: 'Teste');

void main() {
  late FakeSoundOutput sons;
  late Duration agora;

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
    sons = useFakeSounds();
    agora = Duration.zero;
  });

  tearDown(() => appSounds = AppSounds(output: FakeSoundOutput()));

  Future<_MicFalso> abrir(WidgetTester tester) async {
    final mic = _MicFalso();
    await tester.pumpWidget(
      appUnderTest(
        LyricPlayerScreen(sheet: _cifra, recognizer: mic, elapsed: () => agora),
      ),
    );
    await settle(tester);
    return mic;
  }

  Future<void> andar(WidgetTester tester, Duration tempo) async {
    const passo = Duration(milliseconds: 30);
    for (var t = Duration.zero; t < tempo; t += passo) {
      agora += passo;
      await tester.pump(passo);
    }
  }

  Future<void> sair(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('o tocar junto toca o clique, forte no tempo 1', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Começar'));
    await andar(tester, const Duration(milliseconds: 2100));
    expect(sons.played.take(5).toList(), [
      AppSound.clickStrong,
      AppSound.click,
      AppSound.click,
      AppSound.click,
      AppSound.clickStrong,
    ]);
    await sair(tester);
  });

  testWidgets('sem o som do metrônomo o tocar junto não clica', (tester) async {
    await appState.setMetronomeSound(false);
    await abrir(tester);
    await tester.tap(find.text('Começar'));
    await andar(tester, const Duration(milliseconds: 2100));
    expect(sons.played, isEmpty);
    await sair(tester);
  });

  testWidgets('sem o som do metrônomo as sequências não clicam', (
    tester,
  ) async {
    await appState.setMetronomeSound(false);
    await tester.pumpWidget(
      appUnderTest(Metronome(running: true, bpm: 120, onBeat: () {})),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(sons.played, isEmpty);
  });

  testWidgets('sem o microfone a cifra anda no tempo e nada é conferido', (
    tester,
  ) async {
    await appState.setPlayAlongListens(false);
    final mic = await abrir(tester);
    await tester.tap(find.text('Começar'));
    await andar(tester, const Duration(milliseconds: 3600));
    expect(mic.pediuPermissao, isFalse);
    expect(mic.isRunning, isFalse);
    expect(appState.currentStepIndex, 0);
    expect(find.text('Toque este acorde'), findsOneWidget);

    await andar(tester, const Duration(seconds: 12));
    expect(find.text('Música concluída'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(appState.sessionHits + appState.sessionMisses, 0);
    expect(sons.played, isNotEmpty);
    await sair(tester);
  });

  testWidgets('sem o microfone a música começa a 60% do tempo', (
    tester,
  ) async {
    await appState.setPlayAlongListens(false);
    await abrir(tester);
    expect(find.text('72'), findsOneWidget);
    await sair(tester);
  });

  testWidgets('com o microfone a música começa no tempo dela', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('120'), findsOneWidget);
    await sair(tester);
  });

  testWidgets('o BPM escolhido fica salvo pra próxima vez', (tester) async {
    await abrir(tester);
    await tester.tap(find.bySemanticsLabel('Diminuir andamento'));
    await tester.tap(find.bySemanticsLabel('Diminuir andamento'));
    await tester.pump();
    expect(find.text('118'), findsOneWidget);
    await sair(tester);

    await appState.loadProgress();
    await appState.setPlayAlongListens(false);
    await abrir(tester);
    expect(find.text('118'), findsOneWidget);
    await sair(tester);
  });

  testWidgets('com o microfone ligado o tocar junto continua ouvindo', (
    tester,
  ) async {
    final mic = await abrir(tester);
    await tester.tap(find.text('Começar'));
    await settle(tester);
    expect(mic.pediuPermissao, isTrue);
    expect(mic.isRunning, isTrue);
    await sair(tester);
  });

  testWidgets('as opções novas ficam no Aa e são salvas', (tester) async {
    await tester.pumpWidget(
      appUnderTest(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showPracticeOptionsSheet(context),
            child: const Text('Aa'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aa'));
    await settle(tester);
    expect(find.text('Esperar por mim'), findsOneWidget);

    final microfone = find.byKey(const ValueKey('ouvir pelo microfone'));
    await tester.ensureVisible(microfone);
    await tester.tap(microfone);
    await settle(tester);
    expect(appState.playAlongListens, isFalse);
    expect(find.text('Esperar por mim'), findsNothing);

    final metronomo = find.byKey(const ValueKey('som do metrônomo'));
    await tester.ensureVisible(metronomo);
    await tester.tap(metronomo);
    await settle(tester);
    expect(appState.metronomeSound, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('app_play_along_listens'), isFalse);
    expect(prefs.getBool('app_metronome_sound'), isFalse);
  });

  testWidgets('abrir uma música da lista vai direto pro tocar junto', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const LyricSheetListScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await settle(tester);
    final musica = find.text('Riptide').first;
    await tester.ensureVisible(musica);
    await tester.tap(musica);
    await settle(tester);
    expect(find.byType(LyricPlayerScreen), findsOneWidget);
    expect(find.text('Rolar'), findsNothing);
    await sair(tester);
  });
}

class _MicFalso implements ChordRecognizer {
  bool pediuPermissao = false;
  @override
  bool isRunning = false;
  @override
  Future<bool> hasPermission() async => pediuPermissao = true;
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
  }

  @override
  Future<void> stop() async => isRunning = false;
  @override
  Future<void> dispose() async {}
}
