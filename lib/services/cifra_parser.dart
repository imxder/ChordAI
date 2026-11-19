import '../models/lyric_sheet.dart';

// Formato das cifras em assets/lyrics/*.txt, no estilo do Cifra Club:
//
//   Tom: C               tom da música (só mostra na tela)
//   Tempo: 100           BPM inicial do tocar junto
//   Capo: 1              casa do capotraste (só mostra na tela)
//   Batida: D1 D2 U2& U3& D4 U4&
//                        padrão de batida num compasso 4/4: D = pra baixo,
//                        U = pra cima, X = abafado, e o número (com & pro
//                        contratempo) diz em que tempo cai. Sem o número
//                        (D D U U D U) a tela só mostra as setas.
//   Tempos: 4            quantos tempos cada acorde dura no tocar junto;
//   Tempos: Am=2 G=2 C=4 também dá pra dizer por acorde (o resto fica com 4)
//
//   [Refrão]             começa uma seção
//   Am:2  G:2  C         linha de acordes em cima da linha de letra; o :2 diz
//   letra da música      que aquele acorde dura 2 tempos e vale mais que o
//                        Tempos: do topo. O :2 não aparece na tela.

final RegExp _chordToken = RegExp(
  r'^[A-G](#|b)?(maj|m|dim|aug|sus|add|M|°|ø|\+|\d|\(|\)|b|#)*(/[A-G](#|b)?)?$',
);

final RegExp _beatsSuffix = RegExp(r':(\d+)$');

bool _isChordLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return false;
  final tokens = trimmed.split(RegExp(r'\s+'));
  return tokens.every(
    (t) => _chordToken.hasMatch(t.replaceFirst(_beatsSuffix, '')),
  );
}

LyricLine _chordLyricLine(String chordLine, {String lyricText = ''}) {
  final beats = <int?>[];
  final clean = chordLine.replaceAllMapped(RegExp(r'\S+'), (m) {
    final token = m.group(0)!;
    final suffix = _beatsSuffix.firstMatch(token);
    beats.add(suffix == null ? null : int.parse(suffix.group(1)!));
    if (suffix == null) return token;
    final chord = token.substring(0, suffix.start);
    return chord.padRight(token.length);
  });
  return LyricLine(
    chordLine: clean.trimRight(),
    lyricText: lyricText,
    chordBeats: beats.any((b) => b != null) ? beats : const [],
  );
}

LyricSheet parseCifra(String raw, {required String title}) {
  final rawLines = raw.replaceAll('​', '').split('\n');
  String? key;
  int? tempo;
  int? capo;
  List<String>? strummingPattern;
  int? beatsPerChord;
  final beatsByChord = <String, int>{};
  final sections = <LyricSection>[];
  List<LyricLine>? currentLines;
  String? currentTitle;
  var hasOpenedSection = false;

  void flushSection() {
    if (hasOpenedSection) {
      sections.add(
        LyricSection(title: currentTitle, lines: currentLines ?? []),
      );
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

    if (trimmed.toLowerCase().startsWith('tempo:')) {
      tempo = int.tryParse(trimmed.substring(6).trim());
      i++;
      continue;
    }

    if (trimmed.toLowerCase().startsWith('capo:')) {
      capo = int.tryParse(trimmed.substring(5).trim());
      i++;
      continue;
    }

    if (trimmed.toLowerCase().startsWith('tempos:')) {
      for (final part in trimmed.substring(7).trim().split(RegExp(r'\s+'))) {
        final byChord = RegExp(r'^(.+)=(\d+)$').firstMatch(part);
        if (byChord != null) {
          beatsByChord[byChord.group(1)!] = int.parse(byChord.group(2)!);
        } else if (int.tryParse(part) != null) {
          beatsPerChord = int.parse(part);
        }
      }
      i++;
      continue;
    }

    if (trimmed.toLowerCase().startsWith('batida:')) {
      strummingPattern = trimmed
          .substring(7)
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
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
        currentLines!.add(_chordLyricLine(rest));
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
        currentLines!.add(_chordLyricLine(inner));
        i++;
        continue;
      }
    }

    if (_isChordLine(line)) {
      final hasNext = i + 1 < rawLines.length;
      final next = hasNext ? rawLines[i + 1] : '';
      final nextTrimmed = next.trim();
      final nextIsLyric =
          nextTrimmed.isNotEmpty &&
          !_isChordLine(next) &&
          !nextTrimmed.startsWith('[') &&
          !nextTrimmed.toLowerCase().startsWith('tom:');
      if (nextIsLyric) {
        currentLines!.add(_chordLyricLine(line, lyricText: next));
        i += 2;
        continue;
      }
      currentLines!.add(_chordLyricLine(line));
      i++;
      continue;
    }

    currentLines!.add(LyricLine(lyricText: line));
    i++;
  }
  flushSection();

  return LyricSheet(
    title: title,
    key: key,
    tempo: tempo,
    capo: capo,
    strummingPattern: strummingPattern,
    sections: sections,
    beatsPerChord: beatsPerChord,
    beatsByChord: beatsByChord,
  );
}
