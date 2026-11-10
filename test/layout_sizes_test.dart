import 'package:chordai/models/guide_content.dart';
import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/chord_detail_screen.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/screens/custom_tuning_screen.dart';
import 'package:chordai/screens/free_practice_screen.dart';
import 'package:chordai/screens/guide_detail_screen.dart';
import 'package:chordai/screens/guide_list_screen.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/lyric_sheet_screen.dart';
import 'package:chordai/screens/onboarding_screen.dart';
import 'package:chordai/screens/practice_session_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/screens/tuning_check_screen.dart';
import 'package:chordai/services/lyric_sheet_library.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _url = 'http://localhost:5001';

final _screens = <String, Widget Function(LyricSheet sheet)>{
  'início': (_) => const AppShell(),
  'onboarding': (_) => const OnboardingScreen(),
  'afinou?': (_) => const TuningCheckScreen(),
  'detalhe do acorde': (_) => const ChordDetailScreen(serverUrl: _url, chord: 'Bdim'),
  'testar acorde': (_) => const ChordPracticeScreen(serverUrl: _url, chord: 'F'),
  'cifra': (sheet) => LyricSheetScreen(sheet: sheet, serverUrl: _url),
  'tocar junto': (sheet) => LyricPlayerScreen(sheet: sheet, serverUrl: _url),
  'sequências': (_) => const PracticeSessionScreen(serverUrl: _url),
  'reconhecer': (_) => const FreePracticeScreen(serverUrl: _url),
  'afinador': (_) => const TunerScreen(),
  'afinação personalizada': (_) => const CustomTuningScreen(),
  'servidor': (_) => const SettingsScreen(),
  'guia': (_) => const GuideListScreen(),
  'guia detalhe': (_) => GuideDetailScreen(topic: guideTopics[2]),
};

const _setups = <String, (Size, double)>{
  'celular pequeno': (Size(360, 640), 1.0),
  'deitado': (Size(740, 360), 1.0),
  'fonte grande': (Size(360, 740), 1.6),
  'tablet': (Size(1024, 768), 1.0),
};

void main() {
  late LyricSheet sheet;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  for (final setup in _setups.entries) {
    for (final screen in _screens.entries) {
      testWidgets('${screen.key} cabe na tela (${setup.key})', (tester) async {
        sheet = (await tester.runAsync(() => LyricSheetLibrary().loadAll()))!.first;
        final (size, scale) = setup.value;
        setScreen(tester, size, textScale: scale);

        await tester.pumpWidget(appUnderTest(screen.value(sheet)));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 500));

      });
    }

    testWidgets('abas do app cabem na tela (${setup.key})', (tester) async {
      final (size, scale) = setup.value;
      setScreen(tester, size, textScale: scale);
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await tester.pump(const Duration(milliseconds: 300));

      for (final tab in ['Músicas', 'Acordes', 'Perfil']) {
        await tester.tap(find.descendant(
          of: find.byKey(appTabBarKey),
          matching: find.text(tab),
        ).first);
        await tester.pump(const Duration(milliseconds: 300));
      }
    }, variant: TargetPlatformVariant(
      {TargetPlatform.android, TargetPlatform.iOS},
    ));

    testWidgets('tocar junto em andamento cabe na tela (${setup.key})', (tester) async {
      sheet = (await tester.runAsync(() => LyricSheetLibrary().loadAll()))!.first;
      final (size, scale) = setup.value;
      setScreen(tester, size, textScale: scale);
      await tester.pumpWidget(appUnderTest(LyricPlayerScreen(sheet: sheet, serverUrl: _url)));
      await tester.pump();

      appState.startSession(buildLyricPracticeMap(sheet).score);
      await tester.pump(const Duration(seconds: 3));

      appState.stopSession();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
