# Sons do app

O app tem três sons curtos: o clique do metrônomo, o som de acorde aprendido e o som de corda afinada. Todos ficam em `assets/sounds/` e tocam pelo serviço `lib/services/app_sounds.dart`. Dá para desligar os três em Ajustes → Sons, e só o clique em Aa → Som do metrônomo.

| Arquivo | Onde toca | De onde vem |
|---|---|---|
| `click_forte.wav` | tempo 1 de cada compasso, nas sequências e no tocar junto | obra própria, gerado por `tool/gerar_sons.py` |
| `click.wav` | os outros tempos | obra própria, gerado por `tool/gerar_sons.py` |
| `afinado.wav` | quando a corda entra na afinação | obra própria, gerado por `tool/gerar_sons.py` |
| `acorde_aprendido.wav` | quando o acorde vira aprendido no treino | Kenney, Interface Sounds (CC0) |

## Clique do metrônomo (obra própria)

O objetivo era um "tic" curto e seco, parecido com bloco de madeira. A referência foi o ouvido, e nenhum sample de outro programa foi usado.

O script soma três senoides que começam juntas e somem rápido, mais um chiado bem curto no ataque. As frequências não são múltiplas umas das outras, que é o que faz soar como madeira em vez de apito. A variação "madeira" foi escolhida entre três geradas:

- duração: 40 ms
- frequência base: 1250 Hz nos tempos normais e 1650 Hz no tempo 1
- parciais (razão, ganho, decaimento): 1,0 / 1,0 / 9 ms; 2,57 / 0,45 / 5 ms; 4,21 / 0,2 / 3 ms
- chiado no ataque: ganho 0,25, decaimento de 2 ms

Para gerar de novo: `python tool/gerar_sons.py madeira`.

## Corda afinada (obra própria)

Um "di-ding" de duas notas subindo: Dó (1046,5 Hz) e, 90 ms depois, Sol (1568 Hz). Cada nota tem o harmônico de 2× mais fraco, ataque de 4 ms e decaimento de 100 ms, num total de 0,4 s. Foram geradas variações mais agudas e mais redondas, e a escolhida foi essa, a mais grave. A nota mais grave fica acima de 1 kHz, longe da faixa que o afinador escuta (50 a 400 Hz, em `lib/services/pitch_detector.dart`).

Para gerar de novo: `python tool/gerar_sons.py afinado:duas_notas_grave`.

## Acorde aprendido (Kenney, CC0)

- arquivo original: `Audio/confirmation_003.ogg`
- pacote: Interface Sounds 1.0, do Kenney (www.kenney.nl)
- página: https://kenney.nl/assets/interface-sounds
- licença: Creative Commons Zero (CC0), domínio público, sem exigir crédito. Está na página, no bloco "License", e no `License.txt` do pacote, que foi guardado em `assets/sounds/LICENSES/kenney_interface_sounds.txt`.
- baixado em 22/11/2026

O que mudou: o arquivo foi convertido de .ogg para .wav mono, 44,1 kHz e 16 bits, e o pico foi normalizado para −3 dBFS, igual aos outros sons. Nada foi cortado. Mexer no arquivo não muda a licença CC0.

Por que esse e não outro do pacote: ele tem 0,32 s e só notas agudas (Ré e Fá#, de 2,3 a 9 kHz). Foram descartados `confirmation_001` (Sol e Ré a partir de 391 Hz, parecido com um Sol) e `confirmation_004` (Mi e Sol#, perto do Em), porque o modelo poderia ler esses sons como acorde.

## Para o som não virar leitura no microfone

O microfone continua ligado enquanto os sons tocam, então:

- no afinador, as leituras de até 0,5 s depois do som de afinado são ignoradas, e o ponteiro fica onde estava;
- no treino do acorde, as leituras de até 2 s depois do som de aprendido são ignoradas. São 2 s porque o modelo olha 1,5 s de áudio de cada vez, e assim o som já saiu da janela;
- no metrônomo, o clique é curto (40 ms) e agudo.

A regra está em `lib/models/echo_guard.dart`. Não mexe no reconhecimento, na janela, nos limiares nem nos modelos.

## Pacote de áudio e iPhone

O app usa o `flutter_soloud` (5.3.1), feito para tocar som curto com pouca demora. No iPhone ele não mexe na configuração de áudio: quem configura é o `record`, que grava no modo "tocar e gravar" com saída no alto-falante. Por isso:

- o som sai pelo alto-falante, ou no fone se tiver um conectado;
- a gravação não para quando um som toca;
- com o microfone ligado, os sons tocam mesmo com a chave de silencioso ligada, que é como o iOS trata esse modo. Para não tocar, é só desligar Sons nos Ajustes.

No tocar junto com "Ouvir pelo microfone" desligado, o microfone não liga. Se ele ainda não foi usado desde que o app abriu, o iPhone fica no modo normal de tocar som e a chave de silencioso cala o clique. Se já foi usado, continua o modo "tocar e gravar" e o clique toca mesmo no silencioso.

No iPhone o som só é ligado quando o microfone liga, ou quando começa o tocar junto sem microfone. Se ligasse ao abrir o app, poderia parar uma música que estivesse tocando em outro app. No Mac ele liga ao abrir o app, porque a versão 5.3.1 do pacote trava ao fechar o app se o som nunca foi usado.

Tocar som não precisa de permissão nenhuma e não manda nada para lugar nenhum.
