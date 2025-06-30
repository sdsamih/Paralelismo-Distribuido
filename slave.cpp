#include <iostream>
#include <vector>
#include <netinet/in.h>
#include <unistd.h>

#define PORT 5000

using namespace std;

void calculaHistograma(unsigned char* dados, int linhas, int colunas, vector<int>& hist, int n_intervalos) {
    hist.assign(n_intervalos, 0);
    int tamanho_intervalo = 256 / n_intervalos;
    for (int i = 0; i < linhas * colunas; ++i) {
        int intervalo = dados[i] / tamanho_intervalo;
        if (intervalo >= n_intervalos)
            intervalo = n_intervalos - 1;
        hist[intervalo]++;
    }
}

int main() {
    //estabelece os dados usados na criacao do socket
    int server_fd, new_socket; 
    struct sockaddr_in address;    
    socklen_t addrlen = sizeof(address); 

    int linhas, colunas, n_intervalos; 

    server_fd = socket(AF_INET, SOCK_STREAM, 0); //estabelece o socket em si (tcp,ipv4)

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);


    //comeca a aguardar a conexao do master
    bind(server_fd, (struct sockaddr*)&address, sizeof(address));
    listen(server_fd, 5);

    cout << "Slave aguardando conexao..." << endl;

    while (true) {
        new_socket = accept(server_fd, (struct sockaddr*)&address, &addrlen);
        if (new_socket < 0) continue; //enquanto nao receber os dados do master

        //armazena os valores recebidos do master (tamanho da submatriz e n de intervalos)
        recv(new_socket, &linhas, sizeof(int), 0);
        recv(new_socket, &colunas, sizeof(int), 0);
        recv(new_socket, &n_intervalos, sizeof(int), 0);

        int total = linhas * colunas;
        unsigned char* dados = new unsigned char[total]; //vetor alocado pra armazenar os dados do tamanho da submatriz
        recv(new_socket, dados, total, MSG_WAITALL);

        vector<int> hist(n_intervalos);
        calculaHistograma(dados, linhas, colunas, hist, n_intervalos);

        //depois de fazer o calculo do subhistograma, envia para o master
        send(new_socket, hist.data(), hist.size() * sizeof(int), 0);
        close(new_socket);
        delete[] dados;

        cout << "Histograma enviado!" << endl;
    }

    close(server_fd);
    return 0;
}
