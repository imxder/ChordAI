import 'dart:io';

import 'package:chordai/services/cifra_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tocar_junto/rodar_tela.dart';
import 'tocar_junto/simulador.dart';

void main() {
  final riptide = parseCifra(
    File('assets/lyrics/riptide.txt').readAsStringSync(),
    title: 'Riptide',
  );
  final allTooWell = parseCifra(
    File('assets/lyrics/all_too_well.txt').readAsStringSync(),
    title: 'All Too Well',
  );
  ModeloFalso v3({double erro = 0, Set<String> naoOuve = const {}}) =>
      ModeloFalso(conhecidos: acordesDoV3, taxaDeErro: erro, naoOuve: naoOuve);

  final cenarios = <String, Future<Resultado> Function(WidgetTester, bool)>{
    'certinho (Riptide)': (t, e) => simularTela(
      t,
      nome: 'certinho Riptide',
      cifra: riptide,
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'certinho (All Too Well)': (t, e) => simularTela(
      t,
      nome: 'certinho All Too Well',
      cifra: allTooWell,
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(),
      esperarPorMim: e,
    ),
    '0,8 s atrasado': (t, e) => simularTela(
      t,
      nome: '0,8 s atrasado',
      cifra: riptide,
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm, atrasoMs: 800),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'modelo errando 15%': (t, e) => simularTela(
      t,
      nome: 'erro 15%',
      cifra: riptide,
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(erro: 0.15),
      esperarPorMim: e,
    ),
    'modelo sem ouvir o G': (t, e) => simularTela(
      t,
      nome: 'não ouve o G',
      cifra: riptide,
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(naoOuve: {'G'}),
      esperarPorMim: e,
    ),
    'D fora do modelo': (t, e) => simularTela(
      t,
      nome: 'D fora do modelo',
      cifra: cifraDeTeste('C  D  G  Am'),
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'acorde repetido': (t, e) => simularTela(
      t,
      nome: 'C C G Am',
      cifra: cifraDeTeste('C  C  G  Am'),
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'último acorde em silêncio': (t, e) => simularTela(
      t,
      nome: 'último em silêncio',
      cifra: cifraDeTeste('C  G  Am  F'),
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm, trocas: {3: null}),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'Am7 na cifra': (t, e) => simularTela(
      t,
      nome: 'Am7 na cifra',
      cifra: cifraDeTeste('C  Am7  F  G'),
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm, trocas: {1: 'Am'}),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'silêncio do começo ao fim': (t, e) => simularTela(
      t,
      nome: 'silêncio total',
      sobraMs: 400000,
      cifra: riptide,
      tocar: (p, bpm) => tocarPelaCifra(
        p,
        bpm: bpm,
        trocas: {for (var i = 0; i < p.length; i++) i: null},
      ),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'trocas a cada 1,2 s': (t, e) => simularTela(
      t,
      nome: 'trocas a cada 1,2 s',
      cifra: cifraDeTeste('Am  G  C  F  Am  G  C  F  Am  G  C  F', tempos: 2),
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'três errados de propósito': (t, e) => simularTela(
      t,
      nome: 'três errados de propósito',
      cifra: riptide,
      tocar: (p, bpm) =>
          tocarPelaCifra(p, bpm: bpm, trocas: {5: 'Em', 10: 'Em', 15: 'Em'}),
      modelo: v3(),
      esperarPorMim: e,
    ),
    'modo servidor': (t, e) => simularTela(
      t,
      nome: 'servidor',
      cifra: riptide,
      tocar: (p, bpm) => tocarPelaCifra(p, bpm: bpm),
      modelo: v3(),
      servidor: true,
      esperarPorMim: e,
    ),
  };

  const esperadoAcompanhando = <String, (int?, int?, int)>{
    'certinho (Riptide)': (88, 0, 1),
    'certinho (All Too Well)': (243, 0, 1),
    '0,8 s atrasado': (88, 0, 1),
    'modelo errando 15%': (null, null, 1),
    'modelo sem ouvir o G': (59, 29, 1),
    'D fora do modelo': (3, 0, 1),
    'acorde repetido': (4, 0, 1),
    'último acorde em silêncio': (3, 1, 1),
    'Am7 na cifra': (4, 0, 1),
    'silêncio do começo ao fim': (0, 88, 1),
    'trocas a cada 1,2 s': (12, 0, 1),
    'três errados de propósito': (85, 3, 1),
    'modo servidor': (null, null, 1),
  };
  const esperadoEsperando = <String, (int?, int?, int)>{
    'certinho (Riptide)': (88, 0, 2),
    'certinho (All Too Well)': (243, 0, 3),
    '0,8 s atrasado': (88, 0, 2),
    'modelo errando 15%': (null, null, 3),
    'modelo sem ouvir o G': (59, 29, 2),
    'D fora do modelo': (3, 0, 2),
    'acorde repetido': (4, 0, 2),
    'último acorde em silêncio': (3, 1, 2),
    'Am7 na cifra': (4, 0, 2),
    'silêncio do começo ao fim': (0, 88, 88),
    'trocas a cada 1,2 s': (12, 0, 2),
    'três errados de propósito': (null, null, 3),
    'modo servidor': (null, null, 3),
  };

  for (final esperar in [false, true]) {
    final jeito = esperar ? 'esperar por mim' : 'acompanhar o andamento';
    for (final c in cenarios.entries) {
      testWidgets('$jeito: ${c.key}', (tester) async {
        final r = await c.value(tester, esperar);
        // ignore: avoid_print
        print('($jeito) ${r.relatorio()}');
        final (certos, errados, distancia) = (esperar
            ? esperadoEsperando
            : esperadoAcompanhando)[c.key]!;
        expect(r.terminou, isTrue, reason: 'a música tem que terminar');
        expect(r.piorDistancia, lessThanOrEqualTo(distancia));
        if (certos != null) expect(r.acertos, certos);
        if (errados != null) expect(r.erros, errados);
        expect(
          r.mensagemFinal,
          'Música concluída: ${r.acertos} de ${r.acertos + r.erros} acordes certos',
        );
      }, timeout: const Timeout(Duration(minutes: 5)));
    }
  }
}
