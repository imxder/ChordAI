import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/screens/lyric_sheet_screen.dart';
import 'package:chordai/widgets/guitar_neck.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  setUp(mockPlatform);

  testWidgets('tocar num acorde da cifra abre o diagrama dele', (tester) async {
    const sheet = LyricSheet(
      title: 'Teste',
      sections: [
        LyricSection(
          title: 'Intro',
          lines: [LyricLine(chordLine: 'C', lyricText: 'Linha de teste')],
        ),
      ],
    );

    await tester.pumpWidget(
      appUnderTest(
        const LyricSheetScreen(
          sheet: sheet,
          serverUrl: 'http://localhost:5001',
        ),
      ),
    );

    expect(find.byType(GuitarNeck), findsNothing);

    await tester.tap(find.textContaining('C'));
    await settle(tester);

    expect(find.text('Dó maior'), findsOneWidget);
    expect(find.byType(GuitarNeck), findsOneWidget);
  });

  testWidgets('rolar desce a cifra sozinho e parar interrompe', (tester) async {
    final sheet = LyricSheet(
      title: 'Longa',
      sections: [
        LyricSection(
          title: 'Verso',
          lines: [
            for (var i = 0; i < 60; i++)
              LyricLine(chordLine: 'C', lyricText: 'Linha $i'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      appUnderTest(
        LyricSheetScreen(sheet: sheet, serverUrl: 'http://localhost:5001'),
      ),
    );
    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    expect(offset(), 0);

    await tester.tap(find.text('Rolar'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final afterRolling = offset();
    expect(afterRolling, greaterThan(0));

    await tester.tap(find.text('Parar'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(offset(), closeTo(afterRolling, 2));
    expect(find.text('Rolar'), findsOneWidget);
  });
}
