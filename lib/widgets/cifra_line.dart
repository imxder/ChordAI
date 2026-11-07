import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/lyric_sheet.dart';
import '../theme/app_theme.dart';

class CifraLine extends StatelessWidget {
  final LyricLine line;
  final double fontScale;
  final int? activeToken;
  final bool highlighted;
  final ValueChanged<String>? onChordTap;

  const CifraLine({
    super.key,
    required this.line,
    this.fontScale = 1.0,
    this.activeToken,
    this.highlighted = false,
    this.onChordTap,
  });

  static const _baseSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasChord =
        line.chordLine != null && line.chordLine!.trim().isNotEmpty;
    final hasLyric = line.lyricText.trim().isNotEmpty;
    if (!hasChord && !hasLyric) return const SizedBox(height: 14);

    final fontSize = _baseSize * fontScale;

    // Quebrar a linha desalinharia o acorde da sílaba, então ela rola na horizontal.
    return Container(
      width: double.infinity,
      color: highlighted ? colorScheme.primaryContainer : null,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasChord) _chordLine(context, fontSize),
            if (hasLyric)
              Text(
                line.lyricText,
                softWrap: false,
                style: TextStyle(
                  fontFamily: fontChord,
                  fontSize: fontSize,
                  height: 1.4,
                  fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chordLine(BuildContext context, double fontSize) {
    final colorScheme = Theme.of(context).colorScheme;
    final chordLine = line.chordLine!;
    final spans = <InlineSpan>[];
    var lastEnd = 0;
    var tokenIndex = 0;

    for (final match in RegExp(r'\S+').allMatches(chordLine)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: chordLine.substring(lastEnd, match.start)));
      }
      final token = match.group(0)!;
      final onTap = onChordTap;
      if (tokenIndex == activeToken) {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: colorScheme.onPrimary,
              background: Paint()..color = colorScheme.primary,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: colorScheme.primary,
              decoration: onTap == null ? null : TextDecoration.underline,
              decorationColor: colorScheme.primary.withValues(alpha: 0.5),
            ),
            recognizer: onTap == null
                ? null
                : (TapGestureRecognizer()..onTap = () => onTap(token)),
          ),
        );
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
          fontFamily: fontChord,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          height: 1.4,
        ),
        children: spans,
      ),
      softWrap: false,
    );
  }
}
