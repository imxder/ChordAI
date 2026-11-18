import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/chord_prediction.dart';
import '../models/chord_recognition_mode.dart';
import '../models/lyric_practice.dart';
import '../models/lyric_sheet.dart';
import '../services/chord_recognizer.dart';
import '../services/chord_recognizer_factory.dart';
import '../services/play_along_engine.dart';
import '../services/tocar_junto_log.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cifra_line.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import '../widgets/practice_options_sheet.dart';
import '../widgets/recognition_mode_badge.dart';
import 'lyric_sheet_screen.dart';
import '../theme/ph.dart';

class LyricPlayerScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;
  final LyricSheet sheet;
  final ChordRecognizer? recognizer;
  final Duration Function()? elapsed;

  const LyricPlayerScreen({
    super.key,
    required this.serverUrl,
    required this.sheet,
    this.inputDevice,
    this.recognizer,
    this.elapsed,
  });

  @override
  State<LyricPlayerScreen> createState() => _LyricPlayerScreenState();
}

class _LyricPlayerScreenState extends State<LyricPlayerScreen> {
  static const _minBpm = 40;
  static const _maxBpm = 160;
  static const _tick = Duration(milliseconds: 30);

  late final ChordRecognizer _service =
      widget.recognizer ??
      createChordRecognizer(appState.chordRecognitionMode, rawReadings: true);
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  final _stopwatch = Stopwatch();

  late final LyricPracticeMap _practiceMap;
  late int _bpm;
  int _strumBeatIndex = 0;
  String? _finishedMessage;
  PlayAlongEngine? _engine;
  Timer? _ticker;
  final Set<int> _reported = {};

  @override
  void initState() {
    super.initState();
    _practiceMap = buildLyricPracticeMap(widget.sheet);
    _bpm = widget.sheet.tempo?.clamp(_minBpm, _maxBpm) ?? 80;
    if (widget.inputDevice != null) {
      _service.selectDevice(widget.inputDevice);
    }
    appState.addListener(_onAppStateChanged);
  }

  int _lineKeyId(int sectionIndex, int lineIndex) =>
      sectionIndex * 10000 + lineIndex;

  GlobalKey _keyFor(int sectionIndex, int lineIndex) {
    return _lineKeys.putIfAbsent(
      _lineKeyId(sectionIndex, lineIndex),
      () => GlobalKey(),
    );
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
  }

