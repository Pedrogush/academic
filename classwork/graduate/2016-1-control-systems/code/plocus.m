%Trabalho Referente a disciplina de Sistemas de Controle
%Professor: Carlos Eduardo Trabuco Dorea
%Alunos: Pedro Gushiken, Isaac Dantas, Luan Garcia

%Simulação em malha fechada de sistema do oscilador de Van der Pol em malha
%fechada com controlador PID+PID de forma a tratar do problema da regulação
%do sistema em torno do ponto de equilíbrio [u_barra; 0] do oscilador 
%forçado.

%Característica do oscilador: mi=0.5;

%ESPECIFICAÇÕES: 
%1) ERRO EM REGIME NULO PARA A PERTURBAÇÃO DO TIPO DEGRAU
%2) PO% <= 15%
%3) Ts2% <= 8s
%4) u_barra = 0.6

%Objetivo, conseguir que, ao ser inserida uma perturbação na planta, o
%sistema de controle consiga retornar ao ponto de operação desejado
%(problema da regulação)

%Consequências: Como visto anteriormente o sensor possui um zero na origem,
%(sensor de velocidade sendo usado como sensor de posição);
%de forma a conseguir o erro em regime nulo para a perturbação do tipo
%degrau, necessitamos inserir 2 integradores, 1 para cancelamento do zero,
%e mais outro, de forma que no total o sistema tenha 1 integrador em malha 
%aberta

%FT de malha aberta do sistema sem controlador:
%Gp = tf([0 0 1], [1 -0.32 1])
%Gs = tf([0 1 0], [1 9.04 0.36]
%G_malha_aberta = Gp*Gs

%FT do controlador escolhido, Kp=18, 4 zeros em -1, 2 polos na origem:
%2 polos em -20;
%Gc = tf(18*[1 4 6 4 1], [0.0025 0.1 1 0 0])

%FT de malha fechada:
%Gmf = feedback(Gc*Gp*Gs,1)

%Comando: plocus(70,1e-2,0.6,0.5)

function plocus(stoptime, h,u_barra,mi)

%problema da regulação: o sistema é iniciado no ponto de equilíbrio, o
%papel do sistema de controle é apenas retornar em caso de perturbação
referencia = 0;

%magnitude da perturbação introduzida
perturbacao =1;


%inicialização das variáveis em seus respectivos pontos de equilíbrio:

%variáveis estado do oscilador
x_2_ponto(1)=0;
x_ponto(1)=0;
x(1)= u_barra;

%variáveis de estado do sensor de delt(variação do ponto de operação)
y_ponto(:,1,1) = [0; 0];
y(:,1,1) = [0; 0];
y_medido(1) =0;

%variáveis de estado do controlador
%controlador iniciado de forma que seu sinal de controle seja u_barra
xc(:,1,1) = [0; 0;0; 0.8333*10^-4];

%Matrizes de espaço de estado do sensor
A_sensor = [-9.04 -0.36; 1 0];
b_sensor = [1;0];
C_sensor = [0 1];

%Matrizes controlador convertido para espaço de estados
[Ac,bc,Cc,Dc] = tf2ss(11.1274*[1 4 6 4 1], [0.0025 0.1 1 0 0]);

%obs: desempenho obtido com diferentes F.Ts de controladores
%[Ac,bc,Cc,Dc] = tf2ss(18*[1 16/25 2561/2500  7503/12500], [0.1 1 0 0]);
% [Ac,bc,Cc,Dc] = tf2ss(18*[1 9/5 52/25  102/125], [0.1 1 0 0]);

%número de passos a serem dados na simulação
endk = floor(stoptime/h);

%início do laço
tempo(1) = 0;
for k=1:endk
%tempo de simulação
    tempo(k+1)  = tempo(k)+h;
%sinal de referência
    r(k)   = referencia;  

%controlador
    %erro de feedback da saída 
    e(k) = r(k)-y_medido(k);
    
    %variáveis de estado do controlador
    xc_ponto(:,1,k) = Ac*xc(:,1,k) + bc*e(k);
    %Integração
    xc(:,1,k+1) = xc(:,1,k) + h*xc_ponto(:,1,k);
    
    %entrada introduzida na planta
    u(k) = Cc*xc(:,1,k) + Dc*e(k);
    entrada_planta(k) = u(k);
    
    
    %inserir perturbação positiva em 15s, retirar a perturbação em 35
    %segundos e perturbação negativa em 55 segundos
    if tempo(k)>15
        entrada_planta(k) = u(k)+perturbacao;  
    end
    if tempo(k)>35
        entrada_planta(k) = u(k);
    end
    if tempo(k)>55
        entrada_planta(k) = u(k)-perturbacao;
    end
    
    
    %sistema não linear, não é possível fazer em espaço de estado
    %diretamente, usamos euler para integrar as equações:
    
    %Oscilador de Van Der Pol
    x_2_ponto(k)        = mi*(1-x(k).^2)*x_ponto(k)-x(k)+entrada_planta(k);
    %Euler <-> Primeira Integração
    x_ponto(k+1)        = x_ponto(k)                + h*x_2_ponto(k);
    %Euler <-> Segunda Integração
    x(k+1)              = x(k)                      + h*x_ponto(k);
    
    %Sensor de Velocidade, variáveis de estado:
    y_ponto(:,1,k) = A_sensor*y(:,1,k) + b_sensor*x_ponto(k);
    %Integração
    y(:,1,k+1) = y(:,1,k)+h*y_ponto(:,1,k); 
    
    
    %             0.0001*(0.5-rand())<-Ruído
    %Inserido de forma a deixar notável seu efeito no sinal de
    %controle, com um ruído da ordem de 0.01 o sistema é apenas capaz de 
    %deixar o sistema na vizinhança do ponto de operação, com um ruído da 
    %ordem de 0.001 a saída do oscilador não diverge em muito do 
    %comportamento sem ruído, porém o sinal de controle é extremamente 
    %ruidoso.
    
    
    y_medido(k+1) = C_sensor*y(:,1,k+1)+ 0.0001*(0.5-rand());    
    %y_medido é a variável de estado acessível do sistema
    
    
end
%artifício para produzir um vetor tempo com 1 valor a menos
tempo_acesso = tempo(1:endk);

%Figura 1, Medida de delt(desvio do ponto de operação)
figure(1)
plot(tempo,y_medido,'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
leg1 = legend('Medição Modelo real, x_p');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Medição de delta', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

%Figura 2, Sinal de Controle
figure(2)
plot(tempo_acesso,u,'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
leg1 = legend('Sinal de Controle');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Sinal de Controle', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

%Figura 3, Saída do oscilador
figure(3)
plot(tempo,x,'Color',[0 1 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
leg1 = legend('Saída do Oscilador');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do Oscilador', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 
end