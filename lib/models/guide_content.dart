import 'package:flutter/material.dart';

class GuideTopic {
  final String id;
  final String title;
  final IconData icon;
  final List<String> paragraphs;
  final List<String> steps;
  final String? highlight;

  const GuideTopic({
    required this.id,
    required this.title,
    required this.icon,
    this.paragraphs = const [],
    this.steps = const [],
    this.highlight,
  });
}

const List<GuideTopic> guideTopics = [
  GuideTopic(
    id: 'acessorios',
    title: 'Acessórios essenciais',
    icon: Icons.backpack_outlined,
    paragraphs: [
      'Pra começar a tocar você não precisa de muita coisa, mas alguns itens '
          'facilitam bastante a vida de quem está aprendendo.',
    ],
    steps: [
      'Palheta de espessura média (0.70mm a 0.88mm)',
      'Afinador (pode ser o afinador deste app)',
      'Capotraste, se for tocar músicas em tons diferentes',
      'Um apoio ou estante se for estudar com partitura/cifra no celular',
    ],
    highlight:
        'Não precisa comprar nada caro agora — o violão e um afinador já são '
        'suficientes pra praticar todos os dias.',
  ),
  GuideTopic(
    id: 'regular',
    title: 'Regulando o violão',
    icon: Icons.build_outlined,
    paragraphs: [
      '"Regular" o violão é ajustar a altura das cordas e a tensão do '
          'braço pra ficar mais fácil de tocar, sem zumbidos nem cordas '
          'duras demais.',
      'Isso normalmente é feito por um luthier ou numa loja especializada — '
          'não é algo que você precisa fazer sozinho como principiante.',
    ],
    highlight:
        'Se as cordas estão muito "duras" de apertar, ou se tocar e sair um '
        'som de zumbido, vale levar o violão pra regular antes de achar que '
        'o problema é a sua técnica.',
  ),
  GuideTopic(
    id: 'afinar',
    title: 'Como afinar o violão',
    icon: Icons.tune,
    paragraphs: [
      'A afinação padrão do violão, da corda mais grossa pra mais fina, é '
          'E-A-D-G-B-E (Mi, Lá, Ré, Sol, Si, Mi).',
      'Use o afinador deste app: toque uma corda por vez e ajuste a tarraxa '
          'até o indicador ficar verde, no centro.',
    ],
    steps: [
      'Toque a corda solta (sem pressionar nenhuma casa)',
      'Observe se o indicador aponta pra "afrouxar" ou "apertar"',
      'Gire a tarraxa devagar na direção indicada',
      'Toque de novo e repita até ficar verde',
      'Repita para as 6 cordas',
    ],
    highlight: 'Abra o afinador a partir desta tela quando quiser praticar.',
  ),
  GuideTopic(
    id: 'cordas',
    title: 'Trocando as cordas',
    icon: Icons.swap_horiz,
    paragraphs: [
      'Cordas velhas perdem o brilho do som e desafinam com mais facilidade. '
          'É normal trocar a cada 2-3 meses de uso regular, ou antes se '
          'alguma corda arrebentar.',
    ],
    steps: [
      'Afrouxe e remova a corda antiga, uma de cada vez',
      'Encaixe a corda nova no cavalete ou na ponte',
      'Passe pela tarraxa certa e enrole, mantendo tensão com a mão',
      'Afine e repita para as outras cordas',
      'Afine de novo depois de 10-15 minutos (cordas novas "cedem" um pouco)',
    ],
  ),
  GuideTopic(
    id: 'postura',
    title: 'Postura ao tocar',
    icon: Icons.accessibility_new,
    paragraphs: [
      'Uma boa postura evita dor nas costas e no pulso, e facilita a '
          'movimentação da mão esquerda pelo braço do violão.',
    ],
    steps: [
      'Sente-se com a coluna reta, sem apoiar o violão só na perna',
      'O braço do violão deve ficar levemente inclinado pra cima',
      'O pulso da mão esquerda não deve ficar totalmente dobrado',
      'Os dedos pressionam as cordas com a ponta, perto do traste',
    ],
  ),
  GuideTopic(
    id: 'dor_dedos',
    title: 'Dor nos dedos',
    icon: Icons.healing_outlined,
    paragraphs: [
      'É normal sentir um desconforto nas pontas dos dedos da mão esquerda '
          'nas primeiras semanas — ainda não existe a "calosidade" que os '
          'violonistas desenvolvem com a prática.',
    ],
    highlight:
        'Pratique um pouco todos os dias em vez de uma sessão longa só de '
        'vez em quando — isso ajuda a pele a se acostumar sem machucar.',
    steps: [
      'Pare se sentir dor forte ou ver a pele ferida, não só desconforto',
      'Sessões curtas e frequentes funcionam melhor que uma sessão longa',
      'A calosidade costuma se formar em 2 a 4 semanas de prática regular',
    ],
  ),
];
