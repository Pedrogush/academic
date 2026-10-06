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

function estrutura = L2A_IO_CL_Ident_Esc(args)
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
n = (length(modelos)-1)/2;
npar = length(modelos)-1;

%[tempo,r,r_ponto,eta_natural,u,  ...
 %   alfa_ponto,alfa_ponto_n1,alfa_n1,x_i_ponto,       ...
  %  x_m_ponto, x_p_ponto, e_o, norm_2_e_o,            ...
   % theta_p_estimativa, x_i, x_p, x_m, theta_i,       ...
    %A_i, theta_i_ponto, k_T, alfa_barra, alfa,E,e_i] ...
    %= preallocate_memory(n,endk);

%matrizes na forma canônica (companion form):

h_transposto(n) = 1;
%Sistemas em forma canônica controlável

A_p = can(planta(n+1:npar));
%C_p = fliplr(planta(1:n)');
C_p = planta(1:n)';
A_m = can(modelo_de_referencia(n+1:npar));
C_m = fliplr(modelo_de_referencia(1:n));
%C_m = modelo_de_referencia(1:n);

A_i = zeros(n,n,npar,endk);
for i=1:npar+1
A_i(:,:,i,1) = can(modelos(n+1:npar,i));
C_i(1,:,i,1) = fliplr(modelos(1:n,i));
%C_i(1,:,i,1) = modelos(1:n,i);
end
theta_BARRA(:,:,1) = modelos;
theta_i = zeros(npar, npar+1, endk);
for j=1:npar
theta_i(:,j,1) = modelos(:,j);
end
b(n,1)=0;
b(1,1)=1;

%condições iniciais da planta, modelo de referência e modelos de
%identificação
x_p(:,1) = cond_iniciais_p;
x_p_obs(:,1) = x_p(:,1);
y(1)   = C_p*x_p(:,1);
x_m(:,1) = cond_iniciais_m;

for j=1:npar+1
x_i(:,j,1) = cond_iniciais_i(:,j);
y_i(j,1)   = C_i(1,:,j)*x_i(:,j,1);
%inicialização dos erros
e_i(:,j,1) = x_i(:,j,1) - x_p(:,1);
end

%inicialização da matriz E
%for j=1:npar
%    E(:,j,1) = x_i(:,j,1)-x_i(:,npar,1);
%end

%condições iniciais do vetor de combinação linear alfa_barra
alfa = zeros(npar,endk);
alfa(:,1)= alfa0;
alfa_barra(:,1) = transpose([transpose(alfa(:,1)) 1-ones(1,n_de_linhas)*alfa(:,1)]);

%inicialização dos parâmetros do controlador
k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,1);

%inicialização da entrada da planta
u(1)   = ref_amp(1);

%inicialização do tempo de simulação
tempo(1) = 0;
eta_natural(1)=0;
eta_concorrente(1) = 0;

r_ponto(1) = 0;
%início

M = zeros(npar,npar); M_fut =zeros(npar,npar);
vm = zeros(npar,1); vm_fut = zeros(npar,1);
alfa_estrela = [theta_BARRA; ones(1,length(theta_BARRA))]^-1*[planta; 1];
alfa_estrela = alfa_estrela(1:length(alfa_estrela)-1);
k = 0;
n_pontos = 30*npar;
point_collection_matrix = zeros(npar,npar,n_pontos);
point_collection_vector = zeros(npar,1,n_pontos);
while k~=endk
k=k+1;    

%Geração dos erros entre os modelos escolhidos e a planta
for j=1:npar
    e_i(:,j,k) = x_i(:,j,k) - x_p(:,k);
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
end

for j=1:npar
    E(:,j,k) = x_i(:,j,k)-x_i(:,npar+1,k);
end
            passo_calculado(k) = 2/max(eig(M+transpose(E(:,:,k))*E(:,:,k)));
            M0 =  M+transpose(E(:,:,k))*E(:,:,k);
            eig_s(:,k)   = eig(M0-M0^2*gamma*h);
            if min(eig_s(:,k))<0
               gamma = passo_calculado(k)/(10*h); 
            end
%tempo de simulação
    tempo(k+1)  = tempo(k)+h;
