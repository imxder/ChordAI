# Gravações de cordas

Usadas por `test/recorded_strings_test.dart`. Com a pasta sem `.wav`, o teste é pulado.

- Um arquivo por nota, com o nome da nota esperada: `E2.wav`, `A2.wav`, `D3.wav`, `G3.wav`,
  `B3.wav`, `E4.wav`. Sustenido com `#` (`F#3.wav`).
- WAV PCM de 16 bits, qualquer taxa de amostragem. Se for estéreo, só o canal esquerdo é usado.
- Uma corda solta por arquivo, tocada uma vez e deixada soar. Corte o silêncio do começo.

O teste divide o áudio em janelas de 4096 amostras e ignora as que ficam abaixo do limiar de
silêncio do detector. Das restantes, pelo menos 90% precisam dar a nota certa (±50 cents).
