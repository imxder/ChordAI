# ChordAI

[![CI](https://github.com/imxder/ChordAI/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/imxder/ChordAI/actions/workflows/ci.yml) [![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=imxder_ChordAI&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=imxder_ChordAI)

Esse é o app do meu TCC de Engenharia de Software. A ideia é ajudar quem tá começando no violão: você toca o acorde e o app escuta e diz se saiu certo. Também tem afinador, cifras pra tocar junto com a música e um guia pra iniciante.

Fiz em Flutter, então roda no iPhone, no Android, no Windows e no Mac. O modelo que reconhece os acordes eu treinei no [ChordAI-backend](https://github.com/imxder/ChordAI-backend).

## Funcionalidades

- **Afinador**: detecta a nota de cada corda com o algoritmo YIN, com ponteiro estável, aviso de "afinada" e afinações alternativas (Drop D, meio tom abaixo, Open G, Open D, DADGAD) ou personalizadas.
- **Acordes**: diagrama de cada acorde no braço do violão e modo "testar", que ouve você tocar e conta os acertos seguidos até marcar o acorde como aprendido.
- **Reconhecer acorde**: mostra em tempo real o acorde que o app está ouvindo.
- **Sequências**: treino de progressões de acordes com metrônomo.
- **Tocar junto**: cifras só com os acordes (o desenho de cada um e as setas da batida) que avançam no andamento da música ou esperam você trocar de acorde, com andamento ajustável e um resumo no fim com os acordes que você mais errou.
- **Minhas músicas**: dá pra montar a sua música no próprio app, com as partes, os acordes, o andamento e a batida. Ela fica só no aparelho.
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

O modelo escolhido roda dentro do aparelho, em TensorFlow Lite (`assets/models/v3/chord_model.tflite` ou `assets/models/v3_meu/chord_model.tflite`), sem internet nem computador. O app não pede permissão de internet e o som não sai do aparelho. Por que a inferência saiu do servidor está no [ADR 0001](docs/adr/0001-inferencia-no-aparelho.md), e por que o modo servidor saiu de vez do app está no [ADR 0003](docs/adr/0003-sem-modo-servidor.md).

Os dois modelos vêm das releases do backend, [`model-v3`](https://github.com/imxder/ChordAI-backend/releases/tag/model-v3) e [`model-v3-meu`](https://github.com/imxder/ChordAI-backend/releases/tag/model-v3-meu). O `model_info.json` de cada pasta guarda o limiar de confiança do modelo (0,50 no v3, 0,55 no v3_meu) e o hash do `.tflite`.

1. O microfone grava PCM de 16 bits, mono, a 22.050 Hz.
2. O app guarda sempre os últimos 1,5 s de áudio (33.075 amostras).
3. A cada 0,5 s, se o som não for silêncio, passa essa janela pro modelo, fora da thread da interface. A extração de características (chroma) está dentro do próprio modelo, então o app só envia o áudio bruto.
4. Um acorde só aparece na tela quando sai igual em pelo menos 2 das últimas 3 leituras, e no máximo uma vez a cada 1,5 s. Isso evita que uma leitura isolada errada conte como erro.

No iPhone 11, cada leitura leva cerca de 60 ms.

A API Flask do [ChordAI-backend](https://github.com/imxder/ChordAI-backend) continua lá, mas só como ferramenta pra eu testar o modelo pelo computador. Ela usa outro modelo (`trained_model/`) e o app não fala com ela.

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

O `flutter devices` mostra o id. Não use o `flutter install`: ele desinstala o app antes de instalar de novo, e isso apaga os acordes aprendidos, o perfil e as músicas.

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
  services/   áudio, afinador, reconhecimento no aparelho, parser de cifras
  state/      estado do app e preferências salvas
  widgets/    componentes visuais
assets/       cifras, sequências, fontes e os dois modelos (assets/models/v3 e assets/models/v3_meu)
test/         testes unitários e de layout
integration_test/  teste de equivalência dos modelos no aparelho
tool/         conferir_modelos.py, que confere o hash dos modelos
docs/adr/     as decisões de arquitetura (inferência no aparelho, os dois modelos e a saída do modo servidor)
```
