import 'dart:io';

import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/models/score.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/play_along_engine.dart';
import 'package:chordai/widgets/cifra_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('batida com tempo cai no compasso certo', () {
    final strokes = parseStrumPattern(['D1', 'D2', 'U2&', 'U3&', 'D4', 'U4&']);
    expect(strokes.map((s) => s.eighth).toList(), [0, 2, 3, 5, 6, 7]);
    expect(strokes.map((s) => s.kind).toList(), [
      StrumKind.down,
      StrumKind.down,
      StrumKind.up,
      StrumKind.up,
      StrumKind.down,
      StrumKind.up,
    ]);
  });

  test('batida sem tempo e abafado', () {
    final strokes = parseStrumPattern(['D', 'X', 'u']);
    expect(strokes.every((s) => s.eighth == null), isTrue);
    expect(strokes[1].kind, StrumKind.muted);
    expect(strokes[2].kind, StrumKind.up);
  });

  test('as duas cifras têm a batida com tempo', () {
    for (final f in ['riptide', 'all_too_well']) {
      final sheet = parseCifra(
        File('assets/lyrics/$f.txt').readAsStringSync(),
        title: f,
      );
      final strokes = parseStrumPattern(sheet.strummingPattern!);
      expect(strokes.every((s) => s.eighth != null), isTrue, reason: f);
    }
  });

  test('tempo dentro do acorde e oitavo do compasso seguem o relógio', () {
    var agora = Duration.zero;
    final engine = PlayAlongEngine(
      steps: const [
        ChordStep(chord: 'Am', beats: 2),
        ChordStep(chord: 'C'),
      ],
      knownChords: const {'Am', 'C'},
      bpm: 60,
      elapsed: () => agora,
    )..start();
    expect(engine.countingIn, isTrue);
    expect(engine.countInLeft, 4);
    agora = const Duration(milliseconds: 4500);
    engine.update();
    expect(engine.countingIn, isFalse);
    expect(engine.index, 0);
    expect(engine.beatInStep, closeTo(0.5, 0.01));
    expect(engine.eighthInBar, 1);
    agora = const Duration(milliseconds: 6200);
    engine.update();
    expect(engine.index, 1);
    expect(engine.beatInStep, closeTo(0.2, 0.01));
    expect(engine.eighthInBar, 4);
  });

  testWidgets('acorde certo fica verde e errado fica riscado na cifra', (
    tester,
  ) async {
    mockPlatform();
    await tester.pumpWidget(
      appUnderTest(
        const Material(
          child: CifraLine(
            line: LyricLine(chordLine: 'Am  G  C', lyricText: 'letra'),
            tokenResults: {0: true, 1: false},
          ),
        ),
      ),
    );
    final rich = tester.widget<Text>(find.byType(Text).first);
    final spans = (rich.textSpan! as TextSpan).children!.whereType<TextSpan>();
    final am = spans.firstWhere((s) => s.text == 'Am');
    final g = spans.firstWhere((s) => s.text == 'G');
    expect(am.style!.decoration, isNull);
    expect(g.style!.decoration, TextDecoration.lineThrough);
    expect(am.style!.color, isNot(g.style!.color));
  });
}
