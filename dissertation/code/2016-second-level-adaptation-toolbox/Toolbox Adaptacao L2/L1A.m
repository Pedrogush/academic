%Função de Adaptação de Primeiro Nível:
%Proceedings of the 2014 American Control Conference
%Kumpati S. Narendra, Yu Wang, Wei Chen
%Universidade Federal do Rio Grande do Norte
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Gushiken

%A função de adaptação de segundo nível foi adaptada para a adaptação de
%primeiro nível de forma a facilitar o uso de estruturas de dados no
%argumento das funções, permitindo comparações rápidas de desempenho via
%simulação, desta forma, algumas das variáveis declaradas nesta função são
%redundantes no código

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

%gamma é redundante
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

%L1A(args) simula o sistema de acordo com as especificações, a saída da função é uma
%estrutura de dados.

%use plot_adap_figures_L1 usando a estrutura de dados de saída como
%argumento para produzir os gráficos da primeira e segunda variável de
%estado da planta e modelos de referência, adaptação dos alfas no tempo,
%sinal de controle, norma 2 do erro de saída e trajetória dos parâmetros no
%espaço de parâmetros bi dimensional caso o sistema seja de ordem 2.

function estrutura = L1A(args)
%avaliação do inicio do tempo de simulação
tic

%declaração de variáveis usando uma estrutura de dados:
[stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,   ...
 cond_iniciais_m,cond_iniciais_i, alfa0,Q,gamma,P,~,ref_amp, ...
 ref_freq,tol_eta,tau_ref] = convert_struct(args);

endk = floor(stoptime/h);
%variável auxiliar, número de linhas da matriz theta_BARRA referente aos
%modelos de identificação
size_modelos = size(modelos);
n_de_linhas  = size_modelos(1);

%prealocação das variáveis (melhora de eficiência do código), normalmente
%seria colocado antes do laço, porém é necessário colocar aqui por motivos
%de sobrescrita de variáveis
         [tempo,r,r_ponto,eta,u,  ...
          alfa_ponto,alfa_ponto_n1,alfa_n1,x_i_ponto,       ...
          x_m_ponto, x_p_ponto, e_o, norm_2_e_o,            ...
          theta_p_estimativa, x_i, x_p, x_m, theta_i,       ...
          A_i, theta_i_ponto, k_T, alfa_barra, alfa,E,e_i]  ...
        = preallocate_memory(n_de_linhas,endk);

%matrizes na forma canônica (companion form):
A_p = can(planta);
A_m = can(modelo_de_referencia);
for i=1:length(modelos)
A_i(:,:,i,1) = can(modelos(:,i));
end
%inicialização de theta_BARRA referente aos modelos de identificação
theta_BARRA(:,:,1) = modelos;
for j=1:length(modelos)
%inicialização dos modelos de identificação
theta_i(:,j,1) = modelos(:,j);
end
%inicialização de b, que é considerado conhecido,
%os sistemas não contém zeros.
for j=1:n_de_linhas
b(j,1) = 0; %#ok<AGROW>
if j==n_de_linhas
    b(j,1)=1; %#ok<AGROW>
end
end
%condições iniciais da planta e modelo de referência
x_p(:,1) = cond_iniciais_p;

x_m(:,1) = cond_iniciais_m;

for j=1:length(modelos)
%inicialização das condições iniciais dos modelos de identificação
x_i(:,j,1) = cond_iniciais_i(:,j); 

%inicialização dos erros
e_i(:,j,1) = x_i(:,j,1) - x_p(:,1);
%inicialização de theta_i_ponto
theta_i_ponto(:,j,1) = -transpose(e_i(:,j,1))*P*b*x_p(:,1); 
end

%inicialização da matriz E
for j=1:(length(modelos)-1)
    E(:,j,1) = x_i(:,j,1)-x_i(:,length(modelos),1);
end

%condições iniciais do vetor de combinação linear alfa_barra
alfa(:,1)= alfa0;
transpose([transpose(alfa(:,1)) ...
                   1-ones(1,n_de_linhas)*alfa(:,1)]);
alfa_barra(:,1)  = transpose([transpose(alfa(:,1)) ...
                   1-ones(1,n_de_linhas)*alfa(:,1)]);
alfa_barra0(:,1) = transpose([transpose(alfa(:,1)) ...
                   1-ones(1,n_de_linhas)*alfa(:,1)]);
%inicialização dos parâmetros do controlador
k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra0(:,1);

%inicialização da entrada da planta
u(1)   = ref_amp(1);

