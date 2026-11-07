import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/page_parts.dart';
import 'tuner_screen.dart';
import '../theme/ph.dart';

class GuideDetailScreen extends StatelessWidget {
  final GuideTopic topic;

  const GuideDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return IosPage(
      title: topic.title,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final paragraph in topic.paragraphs) ...[
                Text(paragraph, style: textTheme.bodyLarge),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (topic.highlight != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Ph.lightbulbFill, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(topic.highlight!, style: textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        if (topic.steps.isNotEmpty)
          GroupedSection(
            header: 'Passo a passo',
            dividerIndent: 52,
            children: [
              for (final (index, step) in topic.steps.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: fontChord,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step, style: textTheme.bodyLarge)),
                    ],
                  ),
                ),
            ],
          ),
        if (topic.id == 'afinar') ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const TunerScreen()));
            },
            icon: const Icon(Ph.gaugeFill, size: 20),
            label: const Text('Abrir o afinador'),
          ),
        ],
      ],
    );
  }
}
