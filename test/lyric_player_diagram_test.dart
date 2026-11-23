import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/widgets/cifra_line.dart';
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
          lines: [LyricLine(chordLine: 'C', lyricText: 'Linha de teste')],
        ),
      ],
    );

    await tester.pumpWidget(
      appUnderTest(const LyricPlayerScreen(sheet: sheet)),
    );

    await settle(tester);
    final antes = tester.widgetList(find.byType(GuitarNeck)).length;
    final nomes = tester.widgetList(find.text('Dó maior')).length;

    await tester.tap(
      find
          .descendant(
            of: find.byType(CifraLine),
            matching: find.textContaining('C'),
          )
          .first,
    );
    await settle(tester);

    expect(find.text('Dó maior'), findsNWidgets(nomes + 1));
    expect(find.byType(GuitarNeck), findsNWidgets(antes + 1));
  });
}
