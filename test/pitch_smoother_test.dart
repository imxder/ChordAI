import 'package:chordai/services/pitch_detector.dart';
import 'package:chordai/services/pitch_smoother.dart';
import 'package:flutter_test/flutter_test.dart';

PitchSmoother _smootherAt(DateTime Function() clock) =>
    PitchSmoother(clock: clock);

/// Alimenta o smoother com [frequency] por [times] leituras seguidas,
/// avançando o relógio sintético a cada uma (simula o salto de 1024
/// amostras a 22050 Hz usado pelo TunerService, ~46 ms por leitura).
double? _feed(
  PitchSmoother smoother,
  double frequency,
  int times, {
  double confidence = 0.95,
  void Function(Duration elapsed)? tick,
}) {
  double? last;
  for (var i = 0; i < times; i++) {
    tick?.call(const Duration(milliseconds: 46));
    last = smoother.update(PitchEstimate(frequency, confidence));
  }
  return last;
}

void main() {
  group('PitchSmoother', () {
    test('sequência estável com ruído pequeno dá valor estável', () {
      var now = DateTime(2000);
      final smoother = _smootherAt(() => now);
      final freqs = [110.0, 110.3, 109.8, 110.1, 109.9, 110.2, 110.0, 110.1];
      double? last;
      for (final f in freqs) {
        now = now.add(const Duration(milliseconds: 46));
        last = smoother.update(PitchEstimate(f, 0.95));
      }
      expect(last, isNotNull);
      expect(last!, closeTo(110.0, 1.0));
    });

    test('leitura isolada com confiança baixa é descartada', () {
      var now = DateTime(2000);
      final smoother = _smootherAt(() => now);
      _feed(smoother, 110.0, 6, tick: (_) {});
      now = now.add(const Duration(milliseconds: 46));
      final withLowConfidence = smoother.update(const PitchEstimate(220.0, 0.2));
      expect(withLowConfidence, closeTo(110.0, 1.0));
    });

    test('outlier isolado é ignorado (mantém a leitura anterior)', () {
      var now = DateTime(2000);
      final smoother = _smootherAt(() => now);
      // Onset (3 leituras ignoradas) + 3 confirmações = corda A2 estabelece.
      final locked = _feed(smoother, 110.0, 6, tick: (d) => now = now.add(d));
      expect(locked, isNotNull);
      expect(locked!, closeTo(110.0, 1.0));

      // Um salto isolado de mais de 100 cents não deve ser aceito.
      now = now.add(const Duration(milliseconds: 46));
      final afterOutlier = smoother.update(const PitchEstimate(164.8, 0.95)); // E3, ~1 oitava e meia
      expect(afterOutlier, closeTo(110.0, 1.0));

      // E volta a ler A2 normalmente depois.
      now = now.add(const Duration(milliseconds: 46));
      final afterRecovery = smoother.update(const PitchEstimate(110.0, 0.95));
      expect(afterRecovery, closeTo(110.0, 1.0));
    });

    test('troca real de corda só é aceita após confirmações seguidas', () {
      var now = DateTime(2000);
      final smoother = _smootherAt(() => now);
      final lockedA2 = _feed(smoother, 110.0, 6, tick: (d) => now = now.add(d));
      expect(lockedA2!, closeTo(110.0, 1.0));

      // Primeira leitura da nova corda: ainda não confirma.
      now = now.add(const Duration(milliseconds: 46));
      final firstE2 = smoother.update(const PitchEstimate(82.41, 0.95));
      expect(firstE2, closeTo(110.0, 1.0));

      // Segunda leitura seguida e próxima: ainda não (precisa de 3).
      now = now.add(const Duration(milliseconds: 46));
      final secondE2 = smoother.update(const PitchEstimate(82.41, 0.95));
      expect(secondE2, closeTo(110.0, 1.0));

      // Terceira confirma a troca pra E2.
      now = now.add(const Duration(milliseconds: 46));
      final thirdE2 = smoother.update(const PitchEstimate(82.41, 0.95));
      expect(thirdE2, closeTo(82.41, 1.0));
    });

    test('ignora as 3 primeiras leituras depois do silêncio (ataque)', () {
      var now = DateTime(2000);
      final smoother = _smootherAt(() => now);

      // As 3 primeiras leituras do ataque não devem gerar nenhuma saída.
      for (var i = 0; i < 3; i++) {
        now = now.add(const Duration(milliseconds: 46));
        final reading = smoother.update(const PitchEstimate(329.63, 0.95));
        expect(reading, isNull);
      }

      // A partir da 4ª, entram no filtro normal (ainda precisa confirmar).
      now = now.add(const Duration(milliseconds: 46));
      final fourth = smoother.update(const PitchEstimate(329.63, 0.95));
      expect(fourth, isNull);

      now = now.add(const Duration(milliseconds: 46));
      final fifth = smoother.update(const PitchEstimate(329.63, 0.95));
      expect(fifth, isNull);

      now = now.add(const Duration(milliseconds: 46));
      final sixth = smoother.update(const PitchEstimate(329.63, 0.95));
      expect(sixth, closeTo(329.63, 1.0));
    });

    test('depois de ~500ms sem leitura válida volta pra sem sinal', () {
      var now = DateTime(2000);
      final smoother = _smootherAt(() => now);
      final locked = _feed(smoother, 110.0, 6, tick: (d) => now = now.add(d));
      expect(locked, isNotNull);

      now = now.add(const Duration(milliseconds: 300));
      final duringGap = smoother.update(null);
      expect(duringGap, closeTo(110.0, 1.0), reason: 'gap curto mantém o valor');

      now = now.add(const Duration(milliseconds: 300));
      final afterTimeout = smoother.update(null);
      expect(afterTimeout, isNull);
    });

    group('updateInTune', () {
      test('entra em afinado só dentro de 3 cents e sai só acima de 6', () {
        final smoother = PitchSmoother();
        expect(smoother.updateInTune(10), isFalse);
        expect(smoother.updateInTune(4), isFalse); // ainda fora da entrada
        expect(smoother.updateInTune(2), isTrue); // entra
        expect(smoother.updateInTune(5), isTrue); // não sai (histerese)
        expect(smoother.updateInTune(7), isFalse); // agora sai
      });

      test('sem leitura nunca conta como afinado', () {
        final smoother = PitchSmoother();
        expect(smoother.updateInTune(1), isTrue);
        expect(smoother.updateInTune(null), isFalse);
      });
    });
  });
}
