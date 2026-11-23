<p align="center">
  <img src="assets/icon/chordai_icon_1024.png" alt="Ícone do ChordAI" width="120">
</p>

<h1 align="center">ChordAI</h1>

[![CI](https://github.com/imxder/ChordAI/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/imxder/ChordAI/actions/workflows/ci.yml) [![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=imxder_ChordAI&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=imxder_ChordAI) [![Coverage](https://sonarcloud.io/api/project_badges/measure?project=imxder_ChordAI&metric=coverage)](https://sonarcloud.io/component_measures?id=imxder_ChordAI&metric=coverage) [![versão](https://img.shields.io/github/v/release/imxder/ChordAI?label=vers%C3%A3o)](https://github.com/imxder/ChordAI/releases/latest)

![ChordAI no MacBook e no iPhone](docs/imagens/produto-apple.png)

Esse é o app do meu TCC de Engenharia de Software. A ideia é ajudar quem tá começando no violão: você toca o acorde e o app escuta e diz se saiu certo. Também tem afinador, cifras pra tocar junto com a música e um guia pra iniciante.

Fiz em Flutter, então roda no iPhone, no Android, no Windows e no Mac. O modelo que reconhece os acordes eu treinei no [ChordAI-backend](https://github.com/imxder/ChordAI-backend).

<!-- [CONFERIR] GIF de até 10 s reconhecendo um acorde, da sessão do vídeo de prova (16b): ![Reconhecendo um acorde](docs/imagens/reconhecer.gif) -->

## Telas

| | Início | Acordes | Reconhecer | Afinador | Tocar junto |
|---|---|---|---|---|---|
| **iPhone** | ![](docs/imagens/iphone_inicio.png) | ![](docs/imagens/iphone_acordes.png) | ![](docs/imagens/iphone_reconhecer.png) | ![](docs/imagens/iphone_afinador.png) | ![](docs/imagens/iphone_tocar_junto.png) |
| **Android** | ![](docs/imagens/android_inicio.png) | ![](docs/imagens/android_acordes.png) | ![](docs/imagens/android_reconhecer.png) | ![](docs/imagens/android_afinador.png) | ![](docs/imagens/android_tocar_junto.png) |

## Funcionalidades

- **Reconhecer acorde**: mostra em tempo real o acorde que o app está ouvindo. É a função principal. O treino de acorde, as sequências e o tocar junto usam a mesma leitura.
- **Acordes**: diagrama de cada acorde no braço do violão e o "Tocar e testar", que ouve você tocar e marca o acorde como aprendido depois de 3 acertos seguidos. Cada acerto precisa de uma batida nova: deixar o acorde soando conta uma vez só. Quando o acorde vira aprendido, o app toca um som e o botão leva pra lista de acordes.
- **Afinador**: detecta a nota de cada corda com o algoritmo YIN, com ponteiro estável, aviso de "afinada" e afinações alternativas (Drop D, meio tom abaixo, Open G, Open D, DADGAD) ou personalizadas.
- **Sequências**: treino de progressões de acordes com metrônomo.
- **Tocar junto**: cifras só com os acordes (o desenho de cada um e as setas da batida) que avançam no andamento da música ou esperam você trocar de acorde, com andamento ajustável e um resumo no fim com os acordes que você mais errou. Dá pra desligar o microfone e tocar só com o metrônomo. O modelo decide em janelas de 1,5 s, então acorde que dura menos de 1 s não conta.
- **Minhas músicas**: dá pra montar a sua música no próprio app, com as partes, os acordes, o andamento e a batida. Ela fica só no aparelho.
- **Guia do iniciante**: 12 tópicos pra quem nunca tocou, das partes do violão e como afinar até ler o diagrama, ler uma cifra, a batida, trocar de acorde e cuidar do violão. As fontes estão em [docs/guia_fontes.md](docs/guia_fontes.md).
- **Sons**: clique do metrônomo, som de acorde aprendido e de corda afinada ([docs/sons.md](docs/sons.md)). Dá pra desligar.
- **Ajustes** (Configurações no Android e no Windows): aparência (papel, branco, escuro ou igual ao celular), cor do app, afinação, leitura das cifras, sons, reconhecimento e privacidade. No celular, abre pela engrenagem no canto da tela inicial. Os acordes aprendidos aparecem na tela inicial, em "Seus acordes".

No celular, as abas de baixo são Início, Acordes, Reconhecer e Afinador, e as músicas abrem pelo card "Tocar músicas". No Windows e no Mac, as mesmas telas ficam numa barra lateral ([docs/desktop.md](docs/desktop.md)).

## Plataformas e como instalar

![ChordAI no Android e no Windows](docs/imagens/produto-android-windows.png)

| Plataforma | Como instalar |
|---|---|
| **Android** | baixo o `ChordAI.apk` pela [página Baixar da Wiki](https://github.com/imxder/ChordAI/wiki/Baixar) ou direto em [`releases/latest/download/ChordAI.apk`](https://github.com/imxder/ChordAI/releases/latest/download/ChordAI.apk). O Android pede pra permitir apps desconhecidos, e o Play Protect pode avisar: o passo a passo está na Wiki. Precisa de Android 7.0 ou mais novo (página Baixar). O QR Code do pôster aponta pra essa página. |
| **Windows** | baixo o [`ChordAI-windows.zip`](https://github.com/imxder/ChordAI/releases/latest/download/ChordAI-windows.zip), extraio a pasta `ChordAI` e abro o `ChordAI.exe`. Como o app não é assinado, o SmartScreen pode avisar: **[CONFERIR]** o texto do aviso e dos botões ("Mais informações" e "Executar assim mesmo"). |
| **Mac** | baixo o [`ChordAI-macos.zip`](https://github.com/imxder/ChordAI/releases/latest/download/ChordAI-macos.zip) e arrasto o `ChordAI.app` pra pasta Aplicativos. O app é universal (Apple Silicon e Intel), pede macOS 12 ou mais novo e tem só a assinatura ad-hoc (`.github/workflows/release.yml`), sem conta paga da Apple. O Gatekeeper vai avisar que não consegue verificar o app: **[CONFERIR]** o caminho em Ajustes do Sistema → Privacidade e Segurança → "Abrir mesmo assim". |
| **iPhone** | não tem pacote pra baixar. Instalo pelo Mac, com o cabo, em modo release (veja "Como rodar"). Pede iOS 15 ou mais novo. |

**[CONFERIR]** A release v0.2.1 só tem o `ChordAI.apk`. Os dois `.zip` são gerados pelo `release.yml` a partir da próxima tag, então os links do Windows e do Mac só funcionam depois dela.

## Como rodar

Requisitos: Flutter 3.47 (Dart 3.13) e, para iOS, Xcode com CocoaPods.

```bash
flutter pub get
flutter run
```

Para instalar no iPhone em modo release, com o iPhone no cabo ou na mesma rede:

```bash
flutter run --release -d <id-do-iphone>
```

O `flutter devices` mostra o id. Não use o `flutter install`: ele desinstala o app antes de instalar de novo, e isso apaga os acordes aprendidos, as preferências e as músicas.

No Mac e no Windows: `flutter run --release -d macos` e `flutter run --release -d windows`. As imagens de produto e as telas do Windows são geradas por script, e o jeito de refazer está em [`tool/gerar_produto.py`](tool/gerar_produto.py) e em [`test/imagens_docs_test.dart`](test/imagens_docs_test.dart).

## Como o reconhecimento funciona

O modelo escolhido roda dentro do aparelho, em TensorFlow Lite, sem internet nem computador. O app não pede permissão de internet e o som não sai do aparelho ([ADR 0001](docs/adr/0001-inferencia-no-aparelho.md) e [ADR 0003](docs/adr/0003-sem-modo-servidor.md)).

1. O microfone grava 22.050 Hz, mono, e o app guarda sempre os últimos 1,5 s (33.075 amostras).
2. A cada 0,5 s, se não for silêncio, essa janela vai pro modelo, fora da thread da interface. A chroma (quanto de cada nota há na janela) está dentro do modelo, então o app só manda o áudio bruto.
3. O modelo devolve uma probabilidade por acorde, mais a classe "nenhum acorde". Abaixo do limiar de confiança do modelo, o app diz "não reconheci" em vez de chutar.
4. Um acorde só aparece na tela quando sai igual em pelo menos 2 das últimas 3 leituras, e no máximo uma vez a cada 1,5 s.
5. Os dois modelos vêm das releases do backend, e o `model_info.json` de cada pasta guarda o limiar e o hash do `.tflite`.

O caminho completo, com o arquivo e o teste de cada passo, o afinador, o tocar junto e o que fica salvo no aparelho estão em [docs/como-funciona.md](docs/como-funciona.md).

O app traz dois modelos, e eu escolho qual usar em **Ajustes → Reconhecimento → Modelo no aparelho**:

| Modelo | Na tela | Acordes | Limiar | Pasta |
|---|---|---|---|---|
| **v3** (padrão) | "Só v3" | 8: Am, Bb, Bdim, C, Dm, Em, F e G | 0,50 | `assets/models/v3/` |
| **v3_meu** | "v3 + meu dataset" | 9: os 8 + A | 0,55 | `assets/models/v3_meu/` |

Fonte do limiar e dos acordes: o `model_info.json` e o `labels.json` de cada pasta.

**Os números.** Cada um é de um teste diferente, e eu digo qual:

| Teste | v3 | v3_meu |
|---|---:|---:|
| Acerto no **Test do V3**: 1508 janelas de 10 pessoas e violões que não aparecem no treino | **87,4%** | 85,7% |
| Falso aceite com **sem acorde gravado**: 48 janelas de cordas abafadas e afinando (quanto menor, melhor) | 81,2% | **22,9%** |

Fonte: [`experiments/results_duas_fontes/comparativo.md`](https://github.com/imxder/ChordAI-backend/blob/main/experiments/results_duas_fontes/comparativo.md), no backend. O acerto é sem limiar e só nos 8 acordes do v3. O v3 é o padrão porque acertou mais com pessoas e violões que ele nunca ouviu. O v3_meu reconhece o Lá maior e mostra bem menos acorde quando não tem acorde sendo tocado. O teste de sem acorde é pequeno, e as limitações estão no [ADR 0002](docs/adr/0002-dois-modelos-no-app.md). O A só aparece no app quando o v3_meu está escolhido.

**[CONFERIR]** O tempo de cada leitura no iPhone e a demora entre tocar o acorde e ele aparecer na tela ainda não foram medidos no celular. O método está em [docs/como-funciona.md](docs/como-funciona.md), seção 7. No meu computador, o `.tflite` leva 8,78 ms por janela com 1 thread (`export_report.json` do backend).

A API Flask do [ChordAI-backend](https://github.com/imxder/ChordAI-backend) continua lá, mas só como ferramenta pra eu testar um modelo pelo computador. Ela usa outro modelo (`trained_model/`) e o app não fala com ela.

## Testes

```bash
flutter analyze
flutter test                                           # todos
flutter test test/pitch_smoother_test.dart             # um arquivo só
```

São **571 testes em 41 arquivos** de `test/` (`flutter test`, 23/11/2026, num Mac): 561 passam e 10 são pulados de propósito (o `imagens_docs_test.dart`, que só roda num Windows). Mais 2 testes em `integration_test/`, que precisam de um aparelho. A contagem de cada arquivo vem da saída do `flutter test --reporter json`.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `abas_test.dart` | a barra do celular é Início, Acordes, Reconhecer e Afinador, e o microfone só liga na aba que aparece | 9 |
| `acabamento_test.dart` | o nível do microfone vai de 0 a 1, as telas de prática não mostram selo de servidor e o tocar junto mostra só artista e andamento | 4 |
| `afinador_gravacoes_test.dart` | o afinador troca de corda certo quando uma é tocada por cima da outra, numa gravação real | 2 |
| `afinador_tela_test.dart` | o afinador abre no Auto, a corda escolhida, a vibração ao afinar e o link pro guia | 6 |
| `chord_beats_test.dart` | quanto dura cada acorde na cifra (`Tempos:` e `:N`) | 6 |
| `chord_catalog_test.dart` | cada modelo tem os 5 arquivos, a lista de dificuldade bate com os acordes dos modelos e os diagramas têm 6 cordas | 8 |
| `chord_for_model_test.dart` | o acorde da cifra vira o acorde que o modelo conhece (tira o baixo, reduz extensão, troca enarmonia) | 9 |
| `chord_repeat_gate_test.dart` | a regra do treino de acorde (cada acerto pede uma batida nova) e a tela de treino | 16 |
| `chord_sequence_test.dart` | as repetições da cifra sem letra viram uma linha com quantas vezes | 9 |
| `chord_stabilizer_test.dart` | o acorde só passa com 2 de 3 leituras iguais, e silêncio passa direto | 7 |
| `cifra_parser_test.dart` | a leitura de Tom, Tempo, Capo e Batida | 4 |
| `cifras_sem_letra_test.dart` | nenhuma cifra do app tem letra | 3 |
| `desktop_test.dart` | a barra lateral no Windows e no Mac, a barra de abas no celular, mouse, teclado e a cara de cada sistema | 43 |
| `entrada_audio_test.dart` | só dá pra escolher a entrada de áudio no Windows e no Mac, e a escolhida é a usada | 7 |
| `guia_test.dart` | os 12 tópicos do guia, na ordem, e o botão de cada um abre a tela certa | 21 |
| `imagens_docs_test.dart` | gera as imagens do Windows de `docs/imagens/` (pulado fora do Windows) | 10 |
| `latest_samples_buffer_test.dart` | o buffer circular guarda as últimas N amostras, na ordem | 4 |
| `layout_sizes_test.dart` | cada tela cabe em celular pequeno, tablet, modo deitado e fonte grande, e na janela do computador | 206 |
| `lyric_player_diagram_test.dart` | tocar num acorde da cifra abre o diagrama dele | 1 |
| `lyric_practice_test.dart` | os acordes saem da cifra na ordem certa, com o lugar de cada um | 2 |
| `microfone_desktop_test.dart` | microfone bloqueado ou entrada desconectada no Windows, com a mensagem de onde liberar | 12 |
| `minhas_musicas_test.dart` | criar, editar, apagar e reabrir uma música, e ela vira a cifra com a mesma sequência | 19 |
| `musicas_test.dart` | a música abre no tocar junto, o clique, tocar sem microfone e o BPM salvo por música | 10 |
| `navegacao_test.dart` | uma tela abre a outra, e o erro de reconhecimento mostra a mensagem fixa | 4 |
| `on_device_model_test.dart` | o modelo padrão é o v3, e o A só aparece com o v3_meu | 5 |
| `pcm16_decoder_test.dart` | os bytes viram amostras, com o byte que sobra entre blocos | 3 |
| `pitch_detector_test.dart` | o YIN acerta as 6 cordas com erro abaixo de 1 cent e não erra a oitava com harmônico forte | 14 |
| `pitch_smoother_test.dart` | o ponteiro do afinador segura a corda, ignora leitura isolada e só troca de corda confirmando | 13 |
| `privacy_policy_test.dart` | o `PRIVACY.md` tem as seções da LGPD, vai junto no app e a tela mostra todas | 6 |
| `recognition_mode_migration_test.dart` | quem tinha o modo servidor abre no aparelho sem perder nada | 2 |
| `recorded_strings_test.dart` | o afinador acerta a nota de gravações reais das 6 cordas (`test/fixtures/strings/`) | 6 |
| `segundo_plano_test.dart` | o microfone desliga com o app escondido, e a música pausa e volta de onde estava | 7 |
| `settings_test.dart` | a engrenagem abre os Ajustes, o nome da tela por plataforma, e os dados de perfil antigos somem | 14 |
| `sliding_pcm_buffer_test.dart` | as janelas do afinador saem na ordem, com blocos de qualquer tamanho | 3 |
| `sons_test.dart` | o clique forte no tempo 1, o som de aprendido e o de afinado tocam uma vez, e com Sons desligado nada toca | 15 |
| `tela_acesa_test.dart` | a tela fica acesa só enquanto o tocar junto roda | 1 |
| `theme_contrast_test.dart` | as cores do app têm contraste de texto WCAG AA em todas as aparências | 20 |
| `tocar_junto_tela_test.dart` | a batida cai no compasso certo e a cifra pinta o acorde certo e o errado | 7 |
| `tocar_junto_test.dart` | 12 cenários simulados (certinho, atrasado, modelo errando, silêncio...) nos dois jeitos de tocar junto, conferindo o placar | 24 |
| `tuner_note_test.dart` | medir contra a corda escolhida, mesmo perto de outra | 3 |
| `widget_test.dart` | a tela inicial, o atalho pros acordes, a troca de aba e que não sobrou nada da gamificação | 6 |
| `integration_test/chord_model_equivalence_test.dart` | a saída de cada modelo, no aparelho, bate com a esperada pelo backend (`example_expected.json`) | 2 |

**Por que o teste de equivalência roda no aparelho e não no computador.** Ele carrega o `.tflite` pela biblioteca nativa do TensorFlow Lite, e o `flutter test` comum roda na máquina de desenvolvimento, sem essa biblioteca. No celular, no simulador ou no Windows e no Mac (com as bibliotecas de `blobs/`), ela existe, e é onde o app de verdade roda o modelo.

```bash
flutter test integration_test/chord_model_equivalence_test.dart -d <id-do-aparelho>
```

Pra conferir se os `.tflite` em `assets/models/` são os das releases do backend, sem trocar nenhum arquivo por engano:

```bash
python3 tool/conferir_modelos.py
```

O script calcula o sha256 de cada `chord_model.tflite` e compara com o campo `sha256` do `model_info.json` da mesma pasta. Se algum não bater, ele sai com erro. O CI roda esse script em todo push.

## Qualidade

- **CI** (`.github/workflows/ci.yml`): em todo push e PR, confere a formatação, roda o `flutter analyze` e o `flutter test`, confere o hash dos modelos e compila o APK e o app do Mac.
- **SonarCloud**: análise e cobertura dos testes, com o Quality Gate no PR. Os PRs do Dependabot não rodam a análise. Os badges de qualidade e de cobertura do topo são dele.
- **Dependabot** (`.github/dependabot.yml`): toda segunda, confere se tem versão nova dos pacotes. O `tflite_flutter` fica de fora: ele roda os modelos congelados, e só troco de versão testando no iPhone e no Android.
- **Release** (`.github/workflows/release.yml`): numa tag `v*`, gera o APK assinado e os `.zip` do Windows e do Mac.
- **Privacidade**: o app não tem conta, anúncio nem analytics e não pede internet. O que ele guarda fica no aparelho. A política está em [PRIVACY.md](PRIVACY.md) e a segurança em [docs/seguranca.md](docs/seguranca.md).

## Estrutura

```
lib/
  models/     dados e regras (acordes, cifras, afinações, regra do treino, info do modelo)
  screens/    telas
  services/   áudio, afinador, reconhecimento no aparelho, sons, parser de cifras
  state/      estado do app e preferências salvas
  theme/      cores, fontes e o jeito de cada plataforma
  widgets/    componentes visuais
assets/       cifras, sequências, sons, imagens, ícone, fontes e os dois modelos (assets/models/v3 e assets/models/v3_meu)
blobs/        a biblioteca do TFLite pro Windows e pro Mac
test/         testes unitários, de tela e de layout
integration_test/  teste de equivalência dos modelos no aparelho
tool/         conferir_modelos.py (hash dos modelos), gerar_icones.py, gerar_sons.py e gerar_produto.py
docs/         como funciona, arquitetura, computador, sons, fontes do guia, segurança e roteiro de teste no Android
docs/adr/     as decisões de arquitetura (inferência no aparelho, os dois modelos e a saída do modo servidor)
docs/imagens/ as capturas de tela e as imagens de produto
```

Como as camadas conversam, onde ficam as regras e qual arquivo é cada tela: [docs/arquitetura.md](docs/arquitetura.md).

## Links

- [Wiki](https://github.com/imxder/ChordAI/wiki) e a página [Baixar](https://github.com/imxder/ChordAI/wiki/Baixar)
- [ChordAI-backend](https://github.com/imxder/ChordAI-backend): treino, experimentos, exportação do modelo e a API de teste
- [ChordAI Guitar Chords](https://www.kaggle.com/datasets/imxder/chordai-guitar-chords-v1), o meu dataset no Kaggle (CC BY-SA 4.0)
- [Guitar Chords V3](https://www.kaggle.com/datasets/fabianavinci/guitar-chords-v3), da Fabiana Vinci (CC BY-SA 4.0), que ela me autorizou a usar pra treinar e distribuir os pesos no app, com crédito e link
