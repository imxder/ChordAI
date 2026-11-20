import 'package:chordai/models/tuner_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final a2 = guitarStrings[1];

  group('classifyPitchFor (corda escolhida)', () {
    test('mede contra a corda escolhida, mesmo perto de outra', () {
      // 98 Hz é quase um G2, mas com a 5ª corda escolhida mede contra a A2.
      final reading = classifyPitchFor(98.0, a2)!;
      expect(reading.nearestString.name, 'A2');
      expect(reading.cents, closeTo(-200, 1));
    });

    test('oitava de cima ou de baixo da mesma nota conta como a nota', () {
      expect(classifyPitchFor(220.0, a2)!.cents, closeTo(0, 0.01));
      expect(classifyPitchFor(55.0, a2)!.cents, closeTo(0, 0.01));
      expect(classifyPitchFor(222.0, a2)!.cents, closeTo(15.7, 0.1));
    });

    test('sem frequência não tem leitura', () {
      expect(classifyPitchFor(null, a2), isNull);
      expect(classifyPitchFor(0, a2), isNull);
    });
  });
}
