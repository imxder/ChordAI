import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/chord_detail_screen.dart';
import 'package:chordai/screens/guide_detail_screen.dart';
import 'package:chordai/screens/guide_list_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  testWidgets('início mostra os quatro atalhos, o guia e os acordes', (
    tester,
  ) async {
    setScreen(tester, const Size(390, 1400));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    expect(find.text('Aprender acordes'), findsOneWidget);
    expect(find.text('Tocar músicas'), findsOneWidget);
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Reconhecer acorde'), findsOneWidget);
    expect(find.text('Guia do iniciante'), findsOneWidget);
    expect(find.text('Acessórios essenciais'), findsOneWidget);
    expect(find.text('Seus acordes'), findsOneWidget);
    expect(find.text('0 de 8 aprendidos'), findsOneWidget);
    final guide = tester.getTopLeft(find.text('Guia do iniciante')).dy;
    expect(
      guide,
      greaterThan(tester.getTopLeft(find.text('Aprender acordes')).dy),
    );
    for (final word in [
      'Bom dia',
      'Boa tarde',
      'Boa noite',
      'Continuar',
      'Próximo acorde',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('atalho de acordes abre a aba de acordes', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    await tester.tap(find.text('Aprender acordes'));
    await settle(tester);
    expect(
      find.text('Em ordem de dificuldade. 0 de 8 aprendidos.'),
      findsOneWidget,
    );
  });

  testWidgets('a barra de baixo troca de aba sem empilhar telas', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    await tester.tap(find.text('Perfil'));
    await settle(tester);
    expect(find.text('Seu nome'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Acordes').last);
    await settle(tester);
    expect(
      find.text('Em ordem de dificuldade. 0 de 8 aprendidos.'),
      findsOneWidget,
    );
  });

  testWidgets('não sobrou nada da gamificação', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);
    await tester.tap(find.text('Perfil'));
    await settle(tester);

    for (final word in [
      'XP',
      'Nível',
      'moedas',
      'Conquista',
      'Desafio',
      'Loja',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('acorde do mapa do início abre o acorde e mostra os aprendidos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_learned_chords': ['Em', 'C'],
    });
    await appState.loadProgress();
    setScreen(tester, const Size(390, 1400));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    expect(find.text('2 de 8 aprendidos'), findsOneWidget);
    expect(find.bySemanticsLabel('Em, aprendido'), findsOneWidget);
    expect(find.bySemanticsLabel('Am'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Am'));
    await settle(tester);
    expect(find.byType(ChordDetailScreen), findsOneWidget);
  });

  testWidgets('cartão do guia no início abre o tópico', (tester) async {
    setScreen(tester, const Size(390, 1400));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    await tester.tap(find.text('Acessórios essenciais'));
    await settle(tester);
    expect(find.byType(GuideDetailScreen), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.text('Ver tudo'));
    await settle(tester);
    expect(find.byType(GuideListScreen), findsOneWidget);
  });
}
