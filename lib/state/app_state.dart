import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/chord_prediction.dart';
import '../models/gamification.dart';
import '../models/score.dart';

enum SessionStatus { idle, running, paused }

class AppState extends ChangeNotifier {
  static const _xpKey = 'app_xp';
  static const _coinsKey = 'app_coins';
  static const _totalCorrectKey = 'app_total_correct';
  static const _totalSessionsKey = 'app_total_sessions';
  static const _correctChordsKey = 'app_correct_chords';
  static const _lastPracticeDateKey = 'app_last_practice_date';
  static const _streakDaysKey = 'app_streak_days';
  static const _unlockedAchievementsKey = 'app_unlocked_achievements';
  static const _dailyChallengeDateKey = 'app_daily_challenge_date';
  static const _dailyChallengeProgressKey = 'app_daily_challenge_progress';
  static const _dailyChallengeCompletedKey = 'app_daily_challenge_completed';
  static const _unlockedThemesKey = 'app_unlocked_themes';
  static const _selectedThemeKey = 'app_selected_theme';
  static const _learnedChordsKey = 'app_learned_chords';
  static const _serverUrlKey = 'app_server_url';

  static const int chordMasteryStreak = 3;

  SessionStatus sessionStatus = SessionStatus.idle;
  Score? currentScore;
  int currentStepIndex = 0;
  ChordPrediction? lastPrediction;
  int sessionHits = 0;
  int sessionMisses = 0;

  int xp = 0;
  int coins = 0;
  int totalCorrectChords = 0;
  int totalSessionsCompleted = 0;
  Set<String> correctChords = {};
  String? lastPracticeDateIso;
  int streakDays = 0;
  Set<String> unlockedAchievementIds = {};

  String? dailyChallengeDateIso;
  int dailyChallengeProgress = 0;
  bool dailyChallengeCompleted = false;

  Set<int> unlockedThemeIndices = {0};
  int selectedThemeIndex = 0;

  Set<String> learnedChords = {};

  String serverUrl = defaultServerUrl;

