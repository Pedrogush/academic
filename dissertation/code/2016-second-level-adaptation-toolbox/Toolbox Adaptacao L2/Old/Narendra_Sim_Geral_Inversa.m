%Simulação 1 referente ao artigo sobre adaptação de segundo nível:
%Proceedings of the 2014 American Control Conference
%Kumpati S. Narendra, Yu Wang, Wei Chen
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Gushiken

%stoptime é o tempo de simulação
%h é o passo de simulação
%exemplo 1:
%Narendra_Sim_Geral_Inversa(16,1e-3,[3 -2 7; -6 -2 -3], [-2 -1], 
%                           [-1 -3], [0.1; 0.2], [0; 0], [2 2 1 ;0 -1 0], [1 0], 5)
%Narendra_Sim_Geral_Inversa(16,1e-3,[-3 -2 -7 -8; -4 -4 -1 -2; -5 -7 -9
%-1], [-7 -9 -2], [-3 -3 -1], [0.1; 0.2; 0.3], [0 ; 0; 0], [2 2 1 4; 2 0 1
%-1; 5 7 0 1], [1 0 0], 5)
function Narendra_Sim_Geral_Inversa(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,cond_iniciais_m,cond_iniciais_i, alfa0,referencia)
%declaração de variáveis:

size_modelos = size(modelos);
n_de_linhas  = size_modelos(1);
%matrizes na forma canônica (companion form):
for matriz=1:length(modelos)
    for linha=1:n_de_linhas
        for coluna=1:n_de_linhas
            if linha<n_de_linhas
            if coluna~=linha+1
            A_i(linha,coluna,matriz) = 0;
            A_p(linha,coluna) = 0;
            A_m(linha,coluna) = 0;
            end
            end
if linha+1==coluna
if linha<n_de_linhas
A_i(linha,coluna,matriz) = 1;
A_p(linha,coluna)        = 1;
A_m(linha,coluna)        = 1;
end
end
if linha==n_de_linhas
A_i(linha,coluna,matriz) = modelos(coluna, matriz);
A_p(linha,coluna) = planta(coluna);
A_m(linha,coluna) = modelo_de_referencia(coluna);
end
        end
    end
end
theta_BARRA = modelos;

%b é considerado conhecido, os sistemas não contém zeros.
for j=1:n_de_linhas
b(j,1) = 0;
if j==n_de_linhas
    b(j,1)=1;
end
end
%condições iniciais da planta, modelo de referência e modelos de
%identificação
x_p(:,1) = cond_iniciais_p;
x_m(:,1) = cond_iniciais_m;

for j=1:length(modelos)
x_i(:,j,1) = cond_iniciais_i(:,j);
%inicialização dos erros
e_i(:,j,1) = x_i(:,j,1) - x_p(:,1);
end

%inicialização da matriz E
for j=1:(length(modelos)-1)
    E(:,j,1) = [e_i(:,j,1)-e_i(:,length(modelos),1)];
end

%condições iniciais do vetor de combinação linear alfa_barra
alfa(:,1)= alfa0;
alfa_barra(:,1) = transpose([transpose(alfa(:,1)) 1-ones(1,length(alfa))*alfa(:,1)]);

%inicialização dos parâmetros do controlador
k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,1);

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
    r(k)   = referencia;
%Geração dos erros entre os modelos escolhidos e a planta
for j=1:length(modelos)
    e_i(:,j,k) = x_i(:,j,k) - x_p(:,k);
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
end

for j=1:(length(modelos)-1)
    E(:,j,k) = [e_i(:,j,k)-e_i(:,length(modelos),k)];
end
%geração do vetor alfa através da inversa de E
    alfa(:,k) = -(E(:,:,k)^-1)*e_i(:,length(modelos),k);
%composição de alfa para gerar alfa_barra, que é uma parametrização da
%planta
    alfa_barra(:,k+1) = transpose([transpose(alfa(:,k)) 1-ones(1, length(alfa(:,k)))*alfa(:,k)]);
%geração dos parâmetros do controlador, note-se que
%theta_BARRA*alfa_barra(1:3,k) corresponde a theta_p_chapéu, a estimativa
%dos parâmetros da planta
    k_T(:,k+1) =transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,k);
%lei de controle
    u(k+1) = r(k) + transpose(k_T(:,k))*x_p(:,k);
%dinâmica dos modelos, da planta e do modelo de referência
for j=1:length(modelos)
    x_i_ponto(:,j,k) = A_m*x_i(:,j,k) + (A_i(:,:,j) - A_m)*x_p(:,k) + b*u(k);
    x_i(:,j,k+1)     = x_i(:,j,k) + h*x_i_ponto(:,j,k);
end
    x_m_ponto(:,k) = A_m*x_m(:,k) + b*r(k);
    x_m(:,k+1)     = x_m(:,k) + h*x_m_ponto(:,k);
    x_p_ponto(:,k) = A_p*x_p(:,k) + b*u(k);
    x_p(:,k+1)     = x_p(:,k) + h*x_p_ponto(:,k);
    e_o(:,k+1)     = x_m(:, k+1) - x_p(:, k+1);
    norm_2_e_o(k+1)     = sqrt(transpose(e_o(:,k+1))*e_o(:,k+1));
end
plot(tempo, norm_2_e_o)
%plot(tempo, x_p, tempo, x_m)
%plot(tempo, alfa_barra)
%plot(tempo, u)
end