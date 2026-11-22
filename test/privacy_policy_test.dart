import 'dart:io';

import 'package:chordai/models/privacy_policy.dart';
import 'package:chordai/screens/onboarding_screen.dart';
import 'package:chordai/screens/privacy_screen.dart';
import 'package:chordai/screens/profile_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  final markdown = File('PRIVACY.md').readAsStringSync();

  test('leitor separa título, seções, parágrafos e listas', () {
    final policy = parsePrivacyPolicy(
      '# Título\n\nPrimeira linha\ncontinua aqui.\n\n## Seção\n\n- um\n- dois\n\nFim.\n',
    );
    expect(policy.title, 'Título');
    expect(policy.sections, hasLength(2));
    expect(policy.sections[0].title, isNull);
    expect(policy.sections[0].paragraphs, ['Primeira linha continua aqui.']);
    expect(policy.sections[1].title, 'Seção');
    expect(policy.sections[1].items, ['um', 'dois']);
    expect(policy.sections[1].paragraphs, ['Fim.']);
  });

  test('o PRIVACY.md tem as seções que a LGPD pede', () {
    final titles = parsePrivacyPolicy(markdown).sections
        .map((s) => s.title)
        .whereType<String>()
        .toList();
    for (final expected in [
      'Quem cuida dos dados',
      'O que o app guarda no seu aparelho',
      'O microfone',
      'O app não usa a internet',
      'Compartilhamento com terceiros',
      'Por quanto tempo os dados ficam',
      'Seus direitos',
      'Contato',
    ]) {
      expect(titles, contains(expected));
    }
    expect(markdown, contains('não é gravado em arquivo e não é enviado'));
    expect(markdown, contains('não faz nenhuma chamada de rede'));
    expect(markdown, isNot(contains('HTTP')));
  });

  test('o PRIVACY.md vai junto no app', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('- PRIVACY.md'));
  });

  testWidgets('a tela mostra todas as seções do PRIVACY.md', (tester) async {
    mockPlatform();
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(appUnderTest(const PrivacyScreen()));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    for (final section in parsePrivacyPolicy(markdown).sections) {
      if (section.title != null) {
        await tester.scrollUntilVisible(
          find.text(section.title!),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(section.title!), findsOneWidget);
      }
    }
  });

  testWidgets('a linha Privacidade do perfil abre a política', (tester) async {
    mockPlatform();
    await appState.loadProgress();
    setScreen(tester, const Size(400, 1800));
    await tester.pumpWidget(appUnderTest(const ProfileScreen()));
    await tester.pump();
    await tester.tap(find.text('Privacidade'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  testWidgets(
    'o onboarding avisa do microfone antes de pedir e abre a política',
    (tester) async {
      mockPlatform();
      await appState.loadProgress();
      setScreen(tester, const Size(400, 900));
      await tester.pumpWidget(appUnderTest(const OnboardingScreen()));
      await tester.pump();
      expect(find.textContaining('não é gravado nem enviado'), findsOneWidget);
      await tester.tap(find.text('Política de privacidade'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyScreen), findsOneWidget);
    },
  );
}
