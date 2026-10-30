import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/lyric_practice.dart';
import '../models/lyric_sheet.dart';
import '../services/chord_recognition_service.dart';
import '../state/app_state.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/metronome.dart';
import '../widgets/practice_options_sheet.dart';

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
  final _service = ChordRecognitionService();
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};

  late final LyricPracticeMap _practiceMap;
  late int _bpm;
  int _beatsInStep = 0;
  int _strumBeatIndex = 0;
  String _statusMessage = 'Toque em Iniciar';

  String? _lastRecognizedChord;
  bool? _lastMatched;

  final Map<String, int> _chordAttempts = {};
  final Map<String, int> _chordCorrect = {};

  @override
  void initState() {
    super.initState();
    _practiceMap = buildLyricPracticeMap(widget.sheet);
    _bpm = widget.sheet.tempo?.clamp(40, 160) ?? 80;
    if (widget.inputDevice != null) {
      _service.selectDevice(widget.inputDevice);
    }
    appState.addListener(_onAppStateChanged);
  }

  int _lineKeyId(int sectionIndex, int lineIndex) => sectionIndex * 10000 + lineIndex;

  GlobalKey _keyFor(int sectionIndex, int lineIndex) {
    return _lineKeys.putIfAbsent(_lineKeyId(sectionIndex, lineIndex), () => GlobalKey());
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {});
    final unlocked = appState.consumePendingUnlocked();
    for (final achievement in unlocked) {
      _showSnackBar('Conquista desbloqueada: ${achievement.title}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
  }

  void _scrollToCurrentLine() {
    if (!appState.autoScrollInPlayer) return;
    final index = appState.currentStepIndex;
    if (index < 0 || index >= _practiceMap.locations.length) return;
    final loc = _practiceMap.locations[index];
    final ctx = _lineKeys[_lineKeyId(loc.sectionIndex, loc.lineIndex)]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.35,
      );
    }
  }

  Future<void> _start() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('Permissão de microfone negada');
      return;
    }

    appState.startSession(_practiceMap.score);
    appState.setLastSong(widget.sheet.title, extractChords(widget.sheet).length);
    _beatsInStep = 0;
    _strumBeatIndex = 0;
    _lastRecognizedChord = null;
    _lastMatched = null;
    _chordAttempts.clear();
    _chordCorrect.clear();

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: (p) => appState.updatePrediction(p),
      onError: (_) => _showSnackBar('Erro ao conectar com o servidor'),
    );

    setState(() => _statusMessage = 'Ouvindo...');
  }

  Future<void> _stop() async {
    await _service.stop();
    appState.stopSession();
    setState(() => _statusMessage = 'Parado');
  }

  void _onBeat() {
    if (appState.sessionStatus != SessionStatus.running) return;

    final pattern = widget.sheet.strummingPattern;
    if (pattern != null && pattern.isNotEmpty) {
      setState(() => _strumBeatIndex = (_strumBeatIndex + 1) % pattern.length);
    }

    final step = appState.currentStep;
    if (step == null) return;

    _beatsInStep++;
    if (_beatsInStep < step.beats) return;
    _beatsInStep = 0;

    final recognized = appState.lastPrediction?.chord;
    final matched =
        recognized != null && recognized.toLowerCase() == step.chord.toLowerCase();

    _chordAttempts[step.chord] = (_chordAttempts[step.chord] ?? 0) + 1;
    if (matched) {
      _chordCorrect[step.chord] = (_chordCorrect[step.chord] ?? 0) + 1;
    }

    setState(() {
      _lastRecognizedChord = recognized;
      _lastMatched = matched;
    });

    appState.advanceStep(matched: matched);

    if (appState.sessionStatus == SessionStatus.idle) {
      _service.stop();
      setState(() => _statusMessage =
          'Música concluída! ${appState.sessionHits}/${appState.sessionHits + appState.sessionMisses} acordes certos');
      _showSummaryDialog();
    }
  }

  void _showSummaryDialog() {
    final chords = _chordAttempts.keys.toList()
      ..sort((a, b) {
        final rateA = (_chordCorrect[a] ?? 0) / _chordAttempts[a]!;
        final rateB = (_chordCorrect[b] ?? 0) / _chordAttempts[b]!;
        return rateA.compareTo(rateB);
      });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resumo da música'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final chord in chords)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(chord, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_chordCorrect[chord] ?? 0) / _chordAttempts[chord]!,
                          color: (_chordCorrect[chord] ?? 0) == _chordAttempts[chord]
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${_chordCorrect[chord] ?? 0}/${_chordAttempts[chord]}'),
                    ],
                  ),
                ),
              if (chords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Pratique mais o acorde ${chords.first} — foi o que você mais errou.',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String? get _nextChord {
    final score = _practiceMap.score;
    final nextIndex = appState.currentStepIndex + 1;
    if (nextIndex >= score.steps.length) return null;
    return score.steps[nextIndex].chord;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    appState.removeListener(_onAppStateChanged);
    _service.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = appState.sessionStatus == SessionStatus.running;
    final chordColor = Theme.of(context).colorScheme.primary;
    final activeIndex = appState.currentStepIndex;
    final activeLoc = (running && activeIndex >= 0 && activeIndex < _practiceMap.locations.length)
        ? _practiceMap.locations[activeIndex]
        : null;

    final recognized = appState.lastPrediction?.chord;
    final expected = appState.currentStep?.chord;
    final matchState = (!running || expected == null)
        ? ChordMatchState.neutral
        : (recognized != null && recognized.toLowerCase() == expected.toLowerCase()
            ? ChordMatchState.correct
            : ChordMatchState.incorrect);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: widget.sheet.artist != null ? 64 : kToolbarHeight,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.sheet.title),
            if (widget.sheet.artist != null)
              Text(
                '${widget.sheet.artist} · $_bpm BPM',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (widget.sheet.capo != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('Capo ${widget.sheet.capo}'),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opções de prática',
            onPressed: () => showPracticeOptionsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: 0,
              height: 0,
              child: Opacity(
                opacity: 0,
                child: Metronome(running: running, bpm: _bpm, onBeat: _onBeat),
              ),
            ),
            if (widget.sheet.strummingPattern != null &&
                widget.sheet.strummingPattern!.isNotEmpty)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Batida', style: Theme.of(context).textTheme.titleSmall),
                        Row(
                          children: [
                            Icon(Icons.repeat, size: 14, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(width: 4),
                            Text(
                              'repete',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < widget.sheet.strummingPattern!.length; i++)
                          _buildStrumSymbol(
                            widget.sheet.strummingPattern![i],
                            running && i == _strumBeatIndex,
                            chordColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (running)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastMatched == null
                      ? Theme.of(context).colorScheme.surfaceContainerHigh
                      : (_lastMatched! ? Colors.green : Colors.red.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (appState.showGuitarNeckInPlayer) ...[
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: GuitarNeck(chord: expected, matchState: matchState),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expected ?? '—',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _lastMatched == null ? null : Colors.white,
                            ),
                          ),
                          Text(
                            _lastMatched == null
                                ? 'Toque este acorde agora'
                                : (_lastMatched!
                                    ? 'Certo!'
                                    : 'Você tocou ${_lastRecognizedChord ?? "nada"}'),
                            style: TextStyle(
                              color: _lastMatched == null ? null : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.sheet.key != null ||
                      widget.sheet.tempo != null ||
                      widget.sheet.capo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        [
                          if (widget.sheet.key != null) 'Tom: ${widget.sheet.key}',
                          if (widget.sheet.tempo != null)
                            'Tempo original: ${widget.sheet.tempo} BPM',
                          if (widget.sheet.capo != null)
                            'Capo na ${widget.sheet.capo}ª casa',
                        ].join('  •  '),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  for (var si = 0; si < widget.sheet.sections.length; si++) ...[
                    if (widget.sheet.sections[si].title != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          '[${widget.sheet.sections[si].title}]',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: chordColor,
                              ),
                        ),
                      ),
                    for (var li = 0; li < widget.sheet.sections[si].lines.length; li++)
                      Container(
                        key: _keyFor(si, li),
                        child: _buildLine(
                          context,
                          widget.sheet.sections[si].lines[li],
                          chordColor,
                          (activeLoc != null &&
                                  activeLoc.sectionIndex == si &&
                                  activeLoc.lineIndex == li)
                              ? activeLoc.tokenIndex
                              : null,
                          activeLoc != null &&
                              activeLoc.sectionIndex == si &&
                              activeLoc.lineIndex == li,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: appState.currentStep != null
                            ? GuitarNeck(chord: appState.currentStep!.chord)
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACORDE ATUAL',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                    letterSpacing: 1,
                                  ),
                            ),
                            Text(
                              appState.currentStep != null
                                  ? '${chordFullName(appState.currentStep!.chord)} (${appState.currentStep!.chord})'
                                  : '—',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_nextChord != null)
                              Text(
                                'Próximo: $_nextChord',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text('BPM', style: Theme.of(context).textTheme.bodySmall),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: running
                                    ? null
                                    : () => setState(() => _bpm = (_bpm - 5).clamp(40, 160)),
                              ),
                              Text('$_bpm', style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: running
                                    ? null
                                    : () => setState(() => _bpm = (_bpm + 5).clamp(40, 160)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _practiceMap.score.steps.isEmpty
                          ? 0
                          : appState.currentStepIndex / _practiceMap.score.steps.length,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_previous,
                          color: Theme.of(context).colorScheme.outlineVariant, size: 32),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: running ? _stop : _start,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: running ? Colors.red : chordColor,
                          ),
                          child: Icon(
                            running ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Icon(Icons.skip_next,
                          color: Theme.of(context).colorScheme.outlineVariant, size: 32),
                    ],
                  ),
                  if (appState.sessionStatus == SessionStatus.idle && _statusMessage != 'Toque em Iniciar') ...[
                    const SizedBox(height: 8),
                    Text(_statusMessage, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrumSymbol(String symbol, bool active, Color color) {
    final isDown = symbol.toUpperCase() == 'D';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : color.withValues(alpha: 0.12),
      ),
      child: Icon(
        isDown ? Icons.arrow_downward : Icons.arrow_upward,
        size: 16,
        color: active ? Colors.white : color,
      ),
    );
  }

  Widget _buildLine(
    BuildContext context,
    LyricLine line,
    Color chordColor,
    int? activeTokenIndex,
    bool isActiveLine,
  ) {
    final hasChord = line.chordLine != null && line.chordLine!.trim().isNotEmpty;
    final hasLyric = line.lyricText.trim().isNotEmpty;
    if (!hasChord && !hasLyric) return const SizedBox(height: 12);

    return Container(
      width: double.infinity,
      padding: isActiveLine ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : null,
      decoration: isActiveLine
          ? BoxDecoration(
              color: chordColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasChord) _buildChordLine(line.chordLine!, chordColor, activeTokenIndex),
          if (hasLyric)
            Text(
              line.lyricText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13 * appState.lyricFontScale,
                fontWeight: isActiveLine ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChordLine(String chordLine, Color chordColor, int? activeTokenIndex) {
    final spans = <InlineSpan>[];
    final tokenPattern = RegExp(r'\S+');
    var lastEnd = 0;
    var tokenIndex = 0;

    for (final match in tokenPattern.allMatches(chordLine)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: chordLine.substring(lastEnd, match.start)));
      }
      final token = match.group(0)!;
      final isActive = tokenIndex == activeTokenIndex;
      if (isActive) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: chordColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                token,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * appState.lyricFontScale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: token, style: TextStyle(color: chordColor)));
      }
      lastEnd = match.end;
      tokenIndex++;
    }
    if (lastEnd < chordLine.length) {
      spans.add(TextSpan(text: chordLine.substring(lastEnd)));
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 13 * appState.lyricFontScale,
        ),
        children: spans,
      ),
    );
  }
}
