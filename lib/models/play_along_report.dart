class ChordReportLine {
  final String chord;
  final int hits;
  final int total;

  const ChordReportLine(this.chord, this.hits, this.total);

  int get misses => total - hits;
}

List<ChordReportLine> chordsByMisses(Map<String, (int, int)> perChord) {
  final lines = [
    for (final MapEntry(key: chord, value: (hits, total)) in perChord.entries)
      ChordReportLine(chord, hits, total),
  ];
  lines.sort((a, b) {
    final byMisses = b.misses.compareTo(a.misses);
    if (byMisses != 0) return byMisses;
    final byTotal = b.total.compareTo(a.total);
    if (byTotal != 0) return byTotal;
    return a.chord.compareTo(b.chord);
  });
  return lines;
}
