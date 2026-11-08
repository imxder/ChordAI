import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/services/chord_stabilizer.dart';
import 'package:flutter_test/flutter_test.dart';

const _okAm = ChordPrediction(status: 'ok', chord: 'Am', confidence: 0.9);
const _okC = ChordPrediction(status: 'ok', chord: 'C', confidence: 0.8);
const _silence = ChordPrediction(status: 'silence');
const _tooShort = ChordPrediction(status: 'too_short');

void main() {
  group('ChordStabilizer', () {
    test('silence passa direto, sem esperar votos', () {
      final stabilizer = ChordStabilizer();
      final result = stabilizer.process(_silence);
      expect(result?.status, 'silence');
    });

    test('too_short passa direto, sem esperar votos', () {
      final stabilizer = ChordStabilizer();
      final result = stabilizer.process(_tooShort);
      expect(result?.status, 'too_short');
    });

    test('só emite depois de pelo menos 2 das últimas 3 inferências concordarem', () {
      var now = DateTime(2000);
      final stabilizer = ChordStabilizer(clock: () => now);

      expect(stabilizer.process(_okAm), isNull);
      expect(stabilizer.process(_okAm), isNull);
      final third = stabilizer.process(_okAm);
      expect(third?.status, 'ok');
      expect(third?.chord, 'Am');
    });

    test('um outlier isolado entre dois iguais não impede a emissão', () {
      var now = DateTime(2000);
      final stabilizer = ChordStabilizer(clock: () => now);

      stabilizer.process(_okAm);
      stabilizer.process(_okC); // outlier isolado
      final result = stabilizer.process(_okAm); // 2 de 3 são Am
      expect(result?.chord, 'Am');
    });

    test('sem 2 de 3 concordando, não emite nada', () {
      var now = DateTime(2000);
      final stabilizer = ChordStabilizer(clock: () => now);
      const okF = ChordPrediction(status: 'ok', chord: 'F', confidence: 0.7);

      stabilizer.process(_okAm);
      stabilizer.process(_okC);
      final result = stabilizer.process(okF); // Am, C, F: nenhum repete
      expect(result, isNull);
    });

    test('depois de emitir, espera 1.5s antes de emitir de novo', () {
      var now = DateTime(2000);
      final stabilizer = ChordStabilizer(clock: () => now);

      stabilizer.process(_okAm);
      stabilizer.process(_okAm);
      final first = stabilizer.process(_okAm);
      expect(first?.chord, 'Am');

      now = now.add(const Duration(milliseconds: 500));
      final tooSoon = stabilizer.process(_okAm);
      expect(tooSoon, isNull);

      now = now.add(const Duration(milliseconds: 1000));
      final afterInterval = stabilizer.process(_okAm);
      expect(afterInterval?.chord, 'Am');
    });

    test('silence no meio reseta os votos e a espera mínima', () {
      var now = DateTime(2000);
      final stabilizer = ChordStabilizer(clock: () => now);

      stabilizer.process(_okAm);
      stabilizer.process(_okAm);
      final first = stabilizer.process(_okAm);
      expect(first?.chord, 'Am');

      stabilizer.process(_silence);

      now = now.add(const Duration(milliseconds: 1600));
      // Só 1 voto novo depois do silêncio: ainda não deve emitir.
      expect(stabilizer.process(_okAm), isNull);
      expect(stabilizer.process(_okAm), isNull);
      expect(stabilizer.process(_okAm)?.chord, 'Am');
    });
  });
}
