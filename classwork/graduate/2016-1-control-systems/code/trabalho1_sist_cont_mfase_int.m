function my_phase()
[~,X] = ode45(@EOM,[0 1000],[0.1 0.1]);
x1 = X(:,1);
x2 = X(:,2);
plot(x1,x2,'LineWidth',2.0)
leg1 = legend('Mapa de Fase, Cond. Iniciais dentro do ciclo, x_1=x_2=0.1');
set(leg1,'FontSize', 14);
xlabel('x1')
ylabel('x2')
grid
end
function dX = EOM(t, y)
dX = zeros(2,1);
c = 2;
x1  = y(1);
x2  = y(2);
mi=1.5;
dX = [x2;...
      mi*(1-x1^2)*x2-x1];
end

