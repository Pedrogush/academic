function plot_adap_figures(func)

endk = func.endk;
tempo_acesso = func.tempo(1:endk);
%figura 1, saídas referentes a primeira variável de estado da planta e do
%modelo de referência, a referência multiplicada pelo ganho
%estático do modelo de referência evoluindo no tempo
figure(1)
plot(func.tempo,func.x_m(1,:),'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(func.tempo,func.x_p(1,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
plot(func.tempo,func.r/abs(func.modelo_de_referencia(1)), 'Color',[0 0 1],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Modelo, x_m(1)','Planta, x_p(1)','Referencia/Ganho Estático');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema (Método Diferencial)', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

%figura 2, segunda variável de estado (primeira derivada) do modelo de
%referência e da planta evoluindo no tempo
figure(2)
plot(func.tempo,func.x_m(2,:),'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(func.tempo,func.x_p(2,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
leg1 = legend('Modelo, x_m(2)','Planta, x_p(2)');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema (Método Diferencial)', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

%figura 3, adaptação dos alfas no tempo
figure(3)
plot(tempo_acesso,func.alfa_barra,'LineWidth',2.0);
hold on, grid on
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Valores dos alfas', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

%figura 4, sinal de controle no tempo
figure(4)
plot(tempo_acesso,func.u,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Sinal de Controle');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Sinal de Controle', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

%figura 5, norma 2 do erro de saída da planta no tempo
figure(5)
plot(tempo_acesso,func.norm_2_e_o,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Norma 2 do Erro de Saída');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Norma 2 do erro de Saída entre o modelo de referência e a planta', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

%figura 6 condicional, se a ordem do sistema é igual a 2, plotar a evolução
%dos parâmetros no espaço de parâmetros bi-dimensional
    if length(func.planta)==2
    figure(6)    
    line([func.theta_BARRA(1,:,endk) func.theta_BARRA(1,1,endk)], ...
         [func.theta_BARRA(2,:,endk) func.theta_BARRA(2,1,endk)], ...
                      'Color', [1 0 1],'LineWidth',2.0)
    hold on, grid on 
    s = line(func.planta(1), func.planta(2),'Color',[0 1 1], 'LineWidth', 2.0);    
    s.Marker = 'o';    
    line([func.modelos(1,:) func.modelos(1,1)],...
         [func.modelos(2,:) func.modelos(2,1)], ...
             'Color', [1 0 0],'LineWidth',2.0);
    line(func.theta_p_estimativa(1,:), func.theta_p_estimativa(2,:),...
                                  'Color', [0 0 1],'LineWidth',2.0);
    end

%figura 7, evolução da figura de mérito eta no tempo
figure(7)
plot(func.tempo,func.eta,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Fig. Mérito ETA');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Fig. Mérito ETA', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

end