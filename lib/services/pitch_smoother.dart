// Suaviza e estabiliza as leituras brutas de detectPitchWithConfidence (ver
// pitch_detector.dart) antes de chegarem na tela do afinador: filtro de
// mediana em cents, rejeição de saltos isolados, suavização exponencial no
// valor exibido e histerese no estado "afinado". Sem dependência de Flutter,
// para ser testável com dados sintéticos.
import 'dart:math';

import 'pitch_detector.dart';

const double defaultConfidenceThreshold = 0.85;
const int medianWindowSize = 5;
const double jumpThresholdCents = 100.0;
const int confirmationsNeeded = 3;
const int onsetGraceReadings = 3;
const double emaAlpha = 0.3;
const Duration signalTimeout = Duration(milliseconds: 500);
const double tuneInCents = 3.0;
const double tuneOutCents = 6.0;

double _centsOf(double frequency) => 1200 * log(frequency) / ln2;
double _frequencyOfCents(double cents) => pow(2, cents / 1200).toDouble();

class PitchSmoother {
  final double confidenceThreshold;
  final DateTime Function() _now;

  PitchSmoother({
    this.confidenceThreshold = defaultConfidenceThreshold,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final List<double> _medianBuffer = [];
  double? _confirmedCents;
  double? _pendingCents;
  int _pendingStreak = 0;
  int _validStreak = 0;
  double? _smoothedCents;
  DateTime? _lastValidAt;
  bool _inTune = false;

  /// Processa uma nova estimativa (ou `null`, quando o detector não achou
  /// periodicidade ou a confiança ficou abaixo do limiar). Devolve a
  /// frequência suavizada em Hz, ou `null` quando ainda não há leitura
  /// confiável pra mostrar.
  double? update(PitchEstimate? estimate) {
    final now = _now();
    final isValid =
        estimate != null && estimate.confidence >= confidenceThreshold;

    if (!isValid) {
      _validStreak = 0;
      if (_lastValidAt == null || now.difference(_lastValidAt!) > signalTimeout) {
        _reset();
        return null;
      }
      return _smoothedCents == null ? null : _frequencyOfCents(_smoothedCents!);
    }

    _lastValidAt = now;
    _validStreak++;
    if (_validStreak <= onsetGraceReadings) {
      // Ainda no ataque da nota (primeiras leituras depois do silêncio): é
      // onde o detector mais erra a oitava, então nem entram na mediana.
      return _smoothedCents == null ? null : _frequencyOfCents(_smoothedCents!);
    }

    _acceptReading(_centsOf(estimate.frequency));
    return _smoothedCents == null ? null : _frequencyOfCents(_smoothedCents!);
  }

  void _acceptReading(double cents) {
    final reference = _confirmedCents;
    final closeToConfirmed =
        reference != null && (cents - reference).abs() <= jumpThresholdCents;

    if (closeToConfirmed) {
      _pendingCents = null;
      _pendingStreak = 0;
      _pushMedian(cents);
      _confirmedCents = _median();
      // Mesma corda de antes: só um ajuste fino, o ponteiro deslinza.
      _smoothedCents = _smoothedCents == null
          ? _confirmedCents
          : emaAlpha * _confirmedCents! + (1 - emaAlpha) * _smoothedCents!;
      return;
    }

    // Ou ainda não tem corda confirmada (inclusive a primeira leitura da
    // sessão), ou é um salto grande: só assume depois de leituras seguidas
    // e próximas entre si confirmarem — ruído isolado não conta.
    if (_pendingCents != null &&
        (cents - _pendingCents!).abs() <= jumpThresholdCents) {
      _pendingStreak++;
    } else {
      _pendingCents = cents;
      _pendingStreak = 1;
    }

    if (_pendingStreak < confirmationsNeeded) {
      return; // mantém o valor exibido atual
    }

    _medianBuffer.clear();
    _pushMedian(cents);
    _confirmedCents = cents;
    _pendingCents = null;
    _pendingStreak = 0;
    // Troca de corda confirmada: pula direto pro valor novo, sem deslizar
    // o ponteiro passando por notas que não foram tocadas.
    _smoothedCents = _confirmedCents;
  }

  void _pushMedian(double cents) {
    _medianBuffer.add(cents);
    if (_medianBuffer.length > medianWindowSize) {
      _medianBuffer.removeAt(0);
    }
  }

  double _median() {
    final sorted = [..._medianBuffer]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  void _reset() {
    _medianBuffer.clear();
    _confirmedCents = null;
    _pendingCents = null;
    _pendingStreak = 0;
    _validStreak = 0;
    _smoothedCents = null;
    _lastValidAt = null;
  }

  /// Histerese do estado "afinado": entra quando |cents| <= 3 e só sai
  /// quando |cents| > 6, pra não ficar piscando o indicador perto da borda.
  bool updateInTune(double? cents) {
    if (cents == null) {
      _inTune = false;
      return _inTune;
    }
    final abs = cents.abs();
    if (_inTune) {
      if (abs > tuneOutCents) _inTune = false;
    } else {
      if (abs <= tuneInCents) _inTune = true;
    }
    return _inTune;
  }
}
