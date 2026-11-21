import 'dart:math';

import 'package:flutter/material.dart';

import '../models/chord_diagrams.dart';
import '../models/chord_for_model.dart';
import '../models/lyric_sheet.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../theme/ph.dart';
import '../theme/platform_style.dart';
import 'guitar_neck.dart';

double get _scale => isDesktop ? 1.4 : 1.0;

class SequenceChord {
  final String chord;
  final int beats;
  final int step;
  final List<StrumKind?> strum;

  const SequenceChord(
    this.chord,
    this.beats,
    this.step, {
    this.strum = const [],
  });
}

class ChordLine {
  final List<SequenceChord> chords;
  final int times;

  const ChordLine(this.chords, this.times);
}

String _key(SequenceChord c) =>
    '${c.chord}:${c.beats}:${c.strum.map((k) => k?.name).join()}';

bool _same(List<SequenceChord> chords, int a, int b, int length) {
  for (var k = 0; k < length; k++) {
    if (_key(chords[a + k]) != _key(chords[b + k])) return false;
  }
  return true;
}

/// Junta o que se repete seguido numa linha só, com quantas vezes repete.
/// Em cada ponto procura o padrão (de 1 a [maxPattern] acordes) que mais
/// cobre acordes repetindo; o que não repete vira linhas de até [maxLine].
List<ChordLine> groupRepeats(
  List<SequenceChord> chords, {
  int maxPattern = 8,
  int maxLine = 4,
}) {
  final out = <ChordLine>[];
  var pending = <SequenceChord>[];
  void flush() {
    for (var k = 0; k < pending.length; k += maxLine) {
      out.add(ChordLine(pending.skip(k).take(maxLine).toList(), 1));
    }
    pending = [];
  }

  var i = 0;
  while (i < chords.length) {
    var bestLength = 0;
    var bestTimes = 0;
    for (var length = 1; length <= maxPattern; length++) {
      if (i + 2 * length > chords.length) break;
      var times = 1;
      while (i + (times + 1) * length <= chords.length &&
          _same(chords, i, i + times * length, length)) {
        times++;
      }
      if (times >= 2 && length * times > bestLength * bestTimes) {
        bestLength = length;
        bestTimes = times;
      }
    }
    if (bestTimes >= 2) {
      flush();
      out.add(ChordLine(chords.sublist(i, i + bestLength), bestTimes));
      i += bestLength * bestTimes;
    } else {
      pending.add(chords[i]);
      i++;
    }
  }
  flush();
  return out;
}

class ChordSequence extends StatelessWidget {
  final List<List<SequenceChord>> lines;
  final bool collapseRepeats;
  final int? activeStep;
  final int? activeBeat;
  final int? activeEighth;
  final Map<int, bool> results;
  final double fontScale;
  final double arrowScale;
  final ValueChanged<String>? onChordTap;
  final GlobalKey? activeLineKey;

  const ChordSequence({
    super.key,
    required this.lines,
    this.collapseRepeats = false,
    this.activeStep,
    this.activeBeat,
    this.activeEighth,
    this.results = const {},
    this.fontScale = 1.0,
    this.arrowScale = 1.0,
    this.onChordTap,
    this.activeLineKey,
  });

  @override
  Widget build(BuildContext context) {
    final shown = collapseRepeats
        ? groupRepeats([for (final line in lines) ...line])
        : [for (final line in lines) ChordLine(line, 1)];
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in shown)
          Padding(
            key: line.chords.any((c) => c.step == activeStep)
                ? activeLineKey
                : null,
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final chord in line.chords)
                      _ChordItem(
                        chord: chord,
                        active: chord.step == activeStep,
                        activeBeat: chord.step == activeStep
                            ? activeBeat
                            : null,
                        activeEighth: chord.step == activeStep
                            ? activeEighth
                            : null,
                        result: results[chord.step],
                        fontScale: fontScale,
                        arrowScale: arrowScale,
                        onTap: onChordTap == null
                            ? null
                            : () => onChordTap!(chord.chord),
                      ),
                  ],
                ),
                if (line.times > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${line.times}×',
                      textScaler: TextScaler.linear(_scale),
                      semanticsLabel: 'repete ${line.times} vezes',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChordItem extends StatelessWidget {
  final SequenceChord chord;
  final bool active;
  final int? activeBeat;
  final int? activeEighth;
  final bool? result;
  final double fontScale;
  final double arrowScale;
  final VoidCallback? onTap;

  const _ChordItem({
    required this.chord,
    required this.active,
    required this.activeBeat,
    required this.activeEighth,
    required this.result,
    required this.fontScale,
    required this.arrowScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final k = _scale * fontScale;
    final slot = 14.0 * _scale * arrowScale;
    final shape = chordForModel(chord.chord, chordFingerings.keys.toSet());
    final Color nameColor = switch (result) {
      true => tokens.correct,
      false => colorScheme.error,
      null => colorScheme.primary,
    };
    final radius = BorderRadius.circular(GlassTokens.radiusMd);
    final width = chord.strum.isEmpty
        ? 60.0 * k
        : max(60.0 * k, chord.strum.length * slot);
    return Semantics(
      button: onTap != null,
      label: '${chord.chord}, ${chord.beats} tempos',
      excludeSemantics: true,
      child: Material(
        color: active ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shape != null)
                    SizedBox(
                      width: 50 * k,
                      child: GuitarNeck(chord: shape),
                    )
                  else
                    SizedBox(height: 50 * k),
                  const SizedBox(height: 4),
                  Text(
                    chord.chord,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: fontChord,
                      fontWeight: FontWeight.w600,
                      fontSize: 18 * k,
                      height: 1.2,
                      color: nameColor,
                      decoration: result == false
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (chord.strum.isEmpty)
                    _BeatDots(beats: chord.beats, activeBeat: activeBeat)
                  else
                    _StrumArrows(
                      strum: chord.strum,
                      activeEighth: activeEighth,
                      slot: slot,
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

class _BeatDots extends StatelessWidget {
  final int beats;
  final int? activeBeat;

  const _BeatDots({required this.beats, required this.activeBeat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var b = 0; b < beats; b++)
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeBeat != null && b <= activeBeat!
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
      ],
    );
  }
}

class _StrumArrows extends StatelessWidget {
  final List<StrumKind?> strum;
  final int? activeEighth;
  final double slot;

  const _StrumArrows({
    required this.strum,
    required this.activeEighth,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final idle = colorScheme.onSurfaceVariant;
    final names = strum.whereType<StrumKind>().map(
      (k) => switch (k) {
        StrumKind.down => 'baixo',
        StrumKind.up => 'cima',
        StrumKind.muted => 'abafado',
      },
    );
    return Semantics(
      label: 'Batida: ${names.join(', ')}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, kind) in strum.indexed)
            SizedBox(
              width: slot,
              height: slot * 1.3,
              child: kind == null
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: idle.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  : Center(
                      child: Container(
                        width: slot * 1.25,
                        height: slot * 1.25,
                        decoration: i == activeEighth
                            ? BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Icon(
                          switch (kind) {
                            StrumKind.down => Ph.arrowDown,
                            StrumKind.up => Ph.arrowUp,
                            StrumKind.muted => Ph.x,
                          },
                          size: slot * 0.95,
                          color: i == activeEighth
                              ? colorScheme.onPrimary
                              : idle.withValues(
                                  alpha: activeEighth == null ? 0.85 : 0.45,
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