  Future<void> setServerUrl(String value) async {
    serverUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, value);
    notifyListeners();
  }

  final List<Achievement> pendingUnlocked = [];

  final List<String> pendingChordRewards = [];

  int get level => 1 + (xp ~/ 100);

  DailyChallenge get dailyChallenge =>
      dailyChallengesByWeekday[DateTime.now().weekday]!;

  ChordStep? get currentStep {
    final score = currentScore;
    if (score == null || currentStepIndex >= score.steps.length) return null;
    return score.steps[currentStepIndex];
  }

  List<Achievement> consumePendingUnlocked() {
    final list = List<Achievement>.from(pendingUnlocked);
    pendingUnlocked.clear();
    return list;
  }

  List<String> consumePendingChordRewards() {
    final list = List<String>.from(pendingChordRewards);
    pendingChordRewards.clear();
    return list;
  }

  bool isChordLearned(String chord) => learnedChords.contains(chord);

  void registerChordStreak(String chord, int streak) {
    if (learnedChords.contains(chord)) return;
    if (streak < chordMasteryStreak) return;
    learnedChords.add(chord);
    pendingChordRewards.add(chord);
    xp += 25;
    coins += 10;
    _saveProgress();
    notifyListeners();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    xp = prefs.getInt(_xpKey) ?? 0;
    coins = prefs.getInt(_coinsKey) ?? 0;
    totalCorrectChords = prefs.getInt(_totalCorrectKey) ?? 0;
    totalSessionsCompleted = prefs.getInt(_totalSessionsKey) ?? 0;
    correctChords = (prefs.getStringList(_correctChordsKey) ?? []).toSet();
    lastPracticeDateIso = prefs.getString(_lastPracticeDateKey);
    streakDays = prefs.getInt(_streakDaysKey) ?? 0;
    unlockedAchievementIds =
        (prefs.getStringList(_unlockedAchievementsKey) ?? []).toSet();
    dailyChallengeDateIso = prefs.getString(_dailyChallengeDateKey);
    dailyChallengeProgress = prefs.getInt(_dailyChallengeProgressKey) ?? 0;
    dailyChallengeCompleted =
        prefs.getBool(_dailyChallengeCompletedKey) ?? false;
    unlockedThemeIndices =
        (prefs.getStringList(_unlockedThemesKey) ?? ['0'])
            .map(int.parse)
            .toSet();
    selectedThemeIndex = prefs.getInt(_selectedThemeKey) ?? 0;
    learnedChords = (prefs.getStringList(_learnedChordsKey) ?? []).toSet();
    serverUrl = prefs.getString(_serverUrlKey) ?? defaultServerUrl;
    _ensureDailyChallengeFresh();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, xp);
    await prefs.setInt(_coinsKey, coins);
    await prefs.setInt(_totalCorrectKey, totalCorrectChords);
    await prefs.setInt(_totalSessionsKey, totalSessionsCompleted);
    await prefs.setStringList(_correctChordsKey, correctChords.toList());
    if (lastPracticeDateIso != null) {
      await prefs.setString(_lastPracticeDateKey, lastPracticeDateIso!);
    }
    await prefs.setInt(_streakDaysKey, streakDays);
    await prefs.setStringList(
      _unlockedAchievementsKey,
      unlockedAchievementIds.toList(),
    );
    if (dailyChallengeDateIso != null) {
      await prefs.setString(_dailyChallengeDateKey, dailyChallengeDateIso!);
    }
    await prefs.setInt(_dailyChallengeProgressKey, dailyChallengeProgress);
    await prefs.setBool(_dailyChallengeCompletedKey, dailyChallengeCompleted);
    await prefs.setStringList(
      _unlockedThemesKey,
      unlockedThemeIndices.map((i) => i.toString()).toList(),
    );
    await prefs.setInt(_selectedThemeKey, selectedThemeIndex);
    await prefs.setStringList(_learnedChordsKey, learnedChords.toList());
  }

  bool buyTheme(int index, int cost) {
    if (unlockedThemeIndices.contains(index)) return false;
    if (coins < cost) return false;
    coins -= cost;
    unlockedThemeIndices.add(index);
    _saveProgress();
    notifyListeners();
    return true;
  }

  void selectTheme(int index) {
    if (!unlockedThemeIndices.contains(index)) return;
    selectedThemeIndex = index;
    _saveProgress();
    notifyListeners();
  }

  void startSession(Score score) {
    currentScore = score;
    currentStepIndex = 0;
    sessionHits = 0;
    sessionMisses = 0;
    sessionStatus = SessionStatus.running;
    notifyListeners();
  }

  void pauseSession() {
    if (sessionStatus != SessionStatus.running) return;
    sessionStatus = SessionStatus.paused;
    notifyListeners();
  }

  void resumeSession() {
    if (sessionStatus != SessionStatus.paused) return;
    sessionStatus = SessionStatus.running;
    notifyListeners();
  }

  void stopSession() {
    sessionStatus = SessionStatus.idle;
    currentScore = null;
    currentStepIndex = 0;
    notifyListeners();
  }

  void updatePrediction(ChordPrediction prediction) {
    lastPrediction = prediction;
    notifyListeners();
  }

  void advanceStep({required bool matched}) {
    _ensureDailyChallengeFresh();
    final step = currentStep;

    if (matched) {
      sessionHits++;
      totalCorrectChords++;
      xp += 10;
      if (step != null) {
        correctChords.add(step.chord);
        if (!dailyChallengeCompleted &&
            step.chord.toLowerCase() == dailyChallenge.targetChord.toLowerCase()) {
          dailyChallengeProgress++;
          if (dailyChallengeProgress >= dailyChallenge.targetCount) {
            dailyChallengeCompleted = true;
            coins += 15;
            xp += 30;
          }
        }
      }
    } else {
      sessionMisses++;
    }

    final score = currentScore;
    if (score == null) {
      _saveProgress();
      return;
    }

    if (currentStepIndex < score.steps.length - 1) {
      currentStepIndex++;
      _saveProgress();
      notifyListeners();
    } else {
      coins += 5;
      totalSessionsCompleted++;
      _updateStreak();
      final perfectSession = sessionMisses == 0 && sessionHits > 0;
      _checkAchievements(perfectSession: perfectSession);
      _saveProgress();
      stopSession();
    }
  }

  void _ensureDailyChallengeFresh() {
    final today = _dateOnlyIso(DateTime.now());
    if (dailyChallengeDateIso != today) {
      dailyChallengeDateIso = today;
      dailyChallengeProgress = 0;
      dailyChallengeCompleted = false;
    }
  }

  void _updateStreak() {
    final today = DateTime.now();
    final todayIso = _dateOnlyIso(today);
    if (lastPracticeDateIso == todayIso) return;

    final yesterdayIso = _dateOnlyIso(today.subtract(const Duration(days: 1)));
    streakDays = (lastPracticeDateIso == yesterdayIso) ? streakDays + 1 : 1;
    lastPracticeDateIso = todayIso;
  }

  void _checkAchievements({required bool perfectSession}) {
    final metConditions = <String, bool>{
      'first_correct_chord': totalCorrectChords >= 1,
      'persistent_musician_3': streakDays >= 3,
      'persistent_musician_7': streakDays >= 7,
      'rhythm_master': totalSessionsCompleted >= 5,
      'chord_explorer': correctChords.length >= 8,
      'perfect_session': perfectSession,
      'century_club': totalCorrectChords >= 100,
      'level_5': level >= 5,
    };
    for (final achievement in allAchievements) {
      if (unlockedAchievementIds.contains(achievement.id)) continue;
      if (metConditions[achievement.id] == true) {
        unlockedAchievementIds.add(achievement.id);
        pendingUnlocked.add(achievement);
      }
    }
  }

  String _dateOnlyIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

final appState = AppState();
