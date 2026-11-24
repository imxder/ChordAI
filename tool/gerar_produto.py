"""Monta as imagens de produto do README: o app dentro de cada aparelho.

Uso:
    python tool/gerar_produto.py reduzir           mac_*.png de 2400 x 1600 para 1800 x 1200
    python tool/gerar_produto.py apple             docs/imagens/produto-apple.png
    python tool/gerar_produto.py android-windows   docs/imagens/produto-android-windows.png
    python tool/gerar_produto.py tudo              os três

Opções: --tela inicio (qual captura usar, padrão inicio) e, no apple, --iphone e
--macbook com o caminho de cada moldura.

Precisa do Pillow (pip install pillow). Não é dependência do app: só roda quando
eu mudar as capturas, e as imagens geradas ficam commitadas.

Duas imagens, separadas por marca, porque a Apple não deixa um aparelho dela
aparecer na mesma imagem que aparelho de outra marca:
    produto-apple.png            MacBook e iPhone, com as molduras oficiais da Apple
    produto-android-windows.png  celular Android na moldura do Google e a janela do Windows

Molduras da Apple (as "Product Bezels", de developer.apple.com/design/resources).
O arquivo da moldura não vai pro Git (tool/molduras/ está no .gitignore): cada um
baixa o seu. Copio um PNG de iPhone e um de MacBook pra:
    tool/molduras/apple/iphone.png
    tool/molduras/apple/macbook.png
A moldura vai sem nenhuma mudança além do tamanho: sem inclinar, sem cortar, sem
sombra e sem reflexo, e sem texto em cima do aparelho (regras em
developer.apple.com/app-store/marketing/guidelines). O script acha sozinho a
tela de cada moldura: é a parte transparente que não encosta na borda da imagem.

Moldura do Android: o Device Art Generator do Google só funciona no navegador. Eu
arrasto a captura lá, escolho um Pixel, deixo Shadow e Screen glare desligados,
não giro e salvo o resultado em tool/molduras/android/pixel_<tela>.png.

Windows: não existe moldura oficial de notebook, então vai só a janela do app
(docs/imagens/windows_<tela>.png), com o canto arredondado e uma sombra suave.

Capturas usadas (todas em docs/imagens/):
    iphone_<tela>.png      captura do iPhone
    mac_<tela>.png         captura do Mac, 1800 x 1200
    windows_<tela>.png     gerada por test/imagens_docs_test.dart
"""
import argparse
import io
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
IMAGENS = RAIZ / 'docs' / 'imagens'
MOLDURAS = RAIZ / 'tool' / 'molduras'

LARGURA_MAXIMA = 1600
TAMANHO_MAXIMO = 700 * 1024
FUNDO = (237, 237, 240, 255)
MARGEM = 140
ESPACO = 100
MAC_FINAL = (1800, 1200)


def abrir(caminho):
    caminho = Path(caminho)
    if not caminho.exists():
        sys.exit(f'Não achei {caminho.relative_to(RAIZ) if RAIZ in caminho.parents else caminho}.')
    return Image.open(caminho).convert('RGBA')


def area_da_tela(moldura):
    """Máscara da tela da moldura: o transparente que não encosta na borda da imagem."""
    alfa = moldura.getchannel('A')
    binaria = alfa.point(lambda v: 0 if v < 8 else 255)
    largura, altura = binaria.size
    borda = [(x, y) for x in range(largura) for y in (0, altura - 1)]
    borda += [(x, y) for y in range(altura) for x in (0, largura - 1)]
    if all(binaria.getpixel(ponto) != 0 for ponto in borda):
        sys.exit('A moldura não tem fundo transparente nas bordas, então não achei a tela dela.')
    for ponto in borda:
        if binaria.getpixel(ponto) == 0:
            ImageDraw.floodfill(binaria, ponto, 128)
    tela = binaria.point(lambda v: 255 if v == 0 else 0)
    if tela.getbbox() is None:
        sys.exit('A moldura não tem nenhuma parte transparente dentro, então não achei a tela dela.')
    return tela


def completar_lados(captura, proporcao):
    """Alarga a captura até a proporção da tela, repetindo a cor da borda de cada linha.

    Assim a janela inteira cabe na tela, sem cortar em cima e embaixo e sem faixa de outra cor.
    """
    largura_nova = round(captura.height * proporcao)
    if largura_nova <= captura.width:
        return captura
    extra = largura_nova - captura.width
    esquerda = extra // 2
    saida = Image.new('RGBA', (largura_nova, captura.height), (0, 0, 0, 0))
    saida.alpha_composite(captura, (esquerda, 0))
    for y in range(captura.height):
        opacos = [x for x in range(captura.width) if max(captura.getpixel((x, y))[:3]) > 12]
        if not opacos:
            continue
        primeiro, ultimo = opacos[0], opacos[-1]
        linha = min(max(y, 40), captura.height - 41)
        cor_esquerda = captura.getpixel((8, linha))
        cor_direita = captura.getpixel((captura.width - 9, linha))
        for x in range(0, esquerda + primeiro):
            saida.putpixel((x, y), cor_esquerda)
        for x in range(esquerda + ultimo + 1, largura_nova):
            saida.putpixel((x, y), cor_direita)
    return saida


