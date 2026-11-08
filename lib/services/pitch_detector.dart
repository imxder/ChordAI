// Algoritmo YIN: A. de Cheveigné e H. Kawahara, "YIN, a fundamental frequency
// estimator for speech and music", J. Acoust. Soc. Am. 111(4), 2002.
import 'dart:math';
import 'dart:typed_data';

const double defaultMinFreq = 70.0;
const double defaultMaxFreq = 400.0;
const double defaultYinThreshold = 0.15;
const double defaultOctaveMargin = 0.05;

const double silenceRmsThreshold = 0.01;

class PitchEstimate {
  final double frequency;

  /// 1 − CMNDF(τ) no mínimo escolhido: perto de 1 para sinal bem periódico.
  final double confidence;

  const PitchEstimate(this.frequency, this.confidence);
}

double? detectPitch(
  List<double> samples,
  double sampleRate, {
  double minFreq = defaultMinFreq,
  double maxFreq = defaultMaxFreq,
  double threshold = defaultYinThreshold,
  double octaveMargin = defaultOctaveMargin,
}) {
  return detectPitchWithConfidence(
    samples,
    sampleRate,
    minFreq: minFreq,
    maxFreq: maxFreq,
    threshold: threshold,
    octaveMargin: octaveMargin,
  )?.frequency;
}

PitchEstimate? detectPitchWithConfidence(
  List<double> samples,
  double sampleRate, {
  double minFreq = defaultMinFreq,
  double maxFreq = defaultMaxFreq,
  double threshold = defaultYinThreshold,
  double octaveMargin = defaultOctaveMargin,
}) {
  final n = samples.length;
  if (n < 4) return null;

  final x = samples is Float64List ? samples : Float64List.fromList(samples);

  var sumSquares = 0.0;
  for (var i = 0; i < n; i++) {
    sumSquares += x[i] * x[i];
  }
  if (sqrt(sumSquares / n) < silenceRmsThreshold) return null;

  final minLag = max(2, (sampleRate / maxFreq).floor());
  final maxLag = (sampleRate / minFreq).ceil();
  // +1 para conseguir checar se maxLag é mínimo local.
  final lastLag = maxLag + 1;
  // Janela de integração fixa: todo τ soma o mesmo número de termos.
  final w = n - lastLag;
  if (minLag >= maxLag || w < lastLag) return null;

  final diff = Float64List(lastLag + 1);
  for (var tau = 1; tau <= lastLag; tau++) {
    var sum = 0.0;
    for (var i = 0; i < w; i++) {
      final delta = x[i] - x[i + tau];
      sum += delta * delta;
    }
    diff[tau] = sum;
  }

  final cmndf = Float64List(lastLag + 1);
  cmndf[0] = 1;
  var runningSum = 0.0;
  for (var tau = 1; tau <= lastLag; tau++) {
    runningSum += diff[tau];
    cmndf[tau] = runningSum == 0 ? 1 : diff[tau] * tau / runningSum;
  }

  var tau = minLag;
  while (tau <= maxLag && cmndf[tau] >= threshold) {
    tau++;
  }
  if (tau > maxLag) return null;
  while (tau < lastLag && cmndf[tau + 1] < cmndf[tau]) {
    tau++;
  }
  // Ainda descendo na borda: o mínimo de verdade está fora da faixa.
  if (tau >= lastLag) return null;

  // Com harmônicos ímpares fracos, o sinal quase se repete a cada meio período
  // e o primeiro mínimo abaixo do limiar fica uma oitava acima. Só troca se o
  // período dobrado for bem mais periódico; numa nota de verdade os dois dão ~0.
  final doubled = _deepestNear(cmndf, 2 * tau, minLag, maxLag);
  if (doubled != null && cmndf[doubled] < cmndf[tau] - octaveMargin) {
    tau = doubled;
  }

  // Interpola em d(τ), não em d'(τ): a normalização da CMNDF entorta a
  // parábola e puxa o pico alguns décimos de cent.
  final y0 = diff[tau - 1];
  final y1 = diff[tau];
  final y2 = diff[tau + 1];
  final denom = y0 - 2 * y1 + y2;
  var refinedLag = tau.toDouble();
  if (denom > 0) {
    final shift = 0.5 * (y0 - y2) / denom;
    if (shift.abs() < 1) refinedLag += shift;
  }

  return PitchEstimate(
    sampleRate / refinedLag,
    (1 - cmndf[tau]).clamp(0.0, 1.0),
  );
}

int? _deepestNear(Float64List cmndf, int center, int minLag, int maxLag) {
  if (center > maxLag) return null;
  int? best;
  for (var lag = max(minLag, center - 2); lag <= min(maxLag, center + 2); lag++) {
    if (best == null || cmndf[lag] < cmndf[best]) best = lag;
  }
  return best;
}
