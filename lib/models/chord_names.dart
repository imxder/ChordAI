const Map<String, String> _rootNames = {
  'C': 'Dó',
  'C#': 'Dó#',
  'Db': 'Réb',
  'D': 'Ré',
  'D#': 'Ré#',
  'Eb': 'Mib',
  'E': 'Mi',
  'F': 'Fá',
  'F#': 'Fá#',
  'Gb': 'Solb',
  'G': 'Sol',
  'G#': 'Sol#',
  'Ab': 'Láb',
  'A': 'Lá',
  'A#': 'Lá#',
  'Bb': 'Sib',
  'B': 'Si',
};

String chordFullName(String chord) {
  final match = RegExp(r'^([A-G](?:#|b)?)(.*)$').firstMatch(chord);
  if (match == null) return chord;
  final root = match.group(1)!;
  final suffix = match.group(2) ?? '';
  final rootName = _rootNames[root] ?? root;
  if (suffix.isEmpty) return '$rootName maior';
  if (suffix == 'm') return '$rootName menor';
  if (suffix == 'dim') return '$rootName diminuto';
  if (suffix == 'aug') return '$rootName aumentado';
  return '$rootName $suffix';
}
