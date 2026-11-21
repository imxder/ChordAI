import 'dart:convert';
import 'dart:io';

import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/models/on_device_model.dart';
import 'package:chordai/models/play_along_report.dart';
import 'package:chordai/models/user_song.dart';
import 'package:chordai/screens/lyric_sheet_list_screen.dart';
import 'package:chordai/screens/song_editor_screen.dart';
import 'package:chordai/services/cifra_parser.dart';
import 'package:chordai/services/lyric_sheet_library.dart';
import 'package:chordai/services/play_along_engine.dart';
import 'package:chordai/services/user_song_store.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/widgets/practice_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

const _minha = UserSong(
  id: '1',
  title: 'Minha música',
  artist: 'Eu',
  bpm: 60,
  parts: [
    SongPart(
      name: 'Intro',
      chords: [SongChord('Am', 2), SongChord('G', 2), SongChord('C', 4)],
    ),
    SongPart(
      name: 'Refrão',
      chords: [
        SongChord('F', 4),
        SongChord('C', 4),
        SongChord('G', 4),
        SongChord('Am', 4),
        SongChord('Em', 4),
      ],
    ),
  ],
);

List<(String, int)> _sequencia(UserSong song) => [
  for (final s in buildLyricPracticeMap(song.toLyricSheet()).score.steps)
    (s.chord, s.beats),
];

