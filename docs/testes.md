# Testes

O app tem **571 testes em 41 arquivos** de `test/`, e mais **2** em `integration_test/` que precisam de um aparelho. Dos 571, **561 passam e 10 são pulados de propósito** (os do `imagens_docs_test.dart`, que só rodam num Windows). Nenhum falha.

## Como contei

Contei rodando os testes, sem estimar. Em 23/11/2026, num Mac, no código da `master` depois do PR #40 (a branch `docs/final`, que só muda documentação e o `imagens_docs_test.dart`, que é pulado):

```bash
flutter test --reporter json $(git ls-files 'test/*_test.dart' 'test/**/*_test.dart')
```

Cada teste que começa (`testStart`) e termina (`testDone`) conta uma vez, agrupado pelo arquivo (`suite`). Um teste que roda em vários casos, como o `layout_sizes_test.dart` (um por tela e por tamanho de janela), conta uma vez por caso. Os 10 pulados vêm marcados como `skipped`.

Pra rodar:

```bash
flutter test                                           # todos
flutter test test/pitch_smoother_test.dart             # um arquivo só
flutter test --coverage                                # com a cobertura, que o CI manda pro SonarCloud
```

## O que fica de fora

- **`test/imagens_docs_test.dart`** (10 pulados): gera as imagens do Windows de `docs/imagens/`. Precisa da fonte Segoe UI de verdade, então só roda num Windows, com `--update-goldens --dart-define=IMAGENS=true`.
- **`integration_test/chord_model_equivalence_test.dart`** (2): confere a saída de cada modelo contra a esperada pelo backend (`example_expected.json`). Carrega o `.tflite` pela biblioteca nativa do TensorFlow Lite, que o `flutter test` comum não tem, então roda num aparelho:

```bash
flutter test integration_test/chord_model_equivalence_test.dart -d <id-do-aparelho>
```

- **O `OnDeviceChordService` por dentro** (o modelo rodando de verdade) só é coberto por esse teste de equivalência. Os outros testes usam um reconhecedor falso no lugar.

## Como os testes funcionam

- **Reconhecedor falso.** Toda tela que usa o microfone recebe o `ChordRecognizer` pelo construtor, e os testes passam um que finge ouvir um acorde (`MicQueOuve` em `test/test_helpers.dart`, `ReconhecedorFalso` em `test/tocar_junto/simulador.dart`). Assim nenhum teste precisa de microfone nem do modelo.
- **Tocar junto simulado.** O `tocar_junto_test.dart` toca as cifras do app com um modelo falso (`ModeloFalso`) e confere o placar de 12 cenários, nos dois jeitos de tocar junto. Os números são de simulação, não de um violão de verdade.
- **Sons falsos.** O `test/flutter_test_config.dart` troca o `AppSounds` por um que só anota o que tocou, e o `sons_test.dart` e o `musicas_test.dart` conferem essa lista.
- **Preferências.** Os testes usam o `shared_preferences` de mentira, e o `appState.loadProgress()` recarrega o estado a cada teste.
- **Gravações reais.** O afinador é testado com as 6 cordas gravadas de verdade, em `test/fixtures/strings/`.

## Onde está cada teste

### Reconhecimento e modelo: 57

Cobre a leitura do microfone até o acorde, os dois modelos e a entrada de áudio.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `chord_stabilizer_test.dart` | o acorde só passa com 2 de 3 leituras iguais, e silêncio passa direto | 7 |
| `latest_samples_buffer_test.dart` | o buffer circular guarda as últimas N amostras, na ordem | 4 |
| `pcm16_decoder_test.dart` | os bytes viram amostras, com o byte que sobra entre blocos | 3 |
| `on_device_model_test.dart` | o modelo padrão é o v3, e o A só aparece com o v3_meu | 5 |
| `chord_catalog_test.dart` | cada modelo tem os 5 arquivos, a lista de dificuldade bate com os acordes dos modelos e os diagramas têm 6 cordas | 8 |
| `chord_for_model_test.dart` | o acorde da cifra vira o acorde que o modelo conhece (tira o baixo, reduz extensão, troca enarmonia) | 9 |
| `entrada_audio_test.dart` | só dá pra escolher a entrada de áudio no Windows e no Mac, e a escolhida é a usada | 7 |
| `microfone_desktop_test.dart` | microfone bloqueado ou entrada desconectada no Windows, com a mensagem de onde liberar | 12 |
| `recognition_mode_migration_test.dart` | quem tinha o modo servidor abre no aparelho sem perder nada | 2 |

### Regras da prática (treino do acorde e tocar junto): 60

Cobre a regra do treino, a `PlayAlongEngine`, a tela do tocar junto e o clique.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `chord_repeat_gate_test.dart` | a regra do treino de acorde (cada acerto pede uma batida nova) e a tela de treino | 16 |
| `tocar_junto_test.dart` | 12 cenários simulados (certinho, atrasado, modelo errando, silêncio...) nos dois jeitos de tocar junto, conferindo o placar | 24 |
| `tocar_junto_tela_test.dart` | a batida cai no compasso certo e a cifra pinta o acorde certo e o errado | 7 |
| `musicas_test.dart` | a música abre no tocar junto, o clique, tocar sem microfone e o BPM salvo por música | 10 |
| `lyric_player_diagram_test.dart` | tocar num acorde da cifra abre o diagrama dele | 1 |
| `lyric_practice_test.dart` | os acordes saem da cifra na ordem certa, com o lugar de cada um | 2 |

