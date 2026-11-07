import 'package:chordai/models/app_theme.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/profile_screen.dart';
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

  testWidgets('editar o perfil salva o nome e a experiência', (tester) async {
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);
    await tester.tap(find.text('Perfil'));
    await settle(tester);

    await tester.tap(find.text('Seu nome'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '  Alexandre ');
    await tester.tap(find.text('Já toco um pouco'));
    await tester.ensureVisible(find.text('Salvar'));
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    await settle(tester);
    await settle(tester);

    expect(find.text('Alexandre'), findsOneWidget);
    expect(find.text('Já toco um pouco'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_profile_name'), 'Alexandre');
  });

  testWidgets('trocar a cor no perfil não custa nada', (tester) async {
    setScreen(tester, const Size(400, 1800));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);
    await tester.tap(find.text('Perfil'));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Cor Vinho'));
    await tester.pump();
    expect(appState.selectedThemeIndex, 2);
  });

  testWidgets('aparência escura vale pro app e fica salva', (tester) async {
    setScreen(tester, const Size(400, 1800));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);
    await tester.tap(find.text('Perfil'));
    await settle(tester);

    await tester.tap(find.text('Aparência'));
    await settle(tester);
    await tester.tap(find.text('Escuro'));
    await settle(tester);

    expect(appState.appearance, AppAppearance.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_appearance'), 'dark');
    await appState.loadProgress();
    expect(appState.appearance, AppAppearance.dark);
  });

  test('último treino em palavras', () {
    final now = DateTime(2026, 11, 7, 15);
    expect(lastPracticeLabel(null, now), 'Nenhum ainda');
    expect(lastPracticeLabel('2026-11-07', now), 'Hoje');
    expect(lastPracticeLabel('2026-11-06', now), 'Ontem');
    expect(lastPracticeLabel('2026-10-30', now), '30/10/2026');
  });

  test('dados antigos de gamificação são apagados ao carregar', () async {
    SharedPreferences.setMockInitialValues({
      'app_xp': 340,
      'app_coins': 25,
      'app_unlocked_achievements': ['level_5'],
      'app_learned_chords': ['Em', 'Am'],
      'app_selected_theme': 7,
    });
    await appState.loadProgress();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.containsKey('app_xp'), isFalse);
    expect(prefs.containsKey('app_coins'), isFalse);
    expect(prefs.containsKey('app_unlocked_achievements'), isFalse);
    expect(appState.learnedChords, {'Em', 'Am'});
    expect(appState.selectedThemeIndex, 0);
    expect(appState.nextChordToLearn, 'C');
  });

  test('acorde só conta como aprendido depois dos acertos seguidos', () {
    expect(appState.registerChordHits('Em', AppState.chordMasteryHits - 1), isFalse);
    expect(appState.registerChordHits('Em', AppState.chordMasteryHits), isTrue);
    expect(appState.registerChordHits('Em', AppState.chordMasteryHits + 1), isFalse);
    expect(appState.isChordLearned('Em'), isTrue);
    expect(appState.lastPracticeDateIso, isNotNull);
  });
}
