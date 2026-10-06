function plot_adap_figures_L1(func)

endk = func.endk;
tempo_acesso = func.tempo(1:endk);
%figura 1, saídas referentes a primeira variável de estado da planta e do
%modelo de referência, a referência multiplicada pelo ganho
%estático do modelo de referência evoluindo no tempo
figure(1)
subplot(3,1,1)
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


%figura 2, sinal de controle no tempo
subplot(3,1,2)
plot(tempo_acesso,func.u,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Sinal de Controle');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Sinal de Controle', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);

%figura 3, norma 2 do erro de saída da planta no tempo
subplot(3,1,3)
plot(tempo_acesso,func.norm_2_e_o,'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Norma 2 do Erro de Saída');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Norma 2 do erro de Saída entre o modelo de referência e a planta', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14);


end