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

function estrutura = L2A_IO_Ident(args)
tic
%declaração de variáveis:
[t_0,t_final, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,   ...
 cond_iniciais_m,cond_iniciais_i, alfa0,Q,gamma,P,~,ref_amp, ...
 ref_freq,tol_eta,tau_ref] = convert_struct(args);
%prealocação de memória:
     %número de passos a serem dados na simulação
     stoptime = t_final-t_0;
     endk = floor(stoptime/h);
size_modelos = size(modelos);
n_de_linhas  = size_modelos(1);

[tempo,r,r_ponto,eta,u,  ...
    alfa_ponto,alfa_ponto_n1,alfa_n1,x_i_ponto,       ...
    x_m_ponto, x_p_ponto, e_o, norm_2_e_o,            ...
    theta_p_estimativa, x_i, x_p, x_m, theta_i,       ...
    A_i, theta_i_ponto, k_T, alfa_barra, alfa,E,e_i] ...
    = preallocate_memory(n_de_linhas,endk);

%matrizes na forma canônica (companion form):
h_transposto(length(modelos)-1) = 0;
h_transposto(1) = 1;
A_p = can(planta);
A_m = can(modelo_de_referencia);
for i=1:length(modelos)
A_i(:,:,i,1) = can(modelos(:,i));
end
theta_BARRA(:,:,1) = modelos;
for j=1:length(modelos)
theta_i(:,j,1) = modelos(:,j);
end
%b é considerado conhecido, os sistemas não contém zeros.
b(n_de_linhas,1)=1;

%condições iniciais da planta, modelo de referência e modelos de
%identificação
x_p(:,1) = cond_iniciais_p;
y(1)   = h_transposto*x_p(:,1);
x_m(:,1) = cond_iniciais_m;

for j=1:length(modelos)
x_i(:,j,1) = cond_iniciais_i(:,j);
y_i(j,1)   = h_transposto*x_i(:,j,1);
%inicialização dos erros
e_i(:,j,1) = x_i(:,j,1) - x_p(:,1);
end

%inicialização da matriz E
for j=1:(length(modelos)-1)
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
    u(k) = r(k);

%Geração dos erros entre os modelos escolhidos e a planta
for j=1:length(modelos)
    e_i(:,j,k) = x_i(:,j,k) - x_p(:,k);
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
end

for j=1:(n_de_linhas)
    E(1,j,k) = y_i(j,k)-y_i(n_de_linhas+1,k);
end
%geração do vetor alfa através da inversa de E

    alfa_ponto(:,k) = gamma*(-transpose(E(1,:,k))*E(1,:,k)*alfa(:,k)- ...
                     (transpose(E(1,:,k)))*(y_i(n_de_linhas+1,k)-y(k)));

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
    theta_i(:,j,k+1) = theta_i(:,j,k);
    theta_BARRA(:,j,k+1) = theta_i(:,j,k+1);
    A_i(:,:,j,k+1) = can(theta_BARRA(:,j,k+1));
end

    
    for j=1:n_de_linhas+1
    x_i_ponto(:,j,k) = A_m*x_i(:,j,k) + (A_i(:,:,j,k) - A_m)*x_p(:,k) + b*u(k);
    x_i(:,j,k+1)     = x_i(:,j,k) + h*x_i_ponto(:,j,k);
    y_i(j,k+1)       = h_transposto*x_i(:,j,k+1);
    end
    
%dinâmica dos modelos, da planta e do modelo de referência
    x_m_ponto(:,k) = A_m*x_m(:,k) + b*r(k);
    x_m(:,k+1)     = x_m(:,k) + h*x_m_ponto(:,k);
    y_m(k+1)       = h_transposto*x_m(:,k+1);
    x_p_ponto(:,k) = A_p*x_p(:,k) + b*u(k);
    x_p(:,k+1)     = x_p(:,k) + h*x_p_ponto(:,k);
    y(k+1)       = h_transposto*x_p(:,k+1);
    
    %cálculo da norma 2 do erro
    e_o(:,k)     = x_m(:, k) - x_p(:, k);
    norm_2_e_o(k)     = sqrt(transpose(e_o(:,k))*e_o(:,k));
    theta_p_estimativa(:,k) = theta_BARRA(:,:,k)*alfa_barra(:,k);
    %fim do laço principal
end

estrutura = make_struct(x_p,x_m,eta,theta_p_estimativa,norm_2_e_o,  ...
                        e_o,u, alfa_barra, r, modelo_de_referencia, ...
                            planta, theta_BARRA, modelos,tempo,endk);

toc

end