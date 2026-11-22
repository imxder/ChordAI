# Fontes do guia do iniciante

O guia do iniciante (`lib/models/guide_content.dart`) mistura três tipos de informação, e aqui está de onde veio cada uma:

- o que vem do próprio app, que tem como fonte o código;
- o que é notação de cifra, que é a mesma em qualquer lugar;
- o que é sobre tocar violão, que eu tirei de fabricantes de violão e de cordas.

Pra essas últimas, eu só usei página de fabricante que eu abri de verdade, e tirei o número quando não achei fonte boa pra ele. No app, o fim de cada tópico que usa informação de fora tem uma linha "Fonte:" com o nome do site, sem link (o app não abre nada fora dele).

Todas as páginas foram acessadas em 22/11/2026.

| Tópico | Afirmação | Fonte | Link | Acesso |
|---|---|---|---|---|
| Partes do violão | Os nomes das partes: cabeça (headstock), tarraxas (tuning machines), pestana (nut), braço (neck), escala (fingerboard), trastes (frets), corpo (body), boca (soundhole), cavalete (bridge) | Martin Guitar, "Guitar Slang & Jargon for Beginners: Acoustic Guitar Terms Explained" | https://www.martinguitar.com/blog-categories/tips-tutorials/blog-091526-guitar-slang-jargon-for-beginners-acoustic-guitar-terms-explained.html | 22/11/2026 |
| Partes do violão | A lista das partes de novo, e a ordem E A D G B E da corda mais grossa pra mais fina | Martin Guitar, "Acoustic Guitar Playing Guide" | https://www.martinguitar.com/blog-categories/tips-tutorials/blog-032723-acoustic-guitar-playing-guide.html | 22/11/2026 |
| Partes do violão | As cordas são numeradas da 1ª (mais fina) à 6ª (mais grossa) | o próprio app: o desenho das cordas do afinador (`lib/widgets/strings_illustration.dart`, que mostra 6ª Mi a mais grossa até 1ª Mi a mais fina) | — | — |
| Partes do violão | "Casa" é o espaço entre dois trastes | termo de violão em português, sem fonte externa; é o mesmo termo que o app já usa no afinador e nos diagramas | — | — |
| Como afinar o violão | Afinação padrão E A D G B E, da 6ª corda pra 1ª | `lib/models/tuning_preset.dart` (preset Padrão: E2 A2 D3 G3 B3 E4) | — | — |
| Como ler o diagrama | Linhas em pé são as cordas (a 6ª à esquerda), deitadas são os trastes, a linha grossa de cima é a pestana, bolinha é a casa, "o" é corda solta e "x" é corda que não toca | `lib/widgets/guitar_neck.dart` (o desenho que o app usa) e `lib/models/chord_diagrams.dart` (a lista de casas vai da 6ª corda pra 1ª) | — | — |
| Seu primeiro acorde: Em | 2ª casa nas cordas 5 e 4, as outras soltas | `lib/models/chord_diagrams.dart` (`'Em': [0, 2, 2, 0, 0, 0]`) | — | — |
| Seu primeiro acorde: Em | O Em é o primeiro da lista de acordes | `lib/models/chord_difficulty.dart` | — | — |
| Como ler uma cifra | C Dó, D Ré, E Mi, F Fá, G Sol, A Lá, B Si, e o "m" de menor | notação padrão de cifra | — | — |
| Como ler uma cifra | O "2×" no fim da linha quer dizer repetir a linha | `lib/widgets/chord_sequence.dart` (`groupRepeats`) | — | — |
| A batida | ↓ pra baixo, ↑ pra cima, pontinho é tempo sem batida, "x" é abafado | `lib/widgets/chord_sequence.dart` (as setas) e `lib/services/cifra_parser.dart` (o X da batida) | — | — |
| A batida | A batida Comum é ↓ ↓ ↑ ↑ ↓ ↑ | `lib/models/user_song.dart` (`D1 D2 U2& U3& D4 U4&`) | — | — |
| A batida | Começar treinando só pra baixo e depois pra cima | Martin Guitar, "Acoustic Guitar Playing Guide" | https://www.martinguitar.com/blog-categories/tips-tutorials/blog-032723-acoustic-guitar-playing-guide.html | 22/11/2026 |
| A batida | Abafar é encostar de leve nas cordas a mão que faz a batida (escrito de forma geral, porque a página não diz onde a mão vai) | Taylor Guitars, Wood & Steel, "Guitar Lesson: Strumming, Picking and Palm Muting" | https://woodandsteel.taylorguitars.com/issue/2023-issue-3/feature-story/guitar-lesson-strumming-picking-and-palm-muting/ | 22/11/2026 |
| Trocar de acorde | Do Em pro Am, o dedo da 4ª corda na 2ª casa fica onde está | `lib/models/chord_diagrams.dart` (Em e Am têm a 4ª corda na 2ª casa) | — | — |
| Quanto treinar por dia | Entre 15 e 30 minutos por dia | Yamaha, "Eight Great Tips for Learning Steel-String Acoustic Guitar" | https://hub.yamaha.com/guitars/g-acoustic/eight-great-tips-for-learning-steel-string-acoustic-guitar/ | 22/11/2026 |
| Quanto treinar por dia | Não precisa treinar horas; dá pra fazer blocos de 5 minutos com 1 minuto de pausa | Taylor Guitars, "5 Guitar Playing Resolutions For The New Year" | https://blog.taylorguitars.com/5-guitar-playing-resolutions-for-the-new-year | 22/11/2026 |
| Quanto treinar por dia | 3 acertos seguidos marcam o acorde como aprendido | `lib/state/app_state.dart` (`chordMasteryHits`) | — | — |
| Dor nos dedos | As pontas dos dedos doem no começo, é normal, e com o treino os dedos criam calo; fazer pausas e aumentar o tempo aos poucos; corda mais fina ajuda a doer menos | Martin Guitar, "A Beginner's Guide to Overcoming Guitar Frustrations" | https://www.martinguitar.com/blog-categories/tips-tutorials/blog-052924-beginners-guide-overcoming-frustrations.html | 22/11/2026 |
| Dor nos dedos | Os dedos se acostumam rápido com treino regular | Yamaha, "Eight Great Tips for Learning Steel-String Acoustic Guitar" | https://hub.yamaha.com/guitars/g-acoustic/eight-great-tips-for-learning-steel-string-acoustic-guitar/ | 22/11/2026 |
| Acessórios | Palheta média: entre 0,60 e 0,80 mm; pra quem começa batendo nas cordas, uma mais fina também serve | Martin Guitar, "Guitar Pick Buying Guide" | https://www.martinguitar.com/blog-categories/tips-tutorials/blog-110123-guitar-picks.html | 22/11/2026 |
| Trocar as cordas | Quem toca de vez em quando troca a cada 2 ou 3 meses; trocar antes se a corda estiver enferrujada, áspera, torta ou com o som sem vida | Taylor Guitars, "How Often Should You Change Guitar Strings?" | https://blog.taylorguitars.com/how-often-should-you-change-guitar-strings | 22/11/2026 |

