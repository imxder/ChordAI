import 'dart:io';

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

const _fase = String.fromEnvironment('FASE');
const _saida = String.fromEnvironment('SAIDA');

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
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        labelTextStyle: WidgetStatePropertyAll(_f(tt.labelMedium)),
      ),
    ),
    home: const AppShell(),
  );
}

Future<void> _foto(WidgetTester tester, String nome) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_saida/${_fase}_$nome.png'),
  );
}

Future<void> _pausa(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
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
        await _pausa(tester);
        await _foto(tester, '${n}_${an}_inicio');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
        await _pausa(tester);
        await _foto(tester, '${n}_${an}_inicio_rolado');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
        await _pausa(tester);
        final abrir = find.byKey(const ValueKey('abrir ajustes')).hitTestable();
        final perfil = find.byKey(const ValueKey('abrir perfil')).hitTestable();
        await tester.tap((abrir.evaluate().isNotEmpty ? abrir : perfil).first);
        await _pausa(tester);
        await _foto(tester, '${n}_${an}_ajustes');
        if (n == 'android') {
          await tester.binding.handlePopRoute();
          await _pausa(tester);
          await tester.tap(
            find.descendant(
              of: find.byKey(appTabBarKey),
              matching: find.text('Acordes'),
            ),
          );
          await _pausa(tester);
          await _foto(tester, '${n}_${an}_acordes');
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
  for (final (p, n) in [
    (TargetPlatform.windows, 'windows'),
    (TargetPlatform.macOS, 'macos'),
  ]) {
    for (final (a, an) in [
      (AppAppearance.paper, 'claro'),
      (AppAppearance.dark, 'escuro'),
    ]) {
      testWidgets('$n $an', (tester) async {
        debugDefaultTargetPlatformOverride = p;
        mockPlatform();
        await appState.loadProgress();
        setScreen(tester, const Size(1200, 800));
        await tester.pumpWidget(_app(a));
        await _pausa(tester);
        await _foto(tester, '${n}_${an}_barra');
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
  if (File('x').existsSync()) {}
}
