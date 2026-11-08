# Afinador: algoritmo antigo × YIN

Comparação do detector de frequência do afinador antes e depois da troca de algoritmo.

- **Antigo:** autocorrelação sem normalização. Pega o maior pico entre 70 e 400 Hz e refina com
  interpolação parabólica.
- **YIN sem correção:** de Cheveigné & Kawahara (2002), com limiar 0,15 na diferença média
  normalizada cumulativa (CMNDF).
- **YIN corrigido:** YIN com verificação do período dobrado. Se a CMNDF em 2τ for menor que a de τ
  por mais de 0,05, e 2τ ainda estiver dentro da faixa (≥ 70 Hz), o detector usa 2τ.

## Método

Sinais sintéticos de 4096 amostras a 22050 Hz, a mesma janela usada no app, com uma nota por corda
da afinação padrão. Os sinais com harmônicos são somas de senoides em f, 2f, 3f e 4f, com as
amplitudes indicadas no título de cada tabela.

As frequências estão em Hz, com o desvio em cents entre parênteses. Uma leitura conta como erro de
oitava quando fica a menos de 50 cents de 2×, 3×, 4× ou ½ da frequência esperada. "Sem leitura"
significa que o detector não encontrou periodicidade confiável e não devolveu valor.

## Resultados

### Senoide pura

| Corda | Esperado (Hz) | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|---|
| E2 | 82,41 | 82,54 (+2,69 ¢) | 82,41 (0,00 ¢) | 82,41 (0,00 ¢) |
| A2 | 110,00 | 110,03 (+0,40 ¢) | 110,00 (0,00 ¢) | 110,00 (0,00 ¢) |
| D3 | 146,83 | 146,97 (+1,64 ¢) | 146,83 (0,00 ¢) | 146,83 (0,00 ¢) |
| G3 | 196,00 | 196,04 (+0,39 ¢) | 196,00 (0,00 ¢) | 196,00 (0,00 ¢) |
| B3 | 246,94 | 247,02 (+0,54 ¢) | 246,94 (0,00 ¢) | 246,94 (0,00 ¢) |
| E4 | 329,63 | 329,76 (+0,71 ¢) | 329,63 (0,00 ¢) | 329,63 (0,00 ¢) |

### Fundamental fraca, 2º e 3º harmônicos fortes (0,15 / 0,6 / 0,45)

| Corda | Esperado (Hz) | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|---|
| E2 | 82,41 | 82,42 (+0,20 ¢) | 82,41 (0,00 ¢) | 82,41 (0,00 ¢) |
| A2 | 110,00 | 110,00 (0,00 ¢) | 110,00 (0,00 ¢) | 110,00 (0,00 ¢) |
| D3 | 146,83 | 146,84 (+0,09 ¢) | 146,83 (0,00 ¢) | 146,83 (0,00 ¢) |
| G3 | 196,00 | 196,00 (0,00 ¢) | 196,00 (0,00 ¢) | 196,00 (0,00 ¢) |
| B3 | 246,94 | 246,98 (+0,29 ¢) | 246,94 (+0,01 ¢) | 246,94 (+0,01 ¢) |
| E4 | 329,63 | 329,63 (−0,01 ¢) | 329,63 (−0,02 ¢) | 329,63 (−0,02 ¢) |

### Harmônicos pares fortes, ímpares médios (0,15 / 1 / 0,15 / 0,5)

| Corda | Esperado (Hz) | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|---|
| E2 | 82,41 | 82,41 (0,00 ¢) | **164,81 — oitava errada (2×)** | 82,41 (0,00 ¢) |
| A2 | 110,00 | 110,02 (+0,30 ¢) | **220,00 — oitava errada (2×)** | 110,00 (0,00 ¢) |
| D3 | 146,83 | 146,83 (0,00 ¢) | **293,67 — oitava errada (2×)** | 146,83 (0,00 ¢) |
| G3 | 196,00 | 196,02 (+0,16 ¢) | **392,09 — oitava errada (2×)** | 196,00 (0,00 ¢) |
| B3 | 246,94 | 246,96 (+0,15 ¢) | 246,94 (+0,01 ¢) | 246,94 (+0,01 ¢) |
| E4 | 329,63 | 329,63 (−0,02 ¢) | 329,63 (−0,02 ¢) | 329,63 (−0,02 ¢) |

### Harmônicos pares fortes, ímpares quase nulos (0,05 / 1 / 0,05 / 0,5)