## A imagem do violão

O tópico "Partes do violão" usa um desenho pronto, só de contorno, e os nomes das partes (em português) o app escreve por cima, pelo código (`lib/widgets/guitar_parts_drawing.dart`). O app pinta o contorno com a cor do texto do tema, por isso ele aparece escuro no tema claro e claro no tema escuro.

| Arquivo no app | Imagem original | Autor | Licença | Link | Acesso |
|---|---|---|---|---|---|
| `assets/images/violao.png` | "Simple line art vector image of acoustic guitar" ("Simple Guitar" no arquivo), publicada no Openclipart e no Public Domain Vectors | jppi_Stu | Domínio público (o próprio arquivo marca http://creativecommons.org/licenses/publicdomain/, e a página diz que dá pra copiar, modificar, distribuir e usar até com fins comerciais sem pedir permissão) | https://publicdomainvectors.org/en/free-clipart/Simple-line-art-vector-image-of-acoustic-guitar/13848.html | 22/11/2026 |

O que eu mudei no arquivo: gerei um PNG de 613 × 1478 a partir do SVG, cortei a margem branca e transformei o branco em transparente, deixando só as linhas. Mesmo sem a licença pedir, eu deixo o crédito aqui.

## O que ficou sem número

- **Quanto tempo o calo leva pra formar.** O guia antigo dizia "2 a 4 semanas". Não achei esse número numa página de fabricante que eu conseguisse abrir, então ficou "com o treino, a pele cria calo e a dor passa".
- **Quanto tempo esperar pra afinar de novo a corda nova.** O guia antigo dizia "10 a 15 minutos". Ficou "afine de novo depois de tocar um pouco".

## Páginas que eu não consegui usar

As páginas da Fender e do site principal da Yamaha recusaram o acesso (erro 403), as da Gibson vieram sem o texto, e na página de palhetas da D'Addario o número só apareceu num resumo, não no texto da página. Nenhuma delas entrou na tabela.
