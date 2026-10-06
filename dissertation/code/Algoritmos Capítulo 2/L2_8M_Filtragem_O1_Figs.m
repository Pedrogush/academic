function L2_8M_Filtragem_O1_Figs(t,h)

endk = t/h;
y(1) = 0.2;
z(1) = 0;
a_p = 1.5;
a_p_M = 4;
a_p_m = 0.5;
k_p_M = 6;
k_p_m = 1;
k_p = 3;
   hat_a_p(1,1)=0.5;
   hat_k_p(1,1)=1;
      hat_a_p(2,1)=2;
   hat_k_p(2,1)=1;
      hat_a_p(3,1)=4;
   hat_k_p(3,1)=1;
      hat_a_p(4,1)=4;
   hat_k_p(4,1)=3;
      hat_a_p(5,1)=4;
   hat_k_p(5,1)=6;
      hat_a_p(6,1)=2.5;
   hat_k_p(6,1)=6;
      hat_a_p(7,1)=0.5;
   hat_k_p(7,1)=4;
         hat_a_p(8,1)=0.5;
   hat_k_p(8,1)=6;
for i=1:8
   z_hat(i,1) = 0;
   if i~=8
      alfa(i,1) = 0;
   end
   if i==7
       alfa(i,1)=0;
   end
end

a_m = 4;
phi_1(1) = 0;
phi_2(1) = 0;
lambda=4;
e_i_f(8,1)=0;
alfa_8(1) = 1;
for k=1: endk
   u(k) = sin(h*k);
   tempo(k) = h*k;
   tempo_1(k+1) = h+h*k;
   dot_y(k) = -a_p*y(k) + k_p*u(k);
   y(k+1) = y(k) + h*dot_y(k);
   dot_phi_1(k) = -lambda*phi_1(k) + y(k);
   phi_1(k+1) = phi_1(k) + h*dot_phi_1(k);
   dot_phi_2(k) = -lambda*phi_2(k) + u(k);
   phi_2(k+1) = phi_2(k) + h*dot_phi_2(k);
   z(k) = -a_p*phi_1(k)+k_p*phi_2(k);
   %z(k) = y(k)-lambda*phi_1(k);
   for i=1:8
   e_i_f(i,k) = z_hat(i,k) - z(k);
   dot_hat_a_p(i,k) = e_i_f(i,k)*y(k);
   hat_a_p(i,k+1) = hat_a_p(i,k) + h*dot_hat_a_p(i,k);
   dot_hat_k_p(i,k) = -e_i_f(i,k)*u(k);
   hat_k_p(i,k+1) = hat_k_p(i,k) + h*dot_hat_k_p(i,k);
   z_hat(i,k+1) = -phi_1(k+1)*hat_a_p(i,k+1) + phi_2(k+1)*hat_k_p(i,k+1);
   
   end
   for i=1:7
    E_f(1,i,k) = e_i_f(i,k)-e_i_f(8,k);
   end
   dot_alfa(:,k) = (-(E_f(1,:,k)'*E_f(1,:,k))*alfa(:,k) - E_f(1,:,k)'*e_i_f(8,k))';
   alfa(:,k+1) = alfa(:,k) + h*dot_alfa(:,k);
   alfa_8(k+1) = 1-ones(1,7)*alfa(:,k+1);
   for i=1:8
   Bar_Theta(:,i,k) = [hat_a_p(i,k); hat_k_p(i,k)];
   end
   theta_p(:,k) = Bar_Theta(:,:,k)*([alfa(:,k); alfa_8(k)]);
   hat_a_p_n2(k) = theta_p(1,k);
   hat_k_p_n2(k) = theta_p(2,k);
end
figure(1)
plot(0.5,6,'Marker','*','LineWidth',3.0,'Color',[0.5 0 0.5],'LineStyle','none');
hold on
grid on
plot(a_p,k_p,'Marker','x','LineWidth',2.0,'Color', [0 0 0],'LineStyle','none');
hold on
    line([a_p_M a_p_M a_p_m a_p_m a_p_M], ...
         [k_p_M k_p_m k_p_m k_p_M k_p_M], ...
                      'Color', [1 0 0],'LineWidth',2.0)
axis([a_p_m a_p_M k_p_m k_p_M])
linha_anim = animatedline('LineWidth',3.0,'Color',[0.35 0.5 0],'LineStyle','-');
pontos_est = animatedline('MaximumNumPoints',1,'Marker','*','MarkerSize',12,'LineWidth',1.0,'Color', [0.2 0.3 0.4],'LineStyle','none');
skip = 10000;
   grid on

addpoints(pontos_est,hat_a_p_n2(1),hat_k_p_n2(1))
lgd = legend('Estimativas Iniciais','a_p,k_p Verdadeiros','Região de Incerteza','Trajetória','a_p,k_p Estimados');
title(lgd,'0 Segundos')
for k=1:endk   
   addpoints(linha_anim,hat_a_p_n2(k),hat_k_p_n2(k));
   if floor(k/skip)==ceil(k/skip)
   addpoints(pontos_est,hat_a_p_n2(k),hat_k_p_n2(k))
   str_title = num2str(tempo(k));
   title(lgd, [str_title ' Segundos'])
   end
end
set(gca,'fontsize',20)
title('8 Modelos por Regressão Linear ')

end