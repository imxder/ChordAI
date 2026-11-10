import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/chord_prediction.dart';
import '../models/lyric_practice.dart';
import '../models/lyric_sheet.dart';
import '../models/score.dart';
import '../services/chord_recognizer.dart';
import '../services/chord_recognizer_factory.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cifra_line.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/metronome.dart';
import '../widgets/page_parts.dart';
import '../widgets/practice_options_sheet.dart';
import '../widgets/recognition_mode_badge.dart';
import 'lyric_sheet_screen.dart';
import '../theme/ph.dart';

class LyricPlayerScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;
  final LyricSheet sheet;

  const LyricPlayerScreen({
    super.key,
    required this.serverUrl,
    required this.sheet,
    this.inputDevice,
  });

  @override
  State<LyricPlayerScreen> createState() => _LyricPlayerScreenState();
}

class _LyricPlayerScreenState extends State<LyricPlayerScreen> {
  static const _minBpm = 40;
  static const _maxBpm = 160;

  late final ChordRecognizer _service =
      createChordRecognizer(appState.chordRecognitionMode);
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};

  late final LyricPracticeMap _practiceMap;
  late int _bpm;
  int _beatsInStep = 0;
  int _strumBeatIndex = 0;
  String? _finishedMessage;

  String? _lastRecognizedChord;
  bool? _lastMatched;

  final Map<String, int> _chordAttempts = {};
  final Map<String, int> _chordCorrect = {};

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
    _beatsInStep = 0;
    _strumBeatIndex = 0;
    _lastRecognizedChord = null;
    _lastMatched = null;
    _finishedMessage = null;
    _chordAttempts.clear();
    _chordCorrect.clear();

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: _onPrediction,
      onError: (_) => _showSnackBar(
        chordRecognitionErrorMessage(appState.chordRecognitionMode),
      ),
    );
  }

  Future<void> _stop() async {
    await _service.stop();
    appState.stopSession();
  }

  /// Verdadeiro quando o próximo acorde é diferente do atual, ou seja,
  /// quando dá pra saber que o usuário avançou só de ouvir a troca.
  bool _hasDetectableTransition(ChordStep step) {
    final next = _nextChord;
    return next != null && next.toLowerCase() != step.chord.toLowerCase();
  }

  void _onBeat() {
    if (appState.sessionStatus != SessionStatus.running) return;

    final pattern = widget.sheet.strummingPattern;
    if (pattern != null && pattern.isNotEmpty) {
      setState(() => _strumBeatIndex = (_strumBeatIndex + 1) % pattern.length);
    }

    final step = appState.currentStep;
    if (step == null) return;

    // Quando dá pra ouvir a troca de acorde, é ela que decide quando avançar
    // (ver _onPrediction) — o metrônomo só força a passagem quando não tem
    // como detectar a troca (último acorde da música, ou dois acordes iguais
    // em sequência).
    if (_hasDetectableTransition(step)) {
      _beatsInStep = 0;
      return;
    }

    _beatsInStep++;
    if (_beatsInStep < step.beats) return;
    _beatsInStep = 0;
    _advanceStep(matched: true);
  }

  void _onPrediction(ChordPrediction prediction) {
    appState.updatePrediction(prediction);
    if (appState.sessionStatus != SessionStatus.running) return;

    final step = appState.currentStep;
    final recognized = prediction.chord;
    if (step == null || recognized == null) return;

    final isCurrent = recognized.toLowerCase() == step.chord.toLowerCase();
    final isNext =
        _hasDetectableTransition(step) &&
        recognized.toLowerCase() == _nextChord!.toLowerCase();

    setState(() {
      _lastRecognizedChord = recognized;
      _lastMatched = isCurrent || isNext;
    });

    if (isNext) {
      _advanceStep(matched: true);
    } else if (!isCurrent) {
      _chordAttempts[step.chord] = (_chordAttempts[step.chord] ?? 0) + 1;
    }
  }

  void _advanceStep({required bool matched}) {
    final step = appState.currentStep;
    if (step != null) {
      _chordAttempts[step.chord] = (_chordAttempts[step.chord] ?? 0) + 1;
      if (matched) {
        _chordCorrect[step.chord] = (_chordCorrect[step.chord] ?? 0) + 1;
      }
    }

    appState.advanceStep(matched: matched);

    if (appState.sessionStatus == SessionStatus.idle) {
      _service.stop();
      final total = appState.sessionHits + appState.sessionMisses;
      setState(
        () => _finishedMessage =
            'Música concluída: ${appState.sessionHits} de $total acordes certos',
      );
      _showSummaryDialog();
    } else {
      setState(() {
        _lastRecognizedChord = null;
        _lastMatched = null;
      });
    }
  }

  void _showSummaryDialog() {
    double rate(String chord) =>
        (_chordCorrect[chord] ?? 0) / _chordAttempts[chord]!;
    final chords = _chordAttempts.keys.toList()
      ..sort((a, b) => rate(a).compareTo(rate(b)));
    final weakest = chords.isNotEmpty && rate(chords.first) < 1
        ? chords.first
        : null;

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
                            '${_chordCorrect[chord] ?? 0}/${_chordAttempts[chord]}',
                            style: const TextStyle(fontFamily: fontChord),
                          ),
                        ],
                      ),
                    ),
                  if (weakest != null) ...[
                    const SizedBox(height: 12),
                    Text('Vale treinar mais o $weakest.'),
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
    final score = _practiceMap.score;
    final nextIndex = appState.currentStepIndex + 1;
    if (nextIndex >= score.steps.length) return null;
    return score.steps[nextIndex].chord;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
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
          Offstage(
            child: Metronome(running: running, bpm: _bpm, onBeat: _onBeat),
          ),
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

    final StatusLine status;
    if (!running) {
      status = StatusLine(
        text:
            _finishedMessage ??
            (steps.isEmpty ? 'Esta cifra não tem acordes' : 'Primeiro acorde'),
      );
    } else if (_lastMatched == null) {
      status = const StatusLine(text: 'Toque este acorde');
    } else if (_lastMatched!) {
      status = StatusLine(icon: Ph.check, text: 'Certo', color: tokens.correct);
    } else {
      status = StatusLine(
        icon: Ph.x,
        text: _lastRecognizedChord == null
            ? 'Não ouvi nada'
            : 'Você tocou $_lastRecognizedChord',
        color: colorScheme.error,
      );
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
                          matchState: _lastMatched == null || !running
                              ? ChordMatchState.neutral
                              : (_lastMatched!
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
                      onPressed: running || _bpm <= _minBpm
                          ? null
                          : () => setState(
                              () => _bpm = (_bpm - 5).clamp(_minBpm, _maxBpm),
                            ),
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
                      onPressed: running || _bpm >= _maxBpm
                          ? null
                          : () => setState(
                              () => _bpm = (_bpm + 5).clamp(_minBpm, _maxBpm),
                            ),
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
