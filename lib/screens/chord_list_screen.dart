import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_difficulty.dart';
import '../models/chord_names.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import 'chord_detail_screen.dart';
import '../theme/ph.dart';

class ChordListScreen extends StatelessWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const ChordListScreen({super.key, required this.serverUrl, this.inputDevice});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final padding = pagePadding(context);
    final width = MediaQuery.sizeOf(context).width - padding.horizontal;
    final columns = width >= 520 ? 4 : 2;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final cells = [
          for (final chord in chordsByDifficulty)
            _ChordCell(
              chord: chord,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChordDetailScreen(
                    serverUrl: serverUrl,
                    inputDevice: inputDevice,
                    chord: chord,
                  ),
                ),
              ),
            ),
        ];
        return IosPage(
          title: 'Acordes',
          largeTitle: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Text(
                'Em ordem de dificuldade. ${appState.learnedChordCount} de '
                '${chordsByDifficulty.length} aprendidos.',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (var i = 0; i < cells.length; i += columns) ...[
              if (i > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: 12),
                      Expanded(
                        child: i + c < cells.length
                            ? cells[i + c]
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChordCell extends StatelessWidget {
  final String chord;
  final VoidCallback onTap;

  const _ChordCell({required this.chord, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final learned = appState.isChordLearned(chord);

    return Semantics(
      button: true,
      label: '$chord, ${chordFullName(chord)}${learned ? ", aprendido" : ""}',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: GuitarNeck(chord: chord),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: ChordName(chord, size: 22)),
                      if (learned)
                        Icon(
                          Ph.checkCircleFill,
                          size: 20,
                          color: context.tokens.correct,
                        ),
                    ],
                  ),
                  Text(
                    learned ? 'Aprendido' : chordFullName(chord),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: learned ? context.tokens.correct : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
