%Simulação referente ao artigo sobre adaptação de segundo nível:
%Proceedings of the 2014 American Control Conference
%Kumpati S. Narendra, Yu Wang, Wei Chen
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Gushiken

%Modificações: 1)colocamos um ganho na equação diferencial de cálculo de
%alfa, o que não deve, em princípio, alterar a localização dos pontos de
%equilíbrio da equação, nem retirar o comportamento da trajetória dos
%parâmetros
%2) colocamos um esquema de desligamento do sinal PE, similar ao usado no
%TCC


%método de cálculo de alfa através de eq. diferencial

%stoptime é o tempo de simulação
%h é o passo de simulação
%modelos corresponde a THETA_BARRA
%planta corresponde ao vetor theta_p transposto
%modelo_de_referencia corresponde ao vetor theta_m transposto
%cond_iniciais_p corresponde ao vetor x_p(k=1)
%cond_iniciais_m corresponde ao vetor x_m(k=1)
%cond_iniciais_i corresponde aos vetores x_i(k=1) dos n+1 modelos de
%identificação
%alfa0 corresponde ao vetor alfa(k=1)
%referencia corresponde a um sinal de referência constante (o código pode
%ser editado para introduzir uma referência senoidal, mas ainda não sei como introduzi-la nos argumentos da função)
%exemplo 1, 2 parâmetros desconhecidos:
%L2AA_Dif_ModDes_SatAlfa(18,1e-3,[-4 -3 8; -5 -2 -4], [2.3; -3.6],[-4 -4], [0; 0], [0.2; 0.3], [0 0 0 ;0 0 0], [0 1], 5,[1e4 0;0 1e4],20, [1 0; 0 1])
function movie=L2AA_Dif_Anim(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,cond_iniciais_m,cond_iniciais_i, alfa0,referencia,Q,gamma,P,cor)
%declaração de variáveis:
aniline = animatedline('MaximumNumPoints',4,'LineWidth',1.0);
size_modelos = size(modelos);
n_de_linhas  = size_modelos(1);
%matrizes na forma canônica (companion form):
for matriz=1:length(modelos)
    for linha=1:n_de_linhas
        for coluna=1:n_de_linhas
            if linha<n_de_linhas
            if coluna~=linha+1
            A_p(linha,coluna) = 0;
            A_m(linha,coluna) = 0;
            end
            end
if linha+1==coluna
if linha<n_de_linhas
A_p(linha,coluna)        = 1;
A_m(linha,coluna)        = 1;
end
end
if linha==n_de_linhas
A_p(linha,coluna) = planta(coluna);
A_m(linha,coluna) = modelo_de_referencia(coluna);
end
        end
    end
end
for i=1:length(modelos)
A_i(:,:,i,1) = can(modelos(:,i));
end
theta_BARRA(:,:,1) = modelos;
for j=1:length(modelos)
theta_i(:,j,1) = modelos(:,j);
end
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
    E(:,j,1) = [x_i(:,j,1)-x_i(:,length(modelos),1)];
end

%condições iniciais do vetor de combinação linear alfa_barra
alfa(:,1)= alfa0;
alfa_barra(:,1) = transpose([transpose(alfa(:,1)) 1-ones(1,length(alfa))*alfa(:,1)]);
theta0 = theta_BARRA(:,:,1)*alfa_barra(:,1);
%inicialização dos parâmetros do controlador
k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,1);

%inicialização da entrada da planta
u(1)   = referencia;

%inicialização do tempo de simulação
tempo(1) = 0;
eta(1)=0;
%número de passos a serem dados na simulação
endk = floor(stoptime/h);
r_ponto(1) = 0;
%início
for k=1:endk
%tempo de simulação
    tempo(k+1)  = tempo(k)+h;
%sinal de referência
    r(k+1)   = referencia+ 0.2*referencia*sin(tempo(k)) + 0.2*referencia*sin(2*tempo(k));
    if eta(k)<=0
        r_ponto(k) = 10*(-r(k) + referencia);
        r(k+1) = r(k) + h*r_ponto(k);
    end
%Geração dos erros entre os modelos escolhidos e a planta
for j=1:length(modelos)
    e_i(:,j,k) = x_i(:,j,k) - x_p(:,k);
%geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
end

for j=1:(length(modelos)-1)
    E(:,j,k) = [x_i(:,j,k)-x_i(:,length(modelos),k)];