%sinal de referência
    r(k+1) = ref_amp*cos(tempo(k)*ref_freq); 
    if eta_natural(k)<=tol_eta
        r_ponto(k) = tau_ref*(-r(k) + ref_amp(1));
        r(k+1) = r(k) + h*r_ponto(k);
    end
    
    
    u(k) = r(k);


  passo_int_revisado(k) = 2/(max(eig(M+transpose(E(1,:,k))*E(1,:,k))));
  %if passo_int_revisado(k)/(2*h)<gamma
  % gamma = passo_int_revisado(k)/(2*h);
  %end
%geração do vetor alfa através da inversa de E

    alfa_ponto_natural(:,k) = gamma*(-transpose(E(:,:,k))*E(:,:,k)*alfa(:,k)- ...
                     (transpose(E(:,:,k)))*(x_i(:,npar+1,k)-x_p(:,k)))+gamma*(-M*alfa(:,k)-vm);
    alfa_ponto_concorrente(:,k) = gamma*(-M*alfa(:,k)-vm);
    
    % o somatório de muitas multiplicações de matrizes é numericamente instável 
    % é necessário tratar isto para erros de arredondamento



%    point_collection_matrix_prox_iteracao = point_collection_matrix(:,:,2:n_pontos);
%    point_collection_matrix_prox_iteracao(:,:,n_pontos) = transpose(E(1,:,k))*E(1,:,k);
%    point_collection_vector_prox_iteracao = point_collection_vector(:,1,2:n_pontos);    
%    point_collection_vector_prox_iteracao(:,1,n_pontos) = transpose(E(:,:,k))*(x_i(:,n_de_linhas+1,k)-x_p(:,k));
%    M = zeros(npar,npar); M_fut =zeros(npar,npar);
%    vm = zeros(npar,1); vm_fut = zeros(npar,1);
%    for i=1:n_pontos
%        M = M+point_collection_matrix(:,:,i);
%        M_fut = M_fut+point_collection_matrix_prox_iteracao(:,:,i);
%        vm = vm+point_collection_vector(:,1,i);
%        vm_fut = vm_fut+point_collection_vector_prox_iteracao(:,1,i);
%    end    
%    s1 = svd(M);
%    s2 = svd(M_fut);
%    if min(s2)>min(s1)
%        point_collection_matrix = point_collection_matrix_prox_iteracao;
%        point_collection_vector = point_collection_vector_prox_iteracao;
%    end
   s1 = svd(M);
   s2 =  svd(M + transpose(E(1,:,k))*E(1,:,k));
if min(s1)<min(s2)
   if 1.5*norm(M)<norm(M + transpose(E(1,:,k))*E(1,:,k));  
   M = M + transpose(E(:,:,k))*E(:,:,k);   
   vm =vm + transpose(E(:,:,k))*(x_i(:,n_de_linhas+1,k)-x_p(:,k));
   end
end



if norm(-M*alfa(:,k)-vm)<1e-5
    if eta_natural<1e-10
    M = zeros(npar,npar);
    vm = zeros(npar,1);
    end
end

if eta_concorrente(k) < eta_natural(k)
   alfa_ponto(:,k) =  alfa_ponto_natural(:,k);
else
   alfa_ponto(:,k) = alfa_ponto_natural(:,k);
end

    alfa_n1(k) = 1-ones(1, npar)*alfa(:,k);
    alfa_ponto_n1(k) = -ones(1, npar)*alfa_ponto(:,k);
    for i=1:npar
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
    eta_natural(k+1) = transpose(alfa_ponto_natural(:,k))*Q*alfa_ponto_natural(:,k)/ ...
                      (1 + transpose(alfa_ponto_natural(:,k))*Q*alfa_ponto_natural(:,k));
    eta_concorrente(k+1)  = transpose(alfa_ponto_concorrente(:,k))*Q*alfa_ponto_concorrente(:,k)/ ...
                      (1 + transpose(alfa_ponto_concorrente(:,k))*Q*alfa_ponto_concorrente(:,k));
    alfa_barra(:,k) = transpose([transpose(alfa(:,k)) 1-ones(1, npar)*alfa(:,k)]);
    
    
    %Adaptação dos modelos de primeiro nível
  
for j=1:npar+1
    theta_i(:,j,k+1) = theta_i(:,j,k);
    theta_BARRA(:,j,k+1) = theta_BARRA(:,j,k);
    A_i(:,:,j,k) = can(modelos(n+1:npar,j));
    C_i(1,:,j,k) = fliplr(modelos(1:n,j));
    %C_i(1,:,j,k) = modelos(1:n,j);
