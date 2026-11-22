# Segurança

O ChordAI não tem conta, login nem servidor meu, e não usa a internet. O som do microfone é analisado no próprio aparelho e não sai dele. Até a v0.2.1 tinha um modo "Servidor", que mandava o áudio pra API Flask no meu computador; ele saiu do app, e o motivo está no [ADR 0003](adr/0003-sem-modo-servidor.md).

## O que o app acessa

| Permissão | Onde | Pra quê |
|---|---|---|
| Microfone | `RECORD_AUDIO` no Android, `NSMicrophoneUsageDescription` no iOS e no Mac, `com.apple.security.device.audio-input` no Mac | ouvir o violão (reconhecer o acorde e o afinador) |

Só isso. O app de release não pede internet em nenhuma plataforma:

- **Android:** o `AndroidManifest.xml` de `src/main` só tem o `RECORD_AUDIO`. A `INTERNET` aparece só nos manifestos de `src/debug` e `src/profile`, porque o Flutter precisa dela pro hot reload e pro DevTools; eles não entram no APK de release.
- **iOS:** não tem `NSLocalNetworkUsageDescription`, então o app nem pede acesso à rede local.
- **Mac:** o app roda no sandbox, e o `Release.entitlements` só libera o microfone. O `DebugProfile.entitlements` tem o `network.server`, também só pro hot reload.
- **Windows:** o Windows não tem permissão por app; o microfone depende da opção do sistema pros apps da área de trabalho.

## O que fica salvo

- No `shared_preferences`: o perfil (nome e experiência), o progresso, as preferências e as músicas que eu crio. Nada disso sai do aparelho.
- O áudio não fica salvo: ele só existe na memória enquanto o modelo analisa a janela de 1,5 s.
- Na primeira vez que o app abre depois de tirar o modo servidor, ele apaga as chaves antigas desse modo (`app_server_url`, `app_chord_recognition_mode` e `app_on_device_default_migrated`, em `lib/state/app_state.dart`). A `app_server_url` guardava o IP do computador. O resto fica como estava.
- Nenhum áudio ou nome do perfil vai pra `print` ou log, e a mensagem de erro do reconhecimento é fixa (`chordRecognitionErrorMessage`).

## Decisões

- **Sem rede nenhuma.** Com o reconhecimento só no aparelho, o app não tem nada que precise de internet. Tirar a permissão garante isso no sistema, não só no código.
- **Keystore fora do repositório.** O APK da release é assinado no GitHub Actions com a keystore que fica nos secrets; `key.properties`, `*.jks` e `*.keystore` estão no `.gitignore`. Sem esses secrets (no CI de PR e no `flutter run`), o build usa a chave de debug.
- **Dependabot** confere toda segunda os pacotes do `pub` e as Actions (`.github/dependabot.yml`). O `tflite_flutter` fica fora das atualizações automáticas, porque roda os modelos congelados e só troco testando no celular.
