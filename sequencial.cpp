#include <iostream>
#include <opencv2/opencv.hpp>
#include <chrono>
#include <vector>
#include <cuda_runtime.h>

using namespace std;
using namespace cv;


void sequencial(string imagePath, int intervalos) {
    Mat imagem = imread(imagePath, IMREAD_GRAYSCALE);

    int linhas = imagem.rows;
    int colunas = imagem.cols;
    int tamanho_intervalo = 256 / intervalos;

    vector<int> histograma(intervalos, 0);

    //tempo inicial
    auto inicio = chrono::high_resolution_clock::now();

    for (int linha = 0; linha < linhas; linha++) {
        for (int coluna = 0; coluna < colunas; coluna++) {
            int luminescencia = imagem.at<uchar>(linha, coluna);//metodo pra acessar coordenada especifica do OpenCV
            int intervalo_escolhido = luminescencia / tamanho_intervalo;
            if (intervalo_escolhido >= intervalos)
                intervalo_escolhido = intervalos - 1;
            histograma[intervalo_escolhido]++;
        }
    }

    auto fim = chrono::high_resolution_clock::now();//tempo final
    chrono::duration<double, milli> delta = fim - inicio;//delta tempo

    cout << "Histograma (Sequencial)" << endl;
    for (int i = 0; i < intervalos; i++) {
        cout << i << ": " << histograma[i] << endl;
    }

    cout << "Tempo: " << delta.count() << " ms\n\n\n" << endl;
}


int main() {
    sequencial("imagens/32k.png", 16);
    return 0;
}
