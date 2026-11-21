import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/lyric_practice.dart';
import '../models/lyric_sheet.dart';
import '../models/user_song.dart';
import '../services/user_song_store.dart';
import '../state/app_state.dart';
import '../widgets/cifra_line.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import '../widgets/practice_options_sheet.dart';
import 'lyric_player_screen.dart';
import 'song_editor_screen.dart';
import '../theme/ph.dart';

String sheetMeta(LyricSheet sheet) {
  return [
    if (sheet.key != null) 'Tom ${sheet.key}',
    if (sheet.tempo != null) '${sheet.tempo} BPM',
    if (sheet.capo != null) 'Capo na ${sheet.capo}ª casa',
  ].join(' · ');
}

class LyricSheetScreen extends StatefulWidget {
  final LyricSheet sheet;
  final String serverUrl;
  final InputDevice? inputDevice;
  final UserSong? userSong;
  final UserSongStore? store;

  const LyricSheetScreen({
    super.key,
    required this.sheet,
    required this.serverUrl,
    this.inputDevice,
    this.userSong,
    this.store,
  });

  @override
  State<LyricSheetScreen> createState() => _LyricSheetScreenState();
}

class _LyricSheetScreenState extends State<LyricSheetScreen>
    with SingleTickerProviderStateMixin {
  static const _speeds = [12.0, 18.0, 26.0, 36.0, 50.0];

  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  int _speed = 2;
  bool _autoScroll = false;
  bool _dragging = false;

  LyricSheet get sheet => widget.sheet;
  late final LyricPracticeMap _practiceMap = buildLyricPracticeMap(sheet);

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (_dragging || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent) {
      _setAutoScroll(false);
      return;
    }
    final step = _speeds[_speed] * appState.lyricFontScale * seconds;
    _scroll.jumpTo(min(position.maxScrollExtent, position.pixels + step));
  }

  void _setAutoScroll(bool on) {
    if (on == _autoScroll) return;
    setState(() => _autoScroll = on);
    if (on) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _changeSpeed(int delta) {
    setState(() => _speed = (_speed + delta).clamp(0, _speeds.length - 1));
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dragging = true;
    } else if (notification is ScrollEndNotification) {
      _dragging = false;
    }
    return false;
  }

  void _openPlayer() {
    _setAutoScroll(false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LyricPlayerScreen(
          serverUrl: widget.serverUrl,
          inputDevice: widget.inputDevice,
          sheet: sheet,
        ),
      ),
    );
  }

  Future<void> _edit() async {
    _setAutoScroll(false);
    final result = await Navigator.of(context).push<SongEditorResult>(
      MaterialPageRoute(
        builder: (_) =>
            SongEditorScreen(song: widget.userSong, store: widget.store),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _buildBottomBar() {
    if (_autoScroll) {
      return Row(
        children: [
          IconButton(
            tooltip: 'Rolar mais devagar',
            onPressed: _speed == 0 ? null : () => _changeSpeed(-1),
            icon: const Icon(Ph.minus),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Velocidade ${_speed + 1}'),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Rolar mais rápido',
            onPressed: _speed == _speeds.length - 1
                ? null
                : () => _changeSpeed(1),
            icon: const Icon(Ph.plus),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _setAutoScroll(false),
              icon: const Icon(Ph.stopFill, size: 20),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Parar'),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => _setAutoScroll(true),
            icon: const Icon(Ph.arrowDown, size: 20),
            label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Rolar')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: _openPlayer,
            icon: const Icon(Ph.playFill, size: 20),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Tocar junto'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = sheetMeta(sheet);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: IosPage(
          title: sheet.title,
          controller: _scroll,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.userSong != null)
                CupertinoButton(
                  key: const ValueKey('editar música'),
                  padding: EdgeInsets.zero,
                  onPressed: _edit,
                  child: const Icon(
                    Ph.pencilSimple,
                    semanticLabel: 'Editar música',
                  ),
                ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => showPracticeOptionsSheet(context),
                child: const Icon(
                  Ph.textAa,
                  semanticLabel: 'Leitura das cifras',
                ),
              ),
            ],
          ),
          bottomBar: BottomActionBar(child: _buildBottomBar()),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(sheet.title, style: textTheme.headlineMedium),
                  ),
                  if (sheet.artist != null)
                    Text(
                      sheet.artist!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(meta, style: textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            for (final (si, section) in sheet.sections.indexed) ...[
              if (section.title != null) SheetSectionLabel(section.title!),
              for (final (li, line) in section.lines.indexed)
                CifraLine(
                  line: line,
                  fontScale: appState.lyricFontScale,
                  tokenBeats: _practiceMap.beatsFor(si, li),
                  onChordTap: (chord) => _showChordDialog(context, chord),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChordDialog(BuildContext context, String chord) {
    showGlassSheet(
      context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: GlassEnter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChordName(chord, size: 36),
                Text(
                  chordFullName(chord),
                  style: Theme.of(sheetContext).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(height: 220, child: GuitarNeck(chord: chord)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SheetSectionLabel extends StatelessWidget {
  final String title;

  const SheetSectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
