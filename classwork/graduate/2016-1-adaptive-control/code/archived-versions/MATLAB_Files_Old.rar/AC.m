function AC(h,stoptime,bpi0,api0,Ap,bp,Am,bm,cond_iniciais_p,cond_iniciais_m,cond_iniciais_i,referencia,P)

x_p(:,1) = cond_iniciais_p;
x_m(:,1) = cond_iniciais_m;
x_i(:,1) = cond_iniciais_i;
endk = stoptime/h;
tempo(1) = 0;
Ai(:,:,1) = can(api0);
bi(:,1,1) = bpi0;
theta(:,1) = [bpi0; api0];
v(:,1) = [0*ones(length(x_p(:,1)),1) ; x_p(:,1)];
for k=1:endk
tempo(k+1) = tempo(k) + h;
r(k) = referencia*sin(tempo(k));
k_T(:,k) = [bm; transpose(Am(length(Am),:))] - [bi(:,1,k); transpose(Ai(length(x_p(:,k)),:,k))];
u(k+1) = r(k) + transpose(k_T(:,k))*v(:,k);
x_p_ponto(:,k) = Ap*x_p(:,k) + bp*u(k);
x_p(:,k+1) = x_p(:,k) + h*x_p_ponto(:,k);
x_m_ponto(:,k) = Am*x_m(:,k) + bm*r(k);
x_m(:,k+1) = x_m(:,k) + h*x_m_ponto(:,k);
x_i_ponto(:,k) = Ai(:,:,k)*x_i(:,k) + bi(:,1,k)*u(k);
x_i(:,k+1) = x_i(:,k) + h*x_i_ponto(:,k);
v(:,k+1) = [u(k+1)*ones(length(x_p(:,k+1)),1) ; x_p(:,k+1)];
e1(:,k) = [bp*u(k) - bi(:,1,k)*u(k);x_i(:,k) - x_p(:,k)];
theta_ponto(:,1,k) = -transpose(e1(:,k))*P*v(:,k);
theta(:,k+1) = theta(:,k) + h*theta_ponto(:,1,k);
Ai(:,:,k+1) = can(theta(1:2,k+1));

bi(:,1,k+1) = theta(1:length(theta(:,k+1))/2,k+1); 

end
plot(tempo,x_p)
hold on, grid on
plot(tempo,x_i)
hold on, grid on
plot(tempo,x_m)
end