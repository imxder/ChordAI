class ChordStep {
  final String chord;
  final int beats;

  const ChordStep({required this.chord, this.beats = 4});

  factory ChordStep.fromJson(Map<String, dynamic> json) {
    return ChordStep(
      chord: json['chord'] as String,
      beats: json['beats'] as int? ?? 4,
    );
  }
}

class Score {
  final String title;
  final List<ChordStep> steps;

  const Score({required this.title, required this.steps});

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      title: json['title'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => ChordStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
