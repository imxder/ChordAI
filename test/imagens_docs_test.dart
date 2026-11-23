// Gera as imagens do app no Windows que estão em docs/imagens/ (README, Wiki
// e pôster). Não roda no flutter test normal: precisa da fonte Segoe UI de
// verdade, que só existe num Windows. Pra gerar de novo, num Windows:
//
//   flutter test test/imagens_docs_test.dart --update-goldens --dart-define=IMAGENS=true
import 'dart:io';

import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/models/theme_options.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/screens/recognize_screen.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/lyric_sheet_library.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:chordai/theme/ph.dart';
import 'package:chordai/widgets/desktop_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart' show appUnderTest, mockPlatform;

const _gerar = bool.fromEnvironment('IMAGENS');

/// Reconhecedor falso que "ouve" um Dó assim que começa, pra a imagem do
/// Reconhecer mostrar um acorde reconhecido.
class _OuveDo implements ChordRecognizer {
  @override
  bool get isRunning => true;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<List<InputDevice>> listInputDevices() async => const [];
  @override
  void selectDevice(InputDevice? device) {}
  @override
  Future<void> start({
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) async {
    onPrediction(
      const ChordPrediction(status: 'ok', chord: 'C', confidence: 0.92),
    );
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

Future<void> _fonte(String familia, List<String> arquivos) async {
  final loader = FontLoader(familia);
  for (final arquivo in arquivos) {
    final bytes = File(arquivo).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// As fontes de verdade: Segoe UI do Windows e as do app.
Future<void> _fontes() async {
  const windows = r'C:\Windows\Fonts';
  for (final familia in [
    'Segoe UI Variable Text',
    'Segoe UI Variable Display',
    'Segoe UI',
  ]) {
    await _fonte(familia, [
      '$windows\\segoeui.ttf',
      '$windows\\seguisb.ttf',
      '$windows\\segoeuib.ttf',
    ]);
  }
  await _fonte(fontChord, [
    'assets/fonts/IBMPlexMono-Regular.ttf',
    'assets/fonts/IBMPlexMono-SemiBold.ttf',
  ]);
  await _fonte('PhosphorRegular', ['assets/fonts/Phosphor.ttf']);
  await _fonte('PhosphorFill', ['assets/fonts/Phosphor-Fill.ttf']);
  await _fonte('PhosphorDuotone', ['assets/fonts/Phosphor-Duotone.ttf']);
}

const _abas = [
  DesktopDestination(
    icon: Ph.house,
    selectedIcon: Ph.houseFill,
    label: 'Início',
  ),
  DesktopDestination(
    icon: Ph.gauge,
    selectedIcon: Ph.gaugeFill,
    label: 'Afinador',
  ),
  DesktopDestination(
    icon: Ph.squaresFour,
    selectedIcon: Ph.squaresFourFill,
    label: 'Aprender acordes',
  ),
  DesktopDestination(
    icon: Ph.ear,
    selectedIcon: Ph.earFill,
    label: 'Reconhecer acorde',
  ),
  DesktopDestination(
    icon: Ph.bookOpen,
    selectedIcon: Ph.bookOpenFill,
    label: 'Guia do iniciante',
  ),
  DesktopDestination(
    icon: Ph.musicNotes,
    selectedIcon: Ph.musicNotesFill,
    label: 'Músicas',
  ),
  DesktopDestination(
    icon: Ph.gearSix,
    selectedIcon: Ph.gearSixFill,
    label: 'Configurações',
    bottom: true,
  ),
];

const _abaReconhecer = 3;
const _abaMusicas = 5;

/// Uma tela dentro da casca do computador, com a aba [aba] marcada.
Widget _naCasca(int aba, WidgetBuilder tela) => DesktopShell(
  destinations: _abas,
  pages: [for (var i = 0; i < _abas.length; i++) tela],
  rebuildOn: appState,
  selectedIndex: aba,
  onSelected: (_) {},
);

final _windows = TargetPlatformVariant.only(TargetPlatform.windows);

Future<void> _janela(
  WidgetTester tester,
  Widget home, {
  AppAppearance aparencia = AppAppearance.paper,
}) async {
  // 1200 x 800 (a janela inicial) com 1,5 de densidade, pra a imagem sair
  // nítida no pôster.
  tester.view.devicePixelRatio = 1.5;
  tester.view.physicalSize = const Size(1800, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(appUnderTest(home, appearance: aparencia));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 600)),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _salvar(WidgetTester tester, String nome) async {
  // Vários quadros: a troca de tela e a animação de entrada do acorde
  // precisam de frames seguidos pra terminar.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/imagens/windows_$nome.png'),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (_gerar) await _fontes();
  });

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  for (final (aparencia, sufixo) in [
    (AppAppearance.paper, ''),
    (AppAppearance.dark, '_escuro'),
  ]) {
    testWidgets(
      'início$sufixo',
      (tester) async {
        await _janela(tester, const AppShell(), aparencia: aparencia);
        await _salvar(tester, 'inicio$sufixo');
      },
      variant: _windows,
      skip: !_gerar,
    );

    testWidgets(
      'acordes$sufixo',
      (tester) async {
        await _janela(tester, const AppShell(), aparencia: aparencia);
        await tester.tap(find.byKey(const ValueKey('aba Aprender acordes')));
        await _salvar(tester, 'acordes$sufixo');
      },
      variant: _windows,
      skip: !_gerar,
    );

    testWidgets(
      'reconhecer$sufixo',
      (tester) async {
        await _janela(
          tester,
          _naCasca(
            _abaReconhecer,
            (_) => RecognizeScreen(recognizer: _OuveDo()),
          ),
          aparencia: aparencia,
        );
        await tester.tap(find.text('Ouvir'));
        await _salvar(tester, 'reconhecer$sufixo');
      },
      variant: _windows,
      skip: !_gerar,
    );

    testWidgets(
      'afinador$sufixo',
      (tester) async {
        await _janela(tester, const AppShell(), aparencia: aparencia);
        await tester.tap(find.text('Afinador'));
        await _salvar(tester, 'afinador$sufixo');
      },
      variant: _windows,
      skip: !_gerar,
    );

    testWidgets(
      'tocar junto$sufixo',
      (tester) async {
        final musica = (await tester.runAsync(
          () => LyricSheetLibrary().loadAll(),
        ))!.firstWhere((m) => m.title == 'Riptide');
        await _janela(
          tester,
          _naCasca(
            _abaMusicas,
            (_) => LyricPlayerScreen(sheet: musica, recognizer: _OuveDo()),
          ),
          aparencia: aparencia,
        );
        await _salvar(tester, 'tocar_junto$sufixo');
      },
      variant: _windows,
      skip: !_gerar,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }
}
