import 'package:chordai/models/on_device_model.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('quem tinha o modo servidor abre no aparelho sem perder nada', () async {
    SharedPreferences.setMockInitialValues({
      'app_chord_recognition_mode': 'server',
      'app_on_device_default_migrated': true,
      'app_server_url': 'http://192.168.0.10:5000',
      'app_profile_name': 'Alexandre',
      'app_profile_experience': 'Iniciante',
      'app_learned_chords': ['Em', 'Am', 'C'],
      'app_total_correct': 42,
      'app_total_sessions': 7,
      'app_selected_theme': 3,
      'app_appearance': 'dark',
      'app_on_device_model': 'v3Meu',
      'app_minhas_musicas': '{"versao":1,"musicas":[]}',
    });
    final state = AppState();
    await state.loadProgress();

    expect(state.learnedChords, {'Em', 'Am', 'C'});
    expect(state.selectedThemeIndex, 3);
    expect(state.onDeviceModel, OnDeviceModel.v3Meu);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('app_server_url'), isFalse);
    expect(prefs.containsKey('app_chord_recognition_mode'), isFalse);
    expect(prefs.containsKey('app_on_device_default_migrated'), isFalse);
    expect(prefs.getString('app_minhas_musicas'), isNotNull);
    expect(prefs.getStringList('app_learned_chords'), ['Em', 'Am', 'C']);
  });

  test('instalação nova não grava nada do modo servidor', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.loadProgress();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.contains('server') || k.contains('mode')),
      isEmpty,
    );
    expect(state.onDeviceModel, OnDeviceModel.v3);
  });
}
