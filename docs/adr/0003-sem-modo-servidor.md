# ADR 0003: o modo servidor sai do app

- **Status:** aceita
- **Data:** 22/11/2026
- **Repositórios:** [ChordAI](https://github.com/imxder/ChordAI) e [ChordAI-backend](https://github.com/imxder/ChordAI-backend)
- **Caminhos de arquivo:** os que começam com `lib/`, `test/`, `android/`, `ios/` ou `macos/` são do app. `api/` é do backend.

## Contexto

Depois do [ADR 0001](0001-inferencia-no-aparelho.md), o reconhecimento no aparelho virou o padrão e o modo servidor (mandar o áudio pra API Flask do backend) ficou como opção avançada na tela de Reconhecimento. No Windows e no Mac ele nem aparecia.

Mesmo desligado, ele custava bastante pra pouca coisa:

- **Permissões de rede no app inteiro.** `INTERNET` e `usesCleartextTraffic="true"` no Android, `NSLocalNetworkUsageDescription` no iOS e no Mac, e `com.apple.security.network.client` no sandbox do Mac. Tudo isso só pra esse modo.
- **HTTP sem criptografia.** O áudio ia pela rede local sem criptografia. Pra isso existiam a validação do endereço (`server_address.dart`), a regra de só aceitar HTTP em IP privado e o aviso na tela.
- **Outro modelo.** A API usa o `trained_model/` do backend, que não é nem o v3 nem o v3_meu. Então o mesmo acorde podia dar resultado diferente nos dois modos.
- **Mais código e mais coisa pra explicar.** O `chord_recognition_service.dart` (195 linhas), o `server_address.dart` (93 linhas), dois arquivos de teste, a escolha do modo, o campo do endereço e o selo nas telas de prática.

## Decisão

O app só reconhece no aparelho. Saem o `ChordRecognitionService`, o `ServerAddress`, o `ChordRecognitionMode`, o endereço salvo e as permissões de rede de release nas três plataformas que tinham. O pacote `http` deixa de ser dependência do app.

A interface `ChordRecognizer` fica. No app só sobra uma implementação, o `OnDeviceChordService`, mas as telas continuam pedindo um `ChordRecognizer`, e nos testes eu passo reconhecedores falsos que fingem ouvir acordes sem carregar o modelo (o `ReconhecedorFalso` do tocar junto e os `_MicFalso`).

A API Flask continua no backend, como ferramenta pra testar o modelo pelo computador.

Quem tinha o modo servidor salvo abre o app no aparelho, sem perder nada. Na primeira vez que o app abre, ele apaga só as três chaves desse modo (`app_server_url`, `app_chord_recognition_mode` e `app_on_device_default_migrated`). O progresso, as músicas, as preferências e o modelo escolhido ficam como estavam (`test/recognition_mode_migration_test.dart`).

## Alternativas

- **Deixar como estava, escondido em "avançado".** Mantinha as permissões de rede e o HTTP sem criptografia por um modo que eu não uso mais.
- **Deixar o modo servidor só no build de debug.** Tirava a permissão do app de release, mas o código e os testes continuavam, e o app de debug se comportaria diferente do de release.
- **Colocar HTTPS na API.** Pede certificado pra um IP que muda em cada rede, e continuava precisando de um computador ligado na mesma Wi-Fi.

## Consequências

- **O app não faz nenhuma chamada de rede.** O som nunca sai do aparelho, e a [política de privacidade](../../PRIVACY.md) ficou mais simples.
- **O app de release não pede internet.** No Android, a `INTERNET` fica só nos manifestos de debug e profile, que o Flutter usa pro hot reload. No Mac, o `network.server` fica só no `DebugProfile.entitlements`, pelo mesmo motivo.
- **O reconhecimento no aparelho não mudou:** mesmo modelo, mesmos limiares e o mesmo filtro de 2 em 3 leituras.
- **O custo:** **não dá mais pra comparar o app com a API pelo celular.** Pra testar o modelo da API, uso ela direto pelo computador, como está no README do backend. E se um dia eu quiser rodar um modelo grande demais pro celular, vou ter que pôr a rede de volta no app.
