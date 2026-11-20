import 'dart:math';

const List<String> _noteOrder = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

double noteFrequency(String note) {
  final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
  if (match == null) {
    throw ArgumentError('Nota inválida: $note');
  }
  final name = match.group(1)!;
  final octave = int.parse(match.group(2)!);
  final semitoneIndex = _noteOrder.indexOf(name);
  final semitonesFromA4 =
      (octave - 4) * 12 + (semitoneIndex - _noteOrder.indexOf('A'));
  return 440 * pow(2, semitonesFromA4 / 12).toDouble();
}

class TunerNote {
  final String name;
  final String label;
  final double frequency;

  TunerNote(this.name, this.label) : frequency = noteFrequency(name);
}

const List<String> _stringLabels = [
  '6ª corda',
  '5ª corda',
  '4ª corda',
  '3ª corda',
  '2ª corda',
  '1ª corda (mais aguda)',
];

List<TunerNote> buildTuning(List<String> notes) {
  return List.generate(
    notes.length,
    (i) => TunerNote(notes[i], _stringLabels[i]),
  );
}

List<TunerNote> guitarStrings = buildTuning(const [
  'E2',
  'A2',
  'D3',
  'G3',
  'B3',
  'E4',
]);

class TunerReading {
  final TunerNote nearestString;
  final double cents;

  const TunerReading({required this.nearestString, required this.cents});
}

TunerReading? classifyPitch(double? frequency, List<TunerNote> strings) {
  if (frequency == null || frequency <= 0) return null;

  TunerNote? nearest;
  var bestDistance = double.infinity;
  for (final note in strings) {
    final distance = (log(frequency / note.frequency) / ln2).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      nearest = note;
    }
  }
  if (nearest == null) return null;

  final cents = 1200 * (log(frequency / nearest.frequency) / ln2);
  return TunerReading(nearestString: nearest, cents: cents);
}

/// Modo "escolher corda": mede sempre contra [target], sem procurar a corda
/// mais próxima. Se a leitura estiver mais de meia oitava longe, ela é trazida
/// pra oitava da corda escolhida: o YIN às vezes lê a oitava de cima ou de
/// baixo da mesma nota, e isso não quer dizer que a corda está desafinada uma
/// oitava inteira.
TunerReading? classifyPitchFor(double? frequency, TunerNote target) {
  if (frequency == null || frequency <= 0) return null;
  var cents = 1200 * (log(frequency / target.frequency) / ln2);
  while (cents > 600) {
    cents -= 1200;
  }
  while (cents < -600) {
    cents += 1200;
  }
  return TunerReading(nearestString: target, cents: cents);
}
