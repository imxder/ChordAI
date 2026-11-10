import 'package:chordai/models/chord_recognition_mode.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('instalação nova começa no aparelho', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.loadProgress();
    expect(state.chordRecognitionMode, ChordRecognitionMode.onDevice);
  });

  test('quem tinha servidor salvo passa pro aparelho uma única vez', () async {
    SharedPreferences.setMockInitialValues({
      'app_chord_recognition_mode': 'server',
    });
    final state = AppState();
    await state.loadProgress();
    expect(state.chordRecognitionMode, ChordRecognitionMode.onDevice);
  });

  test('depois da migração, escolher servidor de novo é respeitado', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.loadProgress();
    await state.setChordRecognitionMode(ChordRecognitionMode.server);

    final reopened = AppState();
    await reopened.loadProgress();
    expect(reopened.chordRecognitionMode, ChordRecognitionMode.server);
  });
}
