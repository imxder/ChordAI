import 'package:flutter/material.dart';

import '../models/tuner_note.dart';
import '../services/tuner_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/page_parts.dart';
import '../widgets/tuning_gauge.dart';
import 'custom_tuning_screen.dart';
import 'tuning_select_sheet.dart';
import '../theme/ph.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  static const _toleranceCents = 5.0;

  final _service = TunerService();
  bool _listening = false;
  bool _denied = false;
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
    if (!mounted) return;
    if (!hasPermission) {
      setState(() => _denied = true);
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

  String _stripOctave(String note) => note.replaceAll(RegExp(r'\d+$'), '');

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final reading = _reading;
    final inTune = reading != null && reading.cents.abs() <= _toleranceCents;
    final flat = reading != null && !inTune && reading.cents < 0;
    final color = reading == null
        ? colorScheme.onSurfaceVariant
        : (inTune ? tokens.correct : tokens.warning);

    final String status;
    if (_denied) {
      status = 'O afinador precisa de acesso ao microfone';
    } else if (reading == null) {
      status = _listening ? 'Toque uma corda solta' : 'Preparando o microfone';
    } else if (inTune) {
      status = 'Afinada';
    } else {
      status = flat ? 'Grave: aperte a tarraxa' : 'Aguda: afrouxe a tarraxa';
    }

    return IosPage(
      title: 'Afinador',
      children: [
        GroupedSection(
          top: 8,
          children: [
            GroupedRow(
              title: 'Afinação',
              value: appState.activeTuningName,
              onTap: () => showTuningSelectSheet(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TuningGauge(
                    cents: reading?.cents ?? 0,
                    color: color,
                    active: reading != null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('grave', style: textTheme.bodySmall),
                    Text(
                      reading == null
                          ? ''
                          : '${reading.cents >= 0 ? '+' : ''}${reading.cents.round()} cents',
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: fontChord,
                      ),
                    ),
                    Text('agudo', style: textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Column(
                    children: [
                      Text(
                        reading == null
                            ? '–'
                            : _stripOctave(reading.nearestString.name),
                        style: textTheme.displayLarge?.copyWith(
                          color: reading == null
                              ? colorScheme.outlineVariant
                              : color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusLine(
                        icon: inTune ? Ph.checkCircleFill : null,
                        text: status,
                        color: reading == null ? null : color,
                        textAlign: TextAlign.center,
                      ),
                      if (reading != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${reading.nearestString.label} · ${reading.nearestString.frequency.toStringAsFixed(1)} Hz',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final (i, note) in appState.activeTuning.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _StringCell(
                  label: _stripOctave(note.name),
                  active: reading?.nearestString.name == note.name,
                ),
              ),
            ],
          ],
        ),
        GroupedSection(
          children: [
            GroupedRow(
              title: 'Afinação personalizada',
              subtitle: 'Escolha a nota de cada corda',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomTuningScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StringCell extends StatelessWidget {
  final String label;
  final bool active;

  const _StringCell({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: active,
      child: AnimatedContainer(
        duration: motion(context, const Duration(milliseconds: 150)),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: fontChord,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: active ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
