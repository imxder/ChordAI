import '../models/score.dart';

class PlayAlongEngine {
  final List<ChordStep> steps;
  final void Function({required bool matched}) onAdvance;

  int index = 0;
  bool finished = false;
  String? lastHeard;
  bool? lastMatched;
  final Map<String, int> attempts = {};
  final Map<String, int> correct = {};
  int _beatsInStep = 0;

  PlayAlongEngine({required this.steps, required this.onAdvance});

  ChordStep? get currentStep => index < steps.length ? steps[index] : null;

  String? get nextChord =>
      index + 1 < steps.length ? steps[index + 1].chord : null;

  bool _hasDetectableTransition(ChordStep step) {
    final next = nextChord;
    return next != null && next.toLowerCase() != step.chord.toLowerCase();
  }

  void beat() {
    final step = currentStep;
    if (finished || step == null) return;
    if (_hasDetectableTransition(step)) {
      _beatsInStep = 0;
      return;
    }
    _beatsInStep++;
    if (_beatsInStep < step.beats) return;
    _beatsInStep = 0;
    _advance(matched: true);
  }

  void reading(String? recognized) {
    final step = currentStep;
    if (finished || step == null || recognized == null) return;

    final isCurrent = recognized.toLowerCase() == step.chord.toLowerCase();
    final isNext =
        _hasDetectableTransition(step) &&
        recognized.toLowerCase() == nextChord!.toLowerCase();

    lastHeard = recognized;
    lastMatched = isCurrent || isNext;

    if (isNext) {
      _advance(matched: true);
    } else if (!isCurrent) {
      attempts[step.chord] = (attempts[step.chord] ?? 0) + 1;
    }
  }

  void _advance({required bool matched}) {
    final step = currentStep;
    if (step != null) {
      attempts[step.chord] = (attempts[step.chord] ?? 0) + 1;
      if (matched) correct[step.chord] = (correct[step.chord] ?? 0) + 1;
    }
    if (index < steps.length - 1) {
      index++;
      lastHeard = null;
      lastMatched = null;
    } else {
      finished = true;
    }
    onAdvance(matched: matched);
  }
}
