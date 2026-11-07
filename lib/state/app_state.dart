import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/app_theme.dart';
import '../models/chord_difficulty.dart';
import '../models/chord_prediction.dart';
import '../models/score.dart';
import '../models/tuner_note.dart';
import '../models/tuning_preset.dart';

enum SessionStatus { idle, running, paused }

class AppState extends ChangeNotifier {
  static const _totalCorrectKey = 'app_total_correct';
  static const _totalSessionsKey = 'app_total_sessions';
  static const _lastPracticeDateKey = 'app_last_practice_date';
  static const _selectedThemeKey = 'app_selected_theme';
  static const _learnedChordsKey = 'app_learned_chords';
  static const _serverUrlKey = 'app_server_url';
  static const _hasOnboardedKey = 'app_has_onboarded';
  static const _tuningIdKey = 'app_tuning_id';
  static const _customTuningKey = 'app_custom_tuning';
  static const _lyricFontScaleKey = 'app_lyric_font_scale';
  static const _showGuitarNeckKey = 'app_show_guitar_neck';
  static const _autoScrollKey = 'app_auto_scroll';
  static const _appearanceKey = 'app_appearance';
  static const _profileNameKey = 'app_profile_name';
  static const _profileExperienceKey = 'app_profile_experience';

  // Quem instalou uma versão antiga ainda tem esses dados salvos no aparelho.
  static const _removedKeys = [
    'app_xp',
    'app_coins',
    'app_correct_chords',
    'app_streak_days',
    'app_unlocked_achievements',
    'app_daily_challenge_date',
    'app_daily_challenge_progress',
    'app_daily_challenge_completed',
    'app_unlocked_themes',
    'app_last_song_title',
    'app_last_song_chord_count',
  ];

  static const int chordMasteryHits = 3;

  SessionStatus sessionStatus = SessionStatus.idle;
  Score? currentScore;
  int currentStepIndex = 0;
  ChordPrediction? lastPrediction;
  int sessionHits = 0;
  int sessionMisses = 0;

  int totalCorrectChords = 0;
  int totalSessionsCompleted = 0;
  String? lastPracticeDateIso;

  int selectedThemeIndex = 0;
  AppAppearance appearance = AppAppearance.paper;

  Set<String> learnedChords = {};

  String profileName = '';
  String? profileExperience;

  String serverUrl = defaultServerUrl;
  bool hasCompletedOnboarding = false;
  String tuningId = 'padrao';
  List<String>? customTuningNotes;

  List<TunerNote> get activeTuning {
    if (tuningId == customTuningId && customTuningNotes != null) {
      return buildTuning(customTuningNotes!);
    }
    final preset = tuningPresets.firstWhere(
      (p) => p.id == tuningId,
      orElse: () => tuningPresets.first,
    );
    return preset.strings;
  }

  String get activeTuningName {
    if (tuningId == customTuningId) return 'Personalizada';
    return tuningPresets
        .firstWhere((p) => p.id == tuningId, orElse: () => tuningPresets.first)
        .name;
  }

  String? get nextChordToLearn {
    for (final chord in chordsByDifficulty) {
      if (!learnedChords.contains(chord)) return chord;
    }
    return null;
  }

  int get learnedChordCount =>
      chordsByDifficulty.where(learnedChords.contains).length;