| Corda | Esperado (Hz) | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|---|
| E2 | 82,41 | **164,83 — oitava errada (2×)** | **164,81 — oitava errada (2×)** | **164,81 — oitava errada (2×)** |
| A2 | 110,00 | **220,11 — oitava errada (2×)** | **220,00 — oitava errada (2×)** | **220,00 — oitava errada (2×)** |
| D3 | 146,83 | **293,67 — oitava errada (2×)** | **293,66 — oitava errada (2×)** | **293,66 — oitava errada (2×)** |
| G3 | 196,00 | **392,12 — oitava errada (2×)** | **392,03 — oitava errada (2×)** | **392,03 — oitava errada (2×)** |
| B3 | 246,94 | 246,96 (+0,13 ¢) | 246,94 (+0,01 ¢) | 246,94 (+0,01 ¢) |
| E4 | 329,63 | 329,63 (−0,02 ¢) | 329,63 (−0,02 ¢) | 329,63 (−0,02 ¢) |

### Fundamental ausente (0 / 1 / 0,8 / 0,5)

| Corda | Esperado (Hz) | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|---|
| E2 | 82,41 | 82,41 (+0,07 ¢) | 82,41 (0,00 ¢) | 82,41 (0,00 ¢) |
| A2 | 110,00 | 110,00 (+0,04 ¢) | 110,00 (0,00 ¢) | 110,00 (0,00 ¢) |
| D3 | 146,83 | 146,84 (+0,07 ¢) | 146,83 (0,00 ¢) | 146,83 (0,00 ¢) |
| G3 | 196,00 | 196,00 (+0,02 ¢) | 196,00 (0,00 ¢) | 196,00 (0,00 ¢) |
| B3 | 246,94 | 246,96 (+0,14 ¢) | 246,94 (+0,01 ¢) | 246,94 (+0,01 ¢) |
| E4 | 329,63 | 329,63 (+0,01 ¢) | 329,62 (−0,03 ¢) | 329,62 (−0,03 ¢) |

### Ruído branco (10 sorteios, amplitude ±0,5)

| Sorteio | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|
| 1 | **125,94 Hz (falsa)** | sem leitura | sem leitura |
| 2 | **150,93 Hz (falsa)** | sem leitura | sem leitura |
| 3 | **152,22 Hz (falsa)** | sem leitura | sem leitura |
| 4 | **92,36 Hz (falsa)** | sem leitura | sem leitura |
| 5 | **172,37 Hz (falsa)** | sem leitura | sem leitura |
| 6 | **179,13 Hz (falsa)** | sem leitura | sem leitura |
| 7 | **85,84 Hz (falsa)** | sem leitura | sem leitura |
| 8 | **129,77 Hz (falsa)** | sem leitura | sem leitura |
| 9 | **136,78 Hz (falsa)** | sem leitura | sem leitura |
| 10 | **92,61 Hz (falsa)** | sem leitura | sem leitura |

### A2 (0,15 / 0,6 / 0,45) com ruído branco somado

| Amplitude do ruído | Antigo | YIN sem correção | YIN corrigido |
|---|---|---|---|
| 0,10 | 110,00 (+0,02 ¢) | 110,00 (+0,02 ¢) | 110,00 (+0,02 ¢) |
| 0,30 | 110,04 (+0,66 ¢) | 110,05 (+0,77 ¢) | 110,05 (+0,77 ¢) |
| 0,60 | 110,01 (+0,20 ¢) | 110,01 (+0,20 ¢) | 110,01 (+0,20 ¢) |
| 1,00 | 110,12 (+1,89 ¢) | sem leitura | sem leitura |

## Conclusões

1. **Precisão.** Em senoide pura, o antigo erra até 2,69 cents (E2). O YIN fica abaixo de
   0,03 cent em todos os casos em que acerta a nota.
2. **Ruído.** O antigo sempre devolve uma frequência, mesmo quando só há ruído: entre 85 e 179 Hz
   nos 10 sorteios. No afinador, isso faz o ponteiro pular entre cordas. O YIN não deu leitura em
   nenhum deles. Com ruído muito forte sobre a nota (amplitude 1,0), o YIN também prefere não ler a
   arriscar um valor.
3. **Erro de oitava introduzido pelo YIN.** Com harmônicos pares fortes e ímpares médios, o YIN sem
   correção aceita o meio período como período e lê uma oitava acima em E2, A2, D3 e G3, enquanto o
   antigo acerta. A verificação em 2τ corrige esses quatro casos sem alterar os demais.
4. **Limitação dos dois.** Quando os harmônicos ímpares são quase nulos, o sinal praticamente se
   repete a cada meio período. Nem o antigo nem o YIN conseguem separar a nota da oitava acima
   olhando uma única janela. B3 e E4 escapam porque a oitava acima delas (494 e 659 Hz) fica fora da
   faixa de busca, que vai até 400 Hz.
5. **Fundamental ausente.** Os três acertam, porque o período continua sendo o da nota mesmo sem a
   componente fundamental.
