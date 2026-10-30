import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chordai/main.dart';

void main() {
  testWidgets('HomePage shows the main actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    expect(find.text('vamos tocar'), findsOneWidget);
    expect(find.text('Guia do iniciante'), findsOneWidget);
    expect(find.text('Aprender acordes'), findsOneWidget);
    expect(find.text('Tocar músicas'), findsOneWidget);
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Treino livre (IA)'), findsOneWidget);
  });
}
