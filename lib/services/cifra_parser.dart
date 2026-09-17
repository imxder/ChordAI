import '../models/lyric_sheet.dart';

final RegExp _chordToken = RegExp(
  r'^[A-G](#|b)?(m|dim|aug|sus2|sus4|maj7|m7|7|6|9|add9)?$',
);

bool _isChordLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return false;
  final tokens = trimmed.split(RegExp(r'\s+'));
  return tokens.every((t) => _chordToken.hasMatch(t));
}

LyricSheet parseCifra(String raw, {required String title}) {
  final rawLines = raw.replaceAll('​', '').split('\n');
  String? key;
  final sections = <LyricSection>[];
  List<LyricLine>? currentLines;
  String? currentTitle;
  var hasOpenedSection = false;

  void flushSection() {
    if (hasOpenedSection) {
      sections.add(LyricSection(title: currentTitle, lines: currentLines ?? []));
    }
    currentLines = null;
    currentTitle = null;
  }

  var i = 0;
  while (i < rawLines.length) {
    final line = rawLines[i];
    final trimmed = line.trim();

    if (trimmed.toLowerCase().startsWith('tom:')) {
      key = trimmed.substring(4).trim();
      i++;
      continue;
    }

    final sectionMatch = RegExp(r'^\[(.+?)\](.*)$').firstMatch(trimmed);
    if (sectionMatch != null) {
      flushSection();
      currentTitle = sectionMatch.group(1);
      currentLines = [];
      hasOpenedSection = true;
      final rest = sectionMatch.group(2)!.trim();
      if (rest.isNotEmpty && _isChordLine(rest)) {
        currentLines!.add(LyricLine(chordLine: rest));
      }
      i++;
      continue;
    }

    if (!hasOpenedSection) {
      currentLines = [];
      hasOpenedSection = true;
    }
    currentLines ??= [];

    if (trimmed.isEmpty) {
      currentLines!.add(const LyricLine());
      i++;
      continue;
    }

    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      final inner = trimmed.substring(1, trimmed.length - 1);
      if (_isChordLine(inner)) {
        currentLines!.add(LyricLine(chordLine: inner));
        i++;
        continue;
      }
    }

    if (_isChordLine(line)) {
      final hasNext = i + 1 < rawLines.length;
      final next = hasNext ? rawLines[i + 1] : '';
      final nextTrimmed = next.trim();
      final nextIsLyric = nextTrimmed.isNotEmpty &&
          !_isChordLine(next) &&
          !nextTrimmed.startsWith('[') &&
          !nextTrimmed.toLowerCase().startsWith('tom:');
      if (nextIsLyric) {
        currentLines!.add(LyricLine(chordLine: line, lyricText: next));
        i += 2;
        continue;
      }
      currentLines!.add(LyricLine(chordLine: line));
      i++;
      continue;
    }

    currentLines!.add(LyricLine(lyricText: line));
    i++;
  }
  flushSection();

  return LyricSheet(title: title, key: key, sections: sections);
}
