import 'package:flutter/material.dart';

import '../models/lyric_sheet.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/chord_sequence.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/listening_bars.dart';
import '../widgets/page_parts.dart';
import 'privacy_screen.dart';
import 'tuning_check_screen.dart';
import '../theme/ph.dart';
import '../theme/platform_style.dart';

class _OnboardingPage {
  final String title;
  final String body;
  final WidgetBuilder illustration;
  final bool privacyLink;

  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.illustration,
    this.privacyLink = false,
  });
}

const _commonStrum = [
  StrumKind.down,
  null,
  StrumKind.down,
  StrumKind.up,
  null,
  StrumKind.up,
  StrumKind.down,
  StrumKind.up,
];

final _pages = [
  _OnboardingPage(
    title: 'O app ouve o acorde que você toca',
    body:
        'Toque perto do microfone e veja na hora se o acorde saiu certo. O '
        'som é analisado no próprio aparelho e não é gravado nem enviado.',
    privacyLink: true,
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
    title: 'Cifras no seu andamento',
    body:
        'Escolha o BPM e toque junto, acorde por acorde, com o desenho de '
        'cada um e as setas da batida.',
    illustration: (context) => const ChordSequence(
      fontScale: 1.15,
      activeStep: 0,
      activeEighth: 0,
      lines: [
        [
          SequenceChord('Am', 4, 0, strum: _commonStrum),
          SequenceChord('F', 4, 1, strum: _commonStrum),
        ],
        [
          SequenceChord('C', 4, 2, strum: _commonStrum),
          SequenceChord('G', 4, 3, strum: _commonStrum),
        ],
      ],
    ),
  ),
  _OnboardingPage(
    title: 'Seus acordes ficam guardados',
    body:
        'Acerte um acorde ${AppState.chordMasteryHits} vezes seguidas e ele '
        'entra na sua lista de aprendidos, na tela inicial.',
    illustration: (context) {
      final tokens = context.tokens;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, chord) in appState.chordsInModel.indexed)
            Container(
              width: 72,
              height: 84,
              decoration: BoxDecoration(
                color: tokens.cell,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 36, child: GuitarNeck(chord: chord)),
                        const SizedBox(height: 4),
                        ChordName(chord, size: 15),
                      ],
                    ),
                  ),
                  if (i < 3)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: tokens.correct,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
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
    final padding = welcomePadding(context);

    return Scaffold(
      body: SafeArea(
        child: welcomeColumn(
          Column(
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
                    ListeningBars(
                      color: Theme.of(context).colorScheme.primary,
                      level: const AlwaysStoppedAnimation(1.0),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text('ChordAI', style: textTheme.titleLarge),
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
                                  if (page.privacyLink) ...[
                                    const SizedBox(height: 4),
                                    InlineLink(
                                      'Política de privacidade',
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PrivacyScreen(),
                                            ),
                                          ),
                                    ),
                                  ],
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Semantics(
                    label: 'Página ${_page + 1} de ${_pages.length}',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  8,
                  padding.right,
                  16,
                ),
                child: isDesktop
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _continue,
                          style: welcomeButtonStyle,
                          child: Text(isLast ? 'Começar' : 'Continuar'),
                        ),
                      )
                    : FilledButton(
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
      ),
    );
  }
}
