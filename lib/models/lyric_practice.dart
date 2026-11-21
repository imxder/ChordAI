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

  List<int> stepsInSection(int sectionIndex) => [
    for (var i = 0; i < locations.length; i++)
      if (locations[i].sectionIndex == sectionIndex) i,
  ];

  List<int> beatsFor(int sectionIndex, int lineIndex) => [
    for (var i = 0; i < locations.length; i++)
      if (locations[i].sectionIndex == sectionIndex &&
          locations[i].lineIndex == lineIndex)
        score.steps[i].beats,
  ];
}

final RegExp _chordTokenPattern = RegExp(r'\S+');

LyricPracticeMap buildLyricPracticeMap(
  LyricSheet sheet, {
  int beatsPerChord = 4,
}) {
  final steps = <ChordStep>[];
  final locations = <LyricChordLocation>[];

  for (
    var sectionIndex = 0;
    sectionIndex < sheet.sections.length;
    sectionIndex++
  ) {
    final section = sheet.sections[sectionIndex];
    for (var lineIndex = 0; lineIndex < section.lines.length; lineIndex++) {
      final chordLine = section.lines[lineIndex].chordLine;
      if (chordLine == null || chordLine.trim().isEmpty) continue;

      final tokens = _chordTokenPattern.allMatches(chordLine).toList();
      for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
        final chord = tokens[tokenIndex].group(0)!;
        final beats = section.lines[lineIndex].chordBeats;
        steps.add(
          ChordStep(
            chord: chord,
            beats:
                (tokenIndex < beats.length ? beats[tokenIndex] : null) ??
                sheet.beatsByChord[chord] ??
                sheet.beatsPerChord ??
                beatsPerChord,
          ),
        );
        locations.add(
          LyricChordLocation(
            sectionIndex: sectionIndex,
            lineIndex: lineIndex,
            tokenIndex: tokenIndex,
          ),
        );
      }
    }
  }

  return LyricPracticeMap(
    score: Score(title: sheet.title, steps: steps),
    locations: locations,
  );
}
