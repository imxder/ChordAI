import 'package:chordai/models/on_device_model.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/recognition_settings_screen.dart';
import 'package:chordai/screens/recognize_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/on_device_chord_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
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

  group('sem modo servidor', () {
    setUp(() async {
      mockPlatform();
      SharedPreferences.setMockInitialValues({'app_on_device_model': 'v3Meu'});
      await appState.loadProgress();
    });

    testWidgets('as telas de prática não mostram selo de reconhecimento', (
      tester,
    ) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(appUnderTest(const RecognizeScreen()));
      await tester.pump();
      expect(find.textContaining('No aparelho'), findsNothing);
      expect(find.textContaining('Reconhecendo'), findsNothing);
      expect(find.textContaining('dataset'), findsNothing);
    });

    testWidgets('o tocar junto mostra só o artista e o andamento', (
      tester,
    ) async {
      final cifra = parseCifra('Tempo: 90\n[Intro]\nAm  G\n', title: 'x');
      await tester.pumpWidget(appUnderTest(LyricPlayerScreen(sheet: cifra)));
      await tester.pump();
      expect(find.text('90 BPM'), findsOneWidget);
      expect(find.textContaining('No aparelho'), findsNothing);
    });

    testWidgets(
      'Reconhecimento nas configurações mostra o modelo e só a escolha dele',
      (tester) async {
        setScreen(tester, const Size(390, 1600));
        await tester.pumpWidget(appUnderTest(const SettingsScreen()));
        await tester.pump();
        expect(find.text('v3 + meu dataset'), findsOneWidget);

        await tester.tap(find.text('Reconhecimento'));
        await settle(tester);
        expect(find.byType(RecognitionSettingsScreen), findsOneWidget);
        expect(find.text('Modelo no aparelho'), findsOneWidget);
        expect(find.text('Servidor'), findsNothing);
        expect(find.byType(TextField), findsNothing);

        await tester.tap(find.text('Só v3'));
        await settle(tester);
        expect(appState.onDeviceModel, OnDeviceModel.v3);
      },
    );
  });
}
