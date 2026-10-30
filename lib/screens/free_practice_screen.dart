import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/chord_prediction.dart';
import '../services/chord_recognition_service.dart';

class FreePracticeScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const FreePracticeScreen({
    super.key,
    required this.serverUrl,
    this.inputDevice,
  });

  @override
  State<FreePracticeScreen> createState() => _FreePracticeScreenState();
}

class _FreePracticeScreenState extends State<FreePracticeScreen> {
  final _service = ChordRecognitionService();

  bool _listening = false;
  String? _chord;
  double _confidence = 0.0;
  String _statusMessage = 'Toque um acorde no violão';

  @override
  void initState() {
    super.initState();
    if (widget.inputDevice != null) {
      _service.selectDevice(widget.inputDevice);
    }
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _service.stop();
      setState(() {
        _listening = false;
        _statusMessage = 'Toque um acorde no violão';
      });
      return;
    }

    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('Permissão de microfone negada');
      return;
    }

    setState(() {
      _listening = true;
      _chord = null;
      _confidence = 0.0;
      _statusMessage = 'Ouvindo...';
    });

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: _handlePrediction,
      onError: (_) => _showSnackBar('Erro ao conectar com o servidor'),
    );
  }

  void _handlePrediction(ChordPrediction prediction) {
    if (!mounted) return;
    setState(() {
      switch (prediction.status) {
        case 'ok':
          _chord = prediction.chord;
          _confidence = prediction.confidence;
          _statusMessage = 'Ouvindo...';
          break;
        case 'silence':
          _statusMessage = 'Ouvindo...';
          break;
        case 'too_short':
          _statusMessage = 'Áudio muito curto, continue tocando...';
          break;
        default:
          _statusMessage = prediction.message ?? 'Acorde não identificado';
      }
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final chord = _chord;

    return Scaffold(
      appBar: AppBar(title: const Text('Treino livre')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                _listening ? 'OUVINDO' : 'PARADO',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(48),
                  border: Border.all(
                    color: chord != null ? Colors.green : colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      chord ?? '—',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chord != null ? chordFullName(chord) : '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_confidence > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_confidence * 100).toStringAsFixed(0)}% de confiança',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
              const Spacer(),
              Icon(
                Icons.graphic_eq,
                size: 48,
                color: _listening ? colorScheme.primary : colorScheme.outlineVariant,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? Colors.red : colorScheme.primary,
                  ),
                  child: Icon(
                    _listening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_statusMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
