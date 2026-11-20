"""Gera o ícone do ChordAI para todas as plataformas a partir de um desenho só.

Uso:
    python tool/gerar_icones.py

Precisa do Pillow (pip install pillow). Não é dependência do app: só roda
quando eu quiser mudar o ícone, e os arquivos gerados ficam commitados.

O desenho são 6 barras de volume que também são as 6 cordas do violão, com as
3 bolinhas do Lá menor por cima. As medidas estão num quadrado de 1024 e o
mesmo desenho vira o SVG em assets/icon/ e todos os PNG/ICO, então um não
tem como ficar diferente do outro.

Cores (as mesmas de lib/theme/app_theme.dart):
    fundo  0xFF1C1A17  texto quase preto do tema claro
    barras 0xFFF3F0EA  fundo creme do tema claro
    verde  0xFF4CD27A  'correct' do tema escuro (o 0xFF237043 some no fundo escuro)

O que gera:
    assets/icon/                 SVG, PNG de 1024, imagem social do GitHub,
                                 versões do iOS 18 (escuro e tingido) e o macOS
    ios/.../AppIcon.appiconset   todos os tamanhos do Contents.json, sem alfa
    android/.../res              mipmaps antigos, ícone adaptativo e monocromático
    windows/runner/resources     app_icon.ico com 16, 24, 32, 48, 64 e 256
"""
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

RAIZ = Path(__file__).resolve().parent.parent
ICON = RAIZ / 'assets' / 'icon'
IOS = RAIZ / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
RES = RAIZ / 'android' / 'app' / 'src' / 'main' / 'res'
WIN = RAIZ / 'windows' / 'runner' / 'resources' / 'app_icon.ico'

FUNDO = (0x1C, 0x1A, 0x17)
CREME = (0xF3, 0xF0, 0xEA)
VERDE = (0x4C, 0xD2, 0x7A)

# Desenho no quadrado de 1024, centrado em (512, 512).
CORDAS = [232 + 112 * i for i in range(6)]  # Mi Lá Ré Sol Si Mi, da grave pra aguda
ALTURAS = [300, 470, 600, 560, 420, 260]     # parece uma onda de volume
LARGURA_BARRA = 56
# Lá menor: Ré e Sol na casa 2 (mais baixo), Si na casa 1 (mais alto)
BOLINHAS = [(CORDAS[2], 590), (CORDAS[3], 590), (CORDAS[4], 434)]
RAIO = 50
CONTORNO = 14  # anel escuro em volta da bolinha, pra ela não grudar na barra

SUPER = 4  # desenha 4x maior e reduz: deixa as bordas lisas


def barras():
    for x, h in zip(CORDAS, ALTURAS):
        yield (x - LARGURA_BARRA / 2, 512 - h / 2, x + LARGURA_BARRA / 2, 512 + h / 2)


def raio_maximo():
    """Distância do centro até o ponto mais longe do desenho (pra área segura)."""
    r = 0.0
    for x0, y0, x1, y1 in barras():
        for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
            r = max(r, math.hypot(x - 512, y - 512))
    for x, y in BOLINHAS:
        r = max(r, math.hypot(x - 512, y - 512) + RAIO + CONTORNO / 2)
    return r


def svg():
    linhas = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">',
        '  <rect width="1024" height="1024" fill="#%02X%02X%02X"/>' % FUNDO,
    ]
    for (x0, y0, x1, y1) in barras():
        linhas.append(
            f'  <rect x="{x0:g}" y="{y0:g}" width="{x1 - x0:g}" height="{y1 - y0:g}" '
            f'rx="{LARGURA_BARRA / 2:g}" fill="#%02X%02X%02X"/>' % CREME)
    for x, y in BOLINHAS:
        linhas.append(
            f'  <circle cx="{x}" cy="{y}" r="{RAIO}" fill="#%02X%02X%02X" ' % VERDE
            + 'stroke="#%02X%02X%02X" stroke-width="%d"/>' % (FUNDO + (CONTORNO,)))
    linhas.append('</svg>')
    return '\n'.join(linhas) + '\n'


