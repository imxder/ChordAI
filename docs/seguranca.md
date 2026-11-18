# Segurança

O ChordAI não tem conta, login nem servidor meu. O único dado que pode sair do celular é o som do microfone, e só no modo servidor, que vem desligado.

## O que o app acessa

| Permissão | Onde | Pra quê |
|---|---|---|
| Microfone | `RECORD_AUDIO` no Android, `NSMicrophoneUsageDescription` no iOS | ouvir o violão (reconhecer o acorde e o afinador) |
| Internet | `INTERNET` no Android | só o modo servidor usa |
| Rede local | `NSLocalNetworkUsageDescription` no iOS | só o modo servidor usa |

## O que sai do aparelho

- **No aparelho (o padrão):** nada. O som fica na memória, o modelo TFLite roda no próprio celular e o app não faz nenhuma chamada de rede.
- **Servidor (opção avançada):** a cada 1,5 s, um WAV com o som do microfone vai por `POST /predict_chord` pro endereço que eu digitei, e volta só o nome do acorde. Não vai nome do perfil, progresso nem nada além do áudio.

## O que fica salvo

- No `shared_preferences`: o perfil (nome e experiência), o progresso, as preferências e o endereço do servidor. Nada disso sai do aparelho.
- No modo servidor, cada janela de 1,5 s vira um arquivo `chordai_janela_<hora>.wav` na pasta temporária do app. Ele é apagado assim que a resposta chega; se o app fechar no meio, o que sobrou é apagado da próxima vez que o modo servidor começa a ouvir (`deleteLeftoverWindows` em `lib/services/chord_recognition_service.dart`).
- Nenhum áudio, endereço ou nome do perfil vai pra `print` ou log, e a mensagem de erro do reconhecimento é fixa (`chordRecognitionErrorMessage`), sem o endereço nem o erro de rede.

## Decisões

- **Endereço do servidor conferido antes de salvar** (`lib/services/server_address.dart`): tem que ser http ou https, ter IP ou nome válido, porta de 1 a 65535 e nada depois da porta.
- **HTTP só pra rede local.** Sem criptografia, o app só aceita IP privado (192.168.x.x, 10.x.x.x, 172.16 a 172.31), localhost ou nome `.local`. Pra qualquer outro endereço, só HTTPS. Assim o áudio sem criptografia não sai pela internet.
- **Aviso na tela do modo servidor**, dizendo que o som vai sem criptografia e que é pra usar só numa rede confiável.
- **Keystore fora do repositório.** O APK da release é assinado no GitHub Actions com a keystore que fica nos secrets; `key.properties`, `*.jks` e `*.keystore` estão no `.gitignore`. Sem esses secrets (no CI de PR e no `flutter run`), o build usa a chave de debug.
- **Dependabot** confere toda segunda os pacotes do `pub` e as Actions (`.github/dependabot.yml`). O `tflite_flutter` fica fora das atualizações automáticas, porque roda os modelos congelados e só troco testando no celular.

## Riscos que eu aceitei

- **HTTP sem criptografia no modo servidor.** Colocar HTTPS no backend Flask pede certificado pra um IP que muda, e o modo servidor é só uma ferramenta de desenvolvimento: o padrão é o reconhecimento no aparelho. Por isso ficou o aviso e a regra de rede local.
- **`usesCleartextTraffic="true"` no Android pro app inteiro.** O `network_security_config` do Android só libera HTTP por domínio, não por faixa de IP ([documentação](https://developer.android.com/privacy-and-security/security-config)), e o IP do computador é diferente em cada rede. Quem limita o HTTP à rede local é a validação do endereço no app. O app não tem WebView nem outra biblioteca de rede, então o único HTTP que existe é o do modo servidor.
- **Quem está na mesma rede consegue mandar áudio pro backend**, porque a API não tem senha. Ela só devolve o nome de um acorde e não guarda nada, então não tem o que vazar.
