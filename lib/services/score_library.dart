import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/score.dart';

class ScoreLibrary {
  static const List<String> _assetPaths = [
    'assets/scores/progressao_basica.json',
    'assets/scores/todos_os_acordes.json',
    'assets/scores/all_too_well.json',
  ];

  Future<List<Score>> loadAll() async {
    final scores = <Score>[];
    for (final path in _assetPaths) {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      scores.add(Score.fromJson(json));
    }
    return scores;
  }
}
