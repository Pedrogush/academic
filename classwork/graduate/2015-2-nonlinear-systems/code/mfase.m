
[x1,x2] = meshgrid(-2:0.5:2,-2:0.5:2);
mi=1;
c=1;
x1d = x2;
x2d = -mi(1-x1^2)*x2-x1;

figure;
quiver(x1,x2,x1d,x2d);
