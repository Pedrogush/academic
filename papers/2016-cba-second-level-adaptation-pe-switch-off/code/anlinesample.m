h = animatedline('MaximumNumPoints',4,'LineWidth',3.0);
line([1;2;3;4;1], [3;4;5;6;3])
line([0;400],[40;0])
for k = 1:400
    addpoints(h,[k;(k+2)*1.01^-k;k+1;k],[(k+3)*1.01^-k;-k;(k+4);(k+3)*1.01^-k])
    M(k) = getframe;
end