function [y,y_m,u, tempo_1]=L1A_EST_O1(t,h)

endk = t/h;
y(1) = 0.2;
y_m(1) = 0;
a_p = 1.5;
k_p = 3;
a_m = 5;
k_m = 5;

k_1_est = (a_p-a_m)/k_p;
k_2_est = k_m/k_p;

for k=1: endk
   r(k) = 1;
   tempo(k) = h*k;
   tempo_1(k+1) = h+h*k;
   u(k) = k_1_est*y(k)+k_2_est*r(k);
   dot_y(k) = -a_p*y(k) + k_p*u(k);
   y(k+1) = y(k) + h*dot_y(k);
   dot_y_m(k) = -a_m*y_m(k) + k_m*r(k);
   y_m(k+1) = y_m(k) + h*dot_y_m(k);
   e_o(k) = y(k)-y_m(k);
end

end