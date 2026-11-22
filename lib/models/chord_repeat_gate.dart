import 'chord_prediction.dart';

enum ChordRepeatEvent {
  /// Acertou e conta: soma um nos acertos seguidos.
  hit,

  /// Ainda é o mesmo acorde soando desde o último acerto: não conta.
  stillRinging,

  /// O app deixou de ouvir o acorde (silêncio ou "não reconheci"): o
  /// próximo acerto já pode contar.
  released,

  /// Tocou outro acorde: zera os acertos seguidos, como sempre foi.
  miss,

  /// Nada a fazer (começo da gravação, ou "não reconheci" sem acerto antes).
  none,
}

/// Regra do treino de acorde: cada acerto tem que ser uma batida nova.
///
/// O modelo lê os últimos 1,5 s a cada 0,5 s, então um acorde que fica
/// soando continua dando "certo" por vários segundos. Por isso, depois de um
/// acerto, o próximo só conta quando o app deixa de ouvir o acorde antes:
/// um silêncio (cordas abafadas) ou um "não reconheci".
///
/// As leituras têm que vir do ChordStabilizer (o padrão do
/// createChordRecognizer): ele só repassa um "não reconheci" quando ele
/// aparece em 2 das últimas 3 leituras, então uma leitura solta no fim do som
/// não libera o próximo acerto.
class ChordRepeatGate {
  final String chord;
  bool _waitingForRelease = false;

  ChordRepeatGate(this.chord);

  bool get waitingForRelease => _waitingForRelease;

  void reset() => _waitingForRelease = false;

  ChordRepeatEvent process(ChordPrediction prediction) {
    switch (prediction.status) {
      case 'silence':
      case 'unknown':
        if (!_waitingForRelease) return ChordRepeatEvent.none;
        _waitingForRelease = false;
        return ChordRepeatEvent.released;
      case 'ok':
        final matched = prediction.chord?.toLowerCase() == chord.toLowerCase();
        if (!matched) {
          _waitingForRelease = false;
          return ChordRepeatEvent.miss;
        }
        if (_waitingForRelease) return ChordRepeatEvent.stillRinging;
        _waitingForRelease = true;
        return ChordRepeatEvent.hit;
      default:
        return ChordRepeatEvent.none;
    }
  }
}
