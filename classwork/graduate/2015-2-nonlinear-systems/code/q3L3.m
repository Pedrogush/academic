function my_phase()
[~,X] = ode45(@EOM,[0 5000],[100 200]);
x1 = X(:,1);
x2 = X(:,2);
plot(x1,x2)
xlabel('x1')
ylabel('x2')
grid
end
function dX = EOM(t, y)
dX = zeros(2,1);
K   = 0.001;
x1  = y(1);
x2  = y(2);
dX = [-K*x1-3*x2;...
      K*x1-2*x2];
end