void main() {
  group('cifras sem letra', () {
    test('as duas cifras do app abrem só com partes e acordes', () {
      for (final (arquivo, acordes) in [
        ('riptide', 88),
        ('all_too_well', 249),
      ]) {
        final sheet = parseCifra(
          File('assets/lyrics/$arquivo.txt').readAsStringSync(),
          title: arquivo,
        );
        final linhas = sheet.sections.expand((s) => s.lines);
        expect(linhas.every((l) => l.lyricText.trim().isEmpty), isTrue);
        expect(
          buildLyricPracticeMap(sheet).score.steps,
          hasLength(acordes),
          reason: arquivo,
        );
      }
    });
  });

  group('música criada no aparelho', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('vira o texto da cifra com a mesma sequência e os mesmos tempos', () {
      expect(_sequencia(_minha), [
        ('Am', 2),
        ('G', 2),
        ('C', 4),
        ('F', 4),
        ('C', 4),
        ('G', 4),
        ('Am', 4),
        ('Em', 4),
      ]);
      final texto = _minha.toCifraText();
      expect(texto, contains('Tempo: 60'));
      expect(texto, contains('[Refrão]'));
      expect(texto.split('\n').where((l) => l.contains(':4')).length, 3);
      final sheet = _minha.toLyricSheet();
      expect(sheet.isMine, isTrue);
      expect(sheet.artist, 'Eu');
      expect(sheet.strummingPattern, StrumPreset.common.tokens);
    });

    test('criar, editar, apagar e reabrir', () async {
      final store = UserSongStore();
      await store.save(_minha);
      expect((await UserSongStore().loadAll()).single.title, 'Minha música');

      await store.save(_minha.copyWith(title: 'Outro nome', bpm: 120));
      final reaberta = (await UserSongStore().loadAll()).single;
      expect(reaberta.title, 'Outro nome');
      expect(reaberta.bpm, 120);
      expect(reaberta.parts[1].chords.last.chord, 'Em');

      final prefs = await SharedPreferences.getInstance();
      final json = jsonDecode(
        prefs.getString(UserSongStore.key)!,
      ) as Map<String, dynamic>;
      expect(json['versao'], UserSongStore.version);

      await store.delete(_minha.id);
      expect(await UserSongStore().loadAll(), isEmpty);
    });

    test('dado estragado no aparelho não quebra a lista', () async {
      SharedPreferences.setMockInitialValues({UserSongStore.key: 'não é json'});
      expect(await UserSongStore().loadAll(), isEmpty);
    });

    test('toca no tocar junto e o acorde fora do modelo não conta', () {
      const comA = UserSong(
        id: '2',
        title: 'Com Lá',
        bpm: 60,
        parts: [
          SongPart(
            name: 'Verso',
            chords: [SongChord('C', 4), SongChord('A', 4), SongChord('G', 4)],
          ),
        ],
      );
      var agora = Duration.zero;
      final engine = PlayAlongEngine(
        steps: buildLyricPracticeMap(comA.toLyricSheet()).score.steps,
        knownChords: const {'Am', 'Bb', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'},
        bpm: 60,
        elapsed: () => agora,
      )..start();
      expect(engine.modelChords, ['C', null, 'G']);

      for (var ms = 0; ms <= 20000; ms += 250) {
        agora = Duration(milliseconds: ms);
        final segundos = ms / 1000;
        if (segundos >= 4.5 && segundos < 8.5) engine.reading('C');
        if (segundos >= 12.5 && segundos < 16.5) engine.reading('G');
        engine.update();
      }
      expect(engine.finished, isTrue);
      expect(engine.results, [
        StepResult.hit,
        StepResult.notCounted,
        StepResult.hit,
      ]);
      expect(engine.notCountedChords, {'A'});
    });
  });

  test('relatório põe os acordes mais errados primeiro', () {
    final linhas = chordsByMisses({
      'G': (6, 6),
      'F': (2, 5),
      'Am': (3, 4),
      'C': (4, 5),
    });
    expect(linhas.map((l) => l.chord).toList(), ['F', 'C', 'Am', 'G']);
    expect(linhas.first.misses, 3);
    expect(linhas.first.total, 5);
  });

  group('editor', () {
    setUp(() async {
      mockPlatform();
      await appState.loadProgress();
    });

    Future<void> abrirEditor(WidgetTester tester) async {
      setScreen(tester, const Size(400, 1600));
      await tester.pumpWidget(appUnderTest(const SongEditorScreen()));
      await tester.pump();
    }

    testWidgets('só oferece os acordes do modelo escolhido', (tester) async {
      await abrirEditor(tester);
      expect(
        find.textContaining('O app reconhece só estes acordes'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('mais acorde 0')));
      await settle(tester);
      final oferecidos = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((c) => (c.label as Text).data)
          .toList();
      expect(oferecidos, appState.chordsInModel);
      expect(oferecidos, isNot(contains('A')));
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('com o modelo novo o Lá aparece', (tester) async {
      await tester.runAsync(
        () => appState.setOnDeviceModel(OnDeviceModel.v3Meu),
      );
      addTearDown(
        () =>
            tester.runAsync(() => appState.setOnDeviceModel(OnDeviceModel.v3)),
      );
      await abrirEditor(tester);
      await tester.tap(find.byKey(const ValueKey('mais acorde 0')));
      await settle(tester);
      expect(find.byKey(const ValueKey('escolher A')), findsOneWidget);
    });

    testWidgets('salva uma música nova e ela aparece como Minha', (
      tester,
    ) async {
      await abrirEditor(tester);
      await tester.enterText(
        find.byKey(const ValueKey('nome da música')),
        'Teste',
      );
      await tester.tap(find.byKey(const ValueKey('mais acorde 0')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('escolher C')));
      await tester.pump();
      await tester.tap(find.text('Pronto'));
      await settle(tester);
      expect(find.text('C · 4'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('salvar música')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
      final salvas = (await tester.runAsync(() => UserSongStore().loadAll()))!;
      expect(salvas.single.title, 'Teste');
      expect(salvas.single.parts.first.chords.single.chord, 'C');

      await tester.runAsync(() => LyricSheetLibrary().loadAll());
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        appUnderTest(const LyricSheetListScreen(serverUrl: '')),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await settle(tester);
      expect(find.text('Teste'), findsOneWidget);
      expect(find.textContaining('Minha'), findsWidgets);
    });

    testWidgets('sem nome não salva', (tester) async {
      await abrirEditor(tester);
      await tester.tap(find.byKey(const ValueKey('salvar música')));
      await tester.pump();
      expect(find.text('Dê um nome pra música'), findsOneWidget);
    });
  });

  group('editor mexendo na música', () {
    setUp(() async {
      mockPlatform();
      await appState.loadProgress();
    });

    Future<void> abrir(WidgetTester tester, {UserSong? song}) async {
      setScreen(tester, const Size(400, 2400));
      await tester.pumpWidget(
        appUnderTest(SongEditorScreen(song: song ?? _minha)),
      );
      await tester.pump();
    }

    testWidgets('troca a duração de um acorde e tira outro', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('Am · 2'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('escolher Em')));
      await tester.tap(find.text('8'));
      await tester.pump();
      await tester.tap(find.text('Pronto'));
      await settle(tester);
      expect(find.text('Em · 8'), findsOneWidget);

      await tester.tap(find.text('G · 2'));
      await settle(tester);
      await tester.tap(find.text('Tirar acorde'));
      await settle(tester);
      expect(find.text('G · 2'), findsNothing);
    });

    testWidgets('cria parte da lista e com outro nome, muda a ordem e tira', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(find.byKey(const ValueKey('mais parte')));
      await settle(tester);
      await tester.tap(find.text('Ponte'));
      await settle(tester);
      expect(find.text('Ponte'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mais parte')));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, 'Ponte 2');
      await tester.tap(find.text('Usar esse nome'));
      await settle(tester);
      expect(find.text('Ponte 2'), findsOneWidget);

      final antes = tester.getTopLeft(find.text('Intro')).dy;
      await tester.tap(find.bySemanticsLabel('Descer parte').first);
      await tester.pump();
      expect(tester.getTopLeft(find.text('Intro')).dy, greaterThan(antes));
      await tester.tap(find.bySemanticsLabel('Subir parte').at(1));
      await tester.pump();
      expect(tester.getTopLeft(find.text('Intro')).dy, antes);

      await tester.tap(find.bySemanticsLabel('Tirar parte').last);
      await tester.pump();
      expect(find.text('Ponte 2'), findsNothing);
    });

    testWidgets('muda o BPM e a batida', (tester) async {
      await abrir(tester);
      await tester.tap(find.bySemanticsLabel('Mais rápido'));
      await tester.pump();
      expect(find.text('61 BPM'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Mais devagar'));
      await tester.tap(find.bySemanticsLabel('Mais devagar'));
      await tester.pump();
      expect(find.text('59 BPM'), findsOneWidget);

      await tester.tap(find.text('Batida'));
      await settle(tester);
      await tester.tap(find.text('Só pra baixo'));
      await settle(tester);
      expect(find.text('Só pra baixo'), findsOneWidget);
    });

    testWidgets('acorde fora do modelo aparece avisado', (tester) async {
      await abrir(
        tester,
        song: const UserSong(
          id: '3',
          title: 'Com Lá',
          parts: [
            SongPart(name: 'Verso', chords: [SongChord('A', 4)]),
          ],
        ),
      );
      expect(find.textContaining('não reconhece'), findsOneWidget);
    });

    testWidgets('sem acorde não salva', (tester) async {
      await abrir(
        tester,
        song: const UserSong(id: '4', title: 'Vazia'),
      );
      await tester.tap(find.byKey(const ValueKey('salvar música')));
      await tester.pump();
      expect(find.text('Coloque pelo menos um acorde'), findsOneWidget);
    });

    testWidgets('apaga a música depois de confirmar', (tester) async {
      await tester.runAsync(() => UserSongStore().save(_minha));
      await abrir(tester);
      await tester.tap(find.text('Apagar música'));
      await settle(tester);
      await tester.tap(find.text('Cancelar'));
      await settle(tester);
      await tester.tap(find.text('Apagar música'));
      await settle(tester);
      await tester.tap(find.text('Apagar'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);
      expect(await tester.runAsync(() => UserSongStore().loadAll()), isEmpty);
    });

    testWidgets('na lista, abre a música e o lápis abre o editor', (
      tester,
    ) async {
      await tester.runAsync(() => UserSongStore().save(_minha));
      await tester.runAsync(() => LyricSheetLibrary().loadAll());
      await tester.pumpWidget(
        appUnderTest(const LyricSheetListScreen(serverUrl: '')),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await settle(tester);
      await tester.tap(find.text('Minha música'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('editar música')));
      await settle(tester);
      expect(find.byType(SongEditorScreen), findsOneWidget);
      expect(find.text('Editar música'), findsOneWidget);
    });

    testWidgets('no Aa dá pra mudar o tamanho das setas', (tester) async {
      setScreen(tester, const Size(400, 1200));
      await tester.pumpWidget(
        appUnderTest(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPracticeOptionsSheet(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await settle(tester);
      expect(find.text('Tamanho dos acordes'), findsOneWidget);
      expect(find.text('Tamanho das setas da batida'), findsOneWidget);
      await tester.tap(find.text('Grande').last);
      await settle(tester);
      expect(appState.strumArrowScale, 1.3);
      await tester.tap(find.text('Médio').last);
      await settle(tester);
    });
  });
}
