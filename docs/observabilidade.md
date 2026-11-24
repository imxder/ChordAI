# Observabilidade

O que o app registra hoje, por que ele não tem monitoramento em produção e o que eu usaria depois da entrega.

## O que existe hoje

O app só registra alguma coisa em modo debug, ligado ao meu computador por `flutter run`. Quem escreve é o `TocarJuntoLog` (`lib/services/tocar_junto_log.dart`), com `debugPrint`, e só se `kDebugMode` for verdadeiro. No app de release nada é escrito.

Os registros são quatro:

- `[tj] <ms> <evento>`, com a batida, o passo da cifra e quando a música pausou, continuou ou parou (`lyric_player_screen.dart`). Uso pra medir a tolerância do tocar junto, na seção 7.3 do [docs/como-funciona.md](como-funciona.md).
- `crua <status> ...` e `filtro <status> ...`, com a leitura do modelo antes e depois do `ChordStabilizer` (`on_device_chord_service.dart`). Mostram o que o modelo respondeu em cada janela.
- `inferencia_us=<microssegundos>`, na linha da leitura crua. É o tempo de uma chamada ao modelo, com a ida e a volta pelo isolate, e uso pra medir o tempo de cada leitura (seção 7.2 do mesmo documento).
- `ataque rms2=...`, quando o volume sobe de repente (`TocarJuntoLog.blocoDeAudio`). Mostra o momento em que a palheta bateu.

O app não registra o áudio, que só existe na memória, na janela de 1,5 s, e nunca vai pra `print` nem pra log. Também não registra dado de pessoa, porque não tem nome, conta nem identificador. A mensagem de erro do reconhecimento é fixa (`chordRecognitionErrorMessage`), sem detalhe técnico.

No backend, a API Flask (`api/app.py`) mostra mensagens no terminal ao carregar o modelo, com `print`. Ela é uma ferramenta pra eu testar um modelo no computador e só atende o meu computador.

## Por que não tem Firebase nem coisa parecida

Decidi não integrar nenhum serviço de monitoramento, de falhas ou de analytics, por dois motivos.

O app não usa internet. O `AndroidManifest.xml` de release só tem o microfone, e a permissão `INTERNET` só aparece nos manifestos de debug e de profile, por causa do hot reload. Mandar qualquer coisa pra fora exigiria pedir essa permissão ([docs/seguranca.md](seguranca.md) e [ADR 0003](adr/0003-sem-modo-servidor.md)).

O app também não coleta dados. A [política de privacidade](../PRIVACY.md) diz que ele não tem analytics, não usa a internet e não me manda nada. Ligar um serviço desses mudaria isso, e a pessoa instalou o app com essa promessa.

Eu só vejo o que testo, e não sei como o app se comporta nos aparelhos das outras pessoas.

## O que eu usaria depois da entrega

Isso é um plano, ainda não está feito.

1. Um jeito de a pessoa me mandar um problema quando quiser, sem nada automático: uma opção nos Ajustes que gera um texto curto, sem áudio, com o modelo escolhido e o tempo da leitura, que ela copia e me envia.
2. Se eu precisar de relatório de falhas automático, só com a pessoa ligando uma opção (que começa desligada), sem áudio e sem identificador.

Antes de ligar qualquer coisa eu atualizaria a política de privacidade, adicionaria a permissão de internet só nessa versão e avisaria nas notas da release.

O que eu mediria primeiro é o tempo de cada leitura em aparelhos que eu não tenho. Hoje só testei num iPhone 11, num Android, num Windows e num Mac.
