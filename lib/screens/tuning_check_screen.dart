import 'package:flutter/material.dart';

import '../main.dart' show HomePage;
import '../state/app_state.dart';
import 'guide_detail_screen.dart';
import 'tuner_screen.dart';
import '../models/guide_content.dart';

class TuningCheckScreen extends StatelessWidget {
  const TuningCheckScreen({super.key});

  void _goHome(BuildContext context) {
    appState.completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.tune,
                size: 96,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Seu violão está afinado?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Um violão afinado facilita muito o reconhecimento dos '
                'acordes e o aprendizado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TunerScreen()),
                  );
                  if (context.mounted) _goHome(context);
                },
                icon: const Icon(Icons.mic),
                label: const Text('Afinar agora'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _goHome(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Já está afinado'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  final topic = guideTopics.firstWhere((t) => t.id == 'afinar');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GuideDetailScreen(topic: topic)),
                  );
                },
                child: const Text('Como afinar?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
