function my_phase()
[~,X] = ode45(@EOM,[0 10],[2 2]);
x1 = X(:,1);
x2 = X(:,2);
plot(x1,x2,'LineWidth',2)
leg1 = legend('Mapa de Fase Oscilador Simples, x_1=x_2=2');
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
      -x1];
end

