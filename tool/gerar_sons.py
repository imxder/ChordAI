"""Gera o clique do metrônomo e o som de corda afinada do ChordAI.

Uso:
    python tool/gerar_sons.py                 gera as variações em tool/sons_candidatos/
    python tool/gerar_sons.py madeira         grava o clique escolhido em assets/sounds/
    python tool/gerar_sons.py afinado:sino    grava o afinado escolhido em assets/sounds/

Precisa só do numpy. Não é dependência do app: só roda quando eu quiser mudar
o clique, e os .wav escolhidos ficam commitados.

O clique é sintetizado do zero, sem sample nenhum: algumas senoides que
começam juntas e somem rápido (decaimento exponencial), mais um chiado bem
curto no ataque pra dar o "toc". É o jeito clássico de imitar um bloco de
madeira: a madeira vibra em poucas frequências que não são múltiplas umas
das outras e para quase na hora.

Cada variação tem o "tempo 1" (click_forte) e os "outros tempos" (click). O
tempo 1 é o mesmo som com as frequências mais altas, pra dar pra ouvir onde
começa o compasso.

Tudo fica acima de 1 kHz, bem longe da faixa que o afinador escuta (50 a
400 Hz, em lib/services/pitch_detector.dart).

O afinado é um sininho do mesmo jeito: cada nota é uma senoide com alguns
harmônicos, ataque suave de poucos milissegundos e um decaimento mais longo
que o do clique. A nota mais grave fica acima de 1 kHz, então o afinador
(50 a 400 Hz) não confunde o sininho com uma corda.

Formato: .wav mono, 44,1 kHz, 16 bits, pico em -3 dBFS.
"""
import sys
import wave
from pathlib import Path

import numpy as np

RAIZ = Path(__file__).resolve().parent.parent
CANDIDATOS = RAIZ / 'tool' / 'sons_candidatos'
ASSETS = RAIZ / 'assets' / 'sounds'

TAXA = 44100
PICO = 10 ** (-3 / 20)

VARIACOES = {
    'madeira': {
        'duracao_ms': 40,
        'base_hz': 1250,
        'forte_hz': 1650,
        'parciais': [(1.0, 1.0, 9), (2.57, 0.45, 5), (4.21, 0.2, 3)],
        'chiado': 0.25,
        'chiado_ms': 2.0,
    },
    'eletronico': {
        'duracao_ms': 35,
        'base_hz': 1500,
        'forte_hz': 2000,
        'parciais': [(1.0, 1.0, 7), (2.0, 0.15, 4)],
        'chiado': 0.0,
        'chiado_ms': 0.0,
    },
    'seco': {
        'duracao_ms': 20,
        'base_hz': 2200,
        'forte_hz': 2900,
        'parciais': [(1.0, 1.0, 4), (1.48, 0.5, 3), (2.9, 0.25, 2)],
        'chiado': 0.5,
        'chiado_ms': 1.5,
    },
}


SINOS = {
    'sino': {
        'notas': [(1318.5, 0.0)],
        'parciais': [(1.0, 1.0), (2.0, 0.3), (3.0, 0.1)],
        'tau_ms': 110,
        'duracao_ms': 400,
    },
    'duas_notas': {
        'notas': [(1318.5, 0.0), (1975.5, 0.09)],
        'parciais': [(1.0, 1.0), (2.0, 0.2)],
        'tau_ms': 90,
        'duracao_ms': 400,
    },
    'duas_notas_grave': {
        'notas': [(1046.5, 0.0), (1568.0, 0.09)],
        'parciais': [(1.0, 1.0), (2.0, 0.2)],
        'tau_ms': 100,
        'duracao_ms': 400,
    },
    'duas_notas_agudo': {
        'notas': [(1760.0, 0.0), (2637.0, 0.09)],
        'parciais': [(1.0, 1.0), (2.0, 0.15)],
        'tau_ms': 80,
        'duracao_ms': 400,
    },
    'duas_notas_redondo': {
        'notas': [(1318.5, 0.0), (1975.5, 0.09)],
        'parciais': [(1.0, 1.0)],
        'tau_ms': 120,
        'duracao_ms': 400,
    },
    'marimba': {
        'notas': [(1046.5, 0.0)],
        'parciais': [(1.0, 1.0), (4.0, 0.25), (9.9, 0.05)],
        'tau_ms': 70,
        'duracao_ms': 300,
    },
}


