import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_prediction.dart';
import '../services/chord_recognition_service.dart';
import '../state/app_state.dart';
import '../widgets/guitar_neck.dart';

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
  int _streak = 0;
  ChordMatchState _matchState = ChordMatchState.neutral;
  String _statusMessage = 'Toque em Iniciar e execute o acorde';

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
      _showSnackBar('Permissão de microfone negada');
      return;
    }

    setState(() {
      _listening = true;
      _streak = 0;
      _matchState = ChordMatchState.neutral;
      _statusMessage = 'Ouvindo...';
    });

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: _handlePrediction,
      onError: (_) => _showSnackBar('Erro ao conectar com o servidor'),
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
      setState(() => _statusMessage = 'Ouvindo...');
      return;
    }

    if (prediction.status != 'ok') {
      setState(() => _statusMessage = prediction.message ?? 'Ouvindo...');
      return;
    }

    final matched =
        prediction.chord?.toLowerCase() == widget.chord.toLowerCase();

    setState(() {
      if (matched) {
        _streak++;
        _matchState = ChordMatchState.correct;
        _statusMessage = 'Certo! ($_streak/${AppState.chordMasteryStreak})';
      } else {
        _streak = 0;
        _matchState = ChordMatchState.incorrect;
        _statusMessage = 'Reconheci "${prediction.chord}" — tente de novo';
      }
    });

    if (matched) {
      appState.registerChordStreak(widget.chord, _streak);
      final rewards = appState.consumePendingChordRewards();
      if (rewards.contains(widget.chord)) {
        _showSnackBar('Acorde ${widget.chord} aprendido! +25 XP, +10 moedas');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learned = appState.isChordLearned(widget.chord);
    return Scaffold(
      appBar: AppBar(title: Text('Acorde ${widget.chord}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (learned)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Chip(
                    avatar: Icon(Icons.check_circle, color: Colors.green),
                    label: Text('Aprendido'),
                  ),
                ),
              Expanded(
                child: GuitarNeck(chord: widget.chord, matchState: _matchState),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: (_streak / AppState.chordMasteryStreak).clamp(0, 1),
              ),
              const SizedBox(height: 8),
              Text(_statusMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _listening ? _stop : _start,
                icon: Icon(_listening ? Icons.stop : Icons.mic),
                label: Text(_listening ? 'Parar' : 'Iniciar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _listening ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
