import '../models/chord_prediction.dart';

/// Estabiliza as previsões do modelo no aparelho antes de chegarem na tela.
///
/// O modelo roda a cada ~0,5s, bem mais rápido que a API (~1,5s + rede). Sem
/// isso, o mesmo acorde tocado uma vez contaria várias vezes nas telas que
/// somam "acertos seguidos" por previsão recebida (ver
/// chord_practice_screen.dart), e uma leitura isolada ruidosa derrubaria a
/// sequência. Por isso só repassa uma previsão "ok"/"unknown" quando o
/// mesmo resultado aparece em pelo menos 2 das últimas 3 inferências, e no
/// máximo uma vez a cada 1,5s — a mesma cadência e semântica do modo
/// servidor. "silence"/"too_short" não representam uma tentativa de acorde
/// (as telas os ignoram), então passam direto, sem essa espera.
class ChordStabilizer {
  static const int voteWindow = 3;
  static const int minAgreement = 2;
  static const Duration minEmitInterval = Duration(milliseconds: 1500);

  final DateTime Function() _now;
  final List<ChordPrediction> _votes = [];
  DateTime? _lastEmittedAt;

  ChordStabilizer({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  String _voteKey(ChordPrediction prediction) =>
      prediction.status == 'ok' ? 'ok:${prediction.chord}' : prediction.status;

  /// Processa uma leitura bruta (uma por janela de inferência) e devolve a
  /// previsão a repassar pro app, ou `null` quando ainda não deve emitir
  /// nada agora.
  ChordPrediction? process(ChordPrediction raw) {
    if (raw.status == 'silence' || raw.status == 'too_short') {
      _votes.clear();
      _lastEmittedAt = null;
      return raw;
    }

    _votes.add(raw);
    if (_votes.length > voteWindow) _votes.removeAt(0);
    if (_votes.length < voteWindow) return null;

    final counts = <String, int>{};
    for (final vote in _votes) {
      final key = _voteKey(vote);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    String? winnerKey;
    var winnerCount = 0;
    counts.forEach((key, count) {
      if (count > winnerCount) {
        winnerCount = count;
        winnerKey = key;
      }
    });
    if (winnerKey == null || winnerCount < minAgreement) return null;

    final now = _now();
    if (_lastEmittedAt != null && now.difference(_lastEmittedAt!) < minEmitInterval) {
      return null;
    }

    for (final vote in _votes.reversed) {
      if (_voteKey(vote) == winnerKey) {
        _lastEmittedAt = now;
        return vote;
      }
    }
    return null; // inatingível: winnerKey veio dos próprios _votes
  }
}
