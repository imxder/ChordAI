import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/page_parts.dart';
import 'app_shell.dart';
import 'guide_detail_screen.dart';
import 'tuner_screen.dart';
import '../theme/ph.dart';

class TuningCheckScreen extends StatelessWidget {
  const TuningCheckScreen({super.key});

  void _goHome(BuildContext context) {
    appState.completeOnboarding();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final padding = pagePadding(context, bottom: 0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
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
                        Row(
                          children: [
                            for (final (i, note) in [
                              'E',
                              'A',
                              'D',
                              'G',
                              'B',
                              'E',
                            ].indexed) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: context.tokens.cell,
                                    borderRadius: BorderRadius.circular(
                                      GlassTokens.radiusMd,
                                    ),
                                  ),
                                  child: Text(
                                    note,
                                    style: const TextStyle(
                                      fontFamily: fontChord,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            Semantics(
                              header: true,
                              child: Text(
                                'Seu violão está afinado?',
                                style: textTheme.headlineLarge,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Com as cordas afinadas o app reconhece os acordes com '
                              'mais precisão. Leva uns dois minutos.',
                              style: textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            InlineLink(
                              'Como afinar',
                              onPressed: () {
                                final topic = guideTopics.firstWhere(
                                  (t) => t.id == 'afinar',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GuideDetailScreen(topic: topic),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TunerScreen()),
                      );
                      if (context.mounted) _goHome(context);
                    },
                    icon: const Icon(Ph.microphoneFill, size: 20),
                    label: const Text('Afinar agora'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _goHome(context),
                    child: const Text('Já está afinado'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