def sino(p):
    n = int(TAXA * p['duracao_ms'] / 1000)
    t = np.arange(n) / TAXA
    som = np.zeros(n)
    for f0, inicio in p['notas']:
        tn = t - inicio
        ligado = tn >= 0
        tn = np.where(ligado, tn, 0)
        ataque = np.clip(tn / 0.004, 0, 1)
        nota = np.zeros(n)
        for razao, ganho in p['parciais']:
            tau = p['tau_ms'] / 1000 / razao ** 0.5
            nota += ganho * np.sin(2 * np.pi * f0 * razao * tn) * np.exp(-tn / tau)
        som += np.where(ligado, nota * ataque, 0)
    saida = int(TAXA * 0.02)
    som[-saida:] *= np.linspace(1, 0, saida)
    return som / np.max(np.abs(som)) * PICO


def clique(p, forte):
    n = int(TAXA * p['duracao_ms'] / 1000)
    t = np.arange(n) / TAXA
    f0 = p['forte_hz'] if forte else p['base_hz']
    som = np.zeros(n)
    for razao, ganho, tau_ms in p['parciais']:
        som += ganho * np.sin(2 * np.pi * f0 * razao * t) * np.exp(-t / (tau_ms / 1000))
    if p['chiado'] > 0:
        rng = np.random.default_rng(7)
        ruido = np.diff(rng.standard_normal(n + 1))
        som += p['chiado'] * ruido * np.exp(-t / (p['chiado_ms'] / 1000))
    ataque = int(TAXA * 0.0005)
    som[:ataque] *= np.linspace(0, 1, ataque)
    saida = int(TAXA * 0.005)
    som[-saida:] *= np.linspace(1, 0, saida)
    return som / np.max(np.abs(som)) * PICO


def demo(p, bpm=100, tempos=8, por_compasso=4):
    passo = int(TAXA * 60 / bpm)
    total = np.zeros(passo * tempos)
    forte, fraco = clique(p, True), clique(p, False)
    for i in range(tempos):
        c = forte if i % por_compasso == 0 else fraco
        total[i * passo:i * passo + len(c)] += c
    return total


def gravar(caminho, som):
    caminho.parent.mkdir(parents=True, exist_ok=True)
    dados = np.clip(np.round(som * 32767), -32768, 32767).astype('<i2')
    with wave.open(str(caminho), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(dados.tobytes())
    print(caminho.relative_to(RAIZ))


def main():
    if len(sys.argv) > 1 and sys.argv[1].startswith('afinado:'):
        gravar(ASSETS / 'afinado.wav', sino(SINOS[sys.argv[1].split(':', 1)[1]]))
        return
    if len(sys.argv) > 1:
        nome = sys.argv[1]
        p = VARIACOES[nome]
        gravar(ASSETS / 'click_forte.wav', clique(p, True))
        gravar(ASSETS / 'click.wav', clique(p, False))
        return
    for nome, p in VARIACOES.items():
        gravar(CANDIDATOS / f'{nome}_click_forte.wav', clique(p, True))
        gravar(CANDIDATOS / f'{nome}_click.wav', clique(p, False))
        gravar(CANDIDATOS / f'{nome}_demo_100bpm.wav', demo(p))
    for nome, p in SINOS.items():
        gravar(CANDIDATOS / f'afinado_{nome}.wav', sino(p))


if __name__ == '__main__':
    main()
