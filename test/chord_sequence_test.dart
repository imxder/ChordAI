import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/widgets/chord_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

List<SequenceChord> _acordes(String nomes, {int tempos = 4}) => [
  for (final (i, nome) in nomes.split(' ').indexed)
    SequenceChord(nome, tempos, i),
];

List<(String, int)> _linhas(List<ChordLine> linhas) => [
  for (final l in linhas) (l.chords.map((c) => c.chord).join(' '), l.times),
];

void main() {
  group('repetições', () {
    test('o padrão que se repete vira uma linha com quantas vezes', () {
      expect(_linhas(groupRepeats(_acordes('Am G C Am G C Am G C Am G C'))), [
        ('Am G C', 4),
      ]);
      expect(_linhas(groupRepeats(_acordes('C G Am F C G Am F C G Am F'))), [
        ('C G Am F', 3),
      ]);
    });

    test('o que não repete fica em linhas de até 4 acordes', () {
      expect(_linhas(groupRepeats(_acordes('C G Am G F G Am F'))), [
        ('C G Am G', 1),
        ('F G Am F', 1),
      ]);
    });

    test('repetição no meio, com o resto antes e depois', () {
      expect(_linhas(groupRepeats(_acordes('Em C G C G Dm'))), [
        ('Em', 1),
        ('C G', 2),
        ('Dm', 1),
      ]);
    });

    test('mesmo acorde com outra duração não conta como repetição', () {
      final acordes = [
        const SequenceChord('C', 4, 0),
        const SequenceChord('C', 2, 1),
      ];
      expect(_linhas(groupRepeats(acordes)), [('C C', 1)]);
    });
  });

  test('cada acorde recebe as setas dos tempos que ocupa', () {
    final sheet = parseCifra(
      'Batida: D1 D2 U2& U3& D4 U4&\nTempos: Am=2 G=2\n[Intro]\nAm  G  C\n',
      title: 'x',
    );
    final map = buildLyricPracticeMap(sheet);
    final slots = strumSlotsInSection(
      map,
      0,
      parseStrumPattern(sheet.strummingPattern!),
    );
    const d = StrumKind.down;
    const u = StrumKind.up;
    expect(slots[0], [d, null, d, u]);
    expect(slots[1], [null, u, d, u]);
    expect(slots[2], [d, null, d, u, null, u, d, u]);
  });

  test('batida sem tempo não gera setas', () {
    final sheet = parseCifra('Batida: D D U\n[Intro]\nC\n', title: 'x');
    expect(
      strumSlotsInSection(
        buildLyricPracticeMap(sheet),
        0,
        parseStrumPattern(sheet.strummingPattern!),
      ),
      isEmpty,
    );
  });

  group('tela', () {
    setUp(() async {
      mockPlatform();
      await appState.loadProgress();
    });

    Future<double> tamanhoDaSeta(WidgetTester tester, double escala) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(
        appUnderTest(
          Scaffold(
            body: ChordSequence(
              arrowScale: escala,
              lines: const [
                [
                  SequenceChord(
                    'C',
                    2,
                    0,
                    strum: [StrumKind.down, null, StrumKind.down, StrumKind.up],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      return tester.widget<Icon>(find.byType(Icon).first).size!;
    }

    testWidgets('o tamanho das setas segue a preferência', (tester) async {
      final pequena = await tamanhoDaSeta(tester, 0.75);
      final media = await tamanhoDaSeta(tester, 1.0);
      final grande = await tamanhoDaSeta(tester, 1.3);
      expect(pequena, lessThan(media));
      expect(grande, greaterThan(media));
    });

    testWidgets('a seta da vez ganha o círculo', (tester) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(
        appUnderTest(
          const Scaffold(
            body: ChordSequence(
              activeStep: 0,
              activeEighth: 2,
              lines: [
                [
                  SequenceChord(
                    'C',
                    2,
                    0,
                    strum: [StrumKind.down, null, StrumKind.down, StrumKind.up],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      final circulos = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).shape == BoxShape.circle &&
                c.child is Icon,
          );
      expect(circulos, hasLength(1));
    });

    test('o tamanho das setas fica salvo', () async {
      SharedPreferences.setMockInitialValues({});
      final estado = AppState();
      await estado.loadProgress();
      await estado.setStrumArrowScale(1.3);
      final reaberto = AppState();
      await reaberto.loadProgress();
      expect(reaberto.strumArrowScale, 1.3);
    });
  });
}
