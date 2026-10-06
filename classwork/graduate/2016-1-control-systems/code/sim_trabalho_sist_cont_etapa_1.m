%Trabalho Referente a disciplina de Sistemas de Controle
%Professor: Carlos Eduardo Trabuco Dorea
%Alunos: Pedro Gushiken, Isaac Dantas, Luan Garcia
%Simulação em malha aberta de sistema não linear de terceira ordem
%Simulação em malha aberta do modelo linearizado do mesmo sistema


%Comparação:
%Exemplo: sim_trabalho_sist_cont_etapa_1(40,1e-1,1.5,0.5)

%Na linha verde, a posição real do oscilador de Van Der Pol forçado à
%posição x = 1.3 partindo do ponto de equilíbrio u_barra=1.5 

%Na linha vermelha, o comportamento da medição da posição do oscilador (consideramos, já que o
%sensor usado é de velocidade usando um integrador saturado(s+0.04) para
%medir a posição, que a F.T do sensor terá um zero na origem(derivador) e
%portanto sua F.T é:
%s/(s+0.04)*(s+9), quando o projeto for feito, desconsideraremos o zero na
%origem e polo próximo a origem, medindo seu efeito apenas nas simulações
%(dinâmica não modelada)

%Na linha preta, o comportamento do sistema linearizado

function sim_trabalho_sist_cont_etapa_1(stoptime, h,u_barra,mi)
referencia = u_barra;
perturbacao = 1;
A_linearizado = [-9.04 -0.36 0 1; 1 0 0 0; 0 0 0 1; 0 0 -1 mi*(1-u_barra^2)];
b_linearizado = [0;0;0;1];
C_linearizado = [0 1 0 0];
D_linearizado = 0;%ok

C_e = [0 0 1 0];

%inicialização das variáveis em seus respectivos pontos de equilíbrio:
x_2_ponto(1)=0;
x_ponto(1)=0;
x(1)= 0;
y_ponto(:,1,1) = [0; 0];
y(:,1,1) = [0; 0];
y_medido(1) = 0;
xc(:,1,1) = [0; 0; 0;0];
x_lin_ponto(:,1,1) = [0; 0; 0; 0]; %p. eq, ok
x_lin(:,1,1) = [0; 0; 0; 0];
y_lin_medido(1) = 0; %p. eq, ok

A_sensor = [-9.04 -0.36; 1 0];%ok
b_sensor = [1;0];%ok

%número de passos a serem dados na simulação
endk = floor(stoptime/h);

%início
tempo(1) = 0;
for k=1:endk
%tempo de simulação
    tempo(k+1)  = tempo(k)+h;
%sinal de referência
    r(k)   = referencia;    
    %controlador
    [Ac,bc,Cc,Dc] = tf2ss(18*[1 4 6 4 1], [0.0025 0.1 1 0 0]);
    e(k) = -y_medido(k);
    xc_ponto(:,1,k) = Ac*xc(:,1,k) + bc*e(k);
    xc(:,1,k+1) = xc(:,1,k) + h*xc_ponto(:,1,k);
    u(k) = Cc*xc(:,1,k) + Dc*e(k);
    if tempo(k)>10
        u(k) = u(k)+perturbacao; %+ 0.1*sin(tempo(k));  
    end
    if tempo(k)>30
        u(k) = u(k)-perturbacao;
    end
    
    
    
    %sistema não linear, não é possível fazer em espaço de estado
    %diretamente, usamos euler para integrar as equações:
    
    %Oscilador de Van Der Pol
    x_2_ponto(k)        = mi*(1-x(k).^2)*x_ponto(k)-x(k)+u(k);
    %Euler <-> Primeira Integração
    x_ponto(k+1)        = x_ponto(k)                + h*x_2_ponto(k);
    %Euler <-> Segunda Integração
    x(k+1)              = x(k)                      + h*x_ponto(k);
    %Sensor de Velocidade com integrador saturado: s/(s+0.04)(s+9)
    y_ponto(:,1,k) = A_sensor*y(:,1,k) + b_sensor*x_ponto(k);

    y(:,1,k+1) = y(:,1,k)+h*y_ponto(:,1,k); %+(0.01*(rand()-rand()))/2;
    %[0 0.36] foi escolhido de forma a compatibilizar as grandezas das
    %variáveis comparadas levando em conta o ganho em malha aberta do sensor
    y_medido(k+1) = [0 1]*y(:,1,k+1);
    
    %y_medido é a variável de estado acessível do sistema

%Sistema Linearizado
x_lin_ponto(:,1,k) = A_linearizado*x_lin(:,1,k) + b_linearizado*u(k);
x_lin(:,1,k+1)     = x_lin(:,1,k)               + h*x_lin_ponto(:,1,k);
y_lin_medido(k+1)   = C_linearizado*x_lin(:,1,k+1)  + D_linearizado*u(k);
y_lin_saida_osc(k) = C_e*x_lin(:,1,k) + D_linearizado*u(k);
end
%artifício para produzir um vetor tempo com 1 valor a menos
tempo_acesso = tempo(1:endk);


figure(1)
%plot(tempo,y_lin_medido,'Color',[0 0 0],'LineWidth',2.0);
%hold on, grid on
%plot(tempo_acesso,y_lin_saida_osc,'Color',[0 0 1],'LineWidth',2.0);
%hold on, grid on
plot(tempo,y_medido+u_barra,'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
plot(tempo,x+u_barra,'Color',[0 1 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
%leg1 = legend('Modelo linearizado, x_l','saida do oscilador linearizado','Medição Modelo real, x_p','Modelo Real, posição real');
leg1 = legend('Medição Modelo real, x_p','Modelo Real, posição real');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema linearizado e sistema real', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

figure(2)
plot(tempo_acesso,u,'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
end