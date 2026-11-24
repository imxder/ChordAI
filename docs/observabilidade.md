# Observabilidade

O que o app registra hoje, por que ele não tem monitoramento em produção e o que eu usaria depois da entrega.

## O que existe hoje

O app só registra alguma coisa quando roda em modo debug, ligado ao meu computador por `flutter run`. Quem escreve é o `TocarJuntoLog` (`lib/services/tocar_junto_log.dart`), com `debugPrint`, e só se `kDebugMode` for verdadeiro. **No app de release nada é escrito.**

| Registro | De onde vem | Pra que eu uso |
|---|---|---|
| `[tj] <ms> <evento>`: batida, passo da cifra, pausou, continuou e parou | `lyric_player_screen.dart` | medir a tolerância do tocar junto ([docs/como-funciona.md](como-funciona.md), seção 7.3) |
| `crua <status> ...` e `filtro <status> ...`: a leitura do modelo antes e depois do `ChordStabilizer` | `on_device_chord_service.dart` | ver o que o modelo respondeu em cada janela |
| `inferencia_us=<microssegundos>`, na linha da leitura crua: o tempo de uma chamada ao modelo, com a ida e a volta pelo isolate | `on_device_chord_service.dart` | medir o tempo de cada leitura ([docs/como-funciona.md](como-funciona.md), seção 7.2) |
| `ataque rms2=...`: o volume subiu de repente | `TocarJuntoLog.blocoDeAudio` | achar o momento em que a palheta bateu |

O que o app **não** registra:

- **O áudio.** Ele só existe na memória, na janela de 1,5 s, e nunca vai pra `print` nem pra log.
- **Qualquer dado da pessoa.** O app não tem nome, conta nem identificador.
- **Erros enviados pra fora.** A mensagem de erro do reconhecimento é fixa (`chordRecognitionErrorMessage`), sem detalhe técnico.

No backend, a API Flask (`api/app.py`) mostra mensagens no terminal ao carregar o modelo, com `print`. Ela é uma ferramenta pra eu testar um modelo no computador e só atende o meu computador. Não é monitoramento.

## Por que não tem Firebase nem coisa parecida

Eu decidi não integrar nenhum serviço de monitoramento, de falhas ou de analytics. Dois motivos:

- **O app não usa internet.** O `AndroidManifest.xml` de release só tem o microfone, e a permissão `INTERNET` só aparece nos manifestos de debug e de profile, pro hot reload. Mandar qualquer coisa pra fora exigiria pedir essa permissão ([docs/seguranca.md](seguranca.md) e [ADR 0003](adr/0003-sem-modo-servidor.md)).
- **O app não coleta dados.** A [política de privacidade](../PRIVACY.md) diz que ele não tem analytics, não usa a internet e não me manda nada. Ligar um serviço desses mudaria isso, e a pessoa instalou o app com essa promessa.

A consequência é que eu não sei como o app se comporta nos aparelhos das outras pessoas. Eu só vejo o que eu mesmo testo.

## O que eu usaria depois da entrega

Isso é um plano, não está feito.

1. **Um jeito de a pessoa me mandar um problema quando ela quiser**, e não automático: uma opção nos Ajustes que gera um texto curto, sem áudio, com o modelo escolhido e o tempo da leitura, que ela copia e me envia.
2. **Se eu precisar de relatório de falhas automático**, só com a pessoa ligando uma opção (começa desligada), sem áudio e sem identificador.
3. **Antes de ligar qualquer coisa**: atualizar a política de privacidade, adicionar a permissão de internet só nessa versão e avisar nas notas da release.

O que eu mediria primeiro é o tempo de cada leitura em aparelhos que eu não tenho. Hoje eu só testei num iPhone 11, num Android, num Windows e num Mac.
