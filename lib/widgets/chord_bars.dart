import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import 'guitar_neck.dart';

class BarChord {
  final String chord;
  final int beats;
  final int step;

  const BarChord(this.chord, this.beats, this.step);
}

class _Segment {
  final BarChord chord;
  final int firstBeat;
  final int beatInBar;
  final int length;

  const _Segment(this.chord, this.firstBeat, this.beatInBar, this.length);

  bool get continuation => firstBeat > 0;
}

List<List<_Segment>> _bars(List<BarChord> chords) {
  final bars = <List<_Segment>>[];
  var position = 0;
  for (final chord in chords) {
    var done = 0;
    while (done < chord.beats) {
      final bar = position ~/ 4;
      final inBar = position % 4;
      final length = (chord.beats - done).clamp(1, 4 - inBar);
      while (bars.length <= bar) {
        bars.add([]);
      }
      bars[bar].add(_Segment(chord, done, inBar, length));
      done += length;
      position += length;
    }
  }
  return bars;
}

class ChordBars extends StatelessWidget {
  static const minBarWidth = 150.0;

  final List<BarChord> chords;
  final int? activeStep;
  final int? activeBeat;
  final Map<int, bool> results;
  final double fontScale;
  final ValueChanged<String>? onChordTap;
  final GlobalKey? activeRowKey;

  const ChordBars({
    super.key,
    required this.chords,
    this.activeStep,
    this.activeBeat,
    this.results = const {},
    this.fontScale = 1.0,
    this.onChordTap,
    this.activeRowKey,
  });

  @override
  Widget build(BuildContext context) {
    final bars = _bars(chords);
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = (constraints.maxWidth / minBarWidth).floor().clamp(1, 4);
        final rows = <Widget>[];
        for (var start = 0; start < bars.length; start += perRow) {
          final rowBars = bars.skip(start).take(perRow).toList();
          final hasActive = rowBars.any(
            (bar) => bar.any((s) => s.chord.step == activeStep),
          );
          rows.add(
            Padding(
              key: hasActive ? activeRowKey : null,
              padding: const EdgeInsets.only(bottom: 6),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < perRow; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: i < rowBars.length
                            ? _Bar(
                                segments: rowBars[i],
                                activeStep: activeStep,
                                activeBeat: activeBeat,
                                results: results,
                                fontScale: fontScale,
                                onChordTap: onChordTap,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: rows),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final List<_Segment> segments;
  final int? activeStep;
  final int? activeBeat;
  final Map<int, bool> results;
  final double fontScale;
  final ValueChanged<String>? onChordTap;

  const _Bar({
    required this.segments,
    required this.activeStep,
    required this.activeBeat,
    required this.results,
    required this.fontScale,
    required this.onChordTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final used = segments.fold(0, (n, s) => n + s.length);
    final radius = BorderRadius.circular(GlassTokens.radiusMd);
    return Container(
      decoration: BoxDecoration(color: tokens.cell, borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, segment) in segments.indexed) ...[
            if (i > 0) VerticalDivider(width: 1, color: tokens.rule),
            Expanded(
              flex: segment.length,
              child: _SegmentCell(
                segment: segment,
                active: segment.chord.step == activeStep,
                activeBeat: segment.chord.step == activeStep
                    ? activeBeat
                    : null,
                result: results[segment.chord.step],
                fontScale: fontScale,
                onTap: onChordTap == null
                    ? null
                    : () => onChordTap!(segment.chord.chord),
              ),
            ),
          ],
          if (used < 4) Spacer(flex: 4 - used),
        ],
      ),
    );
  }
}

class _SegmentCell extends StatelessWidget {
  final _Segment segment;
  final bool active;
  final int? activeBeat;
  final bool? result;
  final double fontScale;
  final VoidCallback? onTap;

  const _SegmentCell({
    required this.segment,
    required this.active,
    required this.activeBeat,
    required this.result,
    required this.fontScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final Color nameColor;
    if (active) {
      nameColor = colorScheme.onPrimary;
    } else if (result == true) {
      nameColor = tokens.correct;
    } else if (result == false) {
      nameColor = colorScheme.error;
    } else {
      nameColor = colorScheme.primary;
    }
    final numberColor = active
        ? colorScheme.onPrimary.withValues(alpha: 0.75)
        : colorScheme.onSurfaceVariant;
    final chord = segment.chord;

    return Semantics(
      button: onTap != null,
      label: segment.continuation
          ? '${chord.chord} continua'
          : '${chord.chord}, ${chord.beats} tempos',
      excludeSemantics: true,
      child: Material(
        color: active ? colorScheme.primary : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    chord.chord,
                    style: TextStyle(
                      fontFamily: fontChord,
                      fontWeight: FontWeight.w600,
                      fontSize: 17 * fontScale,
                      height: 1.2,
                      color: segment.continuation && !active
                          ? nameColor.withValues(alpha: 0.45)
                          : nameColor,
                      decoration: result == false && !active
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var k = 0; k < segment.length; k++)
                      Expanded(
                        child: Center(
                          child: _BeatNumber(
                            number: segment.beatInBar + k + 1,
                            lit: activeBeat == segment.firstBeat + k,
                            color: numberColor,
                            litColor: colorScheme.onPrimary,
                            litText: colorScheme.primary,
                            style: textTheme.labelSmall,
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

class _BeatNumber extends StatelessWidget {
  final int number;
  final bool lit;
  final Color color;
  final Color litColor;
  final Color litText;
  final TextStyle? style;

  const _BeatNumber({
    required this.number,
    required this.lit,
    required this.color,
    required this.litColor,
    required this.litText,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: lit
          ? BoxDecoration(color: litColor, shape: BoxShape.circle)
          : null,
      child: Text(
        '$number',
        style: style?.copyWith(
          color: lit ? litText : color,
          fontWeight: lit ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class ChordShapesStrip extends StatelessWidget {
  final List<String> chords;
  final ValueChanged<String>? onTap;

  const ChordShapesStrip({super.key, required this.chords, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final chord in chords)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                button: onTap != null,
                label: 'Como fazer o $chord',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onTap == null ? null : () => onTap!(chord),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        SizedBox(width: 64, child: GuitarNeck(chord: chord)),
                        const SizedBox(height: 2),
                        Text(
                          chord,
                          style: textTheme.titleSmall?.copyWith(
                            fontFamily: fontChord,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
