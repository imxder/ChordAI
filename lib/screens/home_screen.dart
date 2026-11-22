import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../theme/platform_style.dart';
import '../widgets/desktop_input.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import 'chord_detail_screen.dart';
import 'free_practice_screen.dart';
import 'guide_detail_screen.dart';
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
        detail: 'Do mais fácil ao mais difícil',
        onTap: onOpenChords,
      ),
      _HomeTile(
        icon: Ph.musicNotesDuotone,
        title: 'Tocar músicas',
        detail: 'Cifras com batida e metrônomo',
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
        const SizedBox(height: 4),
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
        _HomeSectionHeader(
          title: 'Guia do iniciante',
          action: 'Ver tudo',
          onAction: () => _push(context, const GuideListScreen()),
        ),
        _GuideCards(
          onOpen: (topic) => _push(context, GuideDetailScreen(topic: topic)),
        ),
        _HomeSectionHeader(
          title: 'Seus acordes',
          detail:
              '${appState.learnedChordCount} de ${appState.chordsInModel.length} aprendidos',
        ),
        _ChordMap(
          onOpen: (chord) => _push(
            context,
            ChordDetailScreen(serverUrl: appState.serverUrl, chord: chord),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(
            'A bolinha verde marca os acordes que você já aprendeu.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? detail;
  final String? action;
  final VoidCallback? onAction;

  const _HomeSectionHeader({
    required this.title,
    this.detail,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: textTheme.titleLarge),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          if (action != null)
            ClickCursor(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 32),
                onPressed: onAction,
                child: Text(
                  action!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideCards extends StatelessWidget {
  final ValueChanged<GuideTopic> onOpen;

  const _GuideCards({required this.onOpen});

  Widget _card(BuildContext context, GuideTopic topic) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${topic.title}. ${topic.summary}',
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onOpen(topic),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(
                    guideTopicIcons[topic.id] ?? Ph.bookOpenFill,
                    size: 34,
                  ),
                  const Spacer(),
                  Text(
                    topic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topic.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.textScalerOf(context).scale(140).clamp(140, 230);
    if (isDesktop) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 24) / 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final topic in guideTopics)
                SizedBox(
                  width: width,
                  height: height.toDouble(),
                  child: _card(context, topic),
                ),
            ],
          );
        },
      );
    }
    final screen = MediaQuery.sizeOf(context).width;
    final side = pagePadding(context).left;
    return SizedBox(
      height: height.toDouble(),
      child: OverflowBox(
        maxWidth: screen,
        minWidth: screen,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: side),
          itemCount: guideTopics.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) =>
              SizedBox(width: 172, child: _card(context, guideTopics[i])),
        ),
      ),
    );
  }
}

class _ChordMap extends StatelessWidget {
  final ValueChanged<String> onOpen;

  const _ChordMap({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final chords = appState.chordsInModel;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = constraints.maxWidth;
        final columns = width >= 560
            ? chords.length
            : (chords.length <= 8 ? 4 : 5);
        final size = min(
          (width - gap * (columns - 1)) / columns,
          isDesktop ? 96.0 : 120.0,
        );
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final chord in chords)
              _ChordMapItem(
                chord: chord,
                learned: appState.isChordLearned(chord),
                size: size,
                onTap: () => onOpen(chord),
              ),
          ],
        );
      },
    );
  }
}

class _ChordMapItem extends StatelessWidget {
  final String chord;
  final bool learned;
  final double size;
  final VoidCallback onTap;

  const _ChordMapItem({
    required this.chord,
    required this.learned,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final radius = BorderRadius.circular(GlassTokens.radiusLg);
    return Semantics(
      button: true,
      label: learned ? '$chord, aprendido' : chord,
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: learned ? colorScheme.primaryContainer : tokens.cell,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size * 1.25,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(size * 0.1),
                    child: FittedBox(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: size * 0.55,
                            child: GuitarNeck(chord: chord),
                          ),
                          SizedBox(height: size * 0.06),
                          ChordName(chord, size: size * 0.2),
                        ],
                      ),
                    ),
                  ),
                  if (learned)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: tokens.correct,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
