import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/screens/lyric_sheet_screen.dart';
import 'package:chordai/widgets/guitar_neck.dart';
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
          lines: [
            LyricLine(chordLine: 'C', lyricText: 'Linha de teste'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      appUnderTest(
        const LyricSheetScreen(sheet: sheet, serverUrl: 'http://localhost:5001'),
      ),
    );

    expect(find.byType(GuitarNeck), findsNothing);

    await tester.tap(find.textContaining('C'));
    await settle(tester);

    expect(find.text('Dó maior'), findsOneWidget);
    expect(find.byType(GuitarNeck), findsOneWidget);
  });
}
