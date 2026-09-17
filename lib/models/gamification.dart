class Achievement {
  final String id;
  final String title;
  final String description;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
  });
}

const List<Achievement> allAchievements = [
  Achievement(
    id: 'first_correct_chord',
    title: 'Primeiro Acorde Perfeito',
    description: 'Acerte seu primeiro acorde numa sessão de prática.',
  ),
  Achievement(
    id: 'persistent_musician_3',
    title: 'Músico Persistente',
    description: 'Pratique 3 dias seguidos.',
  ),
  Achievement(
    id: 'persistent_musician_7',
    title: 'Uma Semana Inteira!',
    description: 'Pratique 7 dias seguidos.',
  ),
  Achievement(
    id: 'rhythm_master',
    title: 'Mestre do Ritmo',
    description: 'Complete 5 sessões de prática com o metrônomo.',
  ),
  Achievement(
    id: 'chord_explorer',
    title: 'Explorador de Acordes',
    description: 'Acerte todos os 8 acordes reconhecidos pelo app.',
  ),
  Achievement(
    id: 'perfect_session',
    title: 'Sessão Perfeita',
    description: 'Complete uma sessão sem errar nenhum acorde.',
  ),
  Achievement(
    id: 'century_club',
    title: 'Clube dos 100',
    description: 'Acerte 100 acordes no total.',
  ),
  Achievement(
    id: 'level_5',
    title: 'Nível 5',
    description: 'Alcance o nível 5.',
  ),
];

class DailyChallenge {
  final String title;
  final String targetChord;
  final int targetCount;

  const DailyChallenge({
    required this.title,
    required this.targetChord,
    required this.targetCount,
  });
}

const Map<int, DailyChallenge> dailyChallengesByWeekday = {
  1: DailyChallenge(title: 'Domine o Acorde C', targetChord: 'C', targetCount: 10),
  2: DailyChallenge(title: 'Domine o Acorde G', targetChord: 'G', targetCount: 10),
  3: DailyChallenge(title: 'Domine o Acorde Am', targetChord: 'Am', targetCount: 10),
  4: DailyChallenge(title: 'Domine o Acorde F', targetChord: 'F', targetCount: 10),
  5: DailyChallenge(title: 'Domine o Acorde Dm', targetChord: 'Dm', targetCount: 10),
  6: DailyChallenge(title: 'Domine o Acorde Em', targetChord: 'Em', targetCount: 10),
  7: DailyChallenge(title: 'Domine o Acorde Bb', targetChord: 'Bb', targetCount: 10),
};
