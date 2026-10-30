import 'chord_difficulty.dart';

class LyricLine {
  final String? chordLine;
  final String lyricText;

  const LyricLine({this.chordLine, this.lyricText = ''});
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

  const LyricSheet({
    required this.title,
    this.artist,
    this.key,
    this.tempo,
    this.capo,
    this.strummingPattern,
    required this.sections,
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
  if (maxIndex <= 1) return 'Fácil';
  if (maxIndex <= 4) return 'Médio';
  return 'Difícil';
}
