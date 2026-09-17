import 'package:flutter_test/flutter_test.dart';

import 'package:chordai/main.dart';

void main() {
  testWidgets('HomePage shows the main actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ChordAIApp());
    await tester.pump();

    expect(find.text('ChordAI'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Praticar com partitura'), findsOneWidget);
    expect(find.text('Aprender acordes'), findsOneWidget);
    expect(find.text('Letra e cifra'), findsOneWidget);
    expect(find.text('Afinador'), findsOneWidget);
  });
}
