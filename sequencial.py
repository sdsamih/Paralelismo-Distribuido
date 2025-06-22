from PIL import Image
import numpy as np
import time  # Importa o módulo para medir o tempo

def sequencial(path, intervalos):
    relatorio = {}

    imagem = Image.open(path).convert("L")  # carregar a imagem e converter pra grayscale
    matriz = np.array(imagem)  # transformar a imagem em um array NumPy

    tamanho_intervalo = 256 / intervalos  # tamanho de cada intervalo
    histograma = np.zeros(intervalos, dtype=int)

    linhas, colunas = matriz.shape

    inicio = time.time()  # tempo inicial

    for linha in range(linhas):
        for coluna in range(colunas):
            luminescencia = matriz[linha][coluna]
            intervalo_escolhido = int(luminescencia / tamanho_intervalo)
            if intervalo_escolhido >= intervalos:
                intervalo_escolhido = intervalos - 1  # caso 255 caia exatamente no último intervalo
            histograma[intervalo_escolhido] += 1

    fim = time.time()  # tempo final

    tempo_execucao_ms = (fim - inicio) * 1000  # calcula tempo em ms

    relatorio["histograma"] = histograma
    relatorio["tempo_ms"] = tempo_execucao_ms

    return relatorio
