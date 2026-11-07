class GuideTopic {
  final String id;
  final String title;
  final String summary;
  final List<String> paragraphs;
  final List<String> steps;
  final String? highlight;

  const GuideTopic({
    required this.id,
    required this.title,
    required this.summary,
    this.paragraphs = const [],
    this.steps = const [],
    this.highlight,
  });
}

const List<GuideTopic> guideTopics = [
  GuideTopic(
    id: 'acessorios',
    title: 'Acessórios essenciais',
    summary: 'O mínimo para começar',
    paragraphs: [
      'Pra começar a tocar você não precisa de muita coisa, mas alguns itens '
          'facilitam bastante a vida de quem está aprendendo.',
    ],
    steps: [
      'Palheta de espessura média (0.70mm a 0.88mm)',
      'Afinador (pode ser o afinador deste app)',
      'Capotraste, se for tocar músicas em tons diferentes',
      'Um apoio ou estante se for estudar com a cifra no celular',
    ],
    highlight:
        'Não precisa comprar nada caro agora. O violão e um afinador já bastam '
        'pra praticar todo dia.',
  ),
  GuideTopic(
    id: 'regular',
    title: 'Regulando o violão',
    summary: 'Quando levar ao luthier',
    paragraphs: [
      '"Regular" o violão é ajustar a altura das cordas e a tensão do '
          'braço pra ficar mais fácil de tocar, sem zumbidos nem cordas '
          'duras demais.',
      'Isso normalmente é feito por um luthier ou numa loja especializada. '
          'Não é algo que você precisa fazer sozinho como principiante.',
    ],
    highlight:
        'Se as cordas estão muito "duras" de apertar, ou se sai um zumbido '
        'quando você toca, vale levar o violão pra regular antes de achar que '
        'o problema é a sua técnica.',
  ),
  GuideTopic(
    id: 'afinar',
    title: 'Como afinar o violão',
    summary: 'Afinação padrão, corda por corda',
    paragraphs: [
      'A afinação padrão do violão, da corda mais grossa pra mais fina, é '
          'E-A-D-G-B-E (Mi, Lá, Ré, Sol, Si, Mi).',
      'Use o afinador deste app: toque uma corda por vez e ajuste a tarraxa '
          'até o ponteiro parar no centro e aparecer "Afinada".',
    ],
    steps: [
      'Toque a corda solta (sem pressionar nenhuma casa)',
      'Veja se o afinador pede pra apertar ou afrouxar a tarraxa',
      'Gire a tarraxa devagar na direção indicada',
      'Toque de novo e repita até aparecer "Afinada"',
      'Repita para as 6 cordas',
    ],
  ),
  GuideTopic(
    id: 'cordas',
    title: 'Trocando as cordas',
    summary: 'De quanto em quanto tempo e como',
    paragraphs: [
      'Cordas velhas perdem o brilho do som e desafinam com mais facilidade. '
          'É normal trocar a cada 2 ou 3 meses de uso regular, ou antes se '
          'alguma corda arrebentar.',
    ],
    steps: [
      'Afrouxe e remova a corda antiga, uma de cada vez',
      'Encaixe a corda nova no cavalete ou na ponte',
      'Passe pela tarraxa certa e enrole, mantendo tensão com a mão',
      'Afine e repita para as outras cordas',
      'Afine de novo depois de 10 a 15 minutos (cordas novas "cedem" um pouco)',
    ],
  ),
  GuideTopic(
    id: 'postura',
    title: 'Postura ao tocar',
    summary: 'Coluna, braço e pulso',
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
    summary: 'O que é normal nas primeiras semanas',
    paragraphs: [
      'É normal sentir um desconforto nas pontas dos dedos da mão esquerda '
          'nas primeiras semanas. A pele ainda não criou a "calosidade" que '
          'vem com a prática.',
    ],
    highlight:
        'Pratique um pouco todo dia em vez de uma sessão longa de vez em '
        'quando. Assim a pele se acostuma sem machucar.',
    steps: [
      'Pare se sentir dor forte ou ver a pele ferida, não só desconforto',
      'Sessões curtas e frequentes funcionam melhor que uma sessão longa',
      'A calosidade costuma se formar em 2 a 4 semanas de prática regular',
    ],
  ),
];
