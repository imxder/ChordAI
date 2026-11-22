import 'chord_prediction.dart';

enum ChordRepeatEvent { hit, stillRinging, released, miss, none }

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
