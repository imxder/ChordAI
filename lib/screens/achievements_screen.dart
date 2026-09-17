import 'package:flutter/material.dart';

import '../models/app_theme.dart';
import '../models/gamification.dart';
import '../state/app_state.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appState.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = appState.dailyChallenge;
    final progress = appState.dailyChallengeProgress / challenge.targetCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Progresso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nível ${appState.level}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('${appState.xp} XP  •  ${appState.coins} moedas  •  '
                      '${appState.streakDays} dias seguidos'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Desafio de hoje', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(challenge.title),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress.clamp(0, 1)),
                  const SizedBox(height: 4),
                  Text(
                    appState.dailyChallengeCompleted
                        ? 'Concluído!'
                        : '${appState.dailyChallengeProgress}/${challenge.targetCount}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Conquistas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...allAchievements.map((a) {
            final unlocked = appState.unlockedAchievementIds.contains(a.id);
            return Card(
              child: ListTile(
                leading: Icon(
                  unlocked ? Icons.emoji_events : Icons.lock_outline,
                  color: unlocked ? Colors.amber.shade700 : Colors.grey,
                ),
                title: Text(a.title),
                subtitle: Text(a.description),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text('Loja de temas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...appThemeOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final unlocked = appState.unlockedThemeIndices.contains(index);
            final selected = appState.selectedThemeIndex == index;
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: option.color),
                title: Text(option.name),
                subtitle: Text(unlocked ? 'Desbloqueado' : '${option.cost} moedas'),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : FilledButton(
                        onPressed: () {
                          if (unlocked) {
                            appState.selectTheme(index);
                          } else if (!appState.buyTheme(index, option.cost)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Moedas insuficientes')),
                            );
                          } else {
                            appState.selectTheme(index);
                          }
                        },
                        child: Text(unlocked ? 'Usar' : 'Comprar'),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
