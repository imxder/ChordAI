import 'package:flutter/material.dart';

import '../models/tuner_note.dart';
import '../services/tuner_service.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final _service = TunerService();
  bool _listening = false;
  TunerReading? _reading;
  String _statusMessage = 'Toque em Iniciar e dedilhe uma corda';

  Future<void> _toggle() async {
    if (_listening) {
      await _service.stop();
      setState(() {
        _listening = false;
        _statusMessage = 'Parado';
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
      _statusMessage = 'Ouvindo...';
    });

    await _service.start((frequency) {
      if (!mounted) return;
      setState(() {
        _reading = classifyPitch(frequency);
        _statusMessage = _reading == null ? 'Ouvindo...' : '';
      });
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
    final reading = _reading;
    final cents = reading?.cents.clamp(-50, 50) ?? 0.0;
    final inTune = reading != null && reading.cents.abs() < 5;
    final close = reading != null && reading.cents.abs() < 15;
    final color = reading == null
        ? Colors.grey
        : (inTune ? Colors.green : (close ? Colors.orange : Colors.red));

    return Scaffold(
      appBar: AppBar(title: const Text('Afinador')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Text(
                reading?.nearestString.name ?? '—',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 8),
              Text(reading?.nearestString.label ?? ''),
              const SizedBox(height: 32),
              _buildGauge(cents.toDouble(), color),
              const SizedBox(height: 16),
              Text(
                reading == null
                    ? _statusMessage
                    : (inTune
                        ? 'Afinado!'
                        : (reading.cents > 0 ? 'Afrouxe um pouco' : 'Aperte um pouco')),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _toggle,
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

  Widget _buildGauge(double cents, Color color) {
    final fraction = (cents + 50) / 100;
    return SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                left: (width * 0.5) - 1,
                child: Container(width: 2, height: 24, color: Colors.grey.shade500),
              ),
              Positioned(
                left: (width * fraction).clamp(0, width) - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
