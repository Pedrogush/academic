%obs: desempenho obtido com diferentes F.Ts de controladores
%[Ac,bc,Cc,Dc] = tf2ss(18*[1 16/25 2561/2500  7503/12500], [0.1 1 0 0]);
% [Ac,bc,Cc,Dc] = tf2ss(18*[1 9/5 52/25  102/125], [0.1 1 0 0]);