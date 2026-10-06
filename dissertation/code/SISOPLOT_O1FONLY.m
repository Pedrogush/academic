function SISOPLOT_O1FONLY(a_pal,a_spal,a_f,a_2f3,a_2sp3,a_2f4,a_2f8,...
                     k_pal,k_spal,k_f,k_2f3,k_2sp3,k_2f4,k_2f8,tempo_1)

endk=length(a_2sp3);
tempo_1 = tempo_1(1:endk);
a_pal = a_pal(1:endk);
k_pal=k_pal(1:endk);
a_spal=a_spal(1:endk);
k_spal=k_spal(1:endk);
a_f=a_f(1:endk);
k_f = k_f(1:endk);


a_p=1.5;
a_p_M = 4;
a_p_m = 0.5;
k_p_M = 6;
k_p_m = 1;
k_p = 3;
f = 100;
rval(:) = a_p*ones(1,endk);
liminf = a_p_m(1)*ones(1,endk);
limsup = a_p_M(1)*ones(1,endk);
msize=100;
figure(1)
hold on
pl1 = plot(tempo_1,a_f,'LineWidth',2.0,'LineStyle','--');
hold on
[vec1scatter,vec2scatter] = VectorReduction(tempo_1,a_f,1.6,0,20,a_p_m,a_p_M);
p1 = scatter(vec1scatter,vec2scatter,msize,'Marker','o','LineWidth',2,'MarkerEdgeColor',pl1.Color);
hold on
pl2 = plot(tempo_1,a_2f3,'LineWidth',2.0,'LineStyle','-.');
hold on
[vec1scatter,vec2scatter] = VectorReduction(tempo_1,a_2f3,1.6,0,20,a_p_m,a_p_M);
p2 = scatter(vec1scatter,vec2scatter,msize,'Marker','s','LineWidth',2,'MarkerEdgeColor',pl2.Color);
hold on
pl3 = plot(tempo_1,a_2f4,'LineWidth',2.0,'LineStyle','-');
hold on
[vec1scatter,vec2scatter] = VectorReduction(tempo_1,a_2f4,1.6,0,20,a_p_m,a_p_M);
p3 = scatter(vec1scatter,vec2scatter,msize,'Marker','*','LineWidth',2,'MarkerEdgeColor',pl3.Color);
hold on
pl4 = plot(tempo_1,a_2f8,'LineWidth',2.0,'LineStyle',':');
hold on
[vec1scatter,vec2scatter] = VectorReduction(tempo_1,a_2f8,1.6,0,20,a_p_m,a_p_M);
p4 = scatter(vec1scatter,vec2scatter,msize,'Marker','x','LineWidth',2,'MarkerEdgeColor',pl4.Color);
hold on
p5 = plot(tempo_1(1:f:endk),rval(1:f:endk),'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0]);
alpha(p1,0.2);
alpha(p2,0.2);
alpha(p3,0.2);
alpha(p4,0.2);
%lgda = legend('Nivel 1','Valor Correto');
fake_leg1 = plot(30,50,'LineWidth',2.0,'LineStyle','--','Marker','o','MarkerSize',8,'Color',pl1.Color);
fake_leg2 = plot(30,50,'LineWidth',2.0,'LineStyle','-.','Marker','s','MarkerSize',8,'Color',pl2.Color); 
fake_leg3 = plot(30,50,'LineWidth',2.0,'LineStyle','-','Marker','*','MarkerSize',8,'Color',pl3.Color); 
fake_leg4 = plot(30,50,'LineWidth',2.0,'LineStyle',':','Marker','x','MarkerSize',8,'Color',pl4.Color); 
lgda = legend([fake_leg1 fake_leg2 fake_leg3 fake_leg4 p5],'Nível 1 Reg. Linear',...
              'Nível 2 Reg. Lin. N=3','Nível 2 Reg. Lin. N=4',...
              'Nível 2 Reg. Lin. N=8','Valor Correto');
grid on
title('a estimativa - a_p')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 20 a_p_m a_p_M])
set(gca,'fontsize',20)


rval(:) = k_p*ones(1,endk);
liminf = k_p_m(1)*ones(1,endk);
limsup = k_p_M(1)*ones(1,endk);
figure(2)
plot(tempo_1,k_f,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,k_2f3,'LineWidth',3.0,'LineStyle','-.')
hold on
plot(tempo_1,k_2f4,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,k_2f8,'LineWidth',2.0,'LineStyle','-.')
hold on
plot(tempo_1,rval,'LineWidth',1.0,'LineStyle','-.','Color',[0 0 0])
%lgda = legend('Nivel 1','Valor Correto');
lgda = legend('Nível 1 Reg. Linear',...
              'Nível 2 Reg. Lin. N=3','Nível 2 Reg. Lin. N=4', ...
              'Nível 2 Reg. Lin. N=8','Valor Correto');
grid on
title('k estimativa-k_p')
hold on
plot(tempo_1,liminf,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
hold on
plot(tempo_1,limsup,'LineWidth',1.0,'LineStyle','-','Color',[0 0 0])
axis([0 20 k_p_m k_p_M])
set(gca,'fontsize',20)


end