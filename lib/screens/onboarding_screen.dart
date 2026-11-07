import 'package:flutter/material.dart';

import '../models/chord_difficulty.dart';
import '../models/lyric_sheet.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/cifra_line.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import 'tuning_check_screen.dart';
import '../theme/ph.dart';

class _OnboardingPage {
  final String title;
  final String body;
  final WidgetBuilder illustration;

  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.illustration,
  });
}

final _pages = [
  _OnboardingPage(
    title: 'O app ouve o acorde que você toca',
    body: 'Toque perto do microfone e veja na hora se o acorde saiu certo.',
    illustration: (context) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(
          width: 168,
          child: GuitarNeck(chord: 'C', matchState: ChordMatchState.correct),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChordName('C', size: 64),
              StatusLine(
                icon: Ph.check,
                text: 'Certo',
                color: context.tokens.correct,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
  _OnboardingPage(
    title: 'Cifra e letra no seu andamento',
    body:
        'Escolha o BPM e acompanhe a música acorde por acorde, com o '
        'diagrama de cada um na tela.',
    illustration: (context) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CifraLine(
          line: LyricLine(
            chordLine: 'Am        F',
            lyricText: 'Cada acorde fica',
          ),
          activeToken: 0,
          fontScale: 1.4,
        ),
        CifraLine(
          line: LyricLine(
            chordLine: 'C         G',
            lyricText: 'em cima da sílaba certa',
          ),
          fontScale: 1.4,
        ),
      ],
    ),
  ),
  _OnboardingPage(
    title: 'Seus acordes ficam guardados',
    body:
        'Acerte um acorde ${AppState.chordMasteryHits} vezes seguidas e ele '
        'entra na sua lista de aprendidos, no perfil.',
    illustration: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, chord) in chordsByDifficulty.indexed)
            Container(
              width: 64,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < 3 ? colorScheme.primary : context.tokens.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ChordName(
                chord,
                size: 16,
                color: i < 3 ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
        ],
      );
    },
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Quem marca o onboarding como feito é a tela de afinação; marcar aqui faz o
  // MaterialApp trocar a home e pular direto pro início.
  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TuningCheckScreen()),
    );
  }

  void _continue() {
    if (_page < _pages.length - 1) {
      final duration = motion(context, const Duration(milliseconds: 280));
      if (duration == Duration.zero) {
        _controller.jumpToPage(_page + 1);
      } else {
        _controller.nextPage(duration: duration, curve: Curves.easeOutCubic);
      }
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TuningCheckScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLast = _page == _pages.length - 1;
    final padding = pagePadding(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                8,
                padding.right - 12,
                0,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: 'Página ${_page + 1} de ${_pages.length}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? Theme.of(context).colorScheme.onSurface
                                  : context.tokens.rule,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _skip, child: const Text('Pular')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        24,
                        padding.right,
                        24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox.shrink(),
                            page.illustration(context),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 32),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    page.title,
                                    style: textTheme.headlineLarge,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(page.body, style: textTheme.bodyLarge),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 16),
              child: FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(isLast ? 'Começar' : 'Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
