import 'package:flutter/material.dart';

import '../models/tuner_note.dart';
import '../models/tuning_preset.dart';
import '../services/tuner_service.dart';
import '../state/app_state.dart';
import '../widgets/tuning_gauge.dart';
import 'custom_tuning_screen.dart';
import 'tuning_select_sheet.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final _service = TunerService();
  bool _listening = false;
  TunerReading? _reading;

  @override
  void initState() {
    super.initState();
    appState.addListener(_onAppStateChanged);
    _start();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de microfone negada')),
      );
      return;
    }

    setState(() => _listening = true);

    await _service.start((frequency) {
      if (!mounted) return;
      setState(() {
        _reading = classifyPitch(frequency, appState.activeTuning);
      });
    });
  }

  String get _tuningName {
    if (appState.tuningId == customTuningId) return 'Personalizada';
    return tuningPresets
        .firstWhere(
          (p) => p.id == appState.tuningId,
          orElse: () => tuningPresets.first,
        )
        .name;
  }

  String _stripOctave(String note) => note.replaceAll(RegExp(r'\d+$'), '');

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reading = _reading;
    final cents = reading?.cents ?? 0.0;
    final inTune = reading != null && reading.cents.abs() < 5;
    final flat = reading != null && reading.cents < -5;
    final sharp = reading != null && reading.cents > 5;
    final color = reading == null
        ? Colors.grey
        : (inTune ? Colors.green : Colors.orange);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Afinador'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => showTuningSelectSheet(context),
              icon: Text(_tuningName, overflow: TextOverflow.ellipsis),
              label: const Icon(Icons.expand_more, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '♭ grave',
                    style: TextStyle(
                      color: flat ? Colors.orange : colorScheme.outline,
                      fontWeight: flat ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: inTune
                          ? Colors.green.withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inTune)
                          const Icon(Icons.check, size: 16, color: Colors.green),
                        if (inTune) const SizedBox(width: 4),
                        Text(
                          reading == null
                              ? 'Ouvindo...'
                              : (inTune ? 'Afinada' : (flat ? 'Grave' : 'Aguda')),
                          style: TextStyle(
                            color: inTune ? Colors.green : colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'agudo ♯',
                    style: TextStyle(
                      color: sharp ? Colors.orange : colorScheme.outline,
                      fontWeight: sharp ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TuningGauge(cents: cents, color: color, active: reading != null),
              const SizedBox(height: 16),
              Text(
                _stripOctave(reading?.nearestString.name ?? appState.activeTuning.first.name),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                reading != null
                    ? '${reading.nearestString.frequency.toStringAsFixed(1)} Hz · ${reading.nearestString.label}'
                    : _listening
                        ? 'Toque uma corda'
                        : 'Permissão de microfone necessária',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final note in appState.activeTuning)
                    _buildStringChip(note, reading?.nearestString.name == note.name, colorScheme),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Afinação personalizada'),
                  subtitle: const Text('Defina cada corda manualmente'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomTuningScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStringChip(TunerNote note, bool active, ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? Colors.green : colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        _stripOctave(note.name),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : colorScheme.onSurface,
        ),
      ),
    );
  }
}
