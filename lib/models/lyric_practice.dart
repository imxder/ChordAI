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

  List<List<int>> phrasesInSection(int sectionIndex, {int beats = 8}) {
    final phrases = <List<int>>[];
    var current = <int>[];
    var total = 0;
    for (final i in stepsInSection(sectionIndex)) {
      current.add(i);
      total += score.steps[i].beats;
      if (total >= beats) {
        phrases.add(current);
        current = [];
        total = 0;
      }
    }
    if (current.isNotEmpty) phrases.add(current);
    return phrases;
  }

  List<int> stepsInSection(int sectionIndex) => [
    for (var i = 0; i < locations.length; i++)
      if (locations[i].sectionIndex == sectionIndex) i,
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

/// As casas de colcheia (2 por tempo) que cada acorde da parte ocupa no
/// compasso, com o movimento da batida que cai em cada uma (null = o braço só
/// passa). A parte começa no tempo 1. Vazio se a batida não diz o tempo.
Map<int, List<StrumKind?>> strumSlotsInSection(
  LyricPracticeMap map,
  int sectionIndex,
  List<StrumStroke> strokes,
) {
  if (strokes.isEmpty || strokes.any((s) => s.eighth == null)) return {};
  final byEighth = {for (final s in strokes) s.eighth!: s.kind};
  final out = <int, List<StrumKind?>>{};
  var position = 0;
  for (final step in map.stepsInSection(sectionIndex)) {
    final eighths = map.score.steps[step].beats * 2;
    out[step] = [
      for (var e = 0; e < eighths; e++) byEighth[(position + e) % 8],
    ];
    position += eighths;
  }
  return out;
}
