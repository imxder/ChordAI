import 'package:flutter_test/flutter_test.dart';

import 'package:chordai/main.dart';

void main() {
  testWidgets('HomePage shows placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const ChordAIApp());

    expect(find.text('ChordAI'), findsOneWidget);
    expect(find.text('Reconhecimento de acordes em breve'), findsOneWidget);
  });
}
