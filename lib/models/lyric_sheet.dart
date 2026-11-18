import 'chord_difficulty.dart';

enum StrumKind { down, up, muted }

class StrumStroke {
  final StrumKind kind;
  final int? eighth;

  const StrumStroke(this.kind, this.eighth);
}

final RegExp _strumToken = RegExp(r'^([DUXdux])(?:([1-4])(&)?)?$');

List<StrumStroke> parseStrumPattern(List<String> tokens) {
  final strokes = <StrumStroke>[];
  for (final token in tokens) {
    final match = _strumToken.firstMatch(token);
    if (match == null) continue;
    final kind = switch (match.group(1)!.toUpperCase()) {
      'D' => StrumKind.down,
      'U' => StrumKind.up,
      _ => StrumKind.muted,
    };
    final beat = match.group(2);
    strokes.add(
      StrumStroke(
        kind,
        beat == null
            ? null
            : (int.parse(beat) - 1) * 2 + (match.group(3) == null ? 0 : 1),
      ),
    );
  }
  return strokes;
}

class LyricLine {
  final String? chordLine;
  final String lyricText;
  final List<int?> chordBeats;

  const LyricLine({
    this.chordLine,
    this.lyricText = '',
    this.chordBeats = const [],
  });
}

class LyricSection {
  final String? title;
  final List<LyricLine> lines;

  const LyricSection({this.title, required this.lines});
}

class LyricSheet {
  final String title;
  final String? artist;
  final String? key;
  final int? tempo;
  final int? capo;
  final List<String>? strummingPattern;
  final List<LyricSection> sections;
  final int? beatsPerChord;
  final Map<String, int> beatsByChord;

  const LyricSheet({
    required this.title,
    this.artist,
    this.key,
    this.tempo,
    this.capo,
    this.strummingPattern,
    required this.sections,
    this.beatsPerChord,
    this.beatsByChord = const {},
  });
}

Set<String> extractChords(LyricSheet sheet) {
  final chords = <String>{};
  for (final section in sheet.sections) {
    for (final line in section.lines) {
      final chordLine = line.chordLine;
      if (chordLine == null) continue;
      for (final token in chordLine.trim().split(RegExp(r'\s+'))) {
        if (token.isNotEmpty) chords.add(token);
      }
    }
  }
  return chords;
}

String difficultyLabel(Set<String> chords) {
  var maxIndex = -1;
  for (final chord in chords) {
    final idx = chordsByDifficulty.indexOf(chord);
    if (idx > maxIndex) maxIndex = idx;
  }
  if (maxIndex < 0) return 'Desconhecida';
  if (maxIndex <= chordsByDifficulty.indexOf('A')) return 'Fácil';
  if (maxIndex <= chordsByDifficulty.indexOf('Dm')) return 'Médio';
  return 'Difícil';
}