### Afinador: 47

Cobre o YIN, o ponteiro estável e a tela.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `pitch_detector_test.dart` | o YIN acerta as 6 cordas com erro abaixo de 1 cent e não erra a oitava com harmônico forte | 14 |
| `pitch_smoother_test.dart` | o ponteiro do afinador segura a corda, ignora leitura isolada e só troca de corda confirmando | 13 |
| `recorded_strings_test.dart` | o afinador acerta a nota de gravações reais das 6 cordas (`test/fixtures/strings/`) | 6 |
| `afinador_gravacoes_test.dart` | o afinador troca de corda certo quando uma é tocada por cima da outra, numa gravação real | 2 |
| `afinador_tela_test.dart` | o afinador abre no Auto, a corda escolhida, a vibração ao afinar e o link pro guia | 6 |
| `sliding_pcm_buffer_test.dart` | as janelas do afinador saem na ordem, com blocos de qualquer tamanho | 3 |
| `tuner_note_test.dart` | medir contra a corda escolhida, mesmo perto de outra | 3 |

### Músicas e cifras: 41

Cobre ler a cifra, a duração dos acordes e as músicas criadas no app.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `cifra_parser_test.dart` | a leitura de Tom, Tempo, Capo e Batida | 4 |
| `chord_beats_test.dart` | quanto dura cada acorde na cifra (`Tempos:` e `:N`) | 6 |
| `cifras_sem_letra_test.dart` | nenhuma cifra do app tem letra | 3 |
| `chord_sequence_test.dart` | as repetições da cifra sem letra viram uma linha com quantas vezes | 9 |
| `minhas_musicas_test.dart` | criar, editar, apagar e reabrir uma música, e ela vira a cifra com a mesma sequência | 19 |

### Telas, abas e as quatro plataformas: 337

Cobre as abas, a barra lateral, o tamanho de cada tela, o guia, as cores e os Ajustes.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `abas_test.dart` | a barra do celular é Início, Acordes, Reconhecer e Afinador, e o microfone só liga na aba que aparece | 9 |
| `desktop_test.dart` | a barra lateral no Windows e no Mac, a barra de abas no celular, mouse, teclado e a cara de cada sistema | 43 |
| `layout_sizes_test.dart` | cada tela cabe em celular pequeno, tablet, modo deitado e fonte grande, e na janela do computador | 206 |
| `widget_test.dart` | a tela inicial, o atalho pros acordes, a troca de aba e que não sobrou nada da gamificação | 6 |
| `navegacao_test.dart` | uma tela abre a outra, e o erro de reconhecimento mostra a mensagem fixa | 4 |
| `guia_test.dart` | os 12 tópicos do guia, na ordem, e o botão de cada um abre a tela certa | 21 |
| `theme_contrast_test.dart` | as cores do app têm contraste de texto WCAG AA em todas as aparências | 20 |
| `acabamento_test.dart` | o nível do microfone vai de 0 a 1, as telas de prática não mostram selo de servidor e o tocar junto mostra só artista e andamento | 4 |
| `settings_test.dart` | a engrenagem abre os Ajustes, o nome da tela por plataforma, e os dados de perfil antigos somem | 14 |
| `imagens_docs_test.dart` | gera as imagens do Windows de `docs/imagens/` (pulado fora do Windows) | 10 |

### Privacidade, sons e segundo plano: 29

Cobre a política, os três sons, o microfone com o app escondido e a tela acesa.

| Arquivo | O que garante | Testes |
|---|---|---:|
| `privacy_policy_test.dart` | o `PRIVACY.md` tem as seções da LGPD, vai junto no app e a tela mostra todas | 6 |
| `sons_test.dart` | o clique forte no tempo 1, o som de aprendido e o de afinado tocam uma vez, e com Sons desligado nada toca | 15 |
| `segundo_plano_test.dart` | o microfone desliga com o app escondido, e a música pausa e volta de onde estava | 7 |
| `tela_acesa_test.dart` | a tela fica acesa só enquanto o tocar junto roda | 1 |

### Teste no aparelho: 2

| Arquivo | O que garante | Testes |
|---|---|---:|
| `integration_test/chord_model_equivalence_test.dart` | a saída de cada modelo, no aparelho, bate com a esperada pelo backend (`example_expected.json`) | 2 |

## Total por área

| Área | Testes |
|---|---:|
| Reconhecimento e modelo | 57 |
| Regras da prática (treino do acorde e tocar junto) | 60 |
| Afinador | 47 |
| Músicas e cifras | 41 |
| Telas, abas e as quatro plataformas | 337 |
| Privacidade, sons e segundo plano | 29 |
| **Total** | **571** |

Mais os 2 testes de `integration_test/`, que ficam fora da conta.
