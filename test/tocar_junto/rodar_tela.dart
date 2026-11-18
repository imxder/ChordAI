import 'package:chordai/models/lyric_practice.dart';
import 'package:chordai/models/lyric_sheet.dart';
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
  final List<String> passos;
  final List<Tocado> tocados;
  final Map<int, int> avancouEm;
  final int? terminouEm;
  final int acertos;
  final int erros;
  final String? mensagemFinal;
  final Map<String, String> resumo;
  final ReconhecedorFalso reconhecedor;
  final int duracaoMs;

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
    required this.duracaoMs,
  });

  int get ultimoPassoAlcancado => terminouEm != null
      ? passos.length
      : (avancouEm.keys.fold(0, (a, b) => b > a ? b : a));

  List<int> get atrasos => [
    for (final e in avancouEm.entries)
      if (e.key < tocados.length) e.value - tocados[e.key].inicioMs,
  ];

  int get trocasPerdidas => passos.length - 1 - avancouEm.length;

  int indiceDoApp(int ms) {
    var idx = 0;
    avancouEm.forEach((passo, em) {
      if (em <= ms && passo > idx) idx = passo;
    });
    return idx;
  }

  int indiceDoTocador(int ms) {
    for (var i = tocados.length - 1; i >= 0; i--) {
      if (tocados[i].inicioMs <= ms) return i;
    }
    return 0;
  }

  int get maiorAtrasoEmAcordes {
    final fimDaMusica = tocados.last.fimMs;
    var pior = 0;
    for (var ms = 0; ms <= fimDaMusica; ms += 100) {
      if (terminouEm != null && ms >= terminouEm!) break;
      final d = indiceDoTocador(ms) - indiceDoApp(ms);
      if (d > pior) pior = d;
    }
    return pior;
  }

  int get maiorTempoParadoMs {
    final marcos = [
      0,
      ...avancouEm.values.toList()..sort(),
      terminouEm ?? duracaoMs,
    ];
    var pior = 0;
    for (var i = 1; i < marcos.length; i++) {
      final d = marcos[i] - marcos[i - 1];
      if (d > pior) pior = d;
    }
    return pior;
  }

  List<int> atrasoAte(List<Leitura> leituras) {
    final saida = <int>[];
    for (var i = 1; i < passos.length && i < tocados.length; i++) {
      final acorde = tocados[i].acorde;
      if (acorde == null || acorde == tocados[i - 1].acorde) continue;
      for (final l in leituras) {
        if (l.ms >= tocados[i].inicioMs && l.previsao.chord == acorde) {
          if (l.ms < tocados[i].fimMs + 3000) {
            saida.add(l.ms - tocados[i].inicioMs);
          }
          break;
        }
      }
    }
    return saida;
  }

  String relatorio() {
    final a = atrasos..sort();
    String ms(int v) => '${(v / 1000).toStringAsFixed(1)}s';
    final mediana = a.isEmpty ? null : a[a.length ~/ 2];
    return [
      '[$nome]',
      '  passos: ${passos.length}, chegou até o passo $ultimoPassoAlcancado${terminouEm == null ? ' (NÃO terminou)' : ' (terminou em ${ms(terminouEm!)})'}',
      '  trocas que o app percebeu: ${avancouEm.length} de ${passos.length - 1}',
      if (a.isNotEmpty)
        '  atraso entre eu trocar e a cifra andar: mediana ${ms(mediana!)}, mín ${ms(a.first)}, máx ${ms(a.last)}',
      if (atrasoAte(reconhecedor.cruas).isNotEmpty)
        '  só a janela (eu troco -> 1ª leitura crua com o acorde novo): mediana ${ms((atrasoAte(reconhecedor.cruas)..sort())[atrasoAte(reconhecedor.cruas).length ~/ 2])}',
      if (atrasoAte(reconhecedor.repassadas).isNotEmpty)
        '  janela + filtro (eu troco -> 1ª leitura repassada pra tela): mediana ${ms((atrasoAte(reconhecedor.repassadas)..sort())[atrasoAte(reconhecedor.repassadas).length ~/ 2])}',
      '  pior distância (eu à frente da cifra): $maiorAtrasoEmAcordes acordes; maior tempo sem andar: ${ms(maiorTempoParadoMs)}',
      '  placar do app: $acertos certos, $erros errados; mensagem: ${mensagemFinal ?? '-'}',
      if (resumo.isNotEmpty)
        '  resumo: ${resumo.entries.map((e) => '${e.key} ${e.value}').join(', ')}',
      '  leituras cruas: ${reconhecedor.cruas.length}, repassadas pra tela: ${reconhecedor.repassadas.where((l) => l.previsao.chord != null).length} com acorde',
    ].join('\n');
  }
}

LyricSheet cifraDeTeste(String linha, {int tempo = 100}) => LyricSheet(
  title: 'Teste',
  tempo: tempo,
  sections: [
    LyricSection(
      lines: [LyricLine(chordLine: linha, lyricText: 'letra')],
    ),
  ],
);

Future<Resultado> simularTelaDeHoje(
  WidgetTester tester, {
  required String nome,
  required LyricSheet cifra,
  required List<Tocado> Function(List<String> passos) tocar,
  required ModeloFalso modelo,
  bool servidor = false,
  int sobraMs = 6000,
}) async {
  mockPlatform();
  await tester.runAsync(() => appState.loadProgress());
  setScreen(tester, const Size(500, 1200));

  final passos = buildLyricPracticeMap(cifra).score.steps
      .map((s) => s.chord)
      .toList();
  final tocados = tocar(passos);
  DateTime agora() => tester.binding.clock.now();
  final reconhecedor = ReconhecedorFalso(
    modelo: modelo,
    tocados: tocados,
    agora: agora,
    servidor: servidor,
  );

  await tester.pumpWidget(
    appUnderTest(
      LyricPlayerScreen(
        sheet: cifra,
        serverUrl: 'http://teste',
        recognizer: reconhecedor,
      ),
    ),
  );
  await tester.pump();

  final avancouEm = <int, int>{};
  int? terminouEm;
  late DateTime t0;
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

  t0 = agora();
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
        .where((t) => RegExp(r'^\d+/\d+$').hasMatch(t))
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
        : (tester.widget<Text>(mensagem.first).data),
    resumo: resumo,
    reconhecedor: reconhecedor,
    duracaoMs: duracaoMs,
  );

  if (appState.sessionStatus != SessionStatus.idle) {
    await tester.tap(find.text('Parar'));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  return resultado;
}
