import 'package:chordai/screens/recognition_settings_screen.dart';
import 'package:chordai/services/audio_input.dart';
import 'package:chordai/state/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'test_helpers.dart';

const _entradas = [
  {'id': 'mic-pc', 'label': 'Microfone (Realtek Audio)'},
  {'id': 'interface', 'label': 'Focusrite USB Audio'},
];

/// Quantas vezes o app pediu a lista de entradas pro sistema.
var _listou = 0;

/// Simula o plugin do microfone com duas entradas conectadas.
void _simularEntradas() {
  _listou = 0;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (call) async {
          if (call.method == 'listInputDevices') {
            _listou++;
            return _entradas;
          }
          return null;
        },
      );
}

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
    _simularEntradas();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('só dá pra escolher a entrada no Windows e no Mac', () {
    for (final plataforma in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = plataforma;
      expect(
        canChooseAudioInput,
        plataforma == TargetPlatform.windows ||
            plataforma == TargetPlatform.macOS,
        reason: plataforma.name,
      );
    }
  });

  group('entrada usada pra gravar', () {
    test('no celular é sempre a padrão, sem nem pedir a lista', () async {
      await appState.setInputDeviceId('interface');
      for (final celular in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = celular;
        expect(await chosenInputDevice(AudioRecorder()), isNull);
      }
      expect(_listou, 0);
    });

    test('no Windows é a escolhida', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await appState.setInputDeviceId('interface');
      final entrada = await chosenInputDevice(AudioRecorder());
      expect(entrada?.label, 'Focusrite USB Audio');
    });

    test('sem escolha, é a padrão', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await appState.setInputDeviceId(null);
      expect(await chosenInputDevice(AudioRecorder()), isNull);
    });

    test('se a escolhida foi desconectada, volta pra padrão', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await appState.setInputDeviceId('webcam-que-saiu');
      expect(await chosenInputDevice(AudioRecorder()), isNull);
    });
  });

  group('tela Reconhecimento', () {
    testWidgets('no celular não mostra a entrada de áudio', (tester) async {
      await tester.pumpWidget(appUnderTest(const RecognitionSettingsScreen()));
      await settle(tester);
      expect(find.text('Entrada de áudio'), findsNothing);
      expect(_listou, 0);
    });

    testWidgets('no Windows lista as entradas e salva a escolhida', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      setScreen(tester, const Size(500, 1400));
      await tester.pumpWidget(appUnderTest(const RecognitionSettingsScreen()));
      await settle(tester);

      expect(find.text('Entrada de áudio'), findsOneWidget);
      expect(find.text('Padrão do sistema'), findsOneWidget);
      expect(find.text('Microfone (Realtek Audio)'), findsOneWidget);
      expect(find.text('Focusrite USB Audio'), findsOneWidget);

      await tester.tap(find.text('Focusrite USB Audio'));
      await settle(tester);
      expect(appState.inputDeviceId, 'interface');

      // Continua escolhida quando o app abre de novo.
      await appState.loadProgress();
      expect(appState.inputDeviceId, 'interface');

      await tester.tap(find.text('Padrão do sistema'));
      await settle(tester);
      expect(appState.inputDeviceId, isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