end
%geração do vetor alfa através da inversa de E
    alfa_ponto(:,k) = gamma*(-transpose(E(:,:,k))*E(:,:,k)*alfa(:,k)-(transpose(E(:,:,k)))*e_i(:,length(modelos),k));
    alfa_n1(k) = 1-ones(1, length(alfa(:,k)))*alfa(:,k);
    alfa_ponto_n1(k) = -ones(1, length(alfa_ponto(:,k)))*alfa_ponto(:,k);
    for i=1:length(alfa(:,k))
        if (alfa(i,k)>=1 && alfa_ponto(i,k)>0)||(alfa(i,k)<=0 && alfa_ponto(i,k)<0)
            alfa_ponto(i,k)=0;
        end
        if (alfa_n1(k)>=1 && alfa_ponto_n1(k)>0)||(alfa_n1(k)<=0 && alfa_ponto_n1(k)<0)
        for j=1:length(alfa_ponto(:,k))
            if sign(alfa_ponto_n1(k))==sign(alfa_ponto(j,k))
               alfa_ponto(j,k)=0; 
            end
        end              
        end       
        end
    alfa(:,k+1) = alfa(:,k) + h*alfa_ponto(:,k);
    eta(k+1) = 1;
%composição de alfa para gerar alfa_barra, que é uma parametrização da
%planta
    alfa_barra(:,k) = transpose([transpose(alfa(:,k)) 1-ones(1, length(alfa(:,k)))*alfa(:,k)]);
%geração dos parâmetros do controlador, note-se que
%theta_BARRA*alfa_barra(1:3,k) corresponde a theta_p_chapéu, a estimativa
%dos parâmetros da planta

    k_T(:,k) =transpose(modelo_de_referencia) - theta_BARRA(:,:,k)*alfa_barra(:,k);
%lei de controle
    u(k) = r(k) + transpose(k_T(:,k))*x_p(:,k);
%dinâmica dos modelos, da planta e do modelo de referência


for j=1:length(modelos)
    theta_i_ponto(:,j,k) = -transpose(e_i(:,j,k))*P*b*x_p(:,k);
    theta_i(:,j,k+1) = theta_i(:,j,k) + h*theta_i_ponto(:,j,k);
    theta_BARRA(:,j,k+1) = theta_i(:,j,k+1);
    A_i(:,:,j,k+1) = can(theta_BARRA(:,j,k+1));
end


for j=1:length(modelos)
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
    theta_p_estimativa(:,k) = theta_BARRA(:,:,k)*alfa_barra(:,k);
    
    
    %filme
    a11(k) = theta_BARRA(1,1,k);
    a21(k) = theta_BARRA(2,1,k);
    a12(k) = theta_BARRA(1,2,k);
    a22(k) = theta_BARRA(2,2,k);
    a13(k) = theta_BARRA(1,3,k);
    a23(k) = theta_BARRA(2,3,k);
    skip = stoptime/(240*h);
    if length(planta)==2 && floor(k/skip)==ceil(k/skip)
    addpoints(aniline,[theta_BARRA(1,:,k) theta_BARRA(1,1,k)],[theta_BARRA(2,:,k) theta_BARRA(2,1,k)])
    line(a11, a21, 'Color', [1-cor cor 1-cor],'LineWidth',1.0);
    line(a12, a22, 'Color', [1-cor cor 1-cor],'LineWidth',1.0);
    line(a13, a23, 'Color', [1-cor cor 1-cor],'LineWidth',1.0);
    movie(0.5*k/skip) = getframe;
    hold on, grid on
    s = line(planta(1), planta(2),'Color',[cor 1-cor 1-cor], 'LineWidth', 1.0);
    line([theta0(1) planta(1)],[theta0(2) planta(2)]);
     %line([planta(1) planta(1)-theta0(2)-planta(2)], [planta(2) planta(2)+theta0(1)+planta(1)]);
     %line([planta(1) planta(1)+theta0(2)+planta(2)], [planta(2) planta(2)-theta0(1)-planta(1)]);
    s.Marker = 'o';
    line([modelos(1,:) modelos(1,1)],[modelos(2,:) modelos(2,1)], 'Color', [1-cor cor cor],'LineWidth',1.0);
    line(theta_p_estimativa(1,:), theta_p_estimativa(2,:), 'Color', [cor cor 1-cor],'LineWidth',1.0);
    end
end
