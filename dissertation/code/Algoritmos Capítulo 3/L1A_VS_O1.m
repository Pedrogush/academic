function [y,y_m,u, tempo_1]=L1A_VS_O1(t,h)

endk = t/h;
y(1) = 0.2;
y_m(1) = 0;
e_0(1) = 0.2;
a_p = 1.5;
k_p = 3;
a_m = 5;
k_m = 5;
k_1_bar = 4.5;
k_2_bar = 5;

for k=1: endk
   r(k) = 1;
   k_1 = -k_1_bar*sign(k_p*e_0(k)*y(k));
   k_2 = -k_2_bar*sign(k_p*e_0(k)*r(k));
   tempo(k) = h*k;
   tempo_1(k+1) = h+h*k;
   u(k) = k_1*y(k)+k_2*r(k);
   dot_y(k) = -a_p*y(k) + k_p*u(k);
   y(k+1) = y(k) + h*dot_y(k);
   dot_y_m(k) = -a_m*y_m(k) + k_m*r(k);
   y_m(k+1) = y_m(k) + h*dot_y_m(k);
   e_0(k+1) = y(k+1)-y_m(k+1);
end

end