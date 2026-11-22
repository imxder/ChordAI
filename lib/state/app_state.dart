import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme.dart';
import '../models/chord_difficulty.dart';
import '../models/chord_model_info.dart';
import '../models/chord_prediction.dart';
import '../models/on_device_model.dart';
import '../models/score.dart';
import '../models/tuner_note.dart';
import '../models/tuning_preset.dart';

enum SessionStatus { idle, running, paused }

class AppState extends ChangeNotifier {
  static const _selectedThemeKey = 'app_selected_theme';
  static const _learnedChordsKey = 'app_learned_chords';
  static const _hasOnboardedKey = 'app_has_onboarded';
  static const _alwaysOnboardingKey = 'app_always_onboarding';
  static const _tuningIdKey = 'app_tuning_id';
  static const _customTuningKey = 'app_custom_tuning';
  static const _lyricFontScaleKey = 'app_lyric_font_scale';
  static const _strumArrowScaleKey = 'app_strum_arrow_scale';
  static const _showGuitarNeckKey = 'app_show_guitar_neck';
  static const _autoScrollKey = 'app_auto_scroll';
  static const _appearanceKey = 'app_appearance';
  static const _guideReadKey = 'app_guide_read';
  // Chaves do modo servidor, que saiu do app. Só servem pra apagar o que
  // ficou salvo de versões antigas (o endereço era o IP do computador).
  static const _oldServerKeys = [
    'app_server_url',
    'app_chord_recognition_mode',
    'app_on_device_default_migrated',
  ];
  static const _onDeviceModelKey = 'app_on_device_model';
  static const _playAlongWaitsKey = 'app_play_along_waits_for_me';
  static const _inputDeviceIdKey = 'app_input_device_id';

  // Quem instalou uma versão antiga ainda tem esses dados salvos no aparelho.
  static const _removedKeys = [
    'app_total_correct',
    'app_total_sessions',
    'app_last_practice_date',
    'app_profile_name',
    'app_profile_experience',
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

  int selectedThemeIndex = 0;
  AppAppearance appearance = AppAppearance.paper;

  Set<String> learnedChords = {};

  Set<String> readGuideTopics = {};

  OnDeviceModel onDeviceModel = OnDeviceModel.v3;
  Set<String>? _modelChords;
  bool hasCompletedOnboarding = false;
  bool alwaysShowOnboarding = false;
  bool showOnboardingAtLaunch = true;
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
        .name
        .replaceFirst(RegExp(r'\s*\(.*\)$'), '');
  }

  List<String> get chordsInModel {
    final chords = _modelChords;
    if (chords == null) return chordsByDifficulty;
    return chordsByDifficulty.where(chords.contains).toList();
  }

  static final Map<OnDeviceModel, Set<String>> _chordsByModel = {};

  Future<void> _refreshModelChords() async {
    final model = onDeviceModel;
    _modelChords = _chordsByModel[model] ??= (await ChordModelInfo.load(
      model.assetDir,
    )).chords;
  }

  String? get nextChordToLearn {
    for (final chord in chordsInModel) {
      if (!learnedChords.contains(chord)) return chord;
    }
    return null;
  }

  int get learnedChordCount =>
      chordsInModel.where(learnedChords.contains).length;

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
  double strumArrowScale = 1.0;
  bool showGuitarNeckInPlayer = true;
  bool autoScrollInPlayer = true;
  bool playAlongWaitsForMe = false;

  /// Entrada de áudio escolhida no Windows ou no Mac (ver
  /// services/audio_input.dart). `null` é a entrada padrão do sistema, e no
  /// celular fica sempre assim.
  String? inputDeviceId;

