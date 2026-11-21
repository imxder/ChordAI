import 'package:chordai/widgets/chord_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> _mostrar(
  WidgetTester tester,
  List<BarChord> acordes, {
  int? ativo,
  int? tempo,
}) async {
  mockPlatform();
  setScreen(tester, const Size(390, 844));
  await tester.pumpWidget(
    appUnderTest(
      Scaffold(
        body: ChordBars(chords: acordes, activeStep: ativo, activeBeat: tempo),
      ),
    ),
  );
}

int _quantos(WidgetTester tester, String texto) =>
    find.text(texto).evaluate().length;

void main() {
  testWidgets('Am 2, G 2 e C 4 viram dois compassos', (tester) async {
    await _mostrar(tester, const [
      BarChord('Am', 2, 0),
      BarChord('G', 2, 1),
      BarChord('C', 4, 2),
    ]);
    expect(_quantos(tester, 'Am'), 1);
    expect(_quantos(tester, 'C'), 1);
    for (final n in ['1', '2', '3', '4']) {
      expect(_quantos(tester, n), 2, reason: 'tempo $n nos dois compassos');
    }
    final am = tester.getTopLeft(find.text('Am'));
    final c = tester.getTopLeft(find.text('C'));
    expect(c.dy, am.dy);
    expect(c.dx, greaterThan(am.dx));
  });

  testWidgets('acorde de 8 tempos ocupa dois compassos', (tester) async {
    await _mostrar(tester, const [BarChord('F', 8, 0)]);
    expect(_quantos(tester, 'F'), 2);
    expect(_quantos(tester, '1'), 2);
    expect(_quantos(tester, '4'), 2);
  });

  testWidgets('o tempo da vez acende só no acorde da vez', (tester) async {
    await _mostrar(
      tester,
      const [BarChord('Am', 2, 0), BarChord('G', 2, 1), BarChord('C', 4, 2)],
      ativo: 2,
      tempo: 2,
    );
    final acesos = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.fontWeight == FontWeight.w700)
        .map((t) => t.data)
        .toList();
    expect(acesos, ['3']);
  });
}
