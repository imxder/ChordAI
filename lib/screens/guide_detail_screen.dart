import 'package:flutter/material.dart';

import '../models/guide_content.dart';
import 'tuner_screen.dart';

class GuideDetailScreen extends StatelessWidget {
  final GuideTopic topic;

  const GuideDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(topic.icon, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          for (final paragraph in topic.paragraphs) ...[
            Text(paragraph, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
          ],
          if (topic.highlight != null) ...[
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topic.highlight!,
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (topic.steps.isNotEmpty) ...[
            Text('Passo a passo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final entry in topic.steps.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
          ],
          if (topic.id == 'afinar') ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TunerScreen()),
                );
              },
              icon: const Icon(Icons.tune),
              label: const Text('Abrir afinador'),
            ),
          ],
        ],
      ),
    );
  }
}
