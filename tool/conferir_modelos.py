"""Confere se os modelos do app são os das releases do backend.

Uso:
    python3 tool/conferir_modelos.py

Para cada pasta em assets/models/, calcula o sha256 do chord_model.tflite e
compara com o campo sha256.float32 do model_info.json da mesma pasta. Esse
hash vem da release do modelo no ChordAI-backend (model-v3 e model-v3-meu).
Sai com erro se algum não bater ou se faltar arquivo. Só usa a biblioteca
padrão do Python, pra rodar no CI sem instalar nada."""
import hashlib
import json
import sys
from pathlib import Path

MODELOS = Path(__file__).resolve().parent.parent / 'assets' / 'models'


def conferir(pasta):
    """Devolve None se o .tflite bate com o model_info.json, ou o motivo do erro."""
    info_arquivo = pasta / 'model_info.json'
    if not info_arquivo.exists():
        return 'sem model_info.json'
    info = json.loads(info_arquivo.read_text(encoding='utf-8'))
    tflite = pasta / info.get('files', {}).get('float32', 'chord_model.tflite')
    if not tflite.exists():
        return f'sem {tflite.name}'
    esperado = info.get('sha256', {}).get('float32')
    if not esperado:
        return 'o model_info.json não tem sha256.float32'
    calculado = hashlib.sha256(tflite.read_bytes()).hexdigest()
    if calculado != esperado:
        return f'{tflite.name} tem sha256 {calculado}, o model_info.json espera {esperado}'
    return None


def main():
    pastas = sorted(p for p in MODELOS.iterdir() if p.is_dir())
    if not pastas:
        print(f'nenhum modelo em {MODELOS}')
        return 1
    erros = 0
    for pasta in pastas:
        motivo = conferir(pasta)
        if motivo:
            erros += 1
            print(f'ERRO {pasta.name}: {motivo}')
        else:
            print(f'ok   {pasta.name}')
    return 1 if erros else 0


if __name__ == '__main__':
    sys.exit(main())
