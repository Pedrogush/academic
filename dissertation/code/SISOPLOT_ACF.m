function SISOPLOT_ACF(theta_1,theta_n2,theta_n2fe,ym,y1,yn2,yn2fe,u1,un2,un2fe,u_est,tempo_1)

theta_p = [-3 -4 2 1];
theta_p_m = [-8 -6 1 0.5];
theta_p_M = [-0.5 -1.5 7 1.5];

esca1(:) = theta_1(1,1,:);
escan2i(:) = theta_n2(1,:);
escan2fe(:) = theta_n2fe(1,:);
endk=length(esca1);
tempo(1:endk-1) = tempo_1(1:endk-1); 
rval(:) = theta_p(1)*ones(1,endk);
liminf = theta_p_m(1)*ones(1,endk);
limsup = theta_p_M(1)*ones(1,endk);
figure(1)
plot(tempo_1,esca1,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2i,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2fe,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1','Nível 2','Nível 2 FE','Valor Correto');
grid on
title('Estimativa de \theta_p(1)')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 20 theta_p_m(1) theta_p_M(1)])


esca1(:) = theta_1(2,1,:);
escan2i(:) = theta_n2(2,:);
escan2fe(:) = theta_n2fe(2,:);
rval(:) = theta_p(2)*ones(1,endk);
liminf = theta_p_m(2)*ones(1,endk);
limsup = theta_p_M(2)*ones(1,endk);
figure(2)
plot(tempo_1,esca1,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2i,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2fe,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1','Nível 2','Nível 2 FE','Valor Correto');
grid on
title('Estimativa de \theta_p(2)')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 20 theta_p_m(2) theta_p_M(2)])


esca1(:) = theta_1(3,1,:);
escan2i(:) = theta_n2(3,:);
escan2fe(:) = theta_n2fe(3,:);
%escan2i(:) = An2I(2,1,:);
%escan2fe(:) = An2FE(2,1,:);
rval(:) = theta_p(3)*ones(1,endk);
liminf = theta_p_m(3)*ones(1,endk);
limsup = theta_p_M(3)*ones(1,endk);
figure(3)
plot(tempo_1,esca1,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2i,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2fe,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1','Nível 2','Nível 2 FE','Valor Correto');
grid on
title('Estimativa de \theta_p(3)')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 20 theta_p_m(3) theta_p_M(3)])



esca1(:) = theta_1(4,1,:);
escan2i(:) = theta_n2(4,:);
escan2fe(:) = theta_n2fe(4,:);
%escan2i(:) = An2I(2,2,:);
%escan2fe(:) = An2FE(2,2,:);
rval(:) = theta_p(4)*ones(1,endk);
liminf = theta_p_m(4)*ones(1,endk);
limsup = theta_p_M(4)*ones(1,endk);
figure(4)
plot(tempo_1,esca1,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2i,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,escan2fe,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1','Nível 2','Nível 2 FE','Valor Correto');
grid on
title('Estimativa de \theta_p(4)')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 20 theta_p_m(4) theta_p_M(4)])

figure(5)
plot(tempo,u1,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo,un2,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo,un2fe,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo,u_est,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1','Nível 2','Nível 2 FE','Valor Correto');
grid on
title('Sinal de Controle')

figure(6)
plot(tempo_1,y1-ym,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,yn2-ym,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,yn2fe-ym,'LineWidth',2.0,'LineStyle','-.')
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1','Nível 2','Nível 2 FE');
grid on
title('Erro de Saída')
hold on
plot(tempo_1,0*ones(1,endk),'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])


end