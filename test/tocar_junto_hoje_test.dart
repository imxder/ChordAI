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
  const quatroTemposA100 = 2400;
  const doisTemposA100 = 1200;
  const quatroTemposA98 = 2449;

  final cenarios = <String, Future<Resultado> Function(WidgetTester)>{
    'certinho (Riptide, 4 tempos por acorde)': (t) => simularTelaDeHoje(
      t,
      nome: 'certinho',
      cifra: riptide,
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'certinho (All Too Well, 4 tempos por acorde)': (t) => simularTelaDeHoje(
      t,
      nome: 'All Too Well certinho',
      cifra: allTooWell,
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA98),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    '0,8 s atrasado': (t) => simularTelaDeHoje(
      t,
      nome: '0,8 s atrasado',
      cifra: riptide,
      tocar: (p) =>
          tocarNoTempo(p, msPorAcorde: quatroTemposA100, atrasoMs: 800),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'modelo errando 15% das leituras': (t) => simularTelaDeHoje(
      t,
      nome: 'erro 15%',
      cifra: riptide,
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3, taxaDeErro: 0.15),
    ),
    'modelo sem ouvir o G': (t) => simularTelaDeHoje(
      t,
      nome: 'não ouve o G',
      cifra: riptide,
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3, naoOuve: {'G'}),
    ),
    'acorde fora do modelo (D no v3)': (t) => simularTelaDeHoje(
      t,
      nome: 'D fora do modelo',
      cifra: cifraDeTeste('C  D  G  Am'),
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'acorde repetido em sequência': (t) => simularTelaDeHoje(
      t,
      nome: 'C C G Am',
      cifra: cifraDeTeste('C  C  G  Am'),
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'último acorde em silêncio': (t) => simularTelaDeHoje(
      t,
      nome: 'último em silêncio',
      cifra: cifraDeTeste('C  G  Am  F'),
      tocar: (p) =>
          tocarNoTempo(p, msPorAcorde: quatroTemposA100, trocas: {3: null}),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'último acorde: toco só 1,5 s dele e paro': (t) => simularTelaDeHoje(
      t,
      nome: 'último acorde curto',
      cifra: cifraDeTeste('C  G  Am  F'),
      tocar: (p) => [
        ...tocarNoTempo(p.sublist(0, 3), msPorAcorde: quatroTemposA100),
        const Tocado('F', 3 * quatroTemposA100, 3 * quatroTemposA100 + 1500),
      ],
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'cifra com Am7 (o modelo ouve Am)': (t) => simularTelaDeHoje(
      t,
      nome: 'Am7 na cifra',
      cifra: cifraDeTeste('C  Am7  F  G'),
      tocar: (p) =>
          tocarNoTempo(p, msPorAcorde: quatroTemposA100, trocas: {1: 'Am'}),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'silêncio do começo ao fim': (t) => simularTelaDeHoje(
      t,
      nome: 'silêncio total',
      cifra: riptide,
      tocar: (p) => tocarNoTempo([
        for (final _ in p) null,
      ], msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'trocas a cada 1,2 s (Riptide, 2 tempos)': (t) => simularTelaDeHoje(
      t,
      nome: 'trocas a cada 1,2 s',
      cifra: riptide,
      tocar: (p) => tocarNoTempo(p, msPorAcorde: doisTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'três errados de propósito': (t) => simularTelaDeHoje(
      t,
      nome: 'três errados de propósito',
      cifra: riptide,
      tocar: (p) => tocarNoTempo(
        p,
        msPorAcorde: quatroTemposA100,
        trocas: {5: 'Em', 10: 'Em', 15: 'Em'},
      ),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
    ),
    'modo servidor': (t) => simularTelaDeHoje(
      t,
      nome: 'servidor',
      cifra: riptide,
      tocar: (p) => tocarNoTempo(p, msPorAcorde: quatroTemposA100),
      modelo: ModeloFalso(conhecidos: acordesDoV3),
      servidor: true,
    ),
  };

  test('hoje: linha com C/G não é lida como linha de acordes', () {
    final cifra = parseCifra('C/G  Am7  G7\nletra da música\n', title: 'x');
    final linha = cifra.sections.first.lines.first;
    // ignore: avoid_print
    print(
      '[C/G na cifra] chordLine=${linha.chordLine} lyricText=${linha.lyricText}',
    );
  });

  for (final c in cenarios.entries) {
    testWidgets('hoje: ${c.key}', (tester) async {
      final r = await c.value(tester);
      // ignore: avoid_print
      print(r.relatorio());
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
