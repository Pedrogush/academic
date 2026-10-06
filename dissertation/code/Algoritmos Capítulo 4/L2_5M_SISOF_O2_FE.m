function [theta_n2,z_1,z_p,tempo_1] = L2_5M_SISOF_O2_FE(t,h)
tic
endk = t/h;
A_p = [-1 -2; 0 -3];
b_p = [2; 3];
h_p_T = [1 0];
theta_p = [-4 -3; 2 0];
theta_p_m = [3; 1; -1; -3];
theta_p_M = [8; 6; 7; 3];
theta_1(:,1,1) = theta_p_m;
theta_2(:,1,1) = theta_p_m;
theta_3(:,1,1) = theta_p_m;
theta_4(:,1,1) = theta_p_m;
theta_5(:,1,1) = theta_p_m;
theta_2(1,1,1) = theta_p_m(1)+5*(theta_p_M(1)-theta_p_m(1));
theta_3(2,1,1) = theta_p_m(2)+5*(theta_p_M(2)-theta_p_m(2));
theta_4(3,1,1) = theta_p_m(3)+5*(theta_p_M(3)-theta_p_m(3));
theta_5(4,1,1) = theta_p_m(4)+5*(theta_p_M(4)-theta_p_m(4));

%A_1(:,:,1) = 1.3*A_p;
%b_1(:,1,1) = 0.7*b_p;
Lambda_d_s = [1 6 9];
[Lambda_c,l,~,~] = tf2ss(1,Lambda_d_s);
Gamma = [100 0 0 0; 0 100 0 0;0 0 100 0;0 0 0 100];
phi_1(:,endk) = [0; 0];
phi_2(:,endk) = [0; 0];
x_p(:,endk) = [0; 0];
x_p(:,1) = [0.2; 0.4];
tempo(endk) = 0; tempo_1(endk)=0;
u(endk)=0; dot_x_p(:,endk)=[0;0];
alfa(:,endk) = zeros(4,1);
alfa(1,1) = 1;
theta_n2(:,1) = theta_1(:,1,1); 
M(:,:,endk) = zeros(4,4);
v(:,endk) = zeros(4,1);
M_dot(:,:,endk) = zeros(4,4);
v_dot(:,endk) = zeros(4,1);
z_p(1) = h_p_T*x_p(:,1); 
z_1(1) = 0;      
e_1_f(1) = z_1(1) - z_p(1);
   for k=1:endk

      tempo(k) = h*k;
      tempo_1(k+1) = h*k+h;
      
      u(k) = 1+sin(3*h*k)+sin(1.7*h*k)+sin(h*k);
      
      dot_x_p(:,k) = A_p*x_p(:,k) + b_p*u(k);
      x_p(:,k+1) = x_p(:,k) + h*dot_x_p(:,k);
      y_p(k+1) = h_p_T*x_p(:,k+1);      

      dot_phi_1(:,k) = Lambda_c*phi_1(:,k) - l*y_p(k);
      phi_1(:,k+1) = phi_1(:,k)+h*dot_phi_1(:,k);
      dot_phi_2(:,k) = Lambda_c*phi_2(:,k) + l*u(k);
      phi_2(:,k+1) = phi_2(:,k)+h*dot_phi_2(:,k);
      phi(:,k+1) = [phi_1(:,k+1); phi_2(:,k+1)];
      z_p(k+1) = [6 9]*phi_1(:,k+1)+y_p(k+1);
      z_1(k+1) = theta_1(:,k)'*phi(:,k);
      z_2(k+1) = theta_2(:,k)'*phi(:,k);
      z_3(k+1) = theta_3(:,k)'*phi(:,k);
      z_4(k+1) = theta_4(:,k)'*phi(:,k);
      z_5(k+1) = theta_5(:,k)'*phi(:,k);
      e_1_f(k+1) = z_1(k+1) - z_p(k+1);
      e_2_f(k+1) = z_2(k+1) - z_p(k+1);
      e_3_f(k+1) = z_3(k+1) - z_p(k+1);
      e_4_f(k+1) = z_4(k+1) - z_p(k+1);
      e_5_f(k+1) = z_5(k+1) - z_p(k+1);
      m_2 = 1 + phi(:,k)'*phi(:,k);
      eps_1_f(k+1) = e_1_f(k+1)/m_2;
      eps_2_f(k+1) = e_2_f(k+1)/m_2;
      eps_3_f(k+1) = e_3_f(k+1)/m_2;
      eps_4_f(k+1) = e_4_f(k+1)/m_2;
      eps_5_f(k+1) = e_5_f(k+1)/m_2;
      dot_theta_1(:,1,k) = -Gamma*eps_1_f(k+1)*phi(:,k);
      theta_1(:,1,k+1) = theta_1(:,1,k) + h*dot_theta_1(:,1,k);
      dot_theta_2(:,1,k) = -Gamma*eps_2_f(k+1)*phi(:,k);
      theta_2(:,1,k+1) = theta_2(:,1,k) + h*dot_theta_2(:,1,k);
      dot_theta_3(:,1,k) = -Gamma*eps_3_f(k+1)*phi(:,k);
      theta_3(:,1,k+1) = theta_3(:,1,k) + h*dot_theta_3(:,1,k);
      dot_theta_4(:,1,k) = -Gamma*eps_4_f(k+1)*phi(:,k);
      theta_4(:,1,k+1) = theta_4(:,1,k) + h*dot_theta_4(:,1,k);
      dot_theta_5(:,1,k) = -Gamma*eps_5_f(k+1)*phi(:,k);
      theta_5(:,1,k+1) = theta_5(:,1,k) + h*dot_theta_5(:,1,k);
      
      E_f(1,:,k) = [eps_1_f(k)-eps_5_f(k) eps_2_f(k)-eps_5_f(k) eps_3_f(k)-eps_5_f(k) eps_4_f(k)-eps_5_f(k)];
      M_dot(:,:,k) = -0.2*M(:,:,k)+E_f(:,:,k)'*E_f(:,:,k);
      M(:,:,k+1)   = M(:,:,k) + h*M_dot(:,:,k);
      v_dot(:,k)   = -0.2*v(:,k)+E_f(:,:,k)'*eps_5_f(k);
      v(:,k+1)     = v(:,k) + h*v_dot(:,k);      
      
      dot_alfa(:,k) = 10*(-(E_f(:,:,k)'*E_f(:,:,k)+M(:,:,k))*alfa(:,k)+...
                          -E_f(:,:,k)'*eps_5_f(k)-v(:,k));
      alfa(:,k+1) = alfa(:,k) + h*dot_alfa(:,k);  
      alfa_N(k+1) = 1 - ones(1,4)*alfa(:,k+1);
      theta_n2(:,k+1) = alfa(1,k+1)*theta_1(:,k+1)+alfa(2,k+1)*theta_2(:,k+1)+...
                      alfa(3,k+1)*theta_3(:,k+1)+alfa(4,k+1)*theta_4(:,k+1)+...
                      alfa_N(k+1)*theta_5(:,k+1);
      for i=1:4
              if theta_n2(i,k+1)>theta_p_M(i)
                 theta_n2(i,k+1)=theta_p_M(i);
              end
              if theta_n2(i,k+1)<theta_p_m(i)
                 theta_n2(i,k+1)=theta_p_m(i);
              end
      end
      
     %  p1(k) = h^2*(dot_e_1_sp(:,k)'*P*dot_e_1_sp(:,k));
     %  p2(k) = h^2*trace(x_p(:,k)*e_1_sp(:,k)'*P^2*e_1_sp(:,k)*x_p(:,k)');
     %  p3(k) = h^2*(u(k)^2*e_1_sp(:,k)'*P*e_1_sp(:,k));
     %  dot_Dif_V(k) = h*(e_1_sp(:,k)'*(A_m'*P+P*A_m)*e_1_sp(:,k))+p1(k)+p2(k)+p3(k);
     %  Dif_V(k+1) = Dif_V(k)+dot_Dif_V(k);
     %  ddif_V(k) = V(k)-Dif_V(k);
   end
%figure(1)
%plot(tempo,V);

toc
end