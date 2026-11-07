import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/lyric_sheet.dart';
import '../state/app_state.dart';
import '../widgets/cifra_line.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import '../widgets/practice_options_sheet.dart';
import 'lyric_player_screen.dart';
import '../theme/ph.dart';

String sheetMeta(LyricSheet sheet) {
  return [
    if (sheet.key != null) 'Tom ${sheet.key}',
    if (sheet.tempo != null) '${sheet.tempo} BPM',
    if (sheet.capo != null) 'Capo na ${sheet.capo}ª casa',
  ].join(' · ');
}

class LyricSheetScreen extends StatelessWidget {
  final LyricSheet sheet;
  final String serverUrl;
  final InputDevice? inputDevice;

  const LyricSheetScreen({
    super.key,
    required this.sheet,
    required this.serverUrl,
    this.inputDevice,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = sheetMeta(sheet);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => IosPage(
        title: sheet.title,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showPracticeOptionsSheet(context),
          child: const Icon(Ph.textAa, semanticLabel: 'Leitura das cifras'),
        ),
        bottomBar: BottomActionBar(
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LyricPlayerScreen(
                    serverUrl: serverUrl,
                    inputDevice: inputDevice,
                    sheet: sheet,
                  ),
                ),
              );
            },
            icon: const Icon(Ph.playFill, size: 20),
            label: const Text('Tocar junto'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
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
          for (final section in sheet.sections) ...[
            if (section.title != null) SheetSectionLabel(section.title!),
            for (final line in section.lines)
              CifraLine(
                line: line,
                fontScale: appState.lyricFontScale,
                onChordTap: (chord) => _showChordDialog(context, chord),
              ),
          ],
        ],
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
