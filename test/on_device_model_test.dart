import 'package:chordai/models/chord_recognition_mode.dart';
import 'package:chordai/models/on_device_model.dart';
import 'package:chordai/models/score.dart';
import 'package:chordai/services/score_library.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> _chordsOf(Score score) => [for (final s in score.steps) s.chord];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('instalação nova usa só v3, sem o A', () async {
    final state = AppState();
    await state.loadProgress();
    expect(state.onDeviceModel, OnDeviceModel.v3);
    expect(state.chordsInModel, [
      'Em',
      'Am',
      'C',
      'G',
      'Dm',
      'F',
      'Bb',
      'Bdim',
    ]);
  });

  test('escolher o modelo novo mostra o A e fica salvo', () async {
    final state = AppState();
    await state.loadProgress();
    await state.setOnDeviceModel(OnDeviceModel.v3Meu);
    expect(state.chordsInModel, contains('A'));

    final reopened = AppState();
    await reopened.loadProgress();
    expect(reopened.onDeviceModel, OnDeviceModel.v3Meu);
    expect(reopened.chordsInModel, hasLength(9));
  });

  test('trocar de modelo e voltar', () async {
    final state = AppState();
    await state.loadProgress();
    await state.setOnDeviceModel(OnDeviceModel.v3Meu);
    await state.setOnDeviceModel(OnDeviceModel.v3);
    expect(state.chordsInModel, isNot(contains('A')));
  });

  test('A aprendido continua salvo mas só conta no modelo novo', () async {
    SharedPreferences.setMockInitialValues({
      'app_learned_chords': ['Em', 'Am', 'A'],
    });
    final state = AppState();
    await state.loadProgress();
    expect(state.learnedChordCount, 2);
    expect(state.nextChordToLearn, 'C');

    await state.setOnDeviceModel(OnDeviceModel.v3Meu);
    expect(state.learnedChordCount, 3);
    expect(state.isChordLearned('A'), isTrue);
  });

  test('no servidor a lista é a do v3', () async {
    final state = AppState();
    await state.loadProgress();
    await state.setOnDeviceModel(OnDeviceModel.v3Meu);
    await state.setChordRecognitionMode(ChordRecognitionMode.server);
    expect(state.chordsInModel, isNot(contains('A')));
  });

  test('"Todos os acordes" pula o A quando o modelo não reconhece', () async {
    final library = ScoreLibrary();
    Score todos(List<Score> all) =>
        all.firstWhere((s) => s.title == 'Todos os Acordes');

    final v3 = AppState();
    await v3.loadProgress();
    final semA = todos(
      await library.loadAll(onlyChords: v3.chordsInModel.toSet()),
    );
    expect(_chordsOf(semA), isNot(contains('A')));
    expect(semA.steps, hasLength(8));

    await v3.setOnDeviceModel(OnDeviceModel.v3Meu);
    final comA = todos(
      await library.loadAll(onlyChords: v3.chordsInModel.toSet()),
    );
    expect(_chordsOf(comA).first, 'A');
    expect(comA.steps, hasLength(9));
  });
}
