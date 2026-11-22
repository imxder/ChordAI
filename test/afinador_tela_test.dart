import 'package:chordai/models/guide_content.dart';
import 'package:chordai/screens/guide_detail_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/services/audio_input.dart';
import 'package:chordai/services/pitch_smoother.dart';
import 'package:chordai/services/tuner_service.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/widgets/strings_illustration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

bool _auto(WidgetTester tester) =>
    tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value;

bool _selecionada(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isSelected
        .toBoolOrNull() ??
    false;

/// A chave e as casinhas ficam embaixo do ponteiro: rola até elas antes.
Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
}

void main() {
  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  testWidgets('afinador abre no Auto', (tester) async {
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);
    expect(find.text('Reconhecer a corda sozinho'), findsOneWidget);
    expect(_auto(tester), isTrue);
  });

  testWidgets('tocar na casinha escolhe a corda e desliga o Auto', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);

    await _tocar(tester, find.bySemanticsLabel('Afinar a 5ª corda'));
    await settle(tester);

    expect(_auto(tester), isFalse);
    expect(_selecionada(tester, 'Afinar a 5ª corda'), isTrue);
    expect(_selecionada(tester, 'Afinar a 6ª corda'), isFalse);

    // Ligando o Auto de novo, nenhuma casinha fica escolhida.
    await _tocar(tester, find.byType(CupertinoSwitch));
    await settle(tester);
    expect(_auto(tester), isTrue);
    expect(_selecionada(tester, 'Afinar a 5ª corda'), isFalse);
    semantics.dispose();
  });

  testWidgets('desligar o Auto sem corda tocando escolhe a 6ª', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);

    await _tocar(tester, find.byType(CupertinoSwitch));
    await settle(tester);

    expect(_auto(tester), isFalse);
    expect(_selecionada(tester, 'Afinar a 6ª corda'), isTrue);
    semantics.dispose();
  });

  testWidgets('Primeira vez? abre o guia com o desenho das cordas', (
    tester,
  ) async {
    await tester.pumpWidget(appUnderTest(const TunerScreen()));
    await settle(tester);

    await _tocar(tester, find.text('Primeira vez?'));
    await settle(tester);

    expect(find.text('Como afinar o violão'), findsOneWidget);
    expect(find.byType(StringsIllustration), findsOneWidget);
    expect(
      find.text('Abrir o afinador'),
      findsNothing,
      reason: 'já veio do afinador, não abre outro por cima',
    );
  });

  testWidgets('pelo Guia, o mesmo tópico continua com o botão do afinador', (
    tester,
  ) async {
    await tester.pumpWidget(
      appUnderTest(
        GuideDetailScreen(
          topic: guideTopics.firstWhere((t) => t.id == 'afinar'),
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(StringsIllustration), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Abrir o afinador'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Abrir o afinador'), findsOneWidget);
  });

  testWidgets('vibra uma vez quando a corda fica afinada', (tester) async {
    final afinador = _AfinadorQueOuve();
    final vibracoes = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          vibracoes.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(appUnderTest(TunerScreen(service: afinador)));
    await settle(tester);

    afinador.ouvir(110.0);
    afinador.ouvir(110.0);
    await tester.pump();
    expect(vibracoes, hasLength(1));

    afinador.ouvir(104.0);
    afinador.ouvir(110.0);
    await tester.pump();
    expect(vibracoes, hasLength(2));
  });
}

class _AfinadorQueOuve extends TunerService {
  final _suave = PitchSmoother();
  void Function(double? frequency)? _cb;

  @override
  PitchSmoother? get smoother => _suave;

  void ouvir(double frequencia) => _cb?.call(frequencia);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start(
    void Function(double? frequency) onPitch, {
    void Function(MicrophoneProblem problem)? onProblem,
  }) async {
    _cb = onPitch;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
