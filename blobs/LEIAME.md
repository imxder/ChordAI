# Biblioteca do TensorFlow Lite para o Windows e para o Mac

No iPhone e no Android, o `tflite_flutter` (0.12.1) já traz o motor do TensorFlow Lite junto. No
desktop, o próprio README do pacote manda o projeto trazer a biblioteca nativa:

- Windows: `blobs/libtensorflowlite_c-win.dll`, copiada para uma pasta `blobs/` do lado do
  `.exe` pela regra no fim do `windows/CMakeLists.txt`.
- Mac: o pacote procura em `ChordAI.app/Contents/Resources/libtensorflowlite_c-mac.dylib`.

Nada aqui é usado no build do iPhone nem do Android.

## De onde veio cada arquivo

Os dois binários vêm do repositório
[google-ai-edge/flutter_litert](https://github.com/google-ai-edge/flutter_litert), mantido pela
organização do Google que cuida do LiteRT. Eles foram compilados pelo CI desse repositório a partir
da tag v2.21.0 do TensorFlow. É a mesma versão do TensorFlow que exportou os modelos
(`tensorflow==2.21.0` no `requirements.lock.txt` do ChordAI-backend).

Só os arquivos foram usados, e não o pacote `flutter_litert`. Se o pacote fosse trocado, o celular
também trocaria de motor.

| Arquivo | Commit de origem | Tamanho | sha256 |
|---|---|---|---|
| `libtensorflowlite_c-win.dll` | [`daa3258`](https://github.com/google-ai-edge/flutter_litert/commit/daa3258ca23858bcde159d3371088d0e162a6fe1) (`windows/libtensorflowlite_c-win.dll`) | 4.883.968 bytes | `44d5d07fef8a4d5b7c58b8e8b283ec1e900081eb60464ee7ed96a18b662c1476` |
| `libtensorflowlite_c-mac.dylib` | [`f3cf827`](https://github.com/google-ai-edge/flutter_litert/commit/f3cf827ff5857692b8d4f39890cde59d021d1394) (`macos/flutter_litert/Sources/flutter_litert/Resources/libtensorflowlite_c-mac.dylib`) | 12.069.472 bytes | `f20948d053355d72abd74a76567eb0ca407a9cc9b23dc69c7f80ae2e567e72a7` |

Os hashes batem com os que estão na mensagem de cada commit. Para conferir:

```
sha256sum blobs/libtensorflowlite_c-win.dll blobs/libtensorflowlite_c-mac.dylib
```

O que foi conferido antes de usar:

- Windows: a DLL é x64. Ela só depende da `KERNEL32.dll` (foi compilada com o runtime do C++
  embutido), então não precisa instalar nada a mais no PC.
- Mac: a dylib é universal, com x86_64 e arm64, e roda em Mac Intel e Apple Silicon.
- As duas:
  - Exportam todas as funções `TfLite*` que o `tflite_flutter` 0.12.1 chama (a lista está em
    `lib/src/bindings/` do pacote).
  - Têm os nomes das operações do modelo (`ops_float32` em `export/export_report.json` do backend),
    entre elas RFFT2D, IMAG, REAL, BATCH_MATMUL, GATHER e SELECT_V2.
  - Os modelos pedem no mínimo o motor 2.11.0, e essas bibliotecas são 2.21.0.

O que prova que funciona é o teste de equivalência, que compara a saída do modelo com a do Python:

```
flutter test integration_test/chord_model_equivalence_test.dart -d windows
```

Ele passou nos dois modelos (v3 e v3_meu) no Windows e no Mac (Apple Silicon), com diferença de no
máximo 0,001 em cada probabilidade:

```
flutter test integration_test/chord_model_equivalence_test.dart -d macos
```

## Licença

O TensorFlow e o flutter_litert são Apache-2.0, que deixa redistribuir o binário desde que vá junto
uma cópia da licença. A cópia está em `LICENSE-TensorFlow.txt`, tirada da tag v2.21.0 do TensorFlow.

## Mac (como a dylib entrou na pasta macos/)

1. `flutter create --platforms=macos .`
2. Abrir `macos/Runner.xcworkspace` no Xcode.
3. Arrastar `blobs/libtensorflowlite_c-mac.dylib` para o grupo Runner, sem marcar "Copy items if
   needed".
4. Em Runner → Build Phases → Copy Bundle Resources, conferir que a dylib está na lista. É isso que
   coloca ela em `Contents/Resources/`, onde o `tflite_flutter` procura.
5. Rodar o teste de equivalência com `-d macos`.

Isso segue o passo 1 e 2 do guia do Flutter que o README do `tflite_flutter` indica:
https://docs.flutter.dev/platform-integration/macos/c-interop#compiled-dynamic-library-macos

## Por que não o motor do celular

No Windows o motor é o 2.21.0. No iPhone é o TensorFlowLiteC 2.12.0 (`ios/Podfile.lock`) e no
Android é o LiteRT 1.4.0 (do `tflite_flutter`). Os números do celular continuam valendo: a acurácia
do `docs/adr/0002-dois-modelos-no-app.md`. O tempo de cada leitura no celular ainda não foi medido, e o
único tempo salvo é o do computador de desenvolvimento: 8,78 ms por janela, com 1 thread
(`export_report.json` do backend). Nada que o celular usa mudou. Para o desktop, o que existe é o
teste de equivalência.