  Future<void> setTuningPreset(String id) async {
    tuningId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tuningIdKey, id);
    notifyListeners();
  }

  Future<void> setCustomTuning(List<String> notes) async {
    tuningId = customTuningId;
    customTuningNotes = notes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tuningIdKey, customTuningId);
    await prefs.setStringList(_customTuningKey, notes);
    notifyListeners();
  }

  double lyricFontScale = 1.0;
  bool showGuitarNeckInPlayer = true;
  bool autoScrollInPlayer = true;

  Future<void> setLyricFontScale(double value) async {
    lyricFontScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lyricFontScaleKey, value);
    notifyListeners();
  }

  Future<void> setShowGuitarNeckInPlayer(bool value) async {
    showGuitarNeckInPlayer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showGuitarNeckKey, value);
    notifyListeners();
  }

  Future<void> setAutoScrollInPlayer(bool value) async {
    autoScrollInPlayer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScrollKey, value);
    notifyListeners();
  }

  Future<void> setAppearance(AppAppearance value) async {
    appearance = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appearanceKey, value.name);
  }

  Future<void> setProfile({required String name, String? experience}) async {
    profileName = name.trim();
    profileExperience = experience;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, profileName);
    if (experience == null) {
      await prefs.remove(_profileExperienceKey);
    } else {
      await prefs.setString(_profileExperienceKey, experience);
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasOnboardedKey, true);
    notifyListeners();
  }

  Future<void> setServerUrl(String value) async {
    serverUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, value);
    notifyListeners();
  }

  ChordStep? get currentStep {
    final score = currentScore;
    if (score == null || currentStepIndex >= score.steps.length) return null;
    return score.steps[currentStepIndex];
  }

  bool isChordLearned(String chord) => learnedChords.contains(chord);

  /// Retorna true só na vez em que o acorde passa a contar como aprendido.
  bool registerChordHits(String chord, int consecutiveHits) {
    if (learnedChords.contains(chord)) return false;
    if (consecutiveHits < chordMasteryHits) return false;
    learnedChords.add(chord);
    _markPracticedToday();
    _saveProgress();
    notifyListeners();
    return true;
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _removedKeys) {
      await prefs.remove(key);
    }
    totalCorrectChords = prefs.getInt(_totalCorrectKey) ?? 0;
    totalSessionsCompleted = prefs.getInt(_totalSessionsKey) ?? 0;
    lastPracticeDateIso = prefs.getString(_lastPracticeDateKey);
    final savedTheme = prefs.getInt(_selectedThemeKey) ?? 0;
    selectedThemeIndex = savedTheme < appThemeOptions.length ? savedTheme : 0;
    learnedChords = (prefs.getStringList(_learnedChordsKey) ?? []).toSet();
    profileName = prefs.getString(_profileNameKey) ?? '';
    profileExperience = prefs.getString(_profileExperienceKey);
    serverUrl = prefs.getString(_serverUrlKey) ?? defaultServerUrl;
    hasCompletedOnboarding = prefs.getBool(_hasOnboardedKey) ?? false;
    tuningId = prefs.getString(_tuningIdKey) ?? 'padrao';
    customTuningNotes = prefs.getStringList(_customTuningKey);
    lyricFontScale = prefs.getDouble(_lyricFontScaleKey) ?? 1.0;
    showGuitarNeckInPlayer = prefs.getBool(_showGuitarNeckKey) ?? true;
    autoScrollInPlayer = prefs.getBool(_autoScrollKey) ?? true;
    final savedAppearance = prefs.getString(_appearanceKey);
    appearance = AppAppearance.values.firstWhere(
      (a) => a.name == savedAppearance,
      orElse: () => AppAppearance.paper,
    );
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalCorrectKey, totalCorrectChords);
    await prefs.setInt(_totalSessionsKey, totalSessionsCompleted);
    if (lastPracticeDateIso != null) {
      await prefs.setString(_lastPracticeDateKey, lastPracticeDateIso!);
    }
    await prefs.setInt(_selectedThemeKey, selectedThemeIndex);
    await prefs.setStringList(_learnedChordsKey, learnedChords.toList());
  }

  void selectTheme(int index) {
    if (index < 0 || index >= appThemeOptions.length) return;
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
    if (matched) {
      sessionHits++;
      totalCorrectChords++;
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
      totalSessionsCompleted++;
      _markPracticedToday();
      _saveProgress();
      stopSession();
    }
  }

  void _markPracticedToday() {
    lastPracticeDateIso = _dateOnlyIso(DateTime.now());
  }

  String _dateOnlyIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

final appState = AppState();
