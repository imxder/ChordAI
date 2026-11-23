/// Um acorde de uma sequência e quantos tempos ele dura. O tocar junto também
/// usa, pra cada acorde da música.
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

/// Uma sequência de acordes pra treinar trocas com metrônomo (a tela
/// "Sequências de acordes", com os arquivos de assets/scores/). As músicas do
/// tocar junto são outra coisa: o LyricSheet e o UserSong.
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
