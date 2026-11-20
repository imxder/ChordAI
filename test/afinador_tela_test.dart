import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

bool _auto(WidgetTester tester) =>
    tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value;

bool _selecionada(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isSelected
        .toBoolOrNull() ??
    false;

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  testWidgets('afinador abre no Auto', (tester) async {
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);
    expect(find.text('Reconhecer a corda sozinho'), findsOneWidget);
    expect(_auto(tester), isTrue);
  });

  testWidgets('tocar na casinha escolhe a corda e desliga o Auto', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Afinar a 5ª corda'));
    await settle(tester);

    expect(_auto(tester), isFalse);
    expect(_selecionada(tester, 'Afinar a 5ª corda'), isTrue);
    expect(_selecionada(tester, 'Afinar a 6ª corda'), isFalse);

    // Ligando o Auto de novo, nenhuma casinha fica escolhida.
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    expect(_auto(tester), isTrue);
    expect(_selecionada(tester, 'Afinar a 5ª corda'), isFalse);
    semantics.dispose();
  });

  testWidgets('desligar o Auto sem corda tocando escolhe a 6ª', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);

    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);

    expect(_auto(tester), isFalse);
    expect(_selecionada(tester, 'Afinar a 6ª corda'), isTrue);
    semantics.dispose();
  });
}
