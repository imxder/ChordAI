import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/models/lyric_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extrai acordes na ordem certa com a localização de cada um', () {
    const sheet = LyricSheet(
      title: 'Teste',
      key: 'C',
      sections: [
        LyricSection(
          title: 'Verso',
          lines: [
            LyricLine(chordLine: 'C', lyricText: 'Primeira linha'),
            LyricLine(lyricText: 'Linha sem acorde'),
            LyricLine(chordLine: 'G      Am', lyricText: 'Duas trocas na mesma linha'),
          ],
        ),
      ],
    );

    final map = buildLyricPracticeMap(sheet, beatsPerChord: 4);

    expect(map.score.steps.map((s) => s.chord).toList(), ['C', 'G', 'Am']);
    expect(map.score.steps.every((s) => s.beats == 4), isTrue);

    expect(map.locations[0].lineIndex, 0);
    expect(map.locations[0].tokenIndex, 0);

    expect(map.locations[1].lineIndex, 2);
    expect(map.locations[1].tokenIndex, 0);

    expect(map.locations[2].lineIndex, 2);
    expect(map.locations[2].tokenIndex, 1);
  });

  test('ignora seções sem nenhum acorde', () {
    const sheet = LyricSheet(
      title: 'Teste',
      sections: [
        LyricSection(title: 'Intro', lines: [LyricLine(lyricText: 'só letra')]),
      ],
    );

    final map = buildLyricPracticeMap(sheet);

    expect(map.score.steps, isEmpty);
    expect(map.locations, isEmpty);
  });
}
