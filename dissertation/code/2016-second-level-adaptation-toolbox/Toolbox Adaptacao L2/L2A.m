%Simulação referente ao artigo sobre adaptação de segundo nível:
%Proceedings of the 2014 American Control Conference
%Kumpati S. Narendra, Yu Wang, Wei Chen
%Universidade Federal do Rio Grande do Norte
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Gushiken

%Função referente à Adaptação de Segundo Nível com Esquema de Desligamento
%do Sinal PE quando existe acesso às variáveis de estado da planta. A
%entrada da função é uma estrutura de dados


%stoptime é o tempo de simulação
%h é o passo de simulação

%modelos corresponde a THETA_BARRA

%planta corresponde ao vetor theta_p transposto

%modelo_de_referencia corresponde ao vetor theta_m transposto

%cond_iniciais_p corresponde ao vetor x_p(k=1)

%cond_iniciais_m corresponde ao vetor x_m(k=1)

%cond_iniciais_i corresponde aos vetores x_i(k=1) dos n+1 modelos de
%identificação

%alfa0 corresponde ao vetor alfa(k=1), portanto ao escolher alfa0 em
%combinação com theta_BARRA escolhe-se theta(0) na simulação.

%Q corresponde a matriz que pesa o valor de eta de acordo com a taxa de
%adaptação

%gamma é o ganho da equação diferencial que cálcula as estimativas dos
%parâmetros associados à adaptação de segundo nível

%P é a matriz de ganhos adaptativos

%ref_amp é o vetor linha referente às amplitudes dos sinais a serem introduzidos
%na planta

%ref_freq é o vetor coluna referente às frequências dos sinais cosseno a serem
%introduzidos na planta

%tol_eta é a tolerância para a figura de mérito eta a partir da qual deve
%se efetuar o desligamento suave do sinal PE

%tau_ref é a constante de tempo da equação diferencial de primeira ordem
%que efetua a retirada do sinal PE, de forma a manter o sinal suave

%sintaxe; criar uma estrutura de dados args que contenha os seguintes campos:
%        [stoptime, h, modelos, planta, modelo_de_referencia,        ...
%         cond_iniciais_p,cond_iniciais_m,cond_iniciais_i, alfa0,    ...
%         referencia,Q,gamma,P,ref_amp,ref_freq,tol_eta,tau_ref]
 
%onde stoptime,h,referencia,gamma,tol_eta,tau_ref são escalares
%modelos e cond_iniciais_i são  matrizes n x (n+1)
%planta e modelo_de_referencia são vetores 1 x n
%cond_iniciais_p e cond_iniciais_m são vetores n x 1
%alfa0 é um vetor 1x (n+1)
%Q e P são matrizes nxn, definidas positivas e diagonais
%Onde n é a ordem do sistema simulado
%ref_amp é um vetor 1 x k
%ref_freq e um vetor k x 1
%Onde k é o número de sinais a serem introduzidos na planta.

%obs: o código está implementado de forma que o primeiro elemento de
%ref_freq deve ser 0, representando a componente DC do sinal a ser
%introduzido.

%L2AA(args) simula o sistema de acordo com as especificações, a saída da função é uma
%estrutura de dados.

%use plot_adap_figures_L2_VE usando a estrutura de dados de saída como
%argumento para produzir os gráficos

function estrutura = L2A(args)
tic
%declaração de variáveis:
[t0, t_final, h, modelos_polos, modelos_zeros, planta_polos,planta_zeros,         ...
 modelo_de_referencia_polos,modelo_de_referencia_zeros,      ...
 cond_iniciais_p,cond_iniciais_m,cond_iniciais_i, alfa0,Q,   ...
 gamma,P,~,ref_amp,ref_freq,tol_eta,tau_ref] = convert_struct(args);
%prealocação de memória:
     %número de passos a serem dados na simulação
     stoptime = t_final - t0;
     endk = floor(stoptime/h);
size_modelos = size(modelos_polos);
n_de_linhas  = size_modelos(1);

[tempo,r,r_ponto,eta,u,  ...
    alfa_ponto,alfa_ponto_n1,alfa_n1,x_i_ponto,       ...
    x_m_ponto, x_p_ponto, e_o, norm_2_e_o,            ...
    theta_p_estimativa, x_i, x_p, x_m, theta_i,       ...
    A_i, theta_i_ponto, k_T, alfa_barra, alfa,E,e_i] ...
    = preallocate_memory(n_de_linhas,endk);

%matrizes na forma canônica (companion form):
A_p = can(planta_polos);
A_m = can(modelo_de_referencia_polos);
for i=1:length(modelos_polos)/2
A_i(:,:,i,1) = can(modelos_polos(:,i));
end
theta_BARRA(:,:,1) = [modelos_zeros; modelos_polos];
for j=1:length(modelos_polos)
theta_i(:,j,1) = [modelos_zeros(:,j); modelos_polos(:,j)];
end
%b é considerado conhecido, os sistemas não contém zeros.

b_p(:,1) = planta_zeros;
b_m(:,1) = modelo_de_referencia_zeros;
for j=1:length(modelos_zeros)
b_i(:,j,1,1) = modelos_zeros(:,j);
end
%condições iniciais da planta, modelo de referência e modelos de
%identificação
x_p(:,1) = cond_iniciais_p;
x_m(:,1) = cond_iniciais_m;

for j=1:length(modelos_polos)
x_i(:,j,1) = cond_iniciais_i(:,j);
%inicialização dos erros
e_i(:,j,1) = x_i(:,j,1) - x_p(:,1);
end

%inicialização da matriz E
for j=1:(length(modelos_polos)-1)
    E(:,j,1) = x_i(:,j,1)-x_i(:,n_de_linhas+1,1);
end

%condições iniciais do vetor de combinação linear alfa_barra
alfa(:,1)= alfa0;
alfa_barra(:,1) = transpose([transpose(alfa(:,1)) 1-ones(1,n_de_linhas)*alfa(:,1)]);

%inicialização dos parâmetros do controlador
k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,1);

%inicialização da entrada da planta
u(1)   = ref_amp(1);

%inicialização do tempo de simulação
tempo(1) = 0;
eta(1)=0;


r_ponto(1) = 0;
%início


for k=1:endk
%tempo de simulação
    tempo(k+1)  = tempo(k)+h;
%sinal de referência
    r(k+1) = ref_amp*cos(tempo(k)*ref_freq); 
    if eta(k)<=tol_eta
        r_ponto(k) = tau_ref*(-r(k) + ref_amp(1));
        r(k+1) = r(k) + h*r_ponto(k);
    end
    
    
%Geração dos erros entre os modelos escolhidos e a planta
for j=1:length(modelos_polos)
    e_i(:,j,k) = x_i(:,j,k) - x_p(:,k);
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
end

for j=1:(n_de_linhas)
    E(:,j,k) = x_i(:,j,k)-x_i(:,n_de_linhas+1,k);
end
%geração do vetor alfa através da inversa de E
    alfa_ponto(:,k) = gamma*(-transpose(E(:,k))*E(:,k)*alfa(:,k)-(transpose(E(:,k)))*e_i(n_de_linhas+1,k));
    alfa_n1(k) = 1-ones(1, n_de_linhas)*alfa(:,k);
    alfa_ponto_n1(k) = -ones(1, n_de_linhas)*alfa_ponto(:,k);
    for i=1:n_de_linhas
        if (alfa(i,k)>=1 && alfa_ponto(i,k)>0)||(alfa(i,k)<=0 && alfa_ponto(i,k)<0)
            alfa_ponto(i,k)=0;
        end
        if (alfa_n1(k)>=1 && alfa_ponto_n1(k)>0)||(alfa_n1(k)<=0 && alfa_ponto_n1(k)<0)
        for j=1:length(alfa_ponto(:,k))
            if sign(alfa_ponto_n1(k))~=sign(alfa_ponto(j,k))
               alfa_ponto(j,k)=0; 
            end
        end              
        end       
    end
    alfa(:,k+1) = alfa(:,k) + h*alfa_ponto(:,k);
    eta(k+1) = transpose(alfa_ponto(:,k))*Q*alfa_ponto(:,k)/(1 + transpose(alfa_ponto(:,k))*Q*alfa_ponto(:,k));
    
    alfa_barra(:,k) = transpose([transpose(alfa(:,k)) 1-ones(1, n_de_linhas)*alfa(:,k)]);
    
    
    %Adaptação dos modelos de primeiro nível
    for j=1:n_de_linhas+1
    theta_i_ponto(:,j,k) = -(e_i(j,k))*transpose(w_T(:,k));
    theta_i(:,j,k+1) = theta_i(:,j,k) + h*theta_i_ponto(:,j,k);
    theta_BARRA(:,j,k+1) = theta_i(:,j,k+1);
    end
    
    for j=1:n_de_linhas+1
    x_i_ponto(:,j,k) = A_m*x_i(:,j,k) + (A_i(:,:,j,k) - A_m)*x_p(:,k) + b*u(k);
    x_i(:,j,k+1)     = x_i(:,j,k) + h*x_i_ponto(:,j,k);
    end
    
%dinâmica dos modelos, da planta e do modelo de referência
    x_m_ponto(:,k) = A_m*x_m(:,k) + b_m*r(k);
    x_m(:,k+1)     = x_m(:,k) + h*x_m_ponto(:,k);
    
    x_p_ponto(:,k) = A_p*x_p(:,k) + b_p*u(k);
    x_p(:,k+1)     = x_p(:,k) + h*x_p_ponto(:,k);

    %representação 1
    %for j=1:n_de_linhas
    %  theta_T_i(:,j,k) = [theta_i_1_T(:,j,k) theta_i_2_T(:,j,k)];
    %end
    
    %representação 2
    
    %cálculo da norma 2 do erro
    e_o(:,k)     = x_m(:, k) - x_p(:, k);
    norm_2_e_o(k)     = sqrt(transpose(e_o(:,k))*e_o(:,k));
    theta_p_estimativa(:,k) = theta_BARRA(:,:,k)*alfa_barra(:,k);
    %fim do laço principal
end

estrutura = make_struct(x_p,x_m,eta,theta_p_estimativa,norm_2_e_o,  ...
                        e_o,u, alfa_barra, r, modelo_de_referencia, ...
                            planta_polos, theta_BARRA, modelos_polos,tempo,endk);

toc

end