
for c=1:90:180
angulo = c*pi/180;
r = (20-floor(c/360))/20;
cor = abs(cos(floor(c/60)));
%cor = 0;
L2AA_Dif_Anim(900,0.5e-1,[1.5 3.5 2.5+r*cos(angulo); -3 -3 -3+r*sin(angulo)], [2.5; -3],[-4 -4], [0; 0], [0.2; 0.3], [0 0 0 ;0 0 0], [0 0], 5,[1e4 0;0 1e4],100, [1 0;0 1],cor);
end