    [Ac,bc,Cc,Dc] = tf2ss(18*[1 4 6 4 1], [0.0025 0.1 1 0 0]);
    u(1)=0.6;
    xc(:,1,1) = [0;0;0;0.6/7200];
    for k=1:10000
    e(k) = 0.6 - u(k);
    xc_ponto(:,1,k) = Ac*xc(:,1,k) + bc*e(k);
    xc(:,1,k+1) = xc(:,1,k) + h*xc_ponto(:,1,k);
    u(k+1) = Cc*xc(:,1,k+1) + Dc*e(k);
    end
xc(:,1,50)