function [u,y_p,y_m,tempo_1] = L1A_VS_SISOF_O2(t,h)
tic
endk = t/h;
A_p = [3 4; 1 0];
b_p = [1; 0];
h_p_T = [2 1];

Nm = [1 4];
Dm = [1 4 4];
[A_m,b_m,htm,~] = tf2ss(Nm,Dm);

theta_p = [-3 -4 2 1];
theta_p_m = [-8 -6 1 0.5];
theta_p_M = [-0.5 -1.5 7 1.5];

theta_c_est(1,1,1) = 4-(theta_p(4)/theta_p(3));
theta_c_est(2,1,1) = (-4*theta_p(1) + theta_p(2) + 12)/theta_p(3);
theta_c_est(3,1,1) = (theta_p(1) - 4)/theta_p(3);
theta_c_est(4,1,1) = 1/theta_p(3);

theta_1(:,1,1) = theta_p_m;

theta_c(1,1,1) = 4-(theta_1(4,1,1)/theta_1(3,1,1));
theta_c(2,1,1) = (-4*theta_1(1,1,1) + theta_1(2,1,1) + 12)/theta_1(3,1,1);
theta_c(3,1,1) = (theta_1(1,1,1) - 4)/theta_1(3,1,1);
theta_c(4,1,1) = 1/theta_1(3,1,1);

theta_c1 = theta_c;

Nm_s = [0 1 4];
Dm_s = [1 4 4];
%b_1(:,1,1) = 0.7*b_p;
Lambda_w_s = [1 4];
Lambda_d_s = conv([1 3],Lambda_w_s);


[F,g,~,~]        = tf2ss(1,Lambda_w_s);
[Lambda_c,l,~,~] = tf2ss(1,Lambda_d_s);
Gamma = [10 0 0 0; 0 10 0 0;0 0 10 0;0 0 0 10];
%Gamma = zeros(4,4);

phi_1(:,endk) = [0; 0];
phi_2(:,endk) = [0; 0];

x_p(:,endk) = [0; 0];
x_p(:,1) = [0.2; 0.4];
x_m(:,1) = [0; 0];

tempo(endk) = 0; tempo_1(endk)=0;
u(endk)=0; dot_x_p(:,endk)=[0;0];

alfa(:,endk) = zeros(4,1);
alfa(1,1) = 1;
theta_n2(:,1) = theta_1(:,1,1); 

z_p(1) = h_p_T*x_p(:,1); 
z_1(1) = 0;      
e_1_f(1) = z_1(1) - z_p(1);

w(:,1) = [0; 0; 0; 0];
w_1(1) = 0;
w_2(1) = 0;

theta_p_m = [-8 -6 1 0.5];
theta_p_M = [-0.5 -1.5 7 1.5];

theta_bar(1) = 3.93;
theta_bar(2) = 42.5;
theta_bar(3) = 12;
theta_bar(4) = 1;
e_0(1) = 0.01;
y_p(1) = 0.01;
   for k=1:endk

      tempo(k) = h*k;
      tempo_1(k+1) = h*k+h;
      r(k+1) = 1+sin(3*h*k)+sin(1.7*h*k)+sin(h*k);
      theta_1 = -theta_bar(1)*sign(e_0(k)*w_1(k));
      theta_2 = -theta_bar(2)*sign(e_0(k)*w_2(k));
      theta_3 = -theta_bar(3)*sign(e_0(k)*y_p(k));
      theta_4 = -theta_bar(4)*sign(e_0(k)*r(k));
      theta_c = [theta_1 ; theta_2; theta_3; theta_4];
      u(k) = theta_c(:,1)'*w(:,k);
      
      dot_x_p(:,k) = A_p*x_p(:,k) + b_p*u(k);
      x_p(:,k+1) = x_p(:,k) + h*dot_x_p(:,k);
      y_p(k+1) = h_p_T*x_p(:,k+1);      
      
      dot_x_m(:,k) = A_m*x_m(:,k) + b_m*r(k);
      x_m(:,k+1) = x_m(:,k) + h*dot_x_m(:,k);
      y_m(k+1) = htm*x_m(:,k+1);
      
      e_0(k+1) = y_p(k+1) - y_m(k+1);
            
      dot_w_1(k) = -4*w_1(k) + u(k);
      w_1(k+1) = w_1(k) + h*dot_w_1(k);
      dot_w_2(k) = -4*w_2(k) + y_p(k);
      w_2(k+1) = w_2(k) + h*dot_w_2(k);     
      w(:,k+1) = [w_1(k+1);w_2(k+1); y_p(k+1); r(k+1)];

   end
u(k+1) = u(k);
toc
end