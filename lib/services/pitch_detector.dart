import 'dart:math';

const double _minSearchFreq = 70.0;
const double _maxSearchFreq = 400.0;

const double silenceRmsThreshold = 0.01;

double? detectPitch(List<double> samples, double sampleRate) {
  final n = samples.length;
  if (n < 2) return null;

  var sumSquares = 0.0;
  for (final s in samples) {
    sumSquares += s * s;
  }
  final rms = sqrt(sumSquares / n);
  if (rms < silenceRmsThreshold) return null;

  final minLag = (sampleRate / _maxSearchFreq).floor().clamp(1, n - 1);
  final maxLag = (sampleRate / _minSearchFreq).ceil().clamp(1, n - 1);
  if (minLag >= maxLag) return null;

  var bestCorrelation = 0.0;
  var bestLag = -1;
  for (var lag = minLag; lag <= maxLag; lag++) {
    var correlation = 0.0;
    for (var i = 0; i < n - lag; i++) {
      correlation += samples[i] * samples[i + lag];
    }
    if (correlation > bestCorrelation) {
      bestCorrelation = correlation;
      bestLag = lag;
    }
  }
  if (bestLag <= 0) return null;

  final refinedLag = _refineLag(samples, bestLag, bestCorrelation);
  if (refinedLag <= 0) return null;

  return sampleRate / refinedLag;
}

double _correlationAtLag(List<double> samples, int lag) {
  if (lag < 0 || lag >= samples.length) return 0;
  var correlation = 0.0;
  for (var i = 0; i < samples.length - lag; i++) {
    correlation += samples[i] * samples[i + lag];
  }
  return correlation;
}

double _refineLag(List<double> samples, int bestLag, double peakValue) {
  final y0 = _correlationAtLag(samples, bestLag - 1);
  final y1 = peakValue;
  final y2 = _correlationAtLag(samples, bestLag + 1);
  final denom = y0 - 2 * y1 + y2;
  if (denom == 0) return bestLag.toDouble();
  final shift = 0.5 * (y0 - y2) / denom;
  return bestLag + shift;
}
