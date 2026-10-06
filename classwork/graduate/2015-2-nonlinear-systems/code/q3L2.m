function my_phase()
[~,X] = ode45(@EOM,[0 100],[1 -3]);
x1 = X(:,1);
x2 = X(:,2);
plot(x1,x2)
xlabel('x1')
ylabel('x2')
grid
end
function dX = EOM(t, y)
dX = zeros(2,1);
c = 1.03;
x1  = y(1);
x2  = y(2);
dX = [x2;...
      -x1+x2-(x2^3)/3];
end
