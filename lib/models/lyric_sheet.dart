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
  final String? key;
  final List<LyricSection> sections;

  const LyricSheet({required this.title, this.key, required this.sections});
}
