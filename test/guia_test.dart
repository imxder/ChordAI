import 'package:chordai/models/guide_content.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/chord_list_screen.dart';
import 'package:chordai/screens/chord_practice_screen.dart';
import 'package:chordai/screens/guide_detail_screen.dart';
import 'package:chordai/screens/guide_list_screen.dart';
import 'package:chordai/screens/lyric_sheet_list_screen.dart';
import 'package:chordai/screens/practice_session_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/lyric_sheet_library.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/ph.dart';
import 'package:chordai/widgets/page_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  test('os 13 tópicos, na ordem dos três grupos', () {
    expect(guideTopics.map((t) => t.id), [
      'partes',
      'postura',
      'afinar',
      'diagrama',
      'primeiro_acorde',
      'cifra',
      'batida',
      'trocar_acorde',
      'treino_diario',
      'dor_dedos',
      'acessorios',
      'cordas',
      'regular',
    ]);
    final grupos = guideTopics.map((t) => t.group).toList();
    for (var i = 1; i < grupos.length; i++) {
      expect(grupos[i].index, greaterThanOrEqualTo(grupos[i - 1].index));
    }
  });

  test('todo tópico tem título, resumo e texto', () {
    for (final topic in guideTopics) {
      expect(topic.title, isNotEmpty, reason: topic.id);
      expect(topic.summary, isNotEmpty, reason: topic.id);
      expect(
        topic.paragraphs.isNotEmpty || topic.steps.isNotEmpty,
        isTrue,
        reason: topic.id,
      );
      for (final texto in [...topic.paragraphs, ...topic.steps]) {
        expect(texto.trim(), isNotEmpty, reason: topic.id);
      }
    }
  });

  test('os ids antigos continuam existindo', () {
    for (final id in [
      'acessorios',
      'regular',
      'afinar',
      'cordas',
      'postura',
      'dor_dedos',
    ]) {
      expect(guideTopicById(id).id, id);
    }
  });

  test(
    'só o último tópico volta pra lista; os sem prática vão pro próximo',
    () {
      expect(guideTopics.last.action, GuideAction.list);
      for (final topic in guideTopics.where(
        (t) => t.action == GuideAction.next,
      )) {
        expect(guideTopicAfter(topic), isNotNull, reason: topic.id);
      }
    },
  );

  group('telas', () {
    setUp(() async {
      mockPlatform();
      await appState.loadProgress();
    });

    final destinos = <String, Type>{
      'afinar': TunerScreen,
      'diagrama': ChordListScreen,
      'primeiro_acorde': ChordPracticeScreen,
      'cifra': LyricSheetListScreen,
      'batida': LyricSheetListScreen,
      'trocar_acorde': PracticeSessionScreen,
      'treino_diario': ChordPracticeScreen,
      'cordas': TunerScreen,
    };

    for (final topic in guideTopics) {
      testWidgets('o botão de ${topic.id} abre a tela certa', (tester) async {
        await tester.runAsync(() => LyricSheetLibrary().loadAll());
        setScreen(tester, const Size(390, 3000));
        await tester.pumpWidget(appUnderTest(GuideDetailScreen(topic: topic)));
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('ação do guia')));
        await settle(tester);
        switch (topic.action) {
          case GuideAction.next:
            expect(
              find.text(guideTopicAfter(topic)!.title),
              findsWidgets,
              reason: topic.id,
            );
          case GuideAction.list:
            expect(find.byType(GuideListScreen), findsOneWidget);
          default:
            expect(find.byType(destinos[topic.id]!), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }

    testWidgets('abrir um tópico marca como lido e a lista mostra o visto', (
      tester,
    ) async {
      setScreen(tester, const Size(390, 2000));
      await tester.pumpWidget(appUnderTest(const GuideListScreen()));
      await settle(tester);
      expect(find.byIcon(Ph.check), findsNothing);

      await tester.tap(find.text('Como afinar o violão'));
      await settle(tester);
      await tester.pageBack();
      await settle(tester);
      expect(appState.readGuideTopics, {'afinar'});
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('guia afinar')),
          matching: find.byIcon(Ph.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Ph.check), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('app_guide_read'), ['afinar']);
    });

    testWidgets('a lista separa os três grupos', (tester) async {
      setScreen(tester, const Size(390, 2400));
      await tester.pumpWidget(appUnderTest(const GuideListScreen()));
      await settle(tester);
      for (final grupo in GuideGroup.values) {
        expect(find.text(grupo.title), findsOneWidget);
      }
    });

    testWidgets('o início mostra no máximo 8 tópicos do guia', (tester) async {
      setScreen(tester, const Size(390, 1400));
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await settle(tester);
      final carrossel = tester.widget<ListView>(
        find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(carrossel.semanticChildCount, 8);
      expect(find.text(guideTopics.first.title), findsOneWidget);
    });

    testWidgets('no computador também são 8, em 4 colunas', (tester) async {
      setScreen(tester, const Size(1200, 1400));
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await settle(tester);
      final linhas = <double>{};
      for (final topic in guideTopics.take(8)) {
        final card = find
            .ancestor(
              of: find.text(topic.title),
              matching: find.byType(PressScale),
            )
            .first;
        linhas.add(tester.getTopLeft(card).dy.roundToDouble());
      }
      expect(linhas, hasLength(2));
      expect(find.text(guideTopics[8].title), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });
}
