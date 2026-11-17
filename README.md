# ChordAI

Esse é o app do meu TCC de Engenharia de Software. A ideia é ajudar quem tá começando no violão: você toca o acorde e o app escuta e diz se saiu certo. Também tem afinador, cifras pra tocar junto com a música e um guia pra iniciante.

Fiz em Flutter, então roda no iPhone, no Android e no Windows. O modelo que reconhece os acordes eu treinei no [ChordAI-backend](https://github.com/imxder/ChordAI-backend).

## Funcionalidades

- **Afinador**: detecta a nota de cada corda com o algoritmo YIN, com ponteiro estável, aviso de "afinada" e afinações alternativas (Drop D, meio tom abaixo, Open G, Open D, DADGAD) ou personalizadas.
- **Acordes**: diagrama de cada acorde no braço do violão e modo "testar", que ouve você tocar e conta os acertos seguidos até marcar o acorde como aprendido.
- **Reconhecer acorde**: mostra em tempo real o acorde que o app está ouvindo.
- **Sequências**: treino de progressões de acordes com metrônomo.
- **Tocar junto**: letra e cifra que avançam conforme você troca de acorde, com batida, andamento ajustável e resumo de acertos no fim da música.
- **Guia do iniciante**: acessórios, postura, como afinar, troca de cordas e dor nos dedos.
- **Perfil**: acordes aprendidos, último treino, cor do app e aparência (papel, branco, escuro ou igual ao celular).

O app traz dois modelos, e eu escolho qual usar em **Perfil → Reconhecimento → Modelo no aparelho**:

| Modelo | Na tela | Acordes | Pasta |
|---|---|---|---|
| **v3** (padrão) | "Só v3" | 8: Am, Bb, Bdim, C, Dm, Em, F e G | `assets/models/v3/` |
| **v3_meu** | "v3 + meu dataset" | 9: os 8 + A | `assets/models/v3_meu/` |

O v3 é o padrão porque acertou mais no teste com pessoas e violões que ele nunca ouviu. O v3_meu reconhece o Lá maior e mostra bem menos acorde quando não tem acorde sendo tocado. Os números e o motivo estão no [ADR 0002](docs/adr/0002-dois-modelos-no-app.md). O A só aparece no app quando o v3_meu está escolhido.

Quando não há acorde claro, os dois respondem "não reconheci" em vez de chutar.

## Como funciona o reconhecimento

O app tem dois modos, que se escolhe em **Perfil → Reconhecimento**. As telas de prática funcionam igual nos dois.

### No aparelho (padrão)

O modelo escolhido roda dentro do celular, em TensorFlow Lite (`assets/models/v3/chord_model.tflite` ou `assets/models/v3_meu/chord_model.tflite`), sem internet nem computador. Por que saiu do servidor está no [ADR 0001](docs/adr/0001-inferencia-no-aparelho.md).

Os dois modelos vêm das releases do backend, [`model-v3`](https://github.com/imxder/ChordAI-backend/releases/tag/model-v3) e [`model-v3-meu`](https://github.com/imxder/ChordAI-backend/releases/tag/model-v3-meu). O `model_info.json` de cada pasta guarda o limiar de confiança do modelo (0,50 no v3, 0,55 no v3_meu) e o hash do `.tflite`.

1. O microfone grava PCM de 16 bits, mono, a 22.050 Hz.
2. O app guarda sempre os últimos 1,5 s de áudio (33.075 amostras).
3. A cada 0,5 s, se o som não for silêncio, passa essa janela pro modelo, fora da thread da interface. A extração de características (chroma) está dentro do próprio modelo, então o app só envia o áudio bruto.
4. Um acorde só aparece na tela quando sai igual em pelo menos 2 das últimas 3 leituras, e no máximo uma vez a cada 1,5 s. Isso evita que uma leitura isolada errada conte como erro, e mantém a contagem de acertos igual à do modo servidor.

No iPhone 11, cada leitura leva cerca de 60 ms.

### Servidor (avançado)

O app grava janelas de 1,5 s e envia para a API Flask do [ChordAI-backend](https://github.com/imxder/ChordAI-backend) (`POST /predict_chord`), que devolve o acorde e a confiança. Precisa de um computador na mesma rede Wi-Fi do celular rodando o backend. O endereço é configurado na mesma tela: o IP e a porta que aparecem no terminal do servidor, ou o nome do computador na rede. A porta é a 5000 (ou 5001 no Mac, porque o AirPlay ocupa a 5000), por exemplo `192.168.0.10:5000` ou `meu-mac.local:5001`.

**O modo servidor usa outro modelo.** A API Flask carrega o modelo antigo do backend (`trained_model/`, com a chroma calculada no servidor), que não é nem o v3 nem o v3_meu. Então, pro mesmo áudio, o resultado pode ser diferente do modo no aparelho. O que o teste de equivalência confere (veja abaixo) é se cada modelo no aparelho dá as mesmas probabilidades que o backend calculou pra ele.

## Como rodar

Requisitos: Flutter 3.47 (Dart 3.13) e, para iOS, Xcode com CocoaPods.

```bash
flutter pub get
flutter run
```

Para instalar no iPhone em modo release:

```bash
flutter build ios --release
flutter install
```

Para usar o modo servidor, suba o backend seguindo o README do [ChordAI-backend](https://github.com/imxder/ChordAI-backend) e informe o endereço em **Perfil → Reconhecimento**.

## Testes

```bash
flutter analyze
flutter test
```

Os testes cobrem o detector de afinação (inclusive com gravações reais das 6 cordas em `test/fixtures/strings/`), a suavização do ponteiro, o parser de cifras, a estabilização das previsões, a migração de preferências e se cada tela cabe em celular pequeno, tablet, modo deitado e fonte grande.

O teste que compara a saída do modelo no aparelho com a esperada pelo backend precisa da biblioteca nativa do TFLite, então roda num celular ou simulador conectado:

```bash
flutter test integration_test/chord_model_equivalence_test.dart -d <id-do-aparelho>
```

Pra conferir se os `.tflite` em `assets/models/` são os das releases do backend, sem trocar nenhum arquivo por engano:

```bash
python3 tool/conferir_modelos.py
```

O script calcula o sha256 de cada `chord_model.tflite` e compara com o campo `sha256` do `model_info.json` da mesma pasta. Se algum não bater, ele sai com erro. É esse script que o CI vai chamar.

## Estrutura

```
lib/
  models/     dados (acordes, cifras, afinações, info do modelo)
  screens/    telas
  services/   áudio, afinador, reconhecimento (servidor e no aparelho), parser de cifras
  state/      estado do app e preferências salvas
  widgets/    componentes visuais
assets/       cifras, sequências, fontes e os dois modelos (assets/models/v3 e assets/models/v3_meu)
test/         testes unitários e de layout
integration_test/  teste de equivalência dos modelos no aparelho
tool/         conferir_modelos.py, que confere o hash dos modelos
docs/adr/     as decisões de arquitetura (inferência no aparelho e os dois modelos)
```
