function [theta_1,z_1,z_p,tempo_1] = L1_SISOF_O2(t,h)
tic
endk = t/h;
A_p = [-1 -2; 0 -3];
b_p = [2; 3];
h_p_T = [1 0];
theta_p = [-4 -3; 2 0];
theta_p_m = [3; 1; -1; -3];
theta_p_M = [8; 6; 7; 3];
theta_1(:,1,1) = theta_p_m;
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
      e_1_f(k+1) = z_1(k+1) - z_p(k+1);
      m_2 = 1 + phi(:,k)'*phi(:,k);
      eps_1_f(k+1) = e_1_f(k+1)/m_2;
      dot_theta_1(:,1,k) = -Gamma*eps_1_f(k+1)*phi(:,k);
      theta_1(:,1,k+1) = theta_1(:,1,k) + h*dot_theta_1(:,1,k);
      for i=1:4
              if theta_1(i,1,k+1)>theta_p_M(i)
                 theta_1(i,1,k+1)=theta_p_M(i);
              end
              if theta_1(i,1,k+1)<theta_p_m(i)
                 theta_1(i,1,k+1)=theta_p_m(i);
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