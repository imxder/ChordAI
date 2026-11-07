import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  testWidgets('início mostra os quatro atalhos e o guia, sem saudação', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    expect(find.text('Aprender acordes'), findsOneWidget);
    expect(find.text('Tocar músicas'), findsOneWidget);
    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Reconhecer acorde'), findsOneWidget);
    expect(find.text('Guia do iniciante'), findsOneWidget);
    final guide = tester.getTopLeft(find.text('Guia do iniciante')).dy;
    expect(guide, lessThan(tester.getTopLeft(find.text('Aprender acordes')).dy));
    for (final word in ['Bom dia', 'Boa tarde', 'Boa noite', 'Continuar', 'Próximo acorde']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('atalho de acordes abre a aba de acordes', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    await tester.tap(find.text('Aprender acordes'));
    await settle(tester);
    expect(find.text('Em ordem de dificuldade. 0 de 8 aprendidos.'), findsOneWidget);
  });

  testWidgets('a barra de baixo troca de aba sem empilhar telas', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);

    await tester.tap(find.text('Perfil'));
    await settle(tester);
    expect(find.text('Seu nome'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('Acordes').last);
    await settle(tester);
    expect(find.text('Em ordem de dificuldade. 0 de 8 aprendidos.'), findsOneWidget);
  });

  testWidgets('não sobrou nada da gamificação', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);
    await tester.tap(find.text('Perfil'));
    await settle(tester);

    for (final word in ['XP', 'Nível', 'moedas', 'Conquista', 'Desafio', 'Loja']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

}
