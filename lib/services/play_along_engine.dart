import 'dart:math';

import '../models/chord_for_model.dart';
import '../models/score.dart';

enum PlayAlongMode { followTempo, waitForMe }

enum StepResult { pending, hit, miss, notCounted }

class PlayAlongEngine {
  static const Duration lateTolerance = Duration(milliseconds: 1000);
  static const Duration earlyTolerance = Duration(milliseconds: 300);
  static const int countInBeats = 4;
  static const Duration shortestCounted = Duration(milliseconds: 1000);

  final List<ChordStep> steps;
  final PlayAlongMode mode;
  final Duration Function() elapsed;
  final int readingsToHitLongChord;
  final List<String?> modelChords;
  final List<StepResult> results;
  final List<Map<String, int>> _heard;
  final List<double> _startBeat;

  int index = 0;
  bool finished = false;
  int? lastJudged;
  int bpm;
  Duration _anchorTime = Duration.zero;
  double _anchorBeat = -countInBeats.toDouble();
  int _lastBeat = -countInBeats - 1;
  double _waitStartBeat = 0;
  final Map<String, int> _waitHeard = {};

  PlayAlongEngine({
    required this.steps,
    required Set<String> knownChords,
    required this.bpm,
    required this.elapsed,
    this.mode = PlayAlongMode.followTempo,
    this.readingsToHitLongChord = 2,
  }) : modelChords = [
         for (final s in steps) chordForModel(s.chord, knownChords),
       ],
       results = [
         for (final s in steps)
           chordForModel(s.chord, knownChords) == null
               ? StepResult.notCounted
               : StepResult.pending,
       ],
       _heard = [for (final _ in steps) <String, int>{}],
       _startBeat = _cumulative(steps);

  static List<double> _cumulative(List<ChordStep> steps) {
    final out = <double>[];
    var total = 0.0;
    for (final s in steps) {
      out.add(total);
      total += s.beats;
    }
    out.add(total);
    return out;
  }

  double get _beatMs => 60000 / bpm;

  double get position =>
      _anchorBeat + (elapsed() - _anchorTime).inMicroseconds / 1000 / _beatMs;

  bool get countingIn => !finished && position < 0;

  double get beatInStep {
    final pos = position;
    if (pos < 0) return 0;
    final start = mode == PlayAlongMode.waitForMe
        ? _waitStartBeat
        : _startBeat[index];
    return max(0, pos - start);
  }

  int get eighthInBar {
    final pos = position;
    final inBar = ((pos % 4) + 4) % 4;
    return (inBar * 2).floor();
  }

  int get countInLeft => max(1, (-position).ceil());

  ChordStep? get currentStep => index < steps.length ? steps[index] : null;

  String? get nextChord =>
      index + 1 < steps.length ? steps[index + 1].chord : null;

  double get _lateBeats => lateTolerance.inMilliseconds / _beatMs;

  double get _earlyBeats => earlyTolerance.inMilliseconds / _beatMs;

  void start() {
    _anchorTime = elapsed();
    _anchorBeat = -countInBeats.toDouble();
    _lastBeat = -countInBeats - 1;
    _waitStartBeat = 0;
  }

  void setBpm(int value) {
    _anchorBeat = position;
    _anchorTime = elapsed();
    bpm = value;
  }

  bool isTooShort(int step) =>
      steps[step].beats * _beatMs < shortestCounted.inMilliseconds;

  int _readingsNeeded(int step) {
    final ms = steps[step].beats * _beatMs;
    return ms >= 2000 ? readingsToHitLongChord : 1;
  }

  bool update() {
    if (finished) return false;
    final pos = position;
    final beat = pos.floor();
    final beatCrossed = beat > _lastBeat;
    _lastBeat = beat;
    if (pos < 0) return beatCrossed;

    if (mode == PlayAlongMode.followTempo) {
      _followTempo(pos);
    } else {
      _waitForMe(pos);
    }
    return beatCrossed;
  }

  void _followTempo(double pos) {
    var i = index;
    while (i + 1 < steps.length && _startBeat[i + 1] <= pos) {
      i++;
    }
    index = i;
    for (var s = 0; s < steps.length; s++) {
      if (results[s] != StepResult.pending) continue;
      if (pos >= _startBeat[s + 1] + _lateBeats) _judge(s);
    }
    if (pos >= _startBeat[steps.length] + _lateBeats) finished = true;
  }