  void _scrollToCurrentLine() {
    if (!mounted || !appState.autoScrollInPlayer) return;
    final index = appState.currentStepIndex;
    if (index < 0 || index >= _practiceMap.locations.length) return;
    final loc = _practiceMap.locations[index];
    final ctx =
        _lineKeys[_lineKeyId(loc.sectionIndex, loc.lineIndex)]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: motion(context, const Duration(milliseconds: 300)),
        alignment: 0.35,
      );
    }
  }

  Future<void> _start() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('O app precisa de acesso ao microfone');
      return;
    }

    appState.startSession(_practiceMap.score);
    TocarJuntoLog.evento(
      'comecou ${widget.sheet.title} bpm=$_bpm passos=${_practiceMap.score.steps.length} modo=${appState.chordRecognitionMode.name} modelo=${appState.onDeviceModel.name} esperar=${appState.playAlongWaitsForMe}',
    );
    _strumBeatIndex = 0;
    _finishedMessage = null;
    _reported.clear();
    _stopwatch
      ..reset()
      ..start();
    final engine = PlayAlongEngine(
      steps: _practiceMap.score.steps,
      knownChords: appState.chordsInModel.toSet(),
      bpm: _bpm,
      elapsed: widget.elapsed ?? () => _stopwatch.elapsed,
      mode: appState.playAlongWaitsForMe
          ? PlayAlongMode.waitForMe
          : PlayAlongMode.followTempo,
      readingsToHitLongChord:
          appState.chordRecognitionMode == ChordRecognitionMode.server ? 1 : 2,
    )..start();
    _engine = engine;
    _ticker?.cancel();
    _ticker = Timer.periodic(_tick, (_) => _onTick());

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: _onPrediction,
      onError: (_) => _showSnackBar(
        chordRecognitionErrorMessage(appState.chordRecognitionMode),
      ),
    );
  }

  Future<void> _stop() async {
    TocarJuntoLog.evento('parou no passo ${appState.currentStepIndex}');
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    await _service.stop();
    appState.stopSession();
    if (mounted) setState(() {});
  }

  void _onTick() {
    final engine = _engine;
    if (engine == null || appState.sessionStatus != SessionStatus.running) {
      return;
    }
    final beat = engine.update();
    if (beat) {
      TocarJuntoLog.evento('batida');
      SystemSound.play(SystemSoundType.click);
      final pattern = widget.sheet.strummingPattern;
      if (!engine.countingIn && pattern != null && pattern.isNotEmpty) {
        _strumBeatIndex = (_strumBeatIndex + 1) % pattern.length;
      }
    }
    for (var i = 0; i < engine.results.length; i++) {
      final result = engine.results[i];
      if (_reported.contains(i)) continue;
      if (result == StepResult.hit || result == StepResult.miss) {
        _reported.add(i);
        appState.recordChordResult(hit: result == StepResult.hit);
      } else if (result == StepResult.notCounted && i < engine.index) {
        _reported.add(i);
      }
    }
    if (engine.index != appState.currentStepIndex) {
      TocarJuntoLog.evento('cifra no passo ${engine.index}');
      appState.setSessionStep(engine.index);
    }
    if (engine.finished) {
      _finish();
    } else if (beat) {
      setState(() {});
    }
  }

  void _onPrediction(ChordPrediction prediction) {
    TocarJuntoLog.evento(
      'tela_recebeu ${prediction.status} ${prediction.chord ?? '-'}',
    );
    appState.updatePrediction(prediction);
    if (appState.sessionStatus != SessionStatus.running) return;
    _engine?.reading(prediction.status == 'ok' ? prediction.chord : null);
  }

  void _finish() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    _service.stop();
    final engine = _engine!;
    final total = engine.hits + engine.misses;
    appState.stopSession();
    setState(
      () => _finishedMessage =
          'Música concluída: ${engine.hits} de $total acordes certos',
    );
    _showSummaryDialog();
  }

  void _changeBpm(int delta) {
    setState(() => _bpm = (_bpm + delta).clamp(_minBpm, _maxBpm));
    _engine?.setBpm(_bpm);
  }

  void _showSummaryDialog() {
    final engine = _engine!;
    final perChord = engine.perChord;
    double rate(String chord) {
      final (hit, total) = perChord[chord]!;
      return total == 0 ? 0 : hit / total;
    }

    final chords = perChord.keys.toList()
      ..sort((a, b) => rate(a).compareTo(rate(b)));
    final weakest = chords.isNotEmpty && rate(chords.first) < 1
        ? chords.first
        : null;
    final notCounted = engine.notCountedChords;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final tokens = dialogContext.tokens;
        return AlertDialog(
          title: const Text('Resumo da música'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final chord in chords)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: ChordName(chord, size: 16),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: rate(chord),
                              minHeight: 6,
                              color: rate(chord) == 1
                                  ? tokens.correct
                                  : tokens.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${perChord[chord]!.$1} de ${perChord[chord]!.$2}',
                            style: const TextStyle(fontFamily: fontChord),
                          ),
                        ],
                      ),
                    ),
                  if (notCounted.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Não contaram: ${notCounted.join(', ')} (o modelo não conhece)',
                    ),
                  ],
                  if (weakest != null) ...[
                    const SizedBox(height: 12),
                    Text('Vale treinar mais o $weakest.'),
                  ],
                  if (_finishedMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_finishedMessage!),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  String? get _nextChord {
    final steps = _practiceMap.score.steps;
    final nextIndex = appState.currentStepIndex + 1;
    if (nextIndex >= steps.length) return null;
    return steps[nextIndex].chord;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    appState.removeListener(_onAppStateChanged);
    // Sem isso a sessão continuava "rodando" depois de sair da tela.
    if (appState.sessionStatus != SessionStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => appState.stopSession(),
      );
    }
    _service.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final running = appState.sessionStatus == SessionStatus.running;
    final activeIndex = appState.currentStepIndex;
    final activeLoc =
        (running &&
            activeIndex >= 0 &&
            activeIndex < _practiceMap.locations.length)
        ? _practiceMap.locations[activeIndex]
        : null;
    final pattern = widget.sheet.strummingPattern;
    final meta = sheetMeta(widget.sheet);
    final padding = pagePadding(context);

    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: Text(widget.sheet.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor
            .withValues(alpha: 0.86),
        border: null,
        transitionBetweenRoutes: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RecognitionModeBadge(),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => showPracticeOptionsSheet(context),
              child: const Icon(Ph.textAa, semanticLabel: 'Leitura das cifras'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (pattern != null && pattern.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.tokens.rule)),
              ),
              child: Row(
                children: [
                  Text('Batida', style: textTheme.titleSmall),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label:
                          'Batida: ${pattern.map((s) => s.toUpperCase() == 'D' ? 'baixo' : 'cima').join(', ')}',
                      excludeSemantics: true,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i < pattern.length; i++)
                            _StrumSymbol(
                              down: pattern[i].toUpperCase() == 'D',
                              active: running && i == _strumBeatIndex,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 24),
              children: [
                if (widget.sheet.artist != null || meta.isNotEmpty)
                  Text(
                    [
                      if (widget.sheet.artist != null) widget.sheet.artist!,
                      if (meta.isNotEmpty) meta,
                    ].join(' · '),
                    style: textTheme.bodySmall,
                  ),
                for (var si = 0; si < widget.sheet.sections.length; si++) ...[
                  if (widget.sheet.sections[si].title != null)
                    SheetSectionLabel(widget.sheet.sections[si].title!),
                  for (
                    var li = 0;
                    li < widget.sheet.sections[si].lines.length;
                    li++
                  )
                    KeyedSubtree(
                      key: _keyFor(si, li),
                      child: CifraLine(
                        line: widget.sheet.sections[si].lines[li],
                        fontScale: appState.lyricFontScale,
                        highlighted:
                            activeLoc != null &&
                            activeLoc.sectionIndex == si &&
                            activeLoc.lineIndex == li,
                        activeToken:
                            (activeLoc != null &&
                                activeLoc.sectionIndex == si &&
                                activeLoc.lineIndex == li)
                            ? activeLoc.tokenIndex
                            : null,
                      ),
                    ),
                ],
              ],
            ),
          ),
          _buildControls(context, running),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, bool running) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final steps = _practiceMap.score.steps;
    final chord =
        appState.currentStep?.chord ??
        (steps.isNotEmpty ? steps.first.chord : null);
    final padding = pagePadding(context);

    final engine = _engine;
    final judged = running ? engine?.lastJudged : null;
    final StatusLine status;
    bool? lastHit;
    if (!running) {
      status = StatusLine(
        text:
            _finishedMessage ??
            (steps.isEmpty ? 'Esta cifra não tem acordes' : 'Primeiro acorde'),
      );
    } else if (engine != null && engine.countingIn) {
      status = StatusLine(text: 'Prepare-se… ${engine.countInLeft}');
    } else if (engine == null || judged == null) {
      status = const StatusLine(text: 'Toque este acorde');
    } else {
      final judgedChord = steps[judged].chord;
      switch (engine.results[judged]) {
        case StepResult.hit:
          lastHit = true;
          status = StatusLine(
            icon: Ph.check,
            text: 'Certo: $judgedChord',
            color: tokens.correct,
          );
        case StepResult.miss:
          lastHit = false;
          final wrong = engine.wrongChordHeard(judged);
          status = StatusLine(
            icon: Ph.x,
            text: wrong == null
                ? 'Não ouvi o $judgedChord'
                : 'Você tocou $wrong',
            color: colorScheme.error,
          );
        case StepResult.notCounted:
        case StepResult.pending:
          status = StatusLine(
            text: '$judgedChord não conta: o modelo não conhece',
          );
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left - 6, 0, padding.right - 6, 0),
      child: FloatingPanel(
        radius: 28,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (appState.showGuitarNeckInPlayer) ...[
                      SizedBox(
                        width: 64,
                        child: GuitarNeck(
                          chord: chord,
                          matchState: lastHit == null
                              ? ChordMatchState.neutral
                              : (lastHit
                                    ? ChordMatchState.correct
                                    : ChordMatchState.incorrect),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          status,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              ChordName(chord ?? '–', size: 32),
                              const SizedBox(width: 8),
                              if (chord != null)
                                Flexible(
                                  child: Text(
                                    chordFullName(chord),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                          if (running && _nextChord != null)
                            Text(
                              'Depois: $_nextChord',
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: steps.isEmpty
                      ? 0
                      : appState.currentStepIndex / steps.length,
                  semanticsLabel: 'Progresso na música',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Diminuir andamento',
                      icon: const Icon(Ph.minus),
                      onPressed: _bpm <= _minBpm ? null : () => _changeBpm(-5),
                    ),
                    Semantics(
                      label: '$_bpm batidas por minuto',
                      excludeSemantics: true,
                      child: SizedBox(
                        width: 56,
                        child: Column(
                          children: [
                            Text(
                              '$_bpm',
                              style: const TextStyle(
                                fontFamily: fontChord,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            Text('BPM', style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aumentar andamento',
                      icon: const Icon(Ph.plus),
                      onPressed: _bpm >= _maxBpm ? null : () => _changeBpm(5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: steps.isEmpty
                            ? null
                            : (running ? _stop : _start),
                        icon: Icon(
                          running ? Ph.stopFill : Ph.playFill,
                          size: 20,
                        ),
                        label: Text(running ? 'Parar' : 'Começar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: running
                              ? colorScheme.onSurface
                              : null,
                          foregroundColor: running ? colorScheme.surface : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StrumSymbol extends StatelessWidget {
  final bool down;
  final bool active;

  const _StrumSymbol({required this.down, required this.active});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : null,
        border: Border.all(
          color: active ? colorScheme.primary : context.tokens.rule,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        down ? Ph.arrowDown : Ph.arrowUp,
        size: 16,
        color: active ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
    );
  }
}
