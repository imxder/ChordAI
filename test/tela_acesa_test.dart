import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/lyric_sheet_screen.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/screen_awake.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

void main() {
  final pedidos = <bool>[];
  final cifra = parseCifra(
    'Tempo: 100\n${[for (var i = 0; i < 30; i++) '[Parte $i]\nAm  G  C  F\n'].join()}',
    title: 'x',
  );

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
    pedidos.clear();
    wakelockToggle = (on) async => pedidos.add(on);
  });

  testWidgets('a tela fica acesa só enquanto a cifra rola sozinha', (
    tester,
  ) async {
    await tester.pumpWidget(
      appUnderTest(LyricSheetScreen(sheet: cifra, serverUrl: 'http://x')),
    );
    await tester.tap(find.text('Rolar'));
    await tester.pump();
    expect(pedidos, [true]);

    await tester.tap(find.text('Parar'));
    await tester.pump();
    expect(pedidos, [true, false]);
  });

  testWidgets('a tela fica acesa só enquanto o tocar junto roda', (
    tester,
  ) async {
    await tester.pumpWidget(
      appUnderTest(
        LyricPlayerScreen(
          sheet: cifra,
          serverUrl: 'http://x',
          recognizer: _MicFalso(),
        ),
      ),
    );
    await tester.tap(find.text('Começar'));
    await tester.pump();
    expect(pedidos, [true]);

    await tester.tap(find.text('Parar'));
    await tester.pump();
    expect(pedidos.last, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}

class _MicFalso implements ChordRecognizer {
  @override
  bool isRunning = false;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<List<InputDevice>> listInputDevices() async => const [];
  @override
  void selectDevice(InputDevice? device) {}
  @override
  Future<void> start({
    String? serverUrl,
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) async => isRunning = true;
  @override
  Future<void> stop() async => isRunning = false;
  @override
  Future<void> dispose() async {}
}