def desenhar(px, escala=1.0, fundo=True, mono=False):
    """Desenha o ícone num quadrado de px.

    escala: tamanho do desenho em relação ao quadrado (1 = igual ao SVG).
    fundo: False deixa o fundo transparente (camada da frente do Android, iOS 18).
    mono: tudo numa cor só, com as bolinhas recortadas da barra (ícone temático).
    """
    s = px * SUPER
    k = s / 1024 * escala
    off = s / 2 - 512 * k

    def t(v):
        return off + v * k

    anel = (RAIO + CONTORNO / 2) * k
    miolo = (RAIO - CONTORNO / 2) * k

    if mono:
        a = Image.new('L', (s, s), 0)
        d = ImageDraw.Draw(a)
        for x0, y0, x1, y1 in barras():
            d.rounded_rectangle((t(x0), t(y0), t(x1), t(y1)), radius=LARGURA_BARRA / 2 * k, fill=255)
        for x, y in BOLINHAS:
            d.ellipse((t(x) - anel, t(y) - anel, t(x) + anel, t(y) + anel), fill=0)
            d.ellipse((t(x) - miolo, t(y) - miolo, t(x) + miolo, t(y) + miolo), fill=255)
        img = Image.new('RGBA', (s, s), (255, 255, 255, 0))
        img.putalpha(a)
        return img.resize((px, px), Image.LANCZOS)

    img = Image.new('RGBA', (s, s), FUNDO + (255,) if fundo else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x0, y0, x1, y1 in barras():
        d.rounded_rectangle((t(x0), t(y0), t(x1), t(y1)), radius=LARGURA_BARRA / 2 * k, fill=CREME)
    for x, y in BOLINHAS:
        d.ellipse((t(x) - anel, t(y) - anel, t(x) + anel, t(y) + anel), fill=FUNDO + (255,))
        d.ellipse((t(x) - miolo, t(y) - miolo, t(x) + miolo, t(y) + miolo), fill=VERDE)
    return img.resize((px, px), Image.LANCZOS)


def sem_alfa(img):
    return img.convert('RGB')


def gerar_fonte():
    ICON.mkdir(parents=True, exist_ok=True)
    (ICON / 'chordai_icon.svg').write_text(svg(), encoding='utf-8')
    sem_alfa(desenhar(1024)).save(ICON / 'chordai_icon_1024.png')


def gerar_ios():
    """Lê o Contents.json e gera cada tamanho que ele pede, sem canal alfa."""
    info = json.loads((IOS / 'Contents.json').read_text(encoding='utf-8'))
    for img in info['images']:
        lado = float(img['size'].split('x')[0]) * int(img['scale'].rstrip('x'))
        sem_alfa(desenhar(round(lado))).save(IOS / img['filename'])

    # iOS 18: versão escura (fundo transparente, o sistema põe o fundo escuro) e
    # tingida (cinza, o sistema pinta da cor escolhida). Ficam guardadas aqui e
    # entram no Contents.json quando eu tiver o Xcode pra conferir (no Mac).
    pasta = ICON / 'ios18'
    pasta.mkdir(exist_ok=True)
    desenhar(1024, fundo=False).save(pasta / 'AppIcon-escuro.png')
    tingido = desenhar(1024, fundo=False)
    cinza = tingido.convert('L').convert('RGBA')
    cinza.putalpha(tingido.getchannel('A'))
    cinza.save(pasta / 'AppIcon-tingido.png')


# Densidades do Android: (pasta, tamanho do ícone antigo de 48dp, camada de 108dp)
DENSIDADES = [
    ('mdpi', 48, 108),
    ('hdpi', 72, 162),
    ('xhdpi', 96, 216),
    ('xxhdpi', 144, 324),
    ('xxxhdpi', 192, 432),
]

ADAPTATIVO = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
"""

CORES = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#%02X%02X%02X</color>
</resources>
""" % FUNDO


def gerar_android():
    # No ícone adaptativo a camada tem 108dp, mas só os 72dp do meio aparecem.
    # Então o desenho ocupa 72/108 da camada, igual ao que aparece no SVG.
    # E tudo tem que caber no círculo de 66dp do meio (a área segura), senão
    # alguma máscara de launcher corta.
    escala = 72 / 108
    raio_seguro = 1024 * (66 / 108) / 2
    assert raio_maximo() * escala <= raio_seguro, 'desenho sai da área segura'

    for nome, antigo, camada in DENSIDADES:
        # Android 7 ou mais antigo: o PNG aparece do jeito que está.
        sem_alfa(desenhar(antigo)).save(RES / f'mipmap-{nome}' / 'ic_launcher.png')
        pasta = RES / f'drawable-{nome}'
        pasta.mkdir(exist_ok=True)
        desenhar(camada, escala=escala, fundo=False).save(pasta / 'ic_launcher_foreground.png')
        desenhar(camada, escala=escala, mono=True).save(pasta / 'ic_launcher_monochrome.png')

    pasta = RES / 'mipmap-anydpi-v26'
    pasta.mkdir(exist_ok=True)
    (pasta / 'ic_launcher.xml').write_text(ADAPTATIVO, encoding='utf-8')
    (RES / 'values' / 'colors.xml').write_text(CORES, encoding='utf-8')


def gerar_windows():
    tamanhos = [16, 24, 32, 48, 64, 256]
    imagens = [sem_alfa(desenhar(t)).convert('RGBA') for t in tamanhos]
    # Cada tamanho é desenhado separado (não é o de 256 reduzido).
    imagens[-1].save(WIN, format='ICO', sizes=[(t, t) for t in tamanhos],
                     append_images=imagens[:-1])


def gerar_macos():
    """Ainda não tenho a pasta macos/. Deixo os PNG prontos pra sessão do Mac.

    No Mac o ícone não é cortado pelo sistema: o PNG já vem com o quadrado de
    cantos arredondados (824 de 1024, raio 185, como no modelo da Apple) e
    o resto transparente."""
    pasta = ICON / 'macos'
    pasta.mkdir(exist_ok=True)
    s = 1024 * SUPER
    base = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    lado, raio = 824 * SUPER, 185 * SUPER
    m0 = (s - lado) // 2
    mascara = Image.new('L', (s, s), 0)
    ImageDraw.Draw(mascara).rounded_rectangle((m0, m0, m0 + lado, m0 + lado), radius=raio, fill=255)
    desenho = desenhar(1024, escala=824 / 1024).resize((s, s), Image.LANCZOS)
    base.paste(desenho, (0, 0), mascara)
    grande = base.resize((1024, 1024), Image.LANCZOS)
    for t in (16, 32, 64, 128, 256, 512, 1024):
        grande.resize((t, t), Image.LANCZOS).save(pasta / f'app_icon_{t}.png')


def gerar_social():
    """Imagem do Settings → Social preview do GitHub (1280x640)."""
    img = Image.new('RGB', (1280, 640), FUNDO)
    icone = desenhar(440, fundo=False)
    img.paste(icone, (120, 100), icone)
    fonte = ImageFont.truetype(str(RAIZ / 'assets' / 'fonts' / 'IBMPlexMono-SemiBold.ttf'), 120)
    ImageDraw.Draw(img).text((600, 320), 'ChordAI', font=fonte, fill=CREME, anchor='lm')
    img.save(ICON / 'social_preview.png')


if __name__ == '__main__':
    gerar_fonte()
    gerar_ios()
    gerar_android()
    gerar_windows()
    gerar_macos()
    gerar_social()
    print('ícones gerados')
