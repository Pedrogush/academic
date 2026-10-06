function PLOT_VS_O2(uvs,ypvs,ymvs,tempo_1)
grid on
hold on
figure(1)
plot(tempo_1,uvs,'LineWidth',2,'LineStyle','-');
lgdu = legend('Sinal de Controle Chaveado');

figure(2)
grid on
hold on
plot(tempo_1,ypvs-ymvs,'LineWidth',2,'LineStyle','-');
lgdu = legend('Erro de Saída');
hold on
grid on
plot(tempo_1,zeros(1,length(tempo_1)),'LineWidth',2,'LineStyle','-.','Color',[0 0 0]);
end