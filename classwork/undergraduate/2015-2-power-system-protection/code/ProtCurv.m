t1 = zeros(10,190);
t2 = zeros(10,190);
t3 = zeros(10,190);
%%tempo em função do multiplo da corrente, MI
for T=1:10
     for L=1:190
        v=(13.5*T/10)/((1+0.1*L)^1-0.9);
        t1(T,L) = v;
     end

end
%% NI
for T=1:10
     for L=1:190
        v=(0.14*T/10)/((1+0.1*L)^0.02-0.9);
        t2(T,L) = v;
     end

end
%% EI
for T=1:10
     for L=1:190
        v=(80*T/10)/((1+0.1*L)^2-0.9);
        t3(T,L) = v;
     end
end
figure;
subplot(3,1,1);
plot([11:200]/10,log(t3(1:10,:)));
title('EI');
subplot(3,1,2);
plot([11:200]/10,log(t2(1:10,:)));
title('NI');
subplot(3,1,3);
plot([11:200]/10,log(t1(1:10,:)));
title('MI');