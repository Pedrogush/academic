%Universidade Federal do Rio Grande do Norte
%Programa de Pós Graduação em Engenharia Elétrica e da Computação
%Aluno: Pedro Yochinori Gushiken
%Orientador: Aldayr Dantas de Araújo

%Função de Plotagem referente à adaptação de Segundo Nível
%Produz os gráficos da saída dos sistemas, erro de saída, figura
%de mérito, valores dos parâmetros, sinal de controle e trajetória dos
%parâmetros em uma única tela

%Uso da função: plot_adap_figures_L2_VE(func), onde func se trata da estrutura de
%dados de saída produzida pela função L2AA, esta função se encontra
%modificada para sistemas de segunda ordem sem zeros. 


function plot_adap_figures_L2_VE(func)

endk = func.endk;
tempo_acesso = func.tempo(1:endk);
%figura 1, saídas referentes a primeira variável de estado da planta e do
%modelo de referência, a referência multiplicada pelo ganho
%estático do modelo de referência evoluindo no tempo
figure(1)
subplot(4,2,[1,3])
plot(func.tempo,func.x_m(1,:),'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(func.tempo,func.x_p(1,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
plot(func.tempo,func.r/abs(func.modelo_de_referencia(1)), 'Color',[0 0 1],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Modelo, x_m(1)','Planta, x_p(1)','Referencia/Ganho Estático');
set(leg1,'FontSize', 10);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 10); 


%figura 3, adaptação dos alfas no tempo
subplot(4,2,2)
plot(tempo_acesso,func.alfa_barra,'LineWidth',2.0);
hold on, grid on
set(leg1,'FontSize', 10);
ylabel('Amplitude', 'FontSize', 14);
title('Valores dos alfas', 'FontSize', 14);
leg1 = legend('\alpha_1(t)','\alpha_2(t)','\alpha_3(t)');
set(leg1,'FontSize', 10);
axis1 = gca;
set(axis1, 'FontSize', 10);

%figura 4, sinal de controle no tempo
subplot(4,2,4)
plot(tempo_acesso,func.u,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('u(t)');
set(leg1,'FontSize', 10);
ylabel('Amplitude', 'FontSize', 14);
title('Sinal de Controle', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 10);

%figura 5, norma 2 do erro de saída da planta no tempo
subplot(4,2,5)
plot(tempo_acesso,func.norm_2_e_o,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('||e_0||_2');
set(leg1,'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 10);

%figura 6 condicional, se a ordem do sistema é igual a 2, plotar a evolução
%dos parâmetros no espaço de parâmetros bi-dimensional
    if length(func.planta)==2
    subplot(4,2,[6,8])  
    
    %Tracejado do Fecho Convexo delimitado inicialmente
    line([func.theta_BARRA(1,:,endk) func.theta_BARRA(1,1,endk)], ...
         [func.theta_BARRA(2,:,endk) func.theta_BARRA(2,1,endk)], ...
                      'Color', [1 0 1],'LineWidth',2.0)
    hold on, grid on 
    %Marcador referente a theta estrela, parâmetros verdadeiros da planta
    s = line(func.planta(1), func.planta(2),'Color',[0 1 1], 'LineWidth', 2.0);    
    s.Marker = 'o';    
    
    %Tracejado do Fecho Convexo delimitado ao final da simulação
    line([func.modelos(1,:) func.modelos(1,1)],...
         [func.modelos(2,:) func.modelos(2,1)], ...
             'Color', [1 0 0],'LineWidth',2.0);
    %Trajetória da Adaptação de Segundo Nível
    line(func.theta_p_estimativa(1,:), func.theta_p_estimativa(2,:),...
                                  'Color', [0 0 1],'LineWidth',2.0);
    %Estimativa inicial dos parâmetros da planta
    p0 = line([func.theta_p_estimativa(1,1) func.theta_p_estimativa(1,1)], ...
              [func.theta_p_estimativa(2,1) func.theta_p_estimativa(2,1)], ...
              'Color',[0 0 0],'LineWidth',2.0);
    p0.Marker = 'x';
leg1 = legend('Fecho Final','\theta^*','Fecho Inicial', ...
              'Trajetória L2','\theta_0');
set(leg1,'FontSize', 10,'Location','northwest');                              
ylabel('\theta_2', 'FontSize', 14);
xlabel('\theta_1','FontSize',14)
title('Trajetória dos Parâmetros', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 10);            
    end

%figura 7, evolução da figura de mérito eta no tempo
subplot(4,2,7)
plot(func.tempo,func.eta,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('\eta');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Fig. Mérito ETA', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 10);

end