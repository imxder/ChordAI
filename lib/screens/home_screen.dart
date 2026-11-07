import 'package:flutter/material.dart';

import '../models/chord_difficulty.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/page_parts.dart';
import 'free_practice_screen.dart';
import 'guide_list_screen.dart';
import 'tuner_screen.dart';
import '../theme/ph.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenChords;
  final VoidCallback onOpenSongs;

  const HomeScreen({
    super.key,
    required this.onOpenChords,
    required this.onOpenSongs,
  });

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HomeTile(
        icon: Ph.guitarDuotone,
        title: 'Aprender acordes',
        detail:
            '${appState.learnedChordCount} de ${chordsByDifficulty.length} aprendidos',
        onTap: onOpenChords,
      ),
      _HomeTile(
        icon: Ph.musicNotesDuotone,
        title: 'Tocar músicas',
        detail: 'Cifra com letra e metrônomo',
        onTap: onOpenSongs,
      ),
      _HomeTile(
        icon: Ph.gaugeDuotone,
        title: 'Afinador',
        detail: appState.activeTuningName,
        onTap: () => _push(context, const TunerScreen()),
      ),
      _HomeTile(
        icon: Ph.earDuotone,
        title: 'Reconhecer acorde',
        detail: 'O app diz qual acorde ouviu',
        onTap: () =>
            _push(context, FreePracticeScreen(serverUrl: appState.serverUrl)),
      ),
    ];

    return IosPage(
      title: 'ChordAI',
      largeTitle: true,
      children: [
        GroupedSection(
          top: 4,
          dividerIndent: 58,
          children: [
            GroupedRow(
              leading: const IconBadge(Ph.bookOpenFill),
              title: 'Guia do iniciante',
              subtitle: 'Acessórios, regulagem, como afinar e mais',
              onTap: () => _push(context, const GuideListScreen()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var row = 0; row < tiles.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[row]),
                const SizedBox(width: 12),
                Expanded(child: tiles[row + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  final PhDuotone icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 140),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: DuotoneIcon(
                        icon,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  Text(title, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(detail, style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
