function [hat_a_p, hat_k_p,y,y_m,u, tempo_1]=L1A_Filtragem_O1(t,h)

endk = t/h;
y(1) = 0.2;
y_hat(1) = 0;
y_m(1) = 0;
a_p = 1.5;
k_p = 3;
a_m = 5;
k_m = 5;
lambda = 4;
hat_a_p(1) = 0.5;
hat_k_p(1) = 6;
phi_1(1) = 0.2;
phi_2(1) = 0;
   z(1) = y(1) - lambda*phi_1(1);
   z_hat(1) = -hat_a_p(1)*phi_1(1) + hat_k_p(1)*phi_2(1);
e_1_f(1) = z(1)-z_hat(1);
for k=1: endk
   r(k) = 1;
   k_1 = (hat_a_p(k)-a_m)/hat_k_p(k);
   k_2 = k_m/hat_k_p(k);
   u(k) = k_1*y(k)+k_2*r(k);
   tempo(k) = h*k;
   tempo_1(k+1) = h+h*k;
   dot_y(k) = -a_p*y(k) + k_p*u(k);
   y(k+1) = y(k) + h*dot_y(k);
   dot_y_m(k) = -a_m*y_m(k) + k_m*r(k);
   y_m(k+1) = y_m(k) + h*dot_y_m(k);
   e_o(k) = y(k)-y_m(k);
   dot_phi_1(k) = -lambda*phi_1(k) + y(k);
   phi_1(k+1) = phi_1(k) + h*dot_phi_1(k);
   dot_phi_2(k) = -lambda*phi_2(k) + u(k);
   phi_2(k+1) = phi_2(k) + h*dot_phi_2(k);
   z(k) = y(k) - lambda*phi_1(k);
   z_hat(k) = -hat_a_p(k)*phi_1(k) + hat_k_p(k)*phi_2(k);
   e_1_f(k) = z_hat(k) - z(k);
   dot_hat_a_p(k) = e_1_f(k)*y(k);
   hat_a_p(k+1) = hat_a_p(k) + h*dot_hat_a_p(k);
   dot_hat_k_p(k) = -e_1_f(k)*u(k);
   hat_k_p(k+1) = hat_k_p(k) + h*dot_hat_k_p(k);
   
end

end