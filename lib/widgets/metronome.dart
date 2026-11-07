import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class Metronome extends StatefulWidget {
  final bool running;
  final int bpm;
  final VoidCallback onBeat;

  const Metronome({
    super.key,
    required this.running,
    required this.bpm,
    required this.onBeat,
  });

  @override
  State<Metronome> createState() => _MetronomeState();
}

class _MetronomeState extends State<Metronome> {
  Timer? _timer;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant Metronome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running || oldWidget.bpm != widget.bpm) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (!widget.running) return;
    final interval = Duration(milliseconds: (60000 / widget.bpm).round());
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void _tick() {
    SystemSound.play(SystemSoundType.click);
    if (mounted) setState(() => _pulse = !_pulse);
    widget.onBeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: motion(context, const Duration(milliseconds: 100)),
            width: _pulse ? 28 : 16,
            height: _pulse ? 28 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.running
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}
