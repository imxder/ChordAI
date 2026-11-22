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
import 'package:chordai/screens/privacy_screen.dart';
import 'package:chordai/screens/recognition_settings_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/screens/tuning_check_screen.dart';
import 'package:chordai/services/lyric_sheet_library.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

final _screens = <String, Widget Function(LyricSheet sheet)>{
  'início': (_) => const AppShell(),
  'onboarding': (_) => const OnboardingScreen(),
  'afinou?': (_) => const TuningCheckScreen(),
  'detalhe do acorde': (_) => const ChordDetailScreen(chord: 'Bdim'),
  'testar acorde': (_) => const ChordPracticeScreen(chord: 'F'),
  'cifra': (sheet) => LyricSheetScreen(sheet: sheet),
  'tocar junto': (sheet) => LyricPlayerScreen(sheet: sheet),
  'sequências': (_) => const PracticeSessionScreen(),
  'reconhecer': (_) => const FreePracticeScreen(),
  'afinador': (_) => const TunerScreen(),
  'afinação personalizada': (_) => const CustomTuningScreen(),
  'reconhecimento': (_) => const RecognitionSettingsScreen(),
  'ajustes': (_) => const SettingsScreen(),
  'guia': (_) => const GuideListScreen(),
  'guia detalhe': (_) => GuideDetailScreen(topic: guideTopicById('afinar')),
  'guia partes': (_) => GuideDetailScreen(topic: guideTopicById('partes')),
  'guia diagrama': (_) => GuideDetailScreen(topic: guideTopicById('diagrama')),
  'guia cifra': (_) => GuideDetailScreen(topic: guideTopicById('cifra')),
  'guia batida': (_) => GuideDetailScreen(topic: guideTopicById('batida')),
  'privacidade': (_) => const PrivacyScreen(),
};

const _setups = <String, (Size, double)>{
  'celular pequeno': (Size(360, 640), 1.0),
  'deitado': (Size(740, 360), 1.0),
  'fonte grande': (Size(360, 740), 1.6),
  'tablet': (Size(1024, 768), 1.0),
};

// Janela do computador: o tamanho com que abre e o mínimo (ver
// windows/runner/main.cpp). Rodam como Windows, com a barra lateral.
const _desktopSetups = <String, Size>{
  'janela inicial': Size(1200, 800),
  'janela mínima': Size(800, 560),
};

final _windows = TargetPlatformVariant.only(TargetPlatform.windows);

final _celulares = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.iOS,
});

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
        sheet = (await tester.runAsync(() => LyricSheetLibrary().loadAll()))!
            .first;
        final (size, scale) = setup.value;
        setScreen(tester, size, textScale: scale);

        await tester.pumpWidget(appUnderTest(screen.value(sheet)));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 500));
      }, variant: _celulares);
    }

    testWidgets(
      'abas do app cabem na tela (${setup.key})',
      (tester) async {
        final (size, scale) = setup.value;
        setScreen(tester, size, textScale: scale);
        await tester.pumpWidget(appUnderTest(const AppShell()));
        await tester.pump(const Duration(milliseconds: 300));

        for (final tab in ['Acordes', 'Reconhecer', 'Afinador']) {
          await tester.tap(
            find
                .descendant(
                  of: find.byKey(appTabBarKey),
                  matching: find.text(tab),
                )
                .first,
          );
          await tester.pump(const Duration(milliseconds: 300));
        }
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );

    testWidgets('tocar junto em andamento cabe na tela (${setup.key})', (
      tester,
    ) async {
      sheet = (await tester.runAsync(() => LyricSheetLibrary().loadAll()))!
          .first;
      final (size, scale) = setup.value;
      setScreen(tester, size, textScale: scale);
      await tester.pumpWidget(appUnderTest(LyricPlayerScreen(sheet: sheet)));
      await tester.pump();

      appState.startSession(buildLyricPracticeMap(sheet).score);
      await tester.pump(const Duration(seconds: 3));

      appState.stopSession();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  for (final setup in _desktopSetups.entries) {
    for (final screen in _screens.entries) {
      testWidgets('${screen.key} cabe na janela (${setup.key})', (
        tester,
      ) async {
        sheet = (await tester.runAsync(() => LyricSheetLibrary().loadAll()))!
            .first;
        setScreen(tester, setup.value);
        await tester.pumpWidget(appUnderTest(screen.value(sheet)));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 500));
      }, variant: _windows);
    }

    testWidgets('abas da barra lateral cabem na janela (${setup.key})', (
      tester,
    ) async {
      setScreen(tester, setup.value);
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await tester.pump(const Duration(milliseconds: 300));
      for (final tab in [
        'Afinador',
        'Aprender acordes',
        'Reconhecer acorde',
        'Guia do iniciante',
        'Músicas',
        'Configurações',
        'Início',
      ]) {
        await tester.tap(find.byKey(ValueKey('aba $tab')));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }, variant: _windows);

    testWidgets('tocar junto em andamento cabe na janela (${setup.key})', (
      tester,
    ) async {
      sheet = (await tester.runAsync(() => LyricSheetLibrary().loadAll()))!
          .first;
      setScreen(tester, setup.value);
      await tester.pumpWidget(appUnderTest(LyricPlayerScreen(sheet: sheet)));
      await tester.pump();
      appState.startSession(buildLyricPracticeMap(sheet).score);
      await tester.pump(const Duration(seconds: 3));
      appState.stopSession();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }, variant: _windows);
  }
}
