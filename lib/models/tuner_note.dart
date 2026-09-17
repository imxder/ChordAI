import 'dart:math';

class TunerNote {
  final String name;
  final String label;
  final double frequency;

  const TunerNote(this.name, this.label, this.frequency);
}

const List<TunerNote> guitarStrings = [
  TunerNote('E2', '6ª corda (Mi grave)', 82.41),
  TunerNote('A2', '5ª corda (Lá)', 110.00),
  TunerNote('D3', '4ª corda (Ré)', 146.83),
  TunerNote('G3', '3ª corda (Sol)', 196.00),
  TunerNote('B3', '2ª corda (Si)', 246.94),
  TunerNote('E4', '1ª corda (Mi agudo)', 329.63),
];

class TunerReading {
  final TunerNote nearestString;
  final double cents;

  const TunerReading({required this.nearestString, required this.cents});
}

TunerReading? classifyPitch(double? frequency) {
  if (frequency == null || frequency <= 0) return null;

  TunerNote? nearest;
  var bestDistance = double.infinity;
  for (final note in guitarStrings) {
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