def encaixar(moldura, captura, inteira=False):
    """Põe a captura embaixo da moldura, preenchendo a tela. A moldura fica como veio."""
    tela = area_da_tela(moldura)
    x0, y0, x1, y1 = tela.getbbox()
    largura, altura = x1 - x0, y1 - y0
    if inteira:
        captura = completar_lados(captura, largura / altura)
    escala = max(largura / captura.width, altura / captura.height)
    nova = captura.resize((round(captura.width * escala), round(captura.height * escala)), Image.LANCZOS)
    esquerda = (nova.width - largura) // 2
    topo = (nova.height - altura) // 2
    nova = nova.crop((esquerda, topo, esquerda + largura, topo + altura))
    folga = tela.filter(ImageFilter.MaxFilter(5))
    fundo = Image.new('RGBA', moldura.size, (0, 0, 0, 0))
    fundo.paste(nova, (x0, y0), folga.crop((x0, y0, x1, y1)))
    return Image.alpha_composite(fundo, moldura)


def janela_do_windows(captura, raio=16):
    """A janela do app, sem moldura: canto arredondado e uma sombra suave."""
    mascara = Image.new('L', captura.size, 0)
    ImageDraw.Draw(mascara).rounded_rectangle((0, 0, captura.width - 1, captura.height - 1), raio, fill=255)
    janela = captura.copy()
    janela.putalpha(mascara)
    margem = 60
    saida = Image.new('RGBA', (captura.width + 2 * margem, captura.height + 2 * margem), (0, 0, 0, 0))
    sombra = Image.new('RGBA', saida.size, (0, 0, 0, 0))
    sombra.paste((0, 0, 0, 70), (margem, margem + 16), mascara)
    saida = Image.alpha_composite(saida, sombra.filter(ImageFilter.GaussianBlur(24)))
    saida.alpha_composite(janela, (margem, margem))
    return saida


def sem_margem(imagem):
    """Tira só a margem transparente em volta do aparelho. O aparelho em si não muda."""
    return imagem.crop(imagem.getchannel('A').getbbox())


def lado_a_lado(imagens):
    """As imagens na linha de base, com a mesma altura de figura e espaço entre elas."""
    altura = max(i.height for i in imagens)
    largura = sum(i.width for i in imagens) + ESPACO * (len(imagens) - 1) + 2 * MARGEM
    tela = Image.new('RGBA', (largura, altura + 2 * MARGEM), FUNDO)
    x = MARGEM
    for imagem in imagens:
        tela.alpha_composite(imagem, (x, MARGEM + altura - imagem.height))
        x += imagem.width + ESPACO
    return tela


def salvar(imagem, destino):
    """PNG com até 1600 px de largura e até 700 KB: encolhe e reduz as cores até caber."""
    imagem = imagem.convert('RGB')
    if imagem.width > LARGURA_MAXIMA:
        altura = round(imagem.height * LARGURA_MAXIMA / imagem.width)
        imagem = imagem.resize((LARGURA_MAXIMA, altura), Image.LANCZOS)
    while True:
        for cores in (None, 256, 128):
            atual = imagem if cores is None else imagem.quantize(cores, dither=Image.NONE)
            buffer = io.BytesIO()
            atual.save(buffer, 'PNG', optimize=True)
            if buffer.tell() <= TAMANHO_MAXIMO:
                destino.write_bytes(buffer.getvalue())
                print(f'{destino.relative_to(RAIZ)}: {atual.width} x {atual.height}, {buffer.tell() // 1024} KB')
                return
        imagem = imagem.resize((round(imagem.width * 0.9), round(imagem.height * 0.9)), Image.LANCZOS)


def reduzir():
    achou = False
    for arquivo in sorted(IMAGENS.glob('mac_*.png')):
        imagem = Image.open(arquivo)
        if imagem.size == MAC_FINAL:
            print(f'{arquivo.name}: já está em {MAC_FINAL[0]} x {MAC_FINAL[1]}')
        else:
            imagem.convert('RGB').resize(MAC_FINAL, Image.LANCZOS).save(arquivo, optimize=True)
            print(f'{arquivo.name}: {imagem.width} x {imagem.height} -> {MAC_FINAL[0]} x {MAC_FINAL[1]}')
        achou = True
    if not achou:
        sys.exit('Não achei nenhum mac_*.png em docs/imagens/.')


def apple(args):
    macbook = sem_margem(encaixar(abrir(args.macbook), abrir(IMAGENS / f'mac_{args.tela}.png'), inteira=True))
    iphone = sem_margem(encaixar(abrir(args.iphone), abrir(IMAGENS / f'iphone_{args.tela}.png')))
    altura = macbook.height * 0.78
    iphone = iphone.resize((round(iphone.width * altura / iphone.height), round(altura)), Image.LANCZOS)
    salvar(lado_a_lado([macbook, iphone]), IMAGENS / 'produto-apple.png')


def android_windows(args):
    android = abrir(MOLDURAS / 'android' / f'pixel_{args.tela}.png')
    windows = janela_do_windows(abrir(IMAGENS / f'windows_{args.tela}.png'))
    altura = windows.height * 0.9
    android = android.resize((round(android.width * altura / android.height), round(altura)), Image.LANCZOS)
    salvar(lado_a_lado([windows, android]), IMAGENS / 'produto-android-windows.png')


def main():
    parser = argparse.ArgumentParser(description='Monta as imagens de produto do README.')
    parser.add_argument('comando', choices=['reduzir', 'apple', 'android-windows', 'tudo'])
    parser.add_argument('--tela', default='inicio')
    parser.add_argument('--iphone', default=MOLDURAS / 'apple' / 'iphone.png')
    parser.add_argument('--macbook', default=MOLDURAS / 'apple' / 'macbook.png')
    args = parser.parse_args()
    if args.comando in ('reduzir', 'tudo'):
        reduzir()
    if args.comando in ('apple', 'tudo'):
        apple(args)
    if args.comando in ('android-windows', 'tudo'):
        android_windows(args)


if __name__ == '__main__':
    main()
