%Simulação referente ao artigo sobre adaptação de segundo nível:
%Proceedings of the 2014 American Control Conference
%Kumpati S. Narendra, Yu Wang, Wei Chen
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Gushiken

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
%L2A_Dif_ModDes(25,1e-3,[7 -2 3; -3 -2 -6], [0.8 -3],[-4 -4], [0.001; 0.002], [0; 0], [0.001 0.001 0.001 ;0.002 0.002 0.002], [0 0], 5,[1e4 0;0 1e4],1)
%L2A_Dif_ModDes(25,1e-3,[7 3 -2; -3 -6 -2], [0.8 -3],[-4 -4], [0.001; 0.002], [0; 0], [0.001 0.001 0.001 ;0.002 0.002 0.002], [0 0], 5,[1e4 0;0 1e4],1)
%L2A_Dif_ModDes(25,1e-3,[3 -2 7; -6 -2 -3], [0.8 -3],[-4 -4], [0.001; 0.002], [0; 0], [0.001 0.001 0.001 ;0.002 0.002 0.002], [0 0], 5,[1e4 0;0 1e4],1)
function L2A_Dif_ModDes_ModEnm1(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,cond_iniciais_m,cond_iniciais_i, alfa0,referencia,Q,gamma)
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
x_p_chapeu(:,1) = cond_iniciais_p;


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
%inicialização dos parâmetros do controlador
k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,1);

%inicialização da entrada da planta
u(1)   = referencia;
A_p_chapeu(:,:,1) = can(theta_BARRA*alfa_barra(:,1));
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
    r(k+1)   = referencia*sin(tempo(k));
    if eta(k)<=1e-4
        r_ponto(k) = -r(k) + referencia;
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
    e_est(:,k) = x_p_chapeu(:,k) - x_p(:,k);
%geração do vetor alfa através da inversa de E
    alfa_ponto(:,k) = gamma*(-transpose(E(:,:,k))*E(:,:,k)*alfa(:,k)-(transpose(E(:,:,k)))*e_i(:,length(modelos),k));
    alfa(:,k+1) = alfa(:,k) + h*alfa_ponto(:,k);
    eta(k+1) = transpose(alfa_ponto(:,k))*Q*alfa_ponto(:,k)/(1 + transpose(alfa_ponto(:,k))*Q*alfa_ponto(:,k));
%composição de alfa para gerar alfa_barra, que é uma parametrização da
%planta
    alfa_barra(:,k) = transpose([transpose(alfa(:,k)) 1-ones(1, length(alfa(:,k)))*alfa(:,k)]);
    A_p_chapeu(:,:,k) = can(theta_BARRA*alfa_barra(:,k));
%geração dos parâmetros do controlador, note-se que
%theta_BARRA*alfa_barra(1:3,k) corresponde a theta_p_chapéu, a estimativa
%dos parâmetros da planta
    k_T(:,k) =transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,k);
%lei de controle
    u(k) = r(k) + transpose(k_T(:,k))*x_p(:,k);
%dinâmica dos modelos, da planta e do modelo de referência
for j=1:length(modelos)
    x_i_ponto(:,j,k) = A_m*x_i(:,j,k) + (A_i(:,:,j) - A_m)*x_p(:,k) + b*u(k);
    x_i(:,j,k+1)     = x_i(:,j,k) + h*x_i_ponto(:,j,k);
end
    x_m_ponto(:,k) = A_m*x_m(:,k) + b*r(k);
    x_m(:,k+1)     = x_m(:,k) + h*x_m_ponto(:,k);
    x_p_ponto(:,k) = A_p*x_p(:,k) + b*u(k);
    x_p(:,k+1)     = x_p(:,k) + h*x_p_ponto(:,k);
    x_p_chapeu_ponto(:,k) = A_p_chapeu(:,:,k)*x_p(:,k) + b*u(k);
    x_p_chapeu(:,k+1) = x_p_chapeu(:,k) + h*x_p_chapeu_ponto(:,k);
    %cálculo da norma 2 do erro
    e_o(:,k)     = x_m(:, k) - x_p(:, k);
    norm_2_e_o(k)     = sqrt(transpose(e_o(:,k))*e_o(:,k));
    theta_p_estimativa(:,k) = theta_BARRA*alfa_barra(:,k);
end

tempo_acesso = tempo(1:endk);
figure(1)
plot(tempo,x_m(1,:),'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(tempo,x_p(1,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
plot(tempo,r, 'Color',[0 0 1],'LineWidth',2.0);
hold on, grid on
plot(tempo,x_p_chapeu(1,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
leg1 = legend('Modelo, x_m(1)','Planta, x_p(1)','Referencia', 'Est. da Planta');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema (Método Diferencial)', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

figure(2)
plot(tempo,x_m(2,:),'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(tempo,x_p(2,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
leg1 = legend('Modelo, x_m(2)','Planta, x_p(2)');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema (Método Diferencial)', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

figure(3)
plot(tempo_acesso,alfa_barra,'LineWidth',2.0);
hold on, grid on
leg1 = legend('\alpha_{barra}');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Valores dos alfas', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

figure(4)
plot(tempo_acesso,u,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Sinal de Controle');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Sinal de Controle', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

figure(5)
plot(tempo_acesso,norm_2_e_o,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Norma 2 do Erro de Saída');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Norma 2 do erro de Saída entre o modelo de referência e a planta', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

if length(planta)==2
figure(6)
hold on, grid on
s = line(planta(1), planta(2), 'LineWidth', 2.0);
s.Marker = 'o';
line([modelos(1,:) modelos(1,1)],[modelos(2,:) modelos(2,1)]);
line(theta_p_estimativa(1,:), theta_p_estimativa(2,:));
end

figure(7)
plot(tempo,eta,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Fig. Mérito ETA');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Fig. Mérito ETA', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

figure(8)
plot(tempo_acesso,e_est,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Fig. Mérito ETA');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Fig. Mérito ETA', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);
