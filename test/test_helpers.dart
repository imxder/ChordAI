import 'dart:io';

import 'package:chordai/main.dart' show appLocalizationsDelegates;
import 'package:chordai/models/app_theme.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chordFonts = ['IBMPlexMono-Regular.ttf', 'IBMPlexMono-SemiBold.ttf'];
const _textFonts = ['Regular', 'Medium', 'SemiBold', 'Bold'];

bool _fontsLoaded = false;

/// Sem as fontes reais o teste usa a Ahem, bem mais larga, e acusa estouro que não existe.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final chord = FontLoader(fontChord);
  for (final file in _chordFonts) {
    chord.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await chord.load();
  for (final (family, file) in [
    ('PhosphorRegular', 'Phosphor.ttf'),
    ('PhosphorFill', 'Phosphor-Fill.ttf'),
    ('PhosphorDuotone', 'Phosphor-Duotone.ttf'),
  ]) {
    await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file'))).load();
  }
  // No iPhone o texto sai em SF Pro; no teste a Roboto faz esse papel.
  for (final family in [
    'Roboto',
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.SF Pro Text',
    '.SF Pro Display',
    '.SF UI Text',
    '.SF UI Display',
    '.AppleSystemUIFont',
  ]) {
    final loader = FontLoader(family);
    for (final weight in _textFonts) {
      final bytes = File('test/fonts/Roboto-$weight.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  final pubCache = Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['LOCALAPPDATA']}/Pub/Cache';
  final cupertinoDirs = Directory('$pubCache/hosted/pub.dev')
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('cupertino_icons-'));
  for (final dir in cupertinoDirs) {
    final file = File('${dir.path}/assets/CupertinoIcons.ttf');
    if (!file.existsSync()) continue;
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync()))))
        .load();
    break;
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final bytes = icons.readAsBytesSync();
      await (FontLoader('MaterialIcons')
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  }
  _fontsLoaded = true;
}

void mockPlatform() {
  SharedPreferences.setMockInitialValues({});
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async => call.method == 'hasPermission' ? false : null,
  );
}

Widget appUnderTest(Widget home, {AppAppearance appearance = AppAppearance.paper}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: appLocalizationsDelegates,
    theme: buildAppTheme(
      appThemeOptions[appState.selectedThemeIndex],
      appearance: appearance,
    ),
    home: home,
  );
}

/// Troca o pumpAndSettle: a aba Músicas fica montada com um indicador girando
/// enquanto carrega, e aí o pumpAndSettle nunca termina.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void setScreen(WidgetTester tester, Size size, {double textScale = 1.0}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
