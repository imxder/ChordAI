import 'chord_prediction.dart';

enum ChordRepeatEvent { hit, stillRinging, released, miss, none }

/// A regra do treino do acorde: quando uma leitura conta como acerto e
/// quantos acertos seguidos a pessoa já tem.
///
/// Cada acerto precisa de uma batida nova: depois de um acerto, o próximo só
/// conta depois de o app deixar de ouvir o acorde (silêncio ou "não
/// reconheci"). O acorde certo soando sem parar conta uma vez só. Um acorde
/// errado zera a sequência.
class ChordRepeatGate {
  final String chord;
  bool _waitingForRelease = false;
  int _hits = 0;

  ChordRepeatGate(this.chord);

  bool get waitingForRelease => _waitingForRelease;

  /// Acertos seguidos desde o último [reset] ou o último acorde errado.
  int get hits => _hits;

  void reset() {
    _waitingForRelease = false;
    _hits = 0;
  }

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
          _hits = 0;
          return ChordRepeatEvent.miss;
        }
        if (_waitingForRelease) return ChordRepeatEvent.stillRinging;
        _waitingForRelease = true;
        _hits++;
        return ChordRepeatEvent.hit;
      default:
        return ChordRepeatEvent.none;
    }
  }
}
