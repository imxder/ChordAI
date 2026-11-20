// Suaviza e estabiliza as leituras brutas de detectPitchWithConfidence (ver
// pitch_detector.dart) antes de chegarem na tela do afinador: filtro de
// mediana em cents, rejeição de saltos isolados, suavização exponencial no
// valor exibido e histerese no estado "afinado". Também segura a corda até um
// ataque novo (harmônico no fim da nota não troca de corda) e deixa o ponteiro
// parado na última leitura quando a nota acaba. Sem dependência de Flutter,
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

/// Depois que a nota acaba, o ponteiro fica parado na última leitura por esse
/// tempo antes de voltar pra "Toque uma corda solta". Dá tempo de olhar o
/// ponteiro e girar a tarraxa sem ele sumir.
const Duration holdDuration = Duration(seconds: 3);

/// Ataque (corda beliscada): o nível das amostras novas sobe pelo menos 2,5×
/// de um salto pro outro. Nas gravações de test/fixtures/strings o ataque de
/// uma corda sozinha sobe de 8,8× a 28×, mas a Lá tocada por cima do Mi ainda
/// soando sobe só 3,2× (test/afinador_gravacoes_test.dart). Com a corda só
/// soando, a subida fica quase sempre até 1,3×, com um pico de 3,7× no fim da
/// G3: aí a janela abre à toa, mas só troca se outra nota for confirmada.
const double onsetRatio = 2.5;

/// Depois de um ataque, por quanto tempo uma corda diferente pode ser
/// confirmada. Nas gravações a corda nova aparece até ~0,7 s depois do ataque
/// (a Lá por cima do Mi), então 1 s cobre.
const Duration switchWindow = Duration(seconds: 1);

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

  /// Se o afinador já mandou algum nível. Sem nível não dá pra saber quando
  /// teve ataque, então a troca de corda funciona como antes, sem trava.
  bool _hasLevels = false;
  double? _lastLevel;

  /// Até quando uma corda diferente pode ser confirmada (aberto por um ataque
  /// ou pelo começo de uma nota nova depois que a anterior acabou).
  DateTime? _switchAllowedUntil;
  bool _noteEnded = false;

  /// Processa uma nova estimativa (ou `null`, quando o detector não achou
  /// periodicidade ou a confiança ficou abaixo do limiar). Devolve a
  /// frequência suavizada em Hz, ou `null` quando ainda não há leitura
  /// confiável pra mostrar.
  ///
  /// [level] é o RMS só das amostras novas desse salto (ver TunerService);
  /// é com ele que o smoother percebe que uma corda foi beliscada.
  double? update(PitchEstimate? estimate, {double? level}) {
    final now = _now();
    _trackOnset(level, now);
    final isValid =
        estimate != null && estimate.confidence >= confidenceThreshold;

    if (!isValid) {
      _validStreak = 0;
      final lastValid = _lastValidAt;
      if (lastValid == null || now.difference(lastValid) > holdDuration) {
        _reset();
        return null;
      }
      // A nota acabou, mas o ponteiro fica parado na última leitura. A
      // próxima nota pode ser de outra corda.
      if (now.difference(lastValid) > signalTimeout) _noteEnded = true;
      return _shown();
    }

    if (_noteEnded) {
      _noteEnded = false;
      _switchAllowedUntil = now.add(switchWindow);
    }
    _lastValidAt = now;
    _validStreak++;
    if (_validStreak <= onsetGraceReadings) {
      // Ainda no ataque da nota (primeiras leituras depois do silêncio ou de
      // um ataque): é onde o detector mais erra a oitava, então nem entram na
      // mediana.
      return _shown();
    }

    _acceptReading(_centsOf(estimate.frequency), now);
    return _shown();
  }

  /// Volta tudo pro começo: usado quando o afinador troca de modo ou de corda.
  void reset() => _reset();

  double? _shown() =>
      _smoothedCents == null ? null : _frequencyOfCents(_smoothedCents!);

  void _trackOnset(double? level, DateTime now) {
    if (level == null) return;
    _hasLevels = true;
    final previous = _lastLevel;
    _lastLevel = level;
    if (level < silenceRmsThreshold) return;
    if (previous == null || level >= onsetRatio * previous) {
      _switchAllowedUntil = now.add(switchWindow);
      // As primeiras leituras de um ataque também são ignoradas, mesmo com a
      // corda anterior ainda soando.
      _validStreak = 0;
    }
  }

  bool _canSwitch(DateTime now) {
    if (!_hasLevels) return true;
    final until = _switchAllowedUntil;
    return until != null && !now.isAfter(until);
  }

  void _acceptReading(double cents, DateTime now) {
    final reference = _confirmedCents;
    final closeToConfirmed =
        reference != null && (cents - reference).abs() <= jumpThresholdCents;

    if (reference != null && !closeToConfirmed && !_canSwitch(now)) {
      // Longe da corda atual e sem ataque novo: é harmônico ou erro de oitava
      // do fim da nota, não outra corda. O ponteiro fica onde está.
      _pendingCents = null;
      _pendingStreak = 0;
      return;
    }

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
    // A janela de troca não fecha aqui: logo depois do ataque o detector pode
    // confirmar uma leitura errada (com duas cordas soando ele às vezes acha o
    // período comum, como 55 Hz com Mi e Lá juntos), e a nota certa ainda
    // precisa conseguir entrar. Ela fecha sozinha quando o tempo acaba.
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
    _lastLevel = null;
    _switchAllowedUntil = null;
    _noteEnded = false;
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