%número de passos a serem dados na simulação

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
for j=1:length(modelos)
    e_i(:,j,k) = x_i(:,j,k) - x_p(:,k);
end
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
for j=1:(length(modelos)-1)
    E(:,j,k) = x_i(:,j,k)-x_i(:,n_de_linhas+1,k);
end
    %geração do vetor alfa através da equação diferencial proposta na
    %adaptação de segundo nível
    alfa_ponto(:,k) = gamma*(-transpose(E(:,:,k))*E(:,:,k)*alfa(:,k) ...
                      -(transpose(E(:,:,k)))*e_i(:,n_de_linhas+1,k));
    alfa_n1(k)      = 1-ones(1, n_de_linhas)*alfa(:,k);
    alfa_ponto_n1(k)=  -ones(1, n_de_linhas)*alfa_ponto(:,k);
    %lei de projeção de alfa
    for i=1:n_de_linhas
        if (alfa(i,k)>=1 && alfa_ponto(i,k)>0)||(alfa(i,k)<=0 && alfa_ponto(i,k)<0)
            alfa_ponto(i,k)=0;
        end
        if (alfa_n1(k)>=1 && alfa_ponto_n1(k)>0)||(alfa_n1(k)<=0 && alfa_ponto_n1(k)<0)
        for j=1:n_de_linhas
            if sign(alfa_ponto_n1(k))~=sign(alfa_ponto(j,k))
               alfa_ponto(j,k)=0; 
            end
        end              
        end       
    end
    alfa(:,k+1) = alfa(:,k) + h*alfa_ponto(:,k);
   
%composição de alfa para gerar alfa_barra, que é uma parametrização da
%planta
    alfa_barra(:,k) = transpose([transpose(alfa(:,k)) ...
             1-ones(1, length(alfa(:,k)))*alfa(:,k)]);
%geração dos parâmetros do controlador, note-se que
%theta_BARRA*alfa_barra(1:3,k) corresponde a theta_p_chapéu, a estimativa
%dos parâmetros da planta

    k_T(:,k) =transpose(modelo_de_referencia) - theta_BARRA(:,:,k)*alfa_barra0(:,1);
%lei de controle
    u(k) = r(k) + transpose(k_T(:,k))*x_p(:,k);

    
%adaptação dos modelos de identificação
for j=1:n_de_linhas+1
    theta_i_ponto(:,j,k) = -transpose(e_i(:,j,k))*P*b*x_p(:,k);
    theta_i(:,j,k+1) = theta_i(:,j,k) + h*theta_i_ponto(:,j,k);
    theta_BARRA(:,j,k+1) = theta_i(:,j,k+1);
    A_i(:,:,j,k+1) = can(theta_BARRA(:,j,k+1));
end

%dinâmica dos modelos, da planta e do modelo de referência
for j=1:n_de_linhas+1
    x_i_ponto(:,j,k) = A_m*x_i(:,j,k) + (A_i(:,:,j,k) - A_m)*x_p(:,k) + b*u(k);
    x_i(:,j,k+1)     = x_i(:,j,k) + h*x_i_ponto(:,j,k);
end
    x_m_ponto(:,k) = A_m*x_m(:,k) + b*r(k);
    x_m(:,k+1)     = x_m(:,k) + h*x_m_ponto(:,k);
    x_p_ponto(:,k) = A_p*x_p(:,k) + b*u(k);
    x_p(:,k+1)     = x_p(:,k) + h*x_p_ponto(:,k);
    %cálculo da norma 2 do erro
    e_o(:,k)     = x_m(:, k) - x_p(:, k);
    norm_2_e_o(k)     = sqrt(transpose(e_o(:,k))*e_o(:,k));
    %cálculo da estimativa de theta_p através de alfa_barra, usado apenas
    %graficamente
    theta_p_estimativa(:,k) = theta_BARRA(:,:,k)*alfa_barra(:,k);
    %cálculo da figura de mérito eta de forma a decidir sobre o
    %desligamento do sinal de referência persistentemente excitante
     eta(k+1) = transpose(theta_i_ponto(:,3,k))*Q*theta_i_ponto(:,3,k)/(1 +...
                transpose(theta_i_ponto(:,3,k))*Q*theta_i_ponto(:,3,k));
            
%fim do laço principal
end
estrutura = make_struct(x_p,x_m,eta,theta_p_estimativa,norm_2_e_o, ...
                        e_o,u, alfa_barra, r, modelo_de_referencia,...
                        planta, theta_BARRA, modelos,tempo,endk);

toc

%fim da função
end