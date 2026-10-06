function my_phase()
[~,X] = ode45(@EOM,[0 500],[1.8 0]);
x1 = X(:,1);
x2 = X(:,2);
plot(x1,x2)
leg1 = legend('Mapa de Fase, partindo do interior do ciclo');
set(leg1,'FontSize', 14);
xlabel('x1')
ylabel('x2')
grid
end
function dX = EOM(t, y)
dX = zeros(2,1);
x1  = y(1);
x2  = y(2);
f = exp(-x1^2);
dX = [x2;...
      (1-f)*(x1-1)*(x1-2)];
end