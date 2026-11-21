import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/lyric_sheet.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';

class CifraLine extends StatelessWidget {
  final LyricLine line;
  final double fontScale;
  final int? activeToken;
  final bool highlighted;
  final ValueChanged<String>? onChordTap;
  final Map<int, bool> tokenResults;
  final List<int> tokenBeats;

  const CifraLine({
    super.key,
    required this.line,
    this.fontScale = 1.0,
    this.activeToken,
    this.highlighted = false,
    this.onChordTap,
    this.tokenResults = const {},
    this.tokenBeats = const [],
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

    if (hasChord && !hasLyric) return _chordBlocks(context, fontSize);

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

  Widget _chordBlocks(BuildContext context, double fontSize) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final chords = RegExp(r'\S+')
        .allMatches(line.chordLine!)
        .map((m) => m.group(0)!)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (i, chord) in chords.indexed)
            _ChordBlock(
              chord: chord,
              beats: i < tokenBeats.length ? tokenBeats[i] : null,
              fontSize: fontSize,
              active: i == activeToken,
              result: tokenResults[i],
              onTap: onChordTap == null ? null : () => onChordTap!(chord),
              colorScheme: colorScheme,
              tokens: tokens,
            ),
        ],
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
      } else if (tokenResults.containsKey(tokenIndex)) {
        final hit = tokenResults[tokenIndex]!;
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: hit ? context.tokens.correct : colorScheme.error,
              decoration: hit ? null : TextDecoration.lineThrough,
              decorationColor: colorScheme.error,
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

class _ChordBlock extends StatelessWidget {
  final String chord;
  final int? beats;
  final double fontSize;
  final bool active;
  final bool? result;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;
  final AppTokens tokens;

  const _ChordBlock({
    required this.chord,
    required this.beats,
    required this.fontSize,
    required this.active,
    required this.result,
    required this.onTap,
    required this.colorScheme,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (active) {
      background = colorScheme.primary;
      foreground = colorScheme.onPrimary;
    } else if (result == true) {
      background = tokens.cell;
      foreground = tokens.correct;
    } else if (result == false) {
      background = tokens.cell;
      foreground = colorScheme.error;
    } else {
      background = tokens.cell;
      foreground = colorScheme.primary;
    }
    final count = beats ?? 0;
    return Semantics(
      button: onTap != null,
      label: beats == null ? chord : '$chord, $beats tempos',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chord,
                  style: TextStyle(
                    fontFamily: fontChord,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize * 1.15,
                    height: 1.3,
                    color: foreground,
                    decoration: result == false && !active
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: colorScheme.error,
                  ),
                ),
                if (count > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var b = 0; b < count; b++)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: foreground.withValues(alpha: 0.55),
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