end
    %fazer o modelo série paralelo para ode
        %opt = odeset('RelTol',1e-5);
    for j=1:npar+1
    x_i_ponto(:,j,k) = A_m'*x_i(:,j,k) + (A_i(:,:,j,k) - A_m)'*x_p(:,k) + (C_i(1,:,j,k))'*u(k);
    x_i(:,j,k+1)     = x_i(:,j,k) + h*x_i_ponto(:,j,k);
   % x_i_ode = ode45(@(t,y) calc_x_i(t,y,u(k),x_p(:,k),A_i(:,:,j,k),A_m,C_i(1,:,j,k)),...
    %               [tempo(k) tempo(k)+h], x_i(:,j,k));
   % x_i(:,j,k+1)= x_i_ode.y(:,length(x_i_ode.y));
    y_i(j,k+1)       = b'*x_i(:,j,k);
    end
    
%dinâmica dos modelos, da planta e do modelo de referência
    x_m_ponto(:,k) = A_m*x_m(:,k) + b*r(k);
    x_m(:,k+1)     = x_m(:,k) + h*x_m_ponto(:,k);
   
  % x_m_ode = ode45(@(t,y) calc_x_p(t,y,u(k),A_m,C_m), [tempo(k) tempo(k)+h], x_m(:,k));
  % x_m(:,k+1) = x_m_ode.y(:,length(x_m_ode.y));   
   y_m(k+1)       = b'*x_m(:,k+1);
%fix para discretização:    
%   h1 = 1e-5;
%   x_p_int(:,1) = x_p(:,k);
%for k1=1:floor(h/h1)
%   x_p_ponto_int(:,k1) = A_p'*x_p_int(:,k1) + C_p'*u(k);
%   x_p_int(:,k1+1) = x_p_int(:,k1) + h1*x_p_ponto_int(:,k1);
%end
%   k1=1;
%   x_p(:,k+1) = x_p_int(:,floor(h/h1)+1);

%    x_p_ode = ode45(@(t,y) calc_x_p(t,y,u(k),A_p,C_p), [tempo(k) tempo(k)+h], x_p(:,k));
%    x_p(:,k+1) = x_p_ode.y(:,length(x_p_ode.y));

    x_p_ponto(:,k) = A_p'*x_p(:,k) + C_p'*u(k);
    x_p(:,k+1)     = x_p(:,k) + h*x_p_ponto(:,k);
    y(k+1)         = b'*x_p(:,k+1);
    
    %cálculo da norma 2 do erro
    e_o(:,k)     = x_m(:, k) - x_p(:, k);
    norm_2_e_o(k)     = sqrt(transpose(e_o(:,k))*e_o(:,k));
    theta_p_estimativa(:,k) = theta_BARRA(:,:,k)*alfa_barra(:,k);
    %fim do laço principal
    
            tilde_alfa(:,k) = alfa(:,k) - alfa_estrela;
            V(k+1) = tilde_alfa(:,k)'*tilde_alfa(:,k);
            delta_V(k+1) = sign(V(k+1) - V(k));
            garantia_robusta(k) = 2*min(eig(M+transpose(E(:,:,k))*E(:,:,k)))/...
                                    (max(eig(M+transpose(E(:,:,k))*E(:,:,k)))^2);
            Ml                  = diag(eig(M+transpose(E(:,:,k))*E(:,:,k)));
            garantia_exata(k)   = tilde_alfa(:,k)'*M0*tilde_alfa(:,k)/...
                                   (h*tilde_alfa(:,k)'*(M0^2)*tilde_alfa(:,k));

           % if gamma>passo_calculado(k)/h
           %    gamma = garantia_exata(k)/(2*h); 
           % end
  %insight: a mudança brusca no passo de integração afeta bruscamente o 
  %valor de V ponto e a função de energia V, devemos encontrar uma forma de
  %suavemente alterar o valor de h.
if k==endk
    
end


end
plot(delta_V)
estrutura = make_struct(x_p,x_m,eta_natural,theta_p_estimativa,norm_2_e_o,  ...
                        e_o,u, alfa_barra, r, modelo_de_referencia, ...
                            planta, theta_BARRA, modelos,tempo,endk);

toc

end

function x_p = calc_x_p(t,x,u,A_p,C_p)
   x_p = A_p'*x + C_p'*u;
end

function x_i = calc_x_i(t,x,u,x_p,A_i,A_m,C_i)
x_i = A_m'*x +(A_i-A_m)'*x_p+C_i'*u;
end