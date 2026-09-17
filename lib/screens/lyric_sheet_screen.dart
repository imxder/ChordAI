import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/lyric_sheet.dart';
import '../widgets/guitar_neck.dart';

class LyricSheetScreen extends StatelessWidget {
  final LyricSheet sheet;

  const LyricSheetScreen({super.key, required this.sheet});

  @override
  Widget build(BuildContext context) {
    final chordColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(sheet.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (sheet.key != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Tom: ${sheet.key}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          for (final section in sheet.sections) ...[
            if (section.title != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  '[${section.title}]',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: chordColor,
                      ),
                ),
              ),
            for (final line in section.lines)
              _buildLine(context, line, chordColor),
          ],
        ],
      ),
    );
  }

  Widget _buildLine(BuildContext context, LyricLine line, Color chordColor) {
    final hasChord = line.chordLine != null && line.chordLine!.trim().isNotEmpty;
    final hasLyric = line.lyricText.trim().isNotEmpty;

    if (!hasChord && !hasLyric) {
      return const SizedBox(height: 12);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasChord) _buildChordLine(context, line.chordLine!, chordColor),
        if (hasLyric)
          Text(
            line.lyricText,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildChordLine(BuildContext context, String chordLine, Color chordColor) {
    final spans = <InlineSpan>[];
    final tokenPattern = RegExp(r'\S+');
    var lastEnd = 0;

    for (final match in tokenPattern.allMatches(chordLine)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: chordLine.substring(lastEnd, match.start)));
      }
      final token = match.group(0)!;
      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(
            color: chordColor,
            decoration: TextDecoration.underline,
            decorationColor: chordColor.withValues(alpha: 0.4),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showChordDialog(context, token),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < chordLine.length) {
      spans.add(TextSpan(text: chordLine.substring(lastEnd)));
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        children: spans,
      ),
    );
  }

  void _showChordDialog(BuildContext context, String chord) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(chord),
        content: SizedBox(
          width: 200,
          height: 240,
          child: GuitarNeck(chord: chord),
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
}
