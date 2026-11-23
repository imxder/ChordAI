import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/chord_list_screen.dart';
import 'package:chordai/screens/lyric_sheet_list_screen.dart';
import 'package:chordai/screens/recognize_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/audio_input.dart';
import 'package:chordai/services/tuner_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

final _microfonesLigados = <Object?>{};
var _ligou = 0;

void _microfoneFalso() {
  _microfonesLigados.clear();
  _ligou = 0;
  final binding = TestDefaultBinaryMessengerBinding.instance;
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async {
      final id = (call.arguments as Map?)?['recorderId'];
      switch (call.method) {
        case 'hasPermission':
          return true;
        case 'isRecording':
          return _microfonesLigados.contains(id);
        case 'create':
          for (final nome in ['eventsRecord', 'events']) {
            binding.defaultBinaryMessenger.setMockStreamHandler(
              EventChannel('com.llfbandit.record/$nome/$id'),
              MockStreamHandler.inline(onListen: (_, _) {}),
            );
          }
        case 'startStream':
        case 'start':
          _ligou++;
          _microfonesLigados.add(id);
        case 'stop':
        case 'cancel':
        case 'dispose':
          _microfonesLigados.remove(id);
      }
      return null;
    },
  );
}

Future<void> _espera(WidgetTester tester) async {
  await settle(tester);
  await tester.pump(const Duration(seconds: 1));
}

Finder _aba(String nome) =>
    find.descendant(of: find.byKey(appTabBarKey), matching: find.text(nome));

void main() {
  setUp(() async {
    mockPlatform();
    _microfoneFalso();
    await appState.loadProgress();
  });

  testWidgets('a barra do celular é Início, Acordes, Reconhecer e Afinador', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    for (final nome in ['Início', 'Acordes', 'Reconhecer', 'Afinador']) {
      expect(_aba(nome), findsOneWidget, reason: nome);
    }
    expect(_aba('Músicas'), findsNothing);
    expect(_aba('Perfil'), findsNothing);
  });

  testWidgets('o microfone só liga na aba que está aparecendo', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    expect(find.byType(TunerScreen), findsNothing);
    expect(find.byType(RecognizeScreen), findsNothing);
    expect(_ligou, 0);

    await tester.tap(_aba('Afinador'));
    await _espera(tester);
    expect(find.byType(TunerScreen), findsOneWidget);
    expect(_ligou, 1);
    final afinador = tester.state(find.byType(TunerScreen));

    await tester.tap(_aba('Início'));
    await _espera(tester);
    expect(find.byType(TunerScreen), findsNothing);
    expect(afinador.mounted, isFalse);

    await tester.tap(_aba('Reconhecer'));
    await _espera(tester);
    expect(find.byType(RecognizeScreen), findsOneWidget);
    expect(find.byType(TunerScreen), findsNothing);
    expect(_ligou, 1);

    await tester.tap(_aba('Afinador'));
    await _espera(tester);
    expect(find.byType(RecognizeScreen), findsNothing);
    expect(find.byType(TunerScreen), findsOneWidget);
    expect(_ligou, 2);
  });

  testWidgets('o afinador desliga o microfone quando sai da tela', (
    tester,
  ) async {
    final servico = _AfinadorFalso();
    await tester.pumpWidget(appUnderTest(TunerScreen(service: servico)));
    await _espera(tester);
    expect(servico.ligado, isTrue);
    await tester.pumpWidget(const SizedBox());
    await _espera(tester);
    expect(servico.ligado, isFalse);
  });

  testWidgets('Acordes é aba, e o card de acordes troca pra ela', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    await tester.tap(find.text('Aprender acordes'));
    await _espera(tester);
    expect(find.byType(ChordListScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Tocar músicas abre a lista por cima, com voltar', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    await tester.tap(find.text('Tocar músicas'));
    await _espera(tester);
    expect(find.byType(LyricSheetListScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _espera(tester);
    expect(find.byType(LyricSheetListScreen), findsNothing);
  });

  testWidgets('as configurações abrem pela engrenagem e voltam', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    await tester.tap(
      find.byKey(const ValueKey('abrir ajustes')).hitTestable().first,
    );
    await _espera(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _espera(tester);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('o início do celular tem só os dois cards em destaque', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    expect(find.text('Aprender acordes'), findsOneWidget);
    expect(find.text('Tocar músicas'), findsOneWidget);
    expect(find.text('Reconhecer acorde'), findsNothing);
    expect(find.text('O app diz qual acorde ouviu'), findsNothing);
  });

  testWidgets('voltar do Android leva pra Início antes de sair', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    await tester.tap(_aba('Acordes'));
    await _espera(tester);
    expect(find.byType(ChordListScreen), findsOneWidget);
    final handled = await tester.binding.handlePopRoute();
    await _espera(tester);
    expect(handled, isTrue);
    expect(find.text('Tocar músicas'), findsOneWidget);
  });

  testWidgets('o computador continua com as mesmas abas na barra lateral', (
    tester,
  ) async {
    setScreen(tester, const Size(1200, 800));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await _espera(tester);
    expect(find.byKey(appTabBarKey), findsNothing);
    expect(find.byKey(appSideBarKey), findsOneWidget);
    for (final aba in [
      'Início',
      'Afinador',
      'Aprender acordes',
      'Reconhecer acorde',
      'Guia do iniciante',
      'Músicas',
      'Configurações',
    ]) {
      expect(find.byKey(ValueKey('aba $aba')), findsOneWidget, reason: aba);
    }
    expect(find.byKey(const ValueKey('abrir ajustes')), findsNothing);
    expect(find.text('Reconhecer acorde'), findsWidgets);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}

class _AfinadorFalso extends TunerService {
  bool ligado = false;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(
    void Function(double? frequency) onPitch, {
    void Function(MicrophoneProblem problem)? onProblem,
  }) async => ligado = true;

  @override
  Future<void> stop() async => ligado = false;

  @override
  Future<void> dispose() => stop();
}