  Future<void> setStrumArrowScale(double value) async {
    strumArrowScale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_strumArrowScaleKey, value);
  }

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

  Future<void> setAlwaysShowOnboarding(bool value) async {
    alwaysShowOnboarding = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alwaysOnboardingKey, value);
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
    showOnboardingAtLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasOnboardedKey, true);
    notifyListeners();
  }

  Future<void> setOnDeviceModel(OnDeviceModel model) async {
    onDeviceModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onDeviceModelKey, model.name);
    await _refreshModelChords();
    notifyListeners();
  }

  ChordStep? get currentStep {
    final score = currentScore;
    if (score == null || currentStepIndex >= score.steps.length) return null;
    return score.steps[currentStepIndex];
  }

  bool isChordLearned(String chord) => learnedChords.contains(chord);

  Future<void> markGuideTopicRead(String id) async {
    if (!readGuideTopics.add(id)) return;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_guideReadKey, readGuideTopics.toList());
  }

  /// Retorna true só na vez em que o acorde passa a contar como aprendido.
  bool registerChordHits(String chord, int consecutiveHits) {
    if (learnedChords.contains(chord)) return false;
    if (consecutiveHits < chordMasteryHits) return false;
    learnedChords.add(chord);
    _saveProgress();
    notifyListeners();
    return true;
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _removedKeys) {
      await prefs.remove(key);
    }
    final savedTheme = prefs.getInt(_selectedThemeKey) ?? 0;
    selectedThemeIndex = savedTheme < appThemeOptions.length ? savedTheme : 0;
    learnedChords = (prefs.getStringList(_learnedChordsKey) ?? []).toSet();
    readGuideTopics = (prefs.getStringList(_guideReadKey) ?? []).toSet();
    for (final key in _oldServerKeys) {
      if (prefs.containsKey(key)) await prefs.remove(key);
    }
    final savedModel = prefs.getString(_onDeviceModelKey);
    onDeviceModel = OnDeviceModel.values.firstWhere(
      (m) => m.name == savedModel,
      orElse: () => OnDeviceModel.v3,
    );
    await _refreshModelChords();
    hasCompletedOnboarding = prefs.getBool(_hasOnboardedKey) ?? false;
    alwaysShowOnboarding = prefs.getBool(_alwaysOnboardingKey) ?? false;
    showOnboardingAtLaunch = !hasCompletedOnboarding || alwaysShowOnboarding;
    tuningId = prefs.getString(_tuningIdKey) ?? 'padrao';
    customTuningNotes = prefs.getStringList(_customTuningKey);
    lyricFontScale = prefs.getDouble(_lyricFontScaleKey) ?? 1.0;
    strumArrowScale = prefs.getDouble(_strumArrowScaleKey) ?? 1.0;
    showGuitarNeckInPlayer = prefs.getBool(_showGuitarNeckKey) ?? true;
    autoScrollInPlayer = prefs.getBool(_autoScrollKey) ?? true;
    playAlongWaitsForMe = prefs.getBool(_playAlongWaitsKey) ?? false;
    inputDeviceId = prefs.getString(_inputDeviceIdKey);
    final savedAppearance = prefs.getString(_appearanceKey);
    appearance = AppAppearance.values.firstWhere(
      (a) => a.name == savedAppearance,
      orElse: () => AppAppearance.paper,
    );
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> setPlayAlongWaitsForMe(bool value) async {
    playAlongWaitsForMe = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_playAlongWaitsKey, value);
  }

  /// `null` volta pra entrada padrão do sistema.
  Future<void> setInputDeviceId(String? id) async {
    inputDeviceId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_inputDeviceIdKey);
    } else {
      await prefs.setString(_inputDeviceIdKey, id);
    }
  }

  void setSessionStep(int index) {
    if (index == currentStepIndex) return;
    currentStepIndex = index;
    notifyListeners();
  }

  void recordChordResult({required bool hit}) {
    if (hit) {
      sessionHits++;
    } else {
      sessionMisses++;
    }
    _saveProgress();
    notifyListeners();
  }

  void updatePrediction(ChordPrediction prediction) {
    lastPrediction = prediction;
    notifyListeners();
  }

  void advanceStep({required bool matched}) {
    if (matched) {
      sessionHits++;
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
      stopSession();
    }
  }
}

final appState = AppState();
