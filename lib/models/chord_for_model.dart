const Map<String, String> _enharmonics = {
  'A#': 'Bb',
  'Bb': 'A#',
  'C#': 'Db',
  'Db': 'C#',
  'D#': 'Eb',
  'Eb': 'D#',
  'F#': 'Gb',
  'Gb': 'F#',
  'G#': 'Ab',
  'Ab': 'G#',
  'Cb': 'B',
  'Fb': 'E',
  'E#': 'F',
  'B#': 'C',
};

final RegExp _chordName = RegExp(r'^([A-G])([#b]?)(.*)$');

String? chordForModel(String name, Set<String> modelChords) {
  final match = _chordName.firstMatch(name.trim());
  if (match == null) return null;
  final root = '${match.group(1)}${match.group(2)}';
  var rest = match.group(3)!;
  final slash = rest.indexOf('/');
  if (slash >= 0) rest = rest.substring(0, slash);
  rest = rest.replaceAll(RegExp(r'[()]'), '');

  final String quality;
  if (rest.startsWith('dim') ||
      rest.startsWith('°') ||
      rest.startsWith('ø') ||
      rest.startsWith('m7b5')) {
    quality = 'dim';
  } else if (rest.contains('sus') ||
      rest.contains('aug') ||
      rest.contains('+') ||
      rest.startsWith('5')) {
    return null;
  } else if (rest.startsWith('m') && !rest.startsWith('maj')) {
    quality = 'm';
  } else {
    quality = '';
  }

  for (final candidate in [root, _enharmonics[root]]) {
    if (candidate == null) continue;
    final chord = '$candidate$quality';
    if (modelChords.contains(chord)) return chord;
  }
  return null;
}