  void _waitForMe(double pos) {
    final step = index;
    final duration = steps[step].beats.toDouble();
    final waited = pos - _waitStartBeat;
    final isLast = step == steps.length - 1;
    final nextIsAudible =
        !isLast &&
        modelChords[step + 1] != null &&
        !isTooShort(step + 1) &&
        modelChords[step + 1] != modelChords[step];

    if (isLast) {
      final heardLast =
          (_heard[step][modelChords[step]] ?? 0) >= _readingsNeeded(step);
      if ((heardLast || modelChords[step] == null || isTooShort(step)) &&
          waited >= duration) {
        _judge(step);
        finished = true;
      } else if (waited >= duration * 2 + _lateBeats) {
        _judge(step);
        finished = true;
      }
      return;
    }

    if (!nextIsAudible && waited >= duration) {
      _moveTo(step + 1, pos);
    } else if (waited >= duration * 2 + _lateBeats) {
      _moveTo(step + 1, pos);
    }
  }

  void _moveTo(int target, double pos) {
    for (var s = index; s < target; s++) {
      if (results[s] == StepResult.pending) _judge(s);
    }
    index = target;
    _waitStartBeat = pos;
    _waitHeard.clear();
  }

  void _judge(int step) {
    final chord = modelChords[step];
    if (chord == null || isTooShort(step)) {
      results[step] = StepResult.notCounted;
    } else {
      final heard = _heard[step][chord] ?? 0;
      final needed = mode == PlayAlongMode.waitForMe
          ? 1
          : _readingsNeeded(step);
      results[step] = heard >= needed ? StepResult.hit : StepResult.miss;
    }
    lastJudged = step;
  }

  void reading(String? chord) {
    if (finished || chord == null) return;
    final pos = position;
    if (pos < 0) return;

    if (mode == PlayAlongMode.followTempo) {
      for (var s = 0; s < steps.length; s++) {
        if (results[s] != StepResult.pending) continue;
        final from = _startBeat[s] - _earlyBeats;
        final to = _startBeat[s + 1] + _lateBeats;
        if (pos < from || pos > to) continue;
        _heard[s][chord] = (_heard[s][chord] ?? 0) + 1;
      }
      return;
    }

    _heard[index][chord] = (_heard[index][chord] ?? 0) + 1;
    _waitHeard[chord] = (_waitHeard[chord] ?? 0) + 1;
    var ahead = 0;
    for (var target = index + 1; target < steps.length && ahead < 2; target++) {
      if (isTooShort(target)) continue;
      ahead++;
      final targetChord = modelChords[target];
      if (targetChord == null || targetChord == modelChords[index]) continue;
      if ((_waitHeard[targetChord] ?? 0) >= readingsToHitLongChord) {
        _moveTo(target, pos);
        _heard[target][targetChord] = readingsToHitLongChord;
        return;
      }
    }
  }

  String? wrongChordHeard(int step) {
    final expected = modelChords[step];
    String? best;
    var bestCount = 0;
    _heard[step].forEach((chord, count) {
      if (chord != expected && count > bestCount) {
        best = chord;
        bestCount = count;
      }
    });
    return best;
  }

  int get hits => results.where((r) => r == StepResult.hit).length;

  int get misses => results.where((r) => r == StepResult.miss).length;

  Map<String, (int, int)> get perChord {
    final out = <String, (int, int)>{};
    for (var s = 0; s < steps.length; s++) {
      if (results[s] == StepResult.notCounted ||
          results[s] == StepResult.pending) {
        continue;
      }
      final chord = steps[s].chord;
      final (hit, total) = out[chord] ?? (0, 0);
      out[chord] = (hit + (results[s] == StepResult.hit ? 1 : 0), total + 1);
    }
    return out;
  }

  Set<String> get notCountedChords => {
    for (var s = 0; s < steps.length; s++)
      if (results[s] == StepResult.notCounted && modelChords[s] == null)
        steps[s].chord,
  };

  Set<String> get tooShortChords => {
    for (var s = 0; s < steps.length; s++)
      if (results[s] == StepResult.notCounted && modelChords[s] != null)
        steps[s].chord,
  };
}
