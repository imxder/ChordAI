import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/score.dart';
import '../services/chord_recognizer.dart';
import '../services/chord_recognizer_factory.dart';
import '../services/score_library.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/metronome.dart';
import '../widgets/page_parts.dart';
import '../widgets/recognition_mode_badge.dart';
import '../theme/ph.dart';

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
  late final ChordRecognizer _service =
      createChordRecognizer(appState.chordRecognitionMode);
  final _scoreLibrary = ScoreLibrary();

  List<Score> _scores = [];
  Score? _selectedScore;
  int _bpm = 80;
  int _beatsInStep = 0;
  String _statusMessage = 'Escolha uma sequência e toque em Começar';

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
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final score = _selectedScore;
    if (score == null) return;

    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('O app precisa de acesso ao microfone');
      return;
    }

    appState.startSession(score);
    _beatsInStep = 0;

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: (p) => appState.updatePrediction(p),
      onError: (_) => _showSnackBar(
        chordRecognitionErrorMessage(appState.chordRecognitionMode),
      ),
    );

    setState(() => _statusMessage = 'Ouvindo');
  }

  Future<void> _stop() async {
    await _service.stop();
    appState.stopSession();
    setState(() => _statusMessage = 'Treino parado');
  }

  void _onBeat() {
    if (appState.sessionStatus != SessionStatus.running) return;
    final step = appState.currentStep;
    if (step == null) return;

    _beatsInStep++;
    if (_beatsInStep < step.beats) return;
    _beatsInStep = 0;

    final recognized = appState.lastPrediction?.chord;
    final matched =
        recognized != null &&
        recognized.toLowerCase() == step.chord.toLowerCase();
    appState.advanceStep(matched: matched);

    if (appState.sessionStatus == SessionStatus.idle) {
      _service.stop();
      final total = appState.sessionHits + appState.sessionMisses;
      setState(
        () => _statusMessage =
            'Treino concluído: ${appState.sessionHits} de $total acordes certos',
      );
    }
  }

  void _pickScore() {
    showGlassSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(title: 'Sequência'),
              GroupedSection(
                top: 8,
                children: [
                  for (final score in _scores)
                    CheckRow(
                      title: score.title,
                      selected: score == _selectedScore,
                      onTap: () {
                        setState(() => _selectedScore = score);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    if (appState.sessionStatus != SessionStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => appState.stopSession(),
      );
    }
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final running = appState.sessionStatus == SessionStatus.running;
    final step = appState.currentStep;
    final recognized = appState.lastPrediction?.chord;
    final matchState = step == null
        ? ChordMatchState.neutral
        : (recognized != null &&
                  recognized.toLowerCase() == step.chord.toLowerCase()
              ? ChordMatchState.correct
              : ChordMatchState.incorrect);
    final shownChord = step?.chord ?? _selectedScore?.steps.firstOrNull?.chord;

    return IosPage(
      title: 'Sequências',
      trailing: const RecognitionModeBadge(),
      bottomBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _selectedScore == null ? null : (running ? _stop : _start),
          icon: Icon(running ? Ph.stopFill : Ph.playFill, size: 20),
          label: Text(running ? 'Parar' : 'Começar'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: running ? colorScheme.onSurface : null,
            foregroundColor: running ? colorScheme.surface : null,
          ),
        ),
      ),
      children: [
        GroupedSection(
          top: 8,
          children: [
            GroupedRow(
              title: 'Sequência',
              value: _selectedScore?.title ?? 'Carregando',
              onTap: running || _scores.isEmpty ? null : _pickScore,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  Text('Andamento', style: textTheme.bodyLarge),
                  const Spacer(),
                  Text(
                    '$_bpm BPM',
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: fontChord,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlider(
                  min: 40,
                  max: 160,
                  divisions: 24,
                  value: _bpm.toDouble(),
                  activeColor: colorScheme.primary,
                  onChanged: running
                      ? null
                      : (v) => setState(() => _bpm = v.round()),
                ),
              ),
            ),
          ],
        ),
        if (_selectedScore != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedScore!.steps.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final s = _selectedScore!.steps[index];
                final active = running && index == appState.currentStepIndex;
                return Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: active ? colorScheme.primary : context.tokens.cell,
                    borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
                  ),
                  child: ChordName(
                    s.chord,
                    size: 16,
                    color: active ? colorScheme.onPrimary : null,
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        Material(
          color: context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: GuitarNeck(chord: shownChord, matchState: matchState),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChordName(shownChord ?? '–', size: 44),
                      const SizedBox(height: 8),
                      StatusLine(text: _statusMessage),
                    ],
                  ),
                ),
                Metronome(running: running, bpm: _bpm, onBeat: _onBeat),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
