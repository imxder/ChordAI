import 'package:chordai/main.dart' show appLocalizationsDelegates;
import 'package:chordai/models/app_theme.dart';
import 'package:chordai/models/guide_content.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/guide_detail_screen.dart';
import 'package:chordai/screens/guide_list_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:chordai/widgets/guitar_parts_drawing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

TextStyle? _f(TextStyle? t) =>
    t == null || t.fontFamily != null ? t : t.copyWith(fontFamily: 'Roboto');

Widget _app(Widget home, AppAppearance a) {
  final base = buildAppTheme(appThemeOptions[0], appearance: a);
  final tt = base.textTheme;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: const [Locale('pt', 'BR')],
    locale: const Locale('pt', 'BR'),
    theme: base.copyWith(
      textTheme: tt.copyWith(
        labelLarge: _f(tt.labelLarge),
        bodyMedium: _f(tt.bodyMedium),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(_f(tt.labelLarge)),
        ),
      ),
    ),
    home: home,
  );
}

void main() {
  setUpAll(() async => loadAppFonts());
  final telas = <String, Widget Function()>{
    'lista': () => const GuideListScreen(),
    for (final t in guideTopics) t.id: () => GuideDetailScreen(topic: t),
  };
  for (final (a, an) in [
    (AppAppearance.paper, 'claro'),
    (AppAppearance.dark, 'escuro'),
  ]) {
    for (final e in telas.entries) {
      testWidgets('ios ${e.key} $an', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        mockPlatform();
        SharedPreferences.setMockInitialValues({
          'app_guide_read': ['partes', 'postura'],
        });
        await appState.loadProgress();
        setScreen(tester, const Size(390, 1500));
        await tester.pumpWidget(_app(e.value(), a));
        await tester.pump(const Duration(milliseconds: 500));
        final desenho = find.byType(GuitarPartsDrawing);
        if (desenho.evaluate().isNotEmpty) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(GuitarPartsDrawing.asset),
              tester.element(desenho),
            ),
          );
          await tester.pump();
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('guia/ios_${e.key}_$an.png'),
        );
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
  for (final (p, n) in [
    (TargetPlatform.windows, 'windows'),
    (TargetPlatform.macOS, 'macos'),
  ]) {
    testWidgets('home $n', (tester) async {
      debugDefaultTargetPlatformOverride = p;
      mockPlatform();
      await appState.loadProgress();
      setScreen(tester, const Size(1200, 1100));
      await tester.pumpWidget(_app(const AppShell(), AppAppearance.paper));
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('guia/home_$n.png'),
      );
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
