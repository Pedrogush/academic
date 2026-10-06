function my_phase()
[~,X] = ode45(@EOM,[0 10],[1 0]);
x1 = X(:,1);
x2 = X(:,2);
plot(x1,x2)
xlabel('x1')
ylabel('x2')
grid
end
function dX = EOM(t, y)
dX = zeros(2,1);
x1  = y(1);
x2  = y(2);
dX = [x2;...
      -x1];
end
