import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tuner_note.dart';
import '../services/audio_input.dart';
import '../services/tuner_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/mic_lifecycle.dart';
import '../widgets/page_parts.dart';
import '../widgets/tuning_gauge.dart';
import '../models/guide_content.dart';
import 'custom_tuning_screen.dart';
import 'guide_detail_screen.dart';
import 'tuning_select_sheet.dart';
import '../theme/ph.dart';
import '../theme/platform_style.dart';
import '../widgets/desktop_input.dart';

class TunerScreen extends StatefulWidget {
  /// Só pros testes: um afinador falso no lugar do microfone.
  final TunerService? service;

  const TunerScreen({super.key, this.service});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> with MicLifecycle {
  late final TunerService _service = widget.service ?? TunerService();
  bool _listening = false;
  bool _denied = false;
  TunerReading? _reading;
  bool _inTune = false;

  /// Microfone bloqueado ou entrada desconectada (só no computador). Fica na
  /// tela até o áudio voltar a chegar.
  MicrophoneProblem? _problem;
  Timer? _retry;

  /// Corda escolhida tocando na casinha (índice na afinação ativa). `null` é
  /// o modo Auto, em que o app reconhece sozinho a corda que está soando. Não
  /// fica salvo: o afinador sempre abre no Auto.
  int? _targetIndex;

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

    setState(() {
      _listening = true;
      _denied = false;
    });

    await _service.start((frequency) {
      if (!mounted) return;
      final wasInTune = _inTune;
      setState(() {
        _problem = null;
        _reading = _classify(frequency);
        _inTune = _service.smoother?.updateInTune(_reading?.cents) ?? false;
      });
      if (_inTune && !wasInTune && !isDesktop) HapticFeedback.mediumImpact();
    }, onProblem: _onMicrophoneProblem);
  }

  // O afinador não tem botão de começar, então tenta de novo sozinho a cada
  // 3 s. Quando a pessoa libera o microfone ou conecta a entrada de novo, o
  // áudio volta a chegar e a mensagem some.
  void _onMicrophoneProblem(MicrophoneProblem problem) {
    if (!mounted) return;
    setState(() {
      _problem = problem;
      _listening = false;
      _reading = null;
      _inTune = false;
    });
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), () {
      if (mounted && !_listening) _start();
    });
  }

  // Escondendo o app, o afinador desliga o microfone. Ele não tem botão de
  // começar, então liga sozinho de novo quando o app volta (e confere a
  // permissão de novo, caso tenha sido liberada nas Configurações).
  @override
  void onAppHidden() {
    _retry?.cancel();
    if (!_listening) return;
    _service.stop();
    setState(() {
      _listening = false;
      _reading = null;
      _inTune = false;
    });
  }

  @override
  void onAppShown() {
    if (!_listening) _start();
  }

  TunerReading? _classify(double? frequency) {
    final strings = appState.activeTuning;
    final target = _targetIndex;
    if (target == null || target >= strings.length) {
      return classifyPitch(frequency, strings);
    }
    return classifyPitchFor(frequency, strings[target]);
  }

  /// Troca entre o Auto (`null`) e uma corda escolhida. Zera o ponteiro pra
  /// não sobrar a leitura medida contra a corda de antes.
  void _setTarget(int? index) {
    _service.smoother?.reset();
    setState(() {
      _targetIndex = index;
      _reading = null;
      _inTune = _service.smoother?.updateInTune(null) ?? false;
    });
  }

  void _setAuto(bool auto) {
    if (auto) {
      _setTarget(null);
      return;
    }
    // Desligando o Auto, fica escolhida a corda que estava sendo reconhecida
    // (ou a 6ª, se nenhuma estava).
    final current = _reading?.nearestString;
    final index = current == null
        ? 0
        : appState.activeTuning.indexWhere((n) => n.name == current.name);
    _setTarget(index < 0 ? 0 : index);
  }

  String _stripOctave(String note) => note.replaceAll(RegExp(r'\d+$'), '');

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _retry?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final reading = _reading;
    final inTune = _inTune;
    final flat = reading != null && !inTune && reading.cents < 0;
    final color = reading == null
        ? colorScheme.onSurfaceVariant
        : (inTune ? tokens.correct : tokens.warning);

    final String status;
    if (_denied) {
      status = 'O afinador precisa de acesso ao microfone';
    } else if (_problem != null) {
      status = _problem!.message;
    } else if (reading == null) {
      status = _listening ? 'Toque uma corda solta' : 'Preparando o microfone';
    } else if (inTune) {
      status = 'Afinada';
    } else {
      status = flat ? 'Grave: aperte a tarraxa' : 'Aguda: afrouxe a tarraxa';
    }

    final auto = _targetIndex == null;

    final tuningRow = GroupedSection(
      top: 8,
      children: [
        GroupedRow(
          title: 'Afinação',
          value: appState.activeTuningName,
          onTap: () => showTuningSelectSheet(context),
        ),
      ],
    );
    final gaugeCard = Material(
      color: tokens.cell,
      borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        child: Column(
          children: [
            SizedBox(
              height: isDesktop ? 110 : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TuningGauge(
                  cents: reading?.cents ?? 0,
                  color: color,
                  active: reading != null,
                ),
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
                  style: textTheme.bodySmall?.copyWith(fontFamily: fontChord),
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
    );
    final strings = Row(
      children: [
        for (final (i, note) in appState.activeTuning.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _StringCell(
              label: _stripOctave(note.name),
              number: '${appState.activeTuning.length - i}ª',
              semanticsLabel: 'Afinar a ${note.label}',
              active: auto
                  ? reading?.nearestString.name == note.name
                  : _targetIndex == i,
              onTap: () => _setTarget(i),
            ),
          ),
        ],
      ],
    );
    final options = GroupedSection(
      children: [
        GroupedRow(
          title: 'Reconhecer a corda sozinho',
          subtitle: auto
              ? 'O app descobre qual corda está soando'
              : 'Toque na corda que quer afinar',
          chevron: false,
          onTap: () => _setAuto(!auto),
          trailing: CupertinoSwitch(
            value: auto,
            activeTrackColor: colorScheme.primary,
            onChanged: _setAuto,
          ),
        ),
        GroupedRow(
          title: 'Afinação personalizada',
          subtitle: 'Escolha a nota de cada corda',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CustomTuningScreen())),
        ),
        GroupedRow(
          title: 'Primeira vez?',
          subtitle: 'Veja qual corda é qual',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GuideDetailScreen(
                topic: guideTopics.firstWhere((t) => t.id == 'afinar'),
                showTunerButton: false,
              ),
            ),
          ),
        ),
      ],
    );

    return IosPage(
      title: 'Afinador',
      children: [
        tuningRow,
        const SizedBox(height: 16),
        gaugeCard,
        const SizedBox(height: 16),
        strings,
        options,
      ],
    );
  }
}

class _StringCell extends StatelessWidget {
  final String label;
  final String number;
  final String semanticsLabel;
  final bool active;
  final VoidCallback onTap;

  const _StringCell({
    required this.label,
    required this.number,
    required this.semanticsLabel,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: active,
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: ClickCursor(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            children: [
              AnimatedContainer(
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
                    color: active
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(number, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
