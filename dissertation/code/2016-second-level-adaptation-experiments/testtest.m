
x = -5:1:5;
y = -5:1:5;

[xg,yg] = meshgrid(x,y);

dxg = 2*xg;
dyg = 400*yg;

quiver(xg, yg, dxg, dyg, 1)
M=2;
x = -4:0.05:4;
y1 = sqrt(16-x.^2)/200;
y2 = -sqrt(16-x.^2)/200;
hold on
plot(x,y1)
plot(x,y2)
for i=1:4
px = 2*rand();
py = 2*rand();

plot(px,py,'.');
k = -1:0.01:1;
pxl = px - k*2*px;
pyl = py - k*400*py;
plot(pxl,pyl)
plot(0,0,'.')
end