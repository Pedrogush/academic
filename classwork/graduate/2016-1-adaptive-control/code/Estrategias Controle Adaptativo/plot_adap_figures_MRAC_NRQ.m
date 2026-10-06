function plot_adap_figures_MRAC_NRQ(func)

endk = func.endk;
tempo_acesso = func.tempo(1:endk);
%figura 1, saídas referentes a primeira variável de estado da planta e do
%modelo de referência, a referência multiplicada pelo ganho
%estático do modelo de referência evoluindo no tempo
figure(1)
subplot(2,2,1)
plot(func.tempo,func.x_m_out,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(func.tempo,func.x_p_out,'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
plot(func.tempo,func.r, 'Color',[0 0 1],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Modelo, x_m(1)','Planta, x_p(1)','Referencia');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 

%figura 3, adaptação dos alfas no tempo
subplot(2,2,2)
plot(func.tempo,func.theta,'LineWidth',2.0);
hold on, grid on
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Valores dos parâmetros', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

%figura 4, sinal de controle no tempo
subplot(2,2,3)
plot(func.tempo,func.u,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Sinal de Controle');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Sinal de Controle', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

%figura 5, norma 2 do erro de saída da planta no tempo
subplot(2,2,4)
plot(tempo_acesso,func.e_o,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Erro de Saída');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Erro de Saída entre o modelo de referência e a planta', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

end