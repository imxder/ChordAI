# ChordAI no computador

No celular o app tem barra de abas embaixo e tudo pensado pro dedo. No Windows e no Mac ele usa as
mesmas telas, com a mesma lógica, mas com a casca de um programa de computador. Nada disso aparece
no iPhone nem no Android: tudo passa por `isDesktop`, em `lib/theme/platform_style.dart`.

![Reconhecer acorde no Windows](imagens/windows_reconhecer.png)

## O que muda no computador

- **Barra lateral** no lugar das abas de baixo (`lib/widgets/desktop_shell.dart`), com as mesmas
  quatro abas. Cada aba tem a própria pilha de telas: abrindo um acorde ou uma música, a barra
  continua do lado. Abaixo de 1000 px de largura a barra recolhe pra só os ícones, e o ☰ abre e
  fecha.
- **Ordem da barra:** Início, Afinador, Aprender acordes, Reconhecer acorde, Guia do iniciante e
  Músicas. No pé ficam a Entrada de áudio, as Preferências (engrenagem) e o Perfil. No celular o
  afinador, o reconhecer e o guia estão nos cards do Início; no computador, sem eles na barra, só
  dava pra chegar pelo Início.
- **Preferências** (aparência, cor, afinação, leitura das cifras, reconhecimento e privacidade)
  saem do Perfil no computador e viram a tela da engrenagem. No celular continuam no Perfil; as
  duas usam o mesmo `PreferencesSection`.
- **Afinador em duas colunas** no computador: o medidor à esquerda e a afinação, as cordas e as
  opções à direita. Assim ele cabe inteiro, sem rolar, até na janela mínima (800 × 560).
- **Afinador, Reconhecer acorde e Guia do iniciante** só ficam montados enquanto a aba está
  escolhida (`keepAlive: false` no `DesktopDestination`), diferente das outras abas: o afinador liga
  o microfone assim que abre, e se ficasse montado o microfone ligaria junto com o app.
- **"Entrada de áudio"** no pé da barra, porque no computador é comum trocar de microfone
  (interface, webcam, pedaleira). A lista também está em Perfil → Reconhecimento.
- **Só o modelo no aparelho.** O computador roda o modelo sem esforço, então o modo servidor não
  aparece. Se ele ficou salvo de antes, o computador ignora.
- **Cabeçalho** com o título grande à esquerda e o botão de voltar, e a coluna de leitura com até 720
  px (no celular são 600).
- **Duas colunas** onde ajuda:
  - Acordes: a lista de um lado e o acorde aberto do outro.
  - Tocar junto: a cifra de um lado e o painel (acorde, próximo, BPM e Começar) do outro.
  - No Reconhecer o braço e o nome do acorde ficam bem maiores, pra ver de longe.
- **Mouse e teclado** (`lib/widgets/desktop_input.dart`):
  - Realce ao passar o mouse e cursor de mão no que dá pra clicar.
  - Espaço começa e para a prática e o tocar junto.
  - Esc volta uma tela.
  - As bandejas que sobem de baixo viram diálogo no meio da janela.
- **Botão de baixo** compacto, à direita, em vez da pílula na largura toda.

## A cara do Windows 11

Fica em `lib/theme/windows_style.dart` e só vale quando `desktopLook` é `windows`. Não usei
nenhum pacote novo:

- Fonte Segoe UI Variable (cai pra Segoe UI no Windows 10).
- Barra lateral um tom mais escura e o conteúdo numa "folha" com o canto de cima arredondado,
  como o NavigationView. Os itens têm as medidas dele: pílula de 36 px, cantos de 4 e a barrinha
  da cor do app dentro dela.
- Cantos de 8 nos cards, contorno fino e, no escuro, cinza (#202020) em vez do preto do iPhone.
- Botões retangulares de 36 px, com canto de 6.
- Troca de tela suave: a tela nova sobe um pouco enquanto aparece.
- A barra de título fica com a cor do app, inclusive no escuro. Quem pinta é o runner em C++
  (`windows/runner/flutter_window.cpp`, canal `chordai/window`), porque o Flutter não desenha essa
  barra. O ícone e o texto dela ficam escondidos, e o "☰ ChordAI" da barra lateral faz esse papel.

O que eu deixei de fora: o fundo Mica de verdade e uma barra de título própria. Os pacotes pra isso
(`flutter_acrylic` e `window_manager`) são antigos ou pedem o Flutter 3.50, e o projeto está no
3.47.1.

## Como eu sei que o celular não mudou

- `test/layout_sizes_test.dart` roda as telas nos quatro tamanhos de celular de antes e também na
  janela inicial (1200 × 800) e na mínima (800 × 560) do Windows.
- `test/desktop_test.dart` confere a barra lateral no Windows e no Mac e a barra de abas no celular.
- Comparei pixel a pixel 18 telas no iPhone e 18 no Android, renderizadas a partir da master e da
  branch do layout de computador: ficaram iguais.

## A cara do Mac

Fica em `lib/theme/mac_style.dart` e no `macos/Runner/MainFlutterWindow.swift`, e só vale quando
`desktopLook` é `mac`. Também não usei pacote novo:

- **Barra de título integrada.** A janela tem a barra transparente, o título escondido e o conteúdo
  ocupando a janela toda, então os três botões do Mac ficam por cima do app, como no Finder e no
  Música. O título continua existindo (aparece no Mission Control e no menu Janela). A barra lateral
  e o conteúdo começam 28 px abaixo, pra nada ficar embaixo dos botões.
- **Arrastar a janela.** O Flutter recebe todos os cliques, então a janela não arrastaria. Uma
  faixa nativa de 28 px no topo (`TitleBarDragStrip`) arrasta a janela e, com dois cliques, maximiza.
- **Barra lateral translúcida.** O conteúdo da janela é um `NSVisualEffectView` com o material
  `.sidebar`, o mesmo do Finder, e o Flutter fica por cima com o fundo transparente. Na casca, a
  barra lateral não pinta fundo (o vidro aparece) e o conteúdo à direita é opaco, com uma linha fina
  separando.
- **Itens da barra como no Finder.** Sem o ☰ e sem a barrinha laranja do Windows. Em cima, um título
  pequeno em cinza; os itens têm 28 px, canto de 6, texto de 13 e a aba escolhida num retângulo com
  a cor do app clarinha. Abaixo de 1000 px a barra continua recolhendo pra só os ícones.
- **Escuro do Mac.** Cinza das janelas do macOS (#1E1E1E) em vez do preto do iPhone.
- **Botões de 32 px** com canto de 6, o tamanho dos botões do macOS.
- **A janela segue a aparência do app.** O vidro da barra lateral e os botões da janela seguem o
  claro ou escuro do Mac, não o do app. Por isso o app avisa o runner pelo canal `chordai/window`
  (`setAppearance`), o mesmo canal que o Windows usa pra cor da barra de título.

Comparei com o `macos_window_utils` 1.9.1 e o `macos_ui` 2.2.2 (os dois MIT, só macOS, do
publicador macosui.dev). O primeiro faz a barra de título e a transparência, mas isso deu pra fazer
com umas 30 linhas de Swift, sem entrar no `pubspec.lock` de todas as plataformas. O segundo traz
os widgets do Mac prontos, mas obriga a ter outra versão de cada tela, como o `fluent_ui` no Windows.

## Imagens

As imagens em `docs/imagens/` saem de `test/imagens_docs_test.dart`, com a fonte Segoe UI de
verdade. Como precisa dela, só roda num Windows:

```
flutter test test/imagens_docs_test.dart --update-goldens --dart-define=IMAGENS=true
```
