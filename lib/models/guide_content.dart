enum GuideGroup {
  beforePlaying('Antes de tocar'),
  firstChords('Primeiros acordes'),
  guitarCare('Cuidando do violão');

  const GuideGroup(this.title);

  final String title;
}

enum GuideAction {
  next,
  list,
  tuner,
  chords,
  practiceEm,
  songs,
  sequences,
  nextChord,
}

class GuideTopic {
  final String id;
  final String title;
  final String summary;
  final GuideGroup group;
  final List<String> paragraphs;
  final List<String> steps;
  final String? highlight;
  final GuideAction action;

  final List<String> sources;

  const GuideTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.group,
    required this.action,
    this.paragraphs = const [],
    this.steps = const [],
    this.highlight,
    this.sources = const [],
  });
}

GuideTopic guideTopicById(String id) =>
    guideTopics.firstWhere((topic) => topic.id == id);

GuideTopic? guideTopicAfter(GuideTopic topic) {
  final index = guideTopics.indexOf(topic);
  return index >= 0 && index + 1 < guideTopics.length
      ? guideTopics[index + 1]
      : null;
}

const List<GuideTopic> guideTopics = [
  GuideTopic(
    id: 'partes',
    title: 'Partes do violão',
    summary: 'Os nomes que o guia usa',
    group: GuideGroup.beforePlaying,
    action: GuideAction.next,
    paragraphs: [
      'Antes de tocar, vale saber o nome das partes. O resto do guia e as '
          'cifras usam esses nomes o tempo todo.',
      'Na cabeça ficam as tarraxas. Girando uma tarraxa, a corda estica ou '
          'afrouxa, e o som dela fica mais agudo ou mais grave.',
      'A pestana é a pecinha onde o braço encontra a cabeça, e as cordas '
          'passam por ela. Cuidado pra não confundir: "fazer pestana" é outra '
          'coisa, que é apertar várias cordas com um dedo só.',
      'No braço ficam os trastes, as barrinhas de metal atravessadas. O '
          'espaço entre dois trastes é a casa: a 2ª casa fica entre o 1º e o '
          '2º traste. É ali, perto do traste, que você aperta a corda.',
      'No corpo ficam a boca, o buraco por onde o som sai, e o cavalete, '
          'onde as cordas ficam presas.',
      'As cordas são numeradas da mais fina pra mais grossa: a 1ª é a mais '
          'fina e a 6ª é a mais grossa. "Corda solta" é tocar a corda sem '
          'apertar nenhuma casa.',
    ],
    sources: ['Martin Guitar'],
  ),
  GuideTopic(
    id: 'afinar',
    title: 'Como afinar o violão',
    summary: 'Afinação padrão, corda por corda',
    group: GuideGroup.beforePlaying,
    action: GuideAction.tuner,
    paragraphs: [
      'Afinar é deixar cada corda na nota certa. Com o violão desafinado, até '
          'o acorde montado certinho soa errado, e o app reconhece pior.',
      'A afinação padrão, da 6ª corda pra 1ª, é E A D G B E (Mi, Lá, Ré, '
          'Sol, Si, Mi).',
      'Use o afinador do app: toque uma corda de cada vez e gire a tarraxa '
          'dela até o ponteiro parar no centro e aparecer "Afinada".',
    ],
    steps: [
      'Toque a corda solta, sem apertar nenhuma casa',
      'Veja se o afinador pede pra apertar ou afrouxar',
      'Gire a tarraxa devagar pro lado que ele pede',
      'Toque de novo e repita até aparecer "Afinada"',
      'Faça o mesmo nas 6 cordas',
    ],
  ),
  GuideTopic(
    id: 'diagrama',
    title: 'Como ler o diagrama do acorde',
    summary: 'O desenho que mostra onde apertar',
    group: GuideGroup.firstChords,
    action: GuideAction.chords,
    paragraphs: [
      'Todo acorde do app vem com um desenho assim. É o braço do violão em '
          'pé, de frente pra você, com a cabeça pra cima.',
    ],
    steps: [
      'As linhas em pé são as cordas: a da esquerda é a 6ª, a mais grossa, '
          'e a da direita é a 1ª',
      'As linhas deitadas são os trastes. A linha grossa lá em cima é a '
          'pestana',
      'A bolinha mostra a casa onde você aperta a corda',
      'O "o" em cima de uma corda é corda solta: ela toca sem apertar nada',
      'O "x" em cima de uma corda quer dizer que ela não toca',
    ],
    highlight:
        'No Em do desenho: duas bolinhas na 2ª casa, nas cordas 5 e 4, e as '
        'outras quatro cordas soltas.',
  ),
  GuideTopic(
    id: 'primeiro_acorde',
    title: 'Seu primeiro acorde: Em',
    summary: 'Mi menor, com dois dedos',
    group: GuideGroup.firstChords,
    action: GuideAction.practiceEm,
    paragraphs: [
      'O Em (Mi menor) usa só dois dedos e deixa as 6 cordas tocarem. Por '
          'isso ele é o primeiro da lista de acordes do app.',
    ],
    steps: [
      'Aperte a 5ª corda na 2ª casa',
      'Com outro dedo, aperte a 4ª corda também na 2ª casa',
      'Use a ponta dos dedos, perto do traste',
      'Toque as 6 cordas de uma vez',
      'Toque uma corda de cada vez: se alguma sair abafada, ajeite o dedo '
          'que está encostando nela',
    ],
  ),
  GuideTopic(
    id: 'cifra',
    title: 'Como ler uma cifra',
    summary: 'As letras que dizem qual acorde tocar',
    group: GuideGroup.firstChords,
    action: GuideAction.songs,
    paragraphs: [
      'Cifra é a música escrita com os nomes dos acordes, na ordem em que '
          'você toca. Nas músicas do app, cada acorde aparece com o desenho, '
          'o nome e as setas da batida.',
      'Leia da esquerda pra direita e de cima pra baixo. Quando a linha '
          'termina com "2×", toque aquela linha duas vezes.',
      'O nome do acorde é uma letra. O "m" depois da letra quer dizer menor: '
          'Am é Lá menor e Em é Mi menor. Sem o "m", o acorde é maior: C é Dó '
          'maior. Tocando no acorde, o app mostra o nome completo.',
    ],
  ),
  GuideTopic(
    id: 'batida',
    title: 'A batida',
    summary: 'Setas pra baixo e pra cima',
    group: GuideGroup.firstChords,
    action: GuideAction.songs,
    paragraphs: [
      'A batida é o jeito de passar a mão nas cordas. Nas cifras do app, ela '
          'aparece em setas embaixo de cada acorde.',
      '↓ é pra baixo: a mão desce, da corda mais grossa pra mais fina. ↑ é '
          'pra cima: a mão sobe, da mais fina pra mais grossa. Um pontinho no '
          'lugar da seta é um tempo sem batida.',
      'Um "x" é abafado: encoste de leve nas cordas a mão que faz a batida, '
          'pra elas pararem de soar.',
      'A batida que as músicas do app usam é a Comum: ↓ ↓ ↑ ↑ ↓ ↑.',
    ],
    steps: [
      'Treine só as setas pra baixo, devagar',
      'Depois treine só as setas pra cima',
      'Junte as duas na batida Comum',
      'No tocar junto, comece com o andamento baixo e vá subindo',
    ],
    sources: ['Martin Guitar', 'Taylor Guitars'],
  ),
  GuideTopic(
    id: 'trocar_acorde',
    title: 'Trocar de acorde sem parar',
    summary: 'Dois acordes, devagar, até sair redondo',
    group: GuideGroup.firstChords,
    action: GuideAction.sequences,
    paragraphs: [
      'No começo, trocar de acorde é a parte mais difícil. É normal a música '
          'parar enquanto os dedos procuram o lugar.',
    ],
    steps: [
      'Escolha dois acordes que você já sabe, como Em e Am',
      'Monte um, toque, e passe pro outro bem devagar',
      'Repare no dedo que não muda de lugar: do Em pro Am, o da 4ª corda na '
          '2ª casa fica onde está',
      'Olhe o próximo acorde na cifra antes de chegar nele',
      'Nas Sequências de acordes, o metrônomo marca a hora de trocar, e você '
          'escolhe o andamento',
    ],
  ),
  GuideTopic(
    id: 'treino_diario',
    title: 'Quanto treinar por dia',
    summary: 'Pouco tempo, todo dia',
    group: GuideGroup.firstChords,
    action: GuideAction.nextChord,
    paragraphs: [
      'Não precisa treinar horas. Entre 15 e 30 minutos por dia já é bom, e '
          'dá pra dividir em blocos de 5 minutos com 1 minuto de pausa.',
      'Os acordes do app estão na ordem do mais fácil pro mais difícil. Quando '
          'você acerta um acorde 3 vezes seguidas, ele vira aprendido, e o '
          'próximo da lista é o que vale treinar depois.',
    ],
    steps: [
      'Afine o violão',
      'Treine o acorde novo',
      'Treine a troca entre dois acordes',
      'Termine tocando uma música',
    ],
    sources: ['Yamaha', 'Taylor Guitars'],
  ),
  GuideTopic(
    id: 'dor_dedos',
    title: 'Dor nos dedos',
    summary: 'O que é normal no começo',
    group: GuideGroup.guitarCare,
    action: GuideAction.next,
    paragraphs: [
      'No começo, as pontas dos dedos que apertam as cordas doem depois de '
          'treinar. É normal: com o treino, a pele cria calo e a dor passa.',
    ],
    highlight:
        'Faça pausas durante o treino e aumente o tempo aos poucos, conforme '
        'os dedos se acostumam.',
    steps: [
      'Pare se doer forte ou se a pele machucar',
      'Treinos curtos todo dia são melhores que um treino longo',
      'Cordas mais finas ajudam a doer menos',
    ],
    sources: ['Martin Guitar', 'Yamaha'],
  ),
  GuideTopic(
    id: 'acessorios',
    title: 'Acessórios essenciais',
    summary: 'O mínimo para começar',
    group: GuideGroup.guitarCare,
    action: GuideAction.next,
    paragraphs: [
      'Pra começar você não precisa de muita coisa, mas alguns itens '
          'facilitam a vida de quem está aprendendo.',
    ],
    steps: [
      'Palheta média, entre 0,60 e 0,80 mm. Pra quem está começando a bater '
          'nas cordas, uma um pouco mais fina também serve',
      'Afinador (o deste app serve)',
      'Capotraste, se for tocar músicas em tons diferentes',
      'Um apoio pro celular, pra ler a cifra enquanto toca',
    ],
    highlight:
        'Não precisa comprar nada caro agora. O violão e um afinador já bastam '
        'pra treinar todo dia.',
    sources: ['Martin Guitar'],
  ),
  GuideTopic(
    id: 'cordas',
    title: 'Trocar as cordas',
    summary: 'De quanto em quanto tempo e como',
    group: GuideGroup.guitarCare,
    action: GuideAction.tuner,
    paragraphs: [
      'Corda velha perde o brilho do som. Quem toca de vez em quando troca a '
          'cada 2 ou 3 meses.',
      'Troque antes se a corda estiver enferrujada, áspera quando você passa '
          'o dedo, torta, ou se o som ficar sem vida.',
    ],
    steps: [
      'Afrouxe e tire a corda velha, uma de cada vez',
      'Prenda a corda nova no cavalete',
      'Passe pela tarraxa certa e enrole, mantendo a corda esticada com a mão',
      'Afine e faça o mesmo nas outras cordas',
      'Corda nova desafina mais no começo: afine de novo depois de tocar um '
          'pouco',
    ],
    sources: ['Taylor Guitars'],
  ),
  GuideTopic(
    id: 'regular',
    title: 'Quando levar para regular',
    summary: 'Cordas duras demais ou zumbido',
    group: GuideGroup.guitarCare,
    action: GuideAction.list,
    paragraphs: [
      '"Regular" o violão é ajustar a altura das cordas e o braço pra ficar '
          'mais fácil de tocar, sem zumbido e sem corda dura demais.',
      'Quem faz isso é um luthier ou uma loja de instrumentos. Não é algo pra '
          'fazer sozinho no começo.',
    ],
    highlight:
        'Se as cordas estão muito duras de apertar, ou se sai um zumbido '
        'quando você toca, vale levar pra regular antes de achar que o '
        'problema é você.',
  ),
];
