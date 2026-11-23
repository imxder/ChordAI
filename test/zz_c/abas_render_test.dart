import 'package:chordai/main.dart' show appLocalizationsDelegates;
import 'package:chordai/models/app_theme.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

const _fase = String.fromEnvironment('FASE', defaultValue: 'antes');

TextStyle? _f(TextStyle? t) =>
    t == null || t.fontFamily != null ? t : t.copyWith(fontFamily: 'Roboto');

Widget _app(AppAppearance a) {
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
        labelMedium: _f(tt.labelMedium),
        labelSmall: _f(tt.labelSmall),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStatePropertyAll(_f(tt.labelMedium)),
      ),
    ),
    home: const AppShell(),
  );
}

void main() {
  setUpAll(() async => loadAppFonts());
  for (final (p, n) in [
    (TargetPlatform.iOS, 'ios'),
    (TargetPlatform.android, 'android'),
  ]) {
    for (final (a, an) in [
      (AppAppearance.paper, 'claro'),
      (AppAppearance.dark, 'escuro'),
    ]) {
      testWidgets('$n $an', (tester) async {
        debugDefaultTargetPlatformOverride = p;
        mockPlatform();
        SharedPreferences.setMockInitialValues({
          'app_learned_chords': ['Em', 'Am', 'C'],
        });
        await appState.loadProgress();
        setScreen(tester, const Size(390, 844));
        await tester.pumpWidget(_app(a));
        await tester.pump(const Duration(milliseconds: 500));
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('abas/${_fase}_${n}_$an.png'),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
