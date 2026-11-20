import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../theme/platform_style.dart';
import '../widgets/desktop_shell.dart';
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
    if (isDesktop) {
      return _DesktopChords(serverUrl: serverUrl, inputDevice: inputDevice);
    }
    return _ChordGrid(
      onOpen: (chord) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChordDetailScreen(
            serverUrl: serverUrl,
            inputDevice: inputDevice,
            chord: chord,
          ),
        ),
      ),
    );
  }
}

/// No computador: a grade de acordes à esquerda e o detalhe do acorde
/// escolhido à direita. Clicar num acorde troca o detalhe sem abrir outra
/// tela. "Tocar e testar" abre por cima, do lado da barra lateral.
class _DesktopChords extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const _DesktopChords({required this.serverUrl, this.inputDevice});

  @override
  State<_DesktopChords> createState() => _DesktopChordsState();
}

class _DesktopChordsState extends State<_DesktopChords> {
  String? _chord;

  @override
  Widget build(BuildContext context) {
    final chord = _chord ?? appState.chordsInModel.first;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return DesktopSplit(
      leftWidth: wide ? 380 : 330,
      left: _ChordGrid(
        selected: chord,
        onOpen: (chord) => setState(() => _chord = chord),
      ),
      right: ChordDetailScreen(
        key: ValueKey(chord),
        serverUrl: widget.serverUrl,
        inputDevice: widget.inputDevice,
        chord: chord,
      ),
    );
  }
}

class _ChordGrid extends StatelessWidget {
  final void Function(String chord) onOpen;

  /// Acorde aberto do lado (só no computador), com borda pra destacar.
  final String? selected;

  const _ChordGrid({required this.onOpen, this.selected});

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
          for (final chord in appState.chordsInModel)
            _ChordCell(
              chord: chord,
              selected: chord == selected,
              onTap: () => onOpen(chord),
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
                '${appState.chordsInModel.length} aprendidos.',
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
  final bool selected;
  final VoidCallback onTap;

  const _ChordCell({
    required this.chord,
    required this.onTap,
    this.selected = false,
  });

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
            side: selected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
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
