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

// kernel usado pra calcular o histograma (chamado dentro da funcao paralela posteriormente)
/*
imagem: Matriz carregada pelo OpenCV
linhas/colunas: Dimensões da matriz
histograma: Vetor que vai receber os valores calculados
intervalos: N de intervalos usados pro histograma
tamanho_intervalo: Tamanho de cada intervalo (calculado com base no n de intervalos (256/n_intervalos))
*/
__global__ void calcularHistogramaGPU(unsigned char* imagem, int linhas, int colunas, int* histograma, int intervalos, int tamanho_intervalo) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int total_pixels = linhas * colunas;

    if (idx < total_pixels) {
        int luminescencia = imagem[idx];
        int intervalo_escolhido = luminescencia / tamanho_intervalo;
        if (intervalo_escolhido >= intervalos)
            intervalo_escolhido = intervalos - 1;

        atomicAdd(&histograma[intervalo_escolhido], 1);
    }
}


void paralelo(string imagePath, int intervalos) {

    //carregamento inicial da imagem igual do paralelo
    Mat imagem = imread(imagePath, IMREAD_GRAYSCALE);
    if (imagem.empty()) {
        cout << "Erro ao carregar a imagem!" << endl;
        return;
    }
    // tempo inicio
    auto inicio = chrono::high_resolution_clock::now();

    int linhas = imagem.rows;
    int colunas = imagem.cols;
    int tamanho_intervalo = 256 / intervalos;
    int total_pixels = linhas * colunas;


    // Vetor host (na ram)
    vector<int> histograma(intervalos, 0);

    // ponteiros para os espaços de vram utilizados
    unsigned char* d_imagem; //matriz da imagem
    int* d_histograma; //histograma


    cudaMalloc(&d_imagem, total_pixels * sizeof(unsigned char)); //alocar os vetores (e colocar o endereco alocado nos ponteiros)
    cudaMalloc(&d_histograma, intervalos * sizeof(int));

    
    cudaMemcpy(d_imagem, imagem.data, total_pixels * sizeof(unsigned char), cudaMemcpyHostToDevice); //Copiar a matriz da imagem pro espaco alocado
    cudaMemset(d_histograma, 0, intervalos * sizeof(int)); //zerar o vetor do histograma 

    // Definir grid e block
    int threadsPorBloco = 256;
    int blocosPorGrid = (total_pixels + threadsPorBloco - 1) / threadsPorBloco; 

    

    // Chamar o kernel definido previamente (a fun)
    calcularHistogramaGPU<<<blocosPorGrid, threadsPorBloco>>>(d_imagem, linhas, colunas, d_histograma, intervalos, tamanho_intervalo);
    cudaDeviceSynchronize();

    // tempo fim e delta
    auto fim = chrono::high_resolution_clock::now();
    chrono::duration<double, milli> delta = fim - inicio;

    // copiar o resultado (na vram) de volta para a ram
    cudaMemcpy(histograma.data(), d_histograma, intervalos * sizeof(int), cudaMemcpyDeviceToHost);

    // libera a vram
    cudaFree(d_imagem);
    cudaFree(d_histograma);

    // Exibir histograma
    cout << "Histograma (Paralelo CUDA):" << endl;
    for (int i = 0; i < intervalos; i++) {
        cout << i << ": " << histograma[i] << endl;
    }

    cout << "Tempo (GPU): " << delta.count() << " ms\n\n\n" << endl;
}

int main() {
    int opcao;
    string imagePath;
    int intervalos;

    cout << "Digite o caminho da imagem: ";
    cin >> imagePath;

    cout << "Digite o numero de intervalos: ";
    cin >> intervalos;

    cout << "\nEscolha o algoritmo:\n";
    cout << "1 - Sequencial\n";
    cout << "2 - Paralelo (CUDA)\n";
    cout << "Opcao: ";
    cin >> opcao;

    switch (opcao) {
        case 1:
            sequencial(imagePath, intervalos);
            break;
        case 2:
            paralelo(imagePath, intervalos);
            break;
    }

    return 0;
}
