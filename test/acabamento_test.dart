import 'package:chordai/screens/free_practice_screen.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/on_device_chord_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  test('nível do microfone vai de 0 (silêncio) a 1 (violão perto)', () {
    expect(micLevel(0), 0);
    expect(micLevel(0.001), closeTo(0, 1e-9));
    expect(micLevel(0.3), 1);
    expect(micLevel(1), 1);
    expect(micLevel(0.02), inExclusiveRange(0.3, 0.6));
  });

  group('selo do reconhecimento', () {
    setUp(() async {
      mockPlatform();
      SharedPreferences.setMockInitialValues({'app_on_device_model': 'v3Meu'});
      await appState.loadProgress();
    });

    testWidgets('sai da barra de título e aparece inteiro no conteúdo', (
      tester,
    ) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(
        appUnderTest(const FreePracticeScreen(serverUrl: 'http://x')),
      );
      await tester.pump();
      expect(
        find.text('Reconhecendo: No aparelho · v3 + meu dataset'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CupertinoNavigationBar),
          matching: find.textContaining('No aparelho'),
        ),
        findsNothing,
      );
    });

    testWidgets('no tocar junto vai junto do artista e do andamento', (
      tester,
    ) async {
      final cifra = parseCifra('Tempo: 90\n[Intro]\nAm  G\n', title: 'x');
      await tester.pumpWidget(
        appUnderTest(LyricPlayerScreen(sheet: cifra, serverUrl: 'http://x')),
      );
      await tester.pump();
      expect(
        find.textContaining('90 BPM · No aparelho · v3 + meu dataset'),
        findsOneWidget,
      );
    });
  });
}
