%Simulação 1 referente ao artigo sobre adaptação de segundo nível:
%Proceedings of the 2014 American Control Conference
%Kumpati S. Narendra, Yu Wang, Wei Chen
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Gushiken

%stoptime é o tempo de simulação
%h é o passo de simulação

function narendra_sim_inversa(stoptime, h)
%declaração de variáveis:

%modelos de "identificação" fixos
theta_1T = [-2 -4];
theta_2T = [-6 -6];
theta_3T = [3 -6];

%planta
theta_pT = [-2  -1];
%modelo de referência
theta_mT = [-1 -3];
%matrizes na forma canônica (companion form):
A_1 = [0 1; theta_1T];
A_2 = [0 1; theta_2T];
A_3 = [0 1; theta_3T];
A_p = [0 1; theta_pT];
A_m = [0 1; theta_mT];
theta_BARRA = transpose([theta_1T; theta_2T; theta_3T]);

%b é considerado conhecido, os sistemas não contém zeros.
b   = [0 ; 1];

%condições iniciais da planta, modelo de referência e modelos de
%identificação
x_p(1:2,1) = [0.2 ; 0.1];
x_m(1:2,1) = [0 ; 0];
x_1(1:2,1) = [2 ; 2];
x_2(1:2,1) = [1 ; 0];
x_3(1:2,1) = [0 ; 0];
%inicialização dos erros
e_1(1:2,1) = x_1(1:2,1) - x_p(1:2,1);
e_2(1:2,1) = x_2(1:2,1) - x_p(1:2,1);
e_3(1:2,1) = x_3(1:2,1) - x_p(1:2,1);

%inicialização da matriz E
E(1:2,1:2,1)   = [e_1(1:2,1) e_2(1:2,1)];

%condições iniciais do vetor de combinação linear alfa_barra
alfa(1:2,1)= [0 0];
alfa_barra(1:3,1) = transpose([transpose(alfa(1:2,1)) 1-[1 1]*alfa(1:2,1)]);

%inicialização dos parâmetros do controlador
k_T(1:2,1) = transpose(theta_mT) - theta_BARRA*alfa_barra(1:3,1);

%inicialização da entrada da planta
u(1)   = 0;

%inicialização do tempo de simulação
tempo(1) = 0;

%número de passos a serem dados na simulação
endk = floor(stoptime/h);

%início
for k=1:endk
%tempo de simulação
    tempo(k+1)  = tempo(k)+h;
%sinal de referência
    r(k)   = 10*sin(k*h)+10;
%Geração dos erros entre os modelos escolhidos e a planta    
    e_1(1:2,k) = x_1(1:2,k) - x_p(1:2,k);
    e_2(1:2,k) = x_2(1:2,k) - x_p(1:2,k);
    e_3(1:2,k) = x_3(1:2,k) - x_p(1:2,k);
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
    E(1:2,1:2,k) = [e_1(1:2,k)-e_3(1:2,k) e_2(1:2,k)-e_3(1:2,k)];
%geração do vetor alfa através da inversa de E
    alfa(1:2,k) = -(E(1:2,1:2,k)^-1)*e_3(1:2,k);
%composição de alfa para gerar alfa_barra, que é uma parametrização da
%planta
    alfa_barra(1:3,k+1) = transpose([transpose(alfa(1:2,k)) 1-[1 1]*alfa(1:2,k)]);
%geração dos parâmetros do controlador, note-se que
%theta_BARRA*alfa_barra(1:3,k) corresponde a theta_p_chapéu, a estimativa
%dos parâmetros da planta
    k_T(1:2,k) =transpose(theta_mT) - theta_BARRA*alfa_barra(1:3,k);
%lei de controle
    u(k+1) = r(k) + transpose(k_T(1:2,k))*x_p(1:2,k);
%dinâmica dos modelos, da planta e do modelo de referência
    x_1_ponto(1:2,k) = A_m*x_1(1:2,k) + (A_1 - A_m)*x_p(1:2,k) + b*u(k);
    x_1(1:2,k+1)     = x_1(1:2,k) + h*x_1_ponto(1:2,k);
    x_2_ponto(1:2,k) = A_m*x_2(1:2,k) + (A_2 - A_m)*x_p(1:2,k) + b*u(k);
    x_2(1:2,k+1)     = x_2(1:2,k) + h*x_2_ponto(1:2,k);
    x_3_ponto(1:2,k) = A_m*x_3(1:2,k) + (A_3 - A_m)*x_p(1:2,k) + b*u(k);
    x_3(1:2,k+1)     = x_3(1:2,k) + h*x_3_ponto(1:2,k);
    x_m_ponto(1:2,k) = A_m*x_m(1:2,k) + b*r(k);
    x_m(1:2,k+1)     = x_m(1:2,k) + h*x_m_ponto(1:2,k);
    x_p_ponto(1:2,k) = A_p*x_p(1:2,k) + b*u(k);
    x_p(1:2,k+1)     = x_p(1:2,k) + h*x_p_ponto(1:2,k);
end
%plot(tempo, x_p, 'Black', tempo, x_m)
plot(tempo, alfa_barra)
%plot(tempo, u)
end