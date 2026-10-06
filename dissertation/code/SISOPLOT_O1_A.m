function SISOPLOT_O1_A(a_f,a_2f3,...
                     k_f,k_2f3,yn1,yn2,ym,yvs,un1o1,un2o1,uvso1,uest,tempo_1,tempo_vs)
endk = length(a_f);                
a_p=1.5;
a_p_M = 4;
a_p_m = 0.5;
k_p_M = 6;
k_p_m = 1;
k_p = 3;
rval(:) = a_p*ones(1,endk);
liminf = a_p_m(1)*ones(1,endk);
limsup = a_p_M(1)*ones(1,endk);
figure(1)
plot(tempo_1,a_f,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,a_2f3,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1 Reg. Linear',...
              'Nível 2 Reg. Lin. N=3','Valor Correto');
grid on
title('a estimativa - a_p')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 12 a_p_m a_p_M])
set(gca,'fontsize',20)


rval(:) = k_p*ones(1,endk);
liminf = k_p_m(1)*ones(1,endk);
limsup = k_p_M(1)*ones(1,endk);
figure(2)
plot(tempo_1,k_f,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,k_2f3,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1 Reg. Linear',...
              'Nível 2 Reg. Lin. N=3','Valor Correto');
grid on
title('k estimativa-k_p')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 12 k_p_m k_p_M])
set(gca,'fontsize',20)

figure(3)
plot(tempo_1,ym,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,yn1,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_1,yn2,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_vs,yvs,'LineWidth',1.0,'LineStyle','-.')
hold on
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Modelo de Referencia','Nível 1 Reg. Linear',...
              'Nível 2 Reg. Lin. N=3','Estrutura Variavel');
grid on
title('saida da planta e do modelo')
hold on
axis([0 12 0 1.25])
set(gca,'fontsize',20)


un1o1(endk)=un1o1(endk-1);
un2o1(endk)=un2o1(endk-1);
uest(endk) = uest(endk-1);
uvso1(length(uvso1)+1)=uvso1(length(uvso1));
figure(4)
plot(tempo_1,un1o1,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_1,un2o1,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_1,uest,'LineWidth',3.0,'LineStyle','-.')
hold on
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1 Reg. Linear',...
              'Nível 2 Reg. Lin. N=3','Parametros Conhecidos');
grid on
title('sinal de controle com leis integrais')
hold on
axis([0 12 0 2])
set(gca,'fontsize',20)


figure(5)
plot(tempo_vs,uvso1,'LineWidth',2.0,'LineStyle','-.');
hold on
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Estrutura Variavel');
grid on
title('sinal de controle com leis chaveadas')
hold on
axis([0 12 -10 10])
set(gca,'fontsize',20)


end