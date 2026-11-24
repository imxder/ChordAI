# Observabilidade

O que o app registra hoje, por que ele não tem monitoramento em produção e o que seria usado depois da entrega.

## O que existe hoje

O app só registra alguma coisa em modo debug, ligado ao computador de desenvolvimento por `flutter run`. Quem escreve é o `TocarJuntoLog` (`lib/services/tocar_junto_log.dart`), com `debugPrint`, e só se `kDebugMode` for verdadeiro. No app de release nada é escrito.

Os registros são quatro:

- `[tj] <ms> <evento>`, com a batida, o passo da cifra e quando a música pausou, continuou ou parou (`lyric_player_screen.dart`). Serve para medir a tolerância do tocar junto, na seção 7.3 do [docs/como-funciona.md](como-funciona.md).
- `crua <status> ...` e `filtro <status> ...`, com a leitura do modelo antes e depois do `ChordStabilizer` (`on_device_chord_service.dart`). Mostram o que o modelo respondeu em cada janela.
- `inferencia_us=<microssegundos>`, na linha da leitura crua. É o tempo de uma chamada ao modelo, com a ida e a volta pelo isolate, e serve para medir o tempo de cada leitura (seção 7.2 do mesmo documento).
- `ataque rms2=...`, quando o volume sobe de repente (`TocarJuntoLog.blocoDeAudio`). Mostra o momento em que a palheta bateu.

O app não registra o áudio, que só existe na memória, na janela de 1,5 s, e nunca vai para `print` nem para log. Também não registra dado de pessoa, porque não tem nome, conta nem identificador. A mensagem de erro do reconhecimento é fixa (`chordRecognitionErrorMessage`), sem detalhe técnico.

No backend, a API Flask (`api/app.py`) mostra mensagens no terminal ao carregar o modelo, com `print`. Ela é uma ferramenta para testar um modelo no computador e só atende o próprio computador.

## Por que não tem Firebase nem coisa parecida

A decisão foi não integrar nenhum serviço de monitoramento, de falhas ou de analytics, por dois motivos.

O app não usa internet. O `AndroidManifest.xml` de release só tem o microfone, e a permissão `INTERNET` só aparece nos manifestos de debug e de profile, por causa do hot reload. Mandar qualquer coisa para fora exigiria pedir essa permissão ([docs/seguranca.md](seguranca.md) e [ADR 0003](adr/0003-sem-modo-servidor.md)).

O app também não coleta dados. A [política de privacidade](../PRIVACY.md) diz que ele não tem analytics, não usa a internet e não envia nada ao desenvolvedor. Ligar um serviço desses mudaria isso, e a pessoa instalou o app com essa promessa.

Só é visível o que é testado, e não há como saber como o app se comporta nos aparelhos das outras pessoas.

## O que seria usado depois da entrega

Isso é um plano, ainda não está feito.

1. Um jeito de a pessoa enviar um problema quando quiser, sem nada automático: uma opção nos Ajustes que gera um texto curto, sem áudio, com o modelo escolhido e o tempo da leitura, que ela copia e envia.
2. Se for preciso relatório de falhas automático, só com a pessoa ligando uma opção (que começa desligada), sem áudio e sem identificador.

Antes de ligar qualquer coisa, a política de privacidade seria atualizada, a permissão de internet entraria só nessa versão e as notas da release avisariam.

A primeira medida seria o tempo de cada leitura em aparelhos que não estão disponíveis hoje. Até agora o app foi testado num iPhone 11, num Android, num Windows e num Mac.
