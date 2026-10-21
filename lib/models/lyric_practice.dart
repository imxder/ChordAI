import 'lyric_sheet.dart';
import 'score.dart';

class LyricChordLocation {
  final int sectionIndex;
  final int lineIndex;
  final int tokenIndex;

  const LyricChordLocation({
    required this.sectionIndex,
    required this.lineIndex,
    required this.tokenIndex,
  });
}

class LyricPracticeMap {
  final Score score;
  final List<LyricChordLocation> locations;

  const LyricPracticeMap({required this.score, required this.locations});
}

final RegExp _chordTokenPattern = RegExp(r'\S+');

LyricPracticeMap buildLyricPracticeMap(LyricSheet sheet, {int beatsPerChord = 4}) {
  final steps = <ChordStep>[];
  final locations = <LyricChordLocation>[];

  for (var sectionIndex = 0; sectionIndex < sheet.sections.length; sectionIndex++) {
    final section = sheet.sections[sectionIndex];
    for (var lineIndex = 0; lineIndex < section.lines.length; lineIndex++) {
      final chordLine = section.lines[lineIndex].chordLine;
      if (chordLine == null || chordLine.trim().isEmpty) continue;

      final tokens = _chordTokenPattern.allMatches(chordLine).toList();
      for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
        steps.add(ChordStep(chord: tokens[tokenIndex].group(0)!, beats: beatsPerChord));
        locations.add(LyricChordLocation(
          sectionIndex: sectionIndex,
          lineIndex: lineIndex,
          tokenIndex: tokenIndex,
        ));
      }
    }
  }

  return LyricPracticeMap(
    score: Score(title: sheet.title, steps: steps),
    locations: locations,
  );
}
