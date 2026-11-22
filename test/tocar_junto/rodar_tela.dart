import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/models/lyric_sheet.dart';
import 'package:chordai/models/score.dart';
import 'package:chordai/screens/lyric_player_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/widgets/page_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';
import 'simulador.dart';

const acordesDoV3 = {'Am', 'Bb', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'};

class Resultado {
  final String nome;
  final List<ChordStep> passos;
  final List<Tocado> tocados;
  final Map<int, int> avancouEm;
  final int? terminouEm;
  final int acertos;
  final int erros;
  final String? mensagemFinal;
  final Map<String, String> resumo;
  final ReconhecedorFalso reconhecedor;

  Resultado({
    required this.nome,
    required this.passos,
    required this.tocados,
    required this.avancouEm,
    required this.terminouEm,
    required this.acertos,
    required this.erros,
    required this.mensagemFinal,
    required this.resumo,
    required this.reconhecedor,
  });

  bool get terminou => terminouEm != null;

  int indiceDoApp(int ms) {
    var idx = 0;
    var quando = -1;
    avancouEm.forEach((passo, em) {
      if (em <= ms && em >= quando) {
        idx = passo;
        quando = em;
      }
    });
    return idx;
  }

  int indiceDoTocador(int ms) {
    for (var i = tocados.length - 1; i >= 0; i--) {
      if (tocados[i].inicioMs <= ms) return i;
    }
    return 0;
  }

  int get piorDistancia {
    var pior = 0;
    for (var ms = tocados.first.inicioMs; ms <= tocados.last.fimMs; ms += 100) {
      if (terminouEm != null && ms >= terminouEm!) break;
      final d = (indiceDoTocador(ms) - indiceDoApp(ms)).abs();
      if (d > pior) pior = d;
    }
    return pior;
  }

  String relatorio() => [
    '[$nome]',
    '  ${passos.length} acordes, ${terminou ? 'terminou em ${(terminouEm! / 1000).toStringAsFixed(1)}s' : 'NÃO terminou'}',
    '  pior distância entre o que eu toco e a cifra: $piorDistancia acorde(s)',
    '  placar: $acertos certos, $erros errados; ${mensagemFinal ?? '-'}',
    if (resumo.isNotEmpty)
      '  resumo: ${resumo.entries.map((e) => '${e.key} ${e.value}').join(', ')}',
  ].join('\n');
}

LyricSheet cifraDeTeste(String linha, {int tempo = 100, int? tempos}) =>
    LyricSheet(
      title: 'Teste',
      tempo: tempo,
      beatsPerChord: tempos,
      sections: [
        LyricSection(
          lines: [LyricLine(chordLine: linha, lyricText: 'letra')],
        ),
      ],
    );

Future<Resultado> simularTela(
  WidgetTester tester, {
  required String nome,
  required LyricSheet cifra,
  required List<Tocado> Function(List<ChordStep> passos, int bpm) tocar,
  required ModeloFalso modelo,
  bool esperarPorMim = false,
  int sobraMs = 12000,
}) async {
  mockPlatform();
  await tester.runAsync(() => appState.loadProgress());
  await tester.runAsync(() => appState.setPlayAlongWaitsForMe(esperarPorMim));
  setScreen(tester, const Size(500, 1200));

  final passos = buildLyricPracticeMap(cifra).score.steps;
  final bpm = cifra.tempo ?? 80;
  final tocados = tocar(passos, bpm);
  DateTime agora() => tester.binding.clock.now();
  final t0 = agora();
  final reconhecedor = ReconhecedorFalso(
    modelo: modelo,
    tocados: tocados,
    agora: agora,
  );

  await tester.pumpWidget(
    appUnderTest(
      LyricPlayerScreen(
        sheet: cifra,
        recognizer: reconhecedor,
        elapsed: () => agora().difference(t0),
      ),
    ),
  );

  final avancouEm = <int, int>{0: 0};
  int? terminouEm;
  var ultimoIndice = 0;
  void ouvir() {
    final ms = agora().difference(t0).inMilliseconds;
    if (appState.sessionStatus == SessionStatus.running &&
        appState.currentStepIndex != ultimoIndice) {
      ultimoIndice = appState.currentStepIndex;
      avancouEm[ultimoIndice] = ms;
    }
    if (appState.sessionStatus == SessionStatus.idle &&
        terminouEm == null &&
        ms > 0) {
      terminouEm = ms;
    }
  }

  await tester.tap(find.text('Começar'));
  appState.addListener(ouvir);
  final duracaoMs = tocados.last.fimMs + sobraMs;
  while (agora().difference(t0).inMilliseconds < duracaoMs &&
      terminouEm == null) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  appState.removeListener(ouvir);
  await tester.pump();

  final mensagem = find.textContaining('Música concluída');
  final resumo = <String, String>{};
  final dialogo = find.byType(AlertDialog);
  if (dialogo.evaluate().isNotEmpty) {
    final nomes = tester
        .widgetList<ChordName>(
          find.descendant(of: dialogo, matching: find.byType(ChordName)),
        )
        .map((c) => c.chord)
        .toList();
    final fracoes = tester
        .widgetList<Text>(
          find.descendant(of: dialogo, matching: find.byType(Text)),
        )
        .map((t) => t.data ?? '')
        .where((t) => RegExp(r'^\d+ de \d+$').hasMatch(t))
        .toList();
    for (var i = 0; i < nomes.length && i < fracoes.length; i++) {
      resumo[nomes[i]] = fracoes[i];
    }
  }

  final resultado = Resultado(
    nome: nome,
    passos: passos,
    tocados: tocados,
    avancouEm: avancouEm,
    terminouEm: terminouEm,
    acertos: appState.sessionHits,
    erros: appState.sessionMisses,
    mensagemFinal: mensagem.evaluate().isEmpty
        ? null
        : tester.widget<Text>(mensagem.first).data,
    resumo: resumo,
    reconhecedor: reconhecedor,
  );

  if (appState.sessionStatus != SessionStatus.idle) {
    await tester.tap(find.text('Parar'));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  return resultado;
}
