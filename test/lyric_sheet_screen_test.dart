import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/screens/lyric_sheet_screen.dart';
import 'package:chordai/widgets/guitar_neck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      const MaterialApp(home: LyricSheetScreen(sheet: sheet)),
    );

    expect(find.byType(GuitarNeck), findsNothing);

    await tester.tap(find.textContaining('C'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(GuitarNeck), findsOneWidget);
  });
}
