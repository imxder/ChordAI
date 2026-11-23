import 'package:chordai/models/theme_options.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/services/user_song_store.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/platform_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<void> _abrirAjustes(WidgetTester tester) async {
  await tester.pumpWidget(appUnderTest(const AppShell()));
  await settle(tester);
  await tester.tap(
    find.byKey(const ValueKey('abrir ajustes')).hitTestable().first,
  );
  await settle(tester);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  test('o nome da tela depende da plataforma, não do visual', () {
    final nomes = <TargetPlatform, String>{};
    for (final p in [
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.android,
      TargetPlatform.windows,
    ]) {
      debugDefaultTargetPlatformOverride = p;
      nomes[p] = settingsTitle;
    }
    debugDefaultTargetPlatformOverride = null;
    expect(nomes, {
      TargetPlatform.iOS: 'Ajustes',
      TargetPlatform.macOS: 'Ajustes',
      TargetPlatform.android: 'Configurações',
      TargetPlatform.windows: 'Configurações',
    });
  });

  testWidgets('a engrenagem abre as configurações por cima e volta', (
    tester,
  ) async {
    await _abrirAjustes(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('a tela só tem as preferências, sem nome nem números', (
    tester,
  ) async {
    setScreen(tester, const Size(400, 1800));
    await _abrirAjustes(tester);
    for (final item in [
      'Aparência',
      'Cor do app',
      'Afinação',
      'Leitura das cifras',
      'Reconhecimento',
      'Privacidade',
    ]) {
      expect(find.text(item), findsOneWidget, reason: item);
    }
    for (final antigo in [
      'Seu nome',
      'Prática',
      'Último treino',
      'Treinos concluídos',
      'Acordes certos',
      'Acordes aprendidos',
    ]) {
      expect(find.textContaining(antigo), findsNothing, reason: antigo);
    }
  });

  for (final (plataforma, minimo) in [
    (TargetPlatform.iOS, 44.0),
    (TargetPlatform.android, 48.0),
  ]) {
    testWidgets('engrenagem tem área de toque e rótulo (${plataforma.name})', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await settle(tester);
      final botao = find
          .byKey(const ValueKey('abrir ajustes'))
          .hitTestable()
          .first;
      final tamanho = tester.getSize(botao);
      expect(tamanho.width, greaterThanOrEqualTo(minimo));
      expect(tamanho.height, greaterThanOrEqualTo(minimo));
      expect(find.bySemanticsLabel(settingsTitle), findsWidgets);
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(plataforma));
  }

  testWidgets('trocar a cor nas configurações', (tester) async {
    setScreen(tester, const Size(400, 1800));
    await _abrirAjustes(tester);
    await tester.tap(find.bySemanticsLabel('Cor Vinho'));
    await tester.pump();
    expect(appState.selectedThemeIndex, 2);
  });

  testWidgets('aparência escura vale pro app e fica salva', (tester) async {
    setScreen(tester, const Size(400, 1800));
    await _abrirAjustes(tester);
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

  test('nome, experiência e números de prática somem; o resto fica', () async {
    SharedPreferences.setMockInitialValues({
      'app_profile_name': 'Alexandre',
      'app_profile_experience': 'Iniciante',
      'app_total_correct': 42,
      'app_total_sessions': 7,
      'app_last_practice_date': '2026-11-20',
      'app_learned_chords': ['Em', 'Am'],
      'app_selected_theme': 2,
      'app_appearance': 'dark',
      UserSongStore.key: '{"versao":1,"musicas":[]}',
    });
    await appState.loadProgress();
    final prefs = await SharedPreferences.getInstance();

    for (final chave in [
      'app_profile_name',
      'app_profile_experience',
      'app_total_correct',
      'app_total_sessions',
      'app_last_practice_date',
    ]) {
      expect(prefs.containsKey(chave), isFalse, reason: chave);
    }
    expect(appState.learnedChords, {'Em', 'Am'});
    expect(appState.selectedThemeIndex, 2);
    expect(appState.appearance, AppAppearance.dark);
    expect(prefs.getString(UserSongStore.key), isNotNull);
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
    expect(
      appState.registerChordHits('Em', AppState.chordMasteryHits - 1),
      isFalse,
    );
    expect(appState.registerChordHits('Em', AppState.chordMasteryHits), isTrue);
    expect(
      appState.registerChordHits('Em', AppState.chordMasteryHits + 1),
      isFalse,
    );
    expect(appState.isChordLearned('Em'), isTrue);
  });

  testWidgets('no iPhone a engrenagem do título recebe o toque', (
    tester,
  ) async {
    setScreen(tester, const Size(390, 844));
    await tester.pumpWidget(appUnderTest(const AppShell()));
    await settle(tester);
    final botao = find.byKey(const ValueKey('abrir ajustes')).hitTestable();
    expect(botao, findsOneWidget);
    await tester.tap(botao);
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SettingsScreen), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  group('apresentação ao abrir', () {
    test('instalação nova mostra a apresentação', () async {
      SharedPreferences.setMockInitialValues({});
      await appState.loadProgress();
      expect(appState.showOnboardingAtLaunch, isTrue);
    });

    test('quem já viu não vê de novo, a não ser com a opção ligada', () async {
      SharedPreferences.setMockInitialValues({'app_has_onboarded': true});
      await appState.loadProgress();
      expect(appState.showOnboardingAtLaunch, isFalse);

      await appState.setAlwaysShowOnboarding(true);
      expect(appState.showOnboardingAtLaunch, isFalse);
      await appState.loadProgress();
      expect(appState.showOnboardingAtLaunch, isTrue);

      await appState.completeOnboarding();
      expect(appState.showOnboardingAtLaunch, isFalse);
      await appState.loadProgress();
      expect(appState.showOnboardingAtLaunch, isTrue);

      await appState.setAlwaysShowOnboarding(false);
      await appState.loadProgress();
      expect(appState.showOnboardingAtLaunch, isFalse);
    });

    testWidgets('a chave fica nas configurações', (tester) async {
      setScreen(tester, const Size(400, 1800));
      await tester.pumpWidget(appUnderTest(const SettingsScreen()));
      await settle(tester);
      expect(find.text('Mostrar ao abrir o app'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('apresentação ao abrir')));
      await settle(tester);
      expect(appState.alwaysShowOnboarding, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_always_onboarding'), isTrue);
    });
  });
}
