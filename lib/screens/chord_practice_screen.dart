import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import '../models/chord_prediction.dart';
import '../services/chord_recognition_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import '../theme/ph.dart';

class ChordPracticeScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;
  final String chord;

  const ChordPracticeScreen({
    super.key,
    required this.serverUrl,
    required this.chord,
    this.inputDevice,
  });

  @override
  State<ChordPracticeScreen> createState() => _ChordPracticeScreenState();
}

class _ChordPracticeScreenState extends State<ChordPracticeScreen> {
  final _service = ChordRecognitionService();

  bool _listening = false;
  int _hits = 0;
  ChordMatchState _matchState = ChordMatchState.neutral;
  String _statusMessage = 'Toque em Começar e faça o acorde';

  @override
  void initState() {
    super.initState();
    if (widget.inputDevice != null) {
      _service.selectDevice(widget.inputDevice);
    }
  }

  Future<void> _start() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('O app precisa de acesso ao microfone');
      return;
    }

    setState(() {
      _listening = true;
      _hits = 0;
      _matchState = ChordMatchState.neutral;
      _statusMessage = 'Ouvindo';
    });

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: _handlePrediction,
      onError: (_) => _showSnackBar('Não consegui falar com o servidor'),
    );
  }

  Future<void> _stop() async {
    await _service.stop();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _statusMessage = 'Parado';
    });
  }

  void _handlePrediction(ChordPrediction prediction) {
    if (!mounted) return;

    if (prediction.status == 'silence' || prediction.status == 'too_short') {
      setState(() => _statusMessage = 'Ouvindo');
      return;
    }

    if (prediction.status != 'ok') {
      setState(() => _statusMessage = prediction.message ?? 'Ouvindo');
      return;
    }

    final matched =
        prediction.chord?.toLowerCase() == widget.chord.toLowerCase();

    setState(() {
      if (matched) {
        _hits++;
        _matchState = ChordMatchState.correct;
        _statusMessage = 'Certo';
      } else {
        _hits = 0;
        _matchState = ChordMatchState.incorrect;
        _statusMessage = 'Ouvi ${prediction.chord}. Tente de novo';
      }
    });

    if (matched) HapticFeedback.lightImpact();
    if (matched && appState.registerChordHits(widget.chord, _hits)) {
      HapticFeedback.mediumImpact();
      _showSnackBar('${widget.chord} entrou nos seus acordes aprendidos');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final learned = appState.isChordLearned(widget.chord);
    final statusColor = switch (_matchState) {
      ChordMatchState.correct => context.tokens.correct,
      ChordMatchState.incorrect => colorScheme.error,
      ChordMatchState.neutral => null,
    };
    final statusIcon = switch (_matchState) {
      ChordMatchState.correct => Ph.check,
      ChordMatchState.incorrect => Ph.x,
      ChordMatchState.neutral => null,
    };

    return IosPage(
      title: 'Testar ${widget.chord}',
      bottomBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _listening ? _stop : _start,
          icon: Icon(_listening ? Ph.stopFill : Ph.microphoneFill, size: 20),
          label: Text(_listening ? 'Parar' : 'Começar'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: _listening ? colorScheme.onSurface : null,
            foregroundColor: _listening ? colorScheme.surface : null,
          ),
        ),
      ),
      children: [
        Material(
          color: context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.32,
                    maxWidth: 240,
                  ),
                  child: GuitarNeck(
                    chord: widget.chord,
                    matchState: _matchState,
                  ),
                ),
                const SizedBox(height: 18),
                StatusLine(
                  icon: statusIcon,
                  text: _statusMessage,
                  color: statusColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        GroupedSection(
          footer: learned
              ? 'Você já aprendeu este acorde. Treine o quanto quiser.'
              : 'Acerte ${AppState.chordMasteryHits} vezes seguidas para marcar como aprendido.',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acertos seguidos: $_hits de ${AppState.chordMasteryHits}',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        for (var i = 0; i < AppState.chordMasteryHits; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(
                            child: AnimatedContainer(
                              duration: motion(
                                context,
                                const Duration(milliseconds: 160),
                              ),
                              height: 6,
                              decoration: BoxDecoration(
                                color: i < _hits
                                    ? context.tokens.correct
                                    : context.tokens.fill,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
