import 'dart:io';

import 'package:chordai/models/chord_recognition_mode.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/services/chord_recognition_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('janelas que sobraram na pasta temporária', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('chordai_teste'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('apaga só os WAVs do modo servidor', () async {
      for (final name in [
        'chordai_janela_1731900000000.wav',
        'chordai_janela_1731900001500.wav',
        'chord_1731800000000.wav', // nome da versão 0.1.0
        'outro_app.wav',
        'chordai_janela_.wav',
        'anotacoes.txt',
      ]) {
        File('${dir.path}/$name').writeAsStringSync('x');
      }

      final apagados = await ChordRecognitionService.deleteLeftoverWindows(dir);

      expect(apagados, 3);
      final sobrou = dir.listSync().map((e) => e.uri.pathSegments.last).toSet();
      expect(sobrou, {'outro_app.wav', 'chordai_janela_.wav', 'anotacoes.txt'});
    });

    test('pasta que não existe não quebra', () async {
      final sumiu = Directory('${dir.path}/nao_existe');
      expect(await ChordRecognitionService.deleteLeftoverWindows(sumiu), 0);
    });

    test('o nome que o serviço grava é o mesmo que ele apaga depois', () {
      final name = ChordRecognitionService.windowFileName(DateTime.now());
      expect(ChordRecognitionService.windowFilePattern.hasMatch(name), isTrue);
    });
  });

  group('tela do modo servidor', () {
    setUp(() async {
      mockPlatform();
      await appState.loadProgress();
      await appState.setChordRecognitionMode(ChordRecognitionMode.server);
    });

    Future<void> openSettings(WidgetTester tester) async {
      await tester.pumpWidget(
        appUnderTest(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await settle(tester);
    }

    testWidgets('mostra o aviso de que o áudio vai sem criptografia', (
      tester,
    ) async {
      await openSettings(tester);
      expect(find.text(serverModeWarning), findsOneWidget);
      expect(serverModeWarning, contains('sem criptografia'));
    });

    testWidgets('no modo no aparelho não mostra o aviso', (tester) async {
      await appState.setChordRecognitionMode(ChordRecognitionMode.onDevice);
      await openSettings(tester);
      expect(find.text(serverModeWarning), findsNothing);
    });

    testWidgets('endereço inválido mostra o erro e não salva', (tester) async {
      await openSettings(tester);
      await tester.enterText(find.byType(TextField), '8.8.8.8:5000');
      await tester.tap(find.text('Salvar'));
      await settle(tester);

      expect(
        find.textContaining('Sem https, só endereço da rede local'),
        findsOneWidget,
      );
      expect(appState.serverUrl, isNot(contains('8.8.8.8')));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('endereço válido salva arrumado e volta', (tester) async {
      await openSettings(tester);
      await tester.enterText(find.byType(TextField), '192.168.0.10:5000/');
      await tester.tap(find.text('Salvar'));
      // espera a animação de voltar terminar (aqui não tem a aba Músicas girando)
      await tester.pumpAndSettle();

      expect(appState.serverUrl, 'http://192.168.0.10:5000');
      expect(find.byType(SettingsScreen), findsNothing);
    });
  });
}
