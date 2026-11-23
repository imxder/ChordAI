import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/chord_detail_screen.dart';
import 'package:chordai/screens/chord_list_screen.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/lyric_sheet_list_screen.dart';
import 'package:chordai/screens/practice_session_screen.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/chord_recognizer_factory.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/lyric_sheet_library.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

class _MicQueFalha implements ChordRecognizer {
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
    onError(Exception('modelo não carregou'));
  }

  @override
  Future<void> stop() async => isRunning = false;
  @override
  Future<void> dispose() async {}
}

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  group('abrir uma tela a partir de outra', () {
    testWidgets('acorde da lista abre o detalhe, e o detalhe abre o teste', (
      tester,
    ) async {
      setScreen(tester, const Size(390, 1400));
      await tester.pumpWidget(appUnderTest(const ChordListScreen()));
      await settle(tester);
      await tester.tap(find.text('Em').first);
      await settle(tester);
      expect(find.byType(ChordDetailScreen), findsOneWidget);

      await tester.tap(find.text('Tocar e testar'));
      await settle(tester);
      expect(find.byType(ChordPracticeScreen), findsOneWidget);
    });

    testWidgets('músicas abre as sequências de acordes', (tester) async {
      await tester.runAsync(() => LyricSheetLibrary().loadAll());
      setScreen(tester, const Size(390, 1400));
      await tester.pumpWidget(appUnderTest(const LyricSheetListScreen()));
      await settle(tester);
      await tester.tap(find.text('Sequências de acordes'));
      await settle(tester);
      expect(find.byType(PracticeSessionScreen), findsOneWidget);
    });
  });

  group('se o reconhecimento falha, aparece a mensagem fixa', () {
    testWidgets('testar acorde', (tester) async {
      await tester.pumpWidget(
        appUnderTest(
          ChordPracticeScreen(chord: 'C', recognizer: _MicQueFalha()),
        ),
      );
      await tester.tap(find.text('Começar'));
      await settle(tester);
      expect(find.text(chordRecognitionErrorMessage), findsOneWidget);
    });

    testWidgets('tocar junto', (tester) async {
      final cifra = parseCifra('Tempo: 90\n[Intro]\nAm  G\n', title: 'x');
      await tester.pumpWidget(
        appUnderTest(
          LyricPlayerScreen(sheet: cifra, recognizer: _MicQueFalha()),
        ),
      );
      await tester.tap(find.text('Começar'));
      await settle(tester);
      expect(find.text(chordRecognitionErrorMessage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
