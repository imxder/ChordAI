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

O modelo reconhece 8 acordes: Am, Bb, Bdim, C, Dm, Em, F e G. Quando não há acorde claro, ele responde "não reconheci" em vez de chutar.

## Como funciona o reconhecimento

O app tem dois modos, que se escolhe em **Perfil → Reconhecimento**. As telas de prática funcionam igual nos dois.

### No aparelho (padrão)

O modelo roda dentro do celular, em TensorFlow Lite (`assets/models/chord_model.tflite`), sem internet nem computador.

1. O microfone grava PCM de 16 bits, mono, a 22.050 Hz.
2. O app guarda sempre os últimos 1,5 s de áudio (33.075 amostras).
3. A cada 0,5 s, se o som não for silêncio, passa essa janela pro modelo, fora da thread da interface. A extração de características (chroma) está dentro do próprio modelo, então o app só envia o áudio bruto.
4. Um acorde só aparece na tela quando sai igual em pelo menos 2 das últimas 3 leituras, e no máximo uma vez a cada 1,5 s. Isso evita que uma leitura isolada errada conte como erro, e mantém a contagem de acertos igual à do modo servidor.

No iPhone 11, cada leitura leva cerca de 60 ms.

### Servidor (avançado)

O app grava janelas de 1,5 s e envia para a API Flask do [ChordAI-backend](https://github.com/imxder/ChordAI-backend) (`POST /predict_chord`), que devolve o acorde e a confiança. Precisa de um computador na mesma rede Wi-Fi do celular rodando o backend. O endereço é configurado na mesma tela (IP e porta que aparecem no terminal do servidor, ou o nome do computador na rede, como `meu-mac.local:5001`).

Os dois modos usam o mesmo modelo e dão o mesmo resultado para o mesmo áudio. Isso é conferido por um teste que roda no aparelho (veja abaixo).

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

## Estrutura

```
lib/
  models/     dados (acordes, cifras, afinações, info do modelo)
  screens/    telas
  services/   áudio, afinador, reconhecimento (servidor e no aparelho), parser de cifras
  state/      estado do app e preferências salvas
  widgets/    componentes visuais
assets/       cifras, sequências, fontes e o modelo TFLite
test/         testes unitários e de layout
integration_test/  teste de equivalência do modelo no aparelho
```
