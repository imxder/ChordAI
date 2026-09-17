import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/score.dart';
import '../services/chord_recognition_service.dart';
import '../services/score_library.dart';
import '../state/app_state.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/metronome.dart';

class PracticeSessionScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const PracticeSessionScreen({
    super.key,
    required this.serverUrl,
    this.inputDevice,
  });

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  final _service = ChordRecognitionService();
  final _scoreLibrary = ScoreLibrary();

  List<Score> _scores = [];
  Score? _selectedScore;
  int _bpm = 80;
  int _beatsInStep = 0;
  String _statusMessage = 'Escolha uma partitura e toque em Iniciar';

  @override
  void initState() {
    super.initState();
    if (widget.inputDevice != null) {
      _service.selectDevice(widget.inputDevice);
    }
    appState.addListener(_onAppStateChanged);
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await _scoreLibrary.loadAll();
    if (!mounted) return;
    setState(() {
      _scores = scores;
      _selectedScore = scores.isNotEmpty ? scores.first : null;
    });
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {});
    final unlocked = appState.consumePendingUnlocked();
    for (final achievement in unlocked) {
      _showSnackBar('Conquista desbloqueada: ${achievement.title}');
    }
  }

  Future<void> _start() async {
    final score = _selectedScore;
    if (score == null) return;

    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('Permissão de microfone negada');
      return;
    }

    appState.startSession(score);
    _beatsInStep = 0;

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: (p) => appState.updatePrediction(p),
      onError: (_) => _showSnackBar('Erro ao conectar com o servidor'),
    );

    setState(() => _statusMessage = 'Ouvindo...');
  }

  Future<void> _stop() async {
    await _service.stop();
    appState.stopSession();
    setState(() => _statusMessage = 'Sessão parada');
  }

  void _onBeat() {
    if (appState.sessionStatus != SessionStatus.running) return;
    final step = appState.currentStep;
    if (step == null) return;

    _beatsInStep++;
    if (_beatsInStep < step.beats) return;
    _beatsInStep = 0;

    final recognized = appState.lastPrediction?.chord;
    final matched = recognized != null &&
        recognized.toLowerCase() == step.chord.toLowerCase();
    appState.advanceStep(matched: matched);

    if (appState.sessionStatus == SessionStatus.idle) {
      _service.stop();
      setState(() => _statusMessage =
          'Sessão concluída! ${appState.sessionHits}/${appState.sessionHits + appState.sessionMisses} acordes certos');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = appState.sessionStatus == SessionStatus.running;
    final step = appState.currentStep;
    final recognized = appState.lastPrediction?.chord;
    final matchState = step == null
        ? ChordMatchState.neutral
        : (recognized != null &&
                recognized.toLowerCase() == step.chord.toLowerCase()
            ? ChordMatchState.correct
            : ChordMatchState.incorrect);

    return Scaffold(
      appBar: AppBar(title: const Text('Sessão de Prática')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<Score>(
                initialValue: _selectedScore,
                decoration: const InputDecoration(
                  labelText: 'Partitura',
                  border: OutlineInputBorder(),
                ),
                items: _scores
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.title)))
                    .toList(),
                onChanged:
                    running ? null : (s) => setState(() => _selectedScore = s),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('BPM'),
                  Expanded(
                    child: Slider(
                      min: 40,
                      max: 160,
                      divisions: 24,
                      value: _bpm.toDouble(),
                      label: '$_bpm',
                      onChanged: running
                          ? null
                          : (v) => setState(() => _bpm = v.round()),
                    ),
                  ),
                  SizedBox(width: 32, child: Text('$_bpm')),
                ],
              ),
              const SizedBox(height: 8),
              Metronome(running: running, bpm: _bpm, onBeat: _onBeat),
              const SizedBox(height: 16),
              if (_selectedScore != null)
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedScore!.steps.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final s = _selectedScore!.steps[index];
                      final active =
                          running && index == appState.currentStepIndex;
                      return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.deepPurple
                              : Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.chord,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: GuitarNeck(chord: step?.chord, matchState: matchState),
              ),
              Text(_statusMessage, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'XP: ${appState.xp}  •  Nível: ${appState.level}  •  Moedas: ${appState.coins}',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _selectedScore == null
                    ? null
                    : (running ? _stop : _start),
                icon: Icon(running ? Icons.stop : Icons.play_arrow),
                label: Text(running ? 'Parar' : 'Iniciar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: running ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
