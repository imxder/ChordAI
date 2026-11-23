import 'package:chordai/main.dart' show appLocalizationsDelegates;
import 'package:chordai/models/app_theme.dart';
import 'package:chordai/screens/onboarding_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(_f(tt.labelLarge)),
        ),
      ),
    ),
    home: home,
  );
}

void main() {
  setUpAll(() async => loadAppFonts());
  for (final (pl, n) in [
    (TargetPlatform.macOS, 'macos'),
    (TargetPlatform.windows, 'windows'),
  ]) {
    testWidgets('desk $n', (tester) async {
      debugDefaultTargetPlatformOverride = pl;
      mockPlatform();
      await appState.loadProgress();
      setScreen(tester, const Size(1200, 800));
      await tester.pumpWidget(
        _app(const OnboardingScreen(), AppAppearance.paper),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('onb/${n}_0.png'),
      );
      await tester.tap(find.text('Continuar'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('onb/${n}_1.png'),
      );
      await tester.tap(find.text('Pular'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('onb/${n}_afinado.png'),
      );
      debugDefaultTargetPlatformOverride = null;
    });
  }
  for (final (a, an) in [
    (AppAppearance.paper, 'claro'),
    (AppAppearance.dark, 'escuro'),
  ]) {
    testWidgets('onb $an', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      mockPlatform();
      await appState.loadProgress();
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(const OnboardingScreen(), a));
      await tester.pump(const Duration(milliseconds: 300));
      for (var p = 0; p < 3; p++) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('onb/${an}_$p.png'),
        );
        if (p < 2) {
          await tester.tap(find.text('Continuar'));
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
      }
      await tester.pumpWidget(_app(const SettingsScreen(), a));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('onb/${an}_ajustes.png'),
      );
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
