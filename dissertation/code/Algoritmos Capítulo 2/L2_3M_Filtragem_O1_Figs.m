function L2_3M_Filtragem_O1_Figs(t,h)

endk = t/h;
y(1) = 0.2;
z_hat_1(1) = 0;
z_hat_2(1) = 0;
z_hat_3(1) = 0;
a_p = 1.5;
a_p_M = 4;
a_p_m = 0.5;
k_p_M = 6;
k_p_m = 1;
k_p = 3;
a_m = 4;
hat_a_p_1(1) = 0.5;
hat_k_p_1(1) = 1;
hat_a_p_2(1) = 0.5;
hat_k_p_2(1) = 11;
hat_a_p_3(1) = 7;
hat_k_p_3(1) = 1;
alfa_1(1) = 0.5;
alfa_2(1) = 0.5;
alfa_3(1) = 0;
alfa(:,1) = [alfa_1(1); alfa_2(1)];
phi_1(1) = 0;
phi_2(1) = 0;
lambda=4;
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
   z(k) = y(k) - lambda*phi_1(k);
  %z(k) = -a_p*phi_1(k)+k_p*phi_2(k);
  z_hat_1(k) = -phi_1(k)*hat_a_p_1(k) + phi_2(k)*hat_k_p_1(k);
  z_hat_2(k) = -phi_1(k)*hat_a_p_2(k) + phi_2(k)*hat_k_p_2(k);
  z_hat_3(k) = -phi_1(k)*hat_a_p_3(k) + phi_2(k)*hat_k_p_3(k);
  % dot_z_hat_1(k) = -lambda*z_hat_1(k) -hat_a_p_1(k)*y(k) + hat_k_p_1(k)*u(k);
  % z_hat_1(k+1) = z_hat_1(k)+h*dot_z_hat_1(k);
  % dot_z_hat_2(k) = -lambda*z_hat_2(k) -hat_a_p_2(k)*y(k) + hat_k_p_2(k)*u(k);
  % z_hat_2(k+1) = z_hat_2(k)+h*dot_z_hat_2(k);
  % dot_z_hat_3(k) = -lambda*z_hat_3(k) -hat_a_p_3(k)*y(k) + hat_k_p_3(k)*u(k);
  % z_hat_3(k+1) = z_hat_3(k)+h*dot_z_hat_3(k);
   e_1_f(k) = z_hat_1(k) - z(k);
   e_2_f(k) = z_hat_2(k) - z(k);
   e_3_f(k) = z_hat_3(k) - z(k);
   dot_hat_a_p_1(k) = e_1_f(k)*y(k);
   hat_a_p_1(k+1) = hat_a_p_1(k) + h*dot_hat_a_p_1(k);
   dot_hat_a_p_2(k) = e_2_f(k)*y(k);
   hat_a_p_2(k+1) = hat_a_p_2(k) + h*dot_hat_a_p_2(k);
   dot_hat_a_p_3(k) = e_3_f(k)*y(k);
   hat_a_p_3(k+1) = hat_a_p_3(k) + h*dot_hat_a_p_3(k);
   dot_hat_k_p_1(k) = -e_1_f(k)*u(k);
   hat_k_p_1(k+1) = hat_k_p_1(k) + h*dot_hat_k_p_1(k);
   dot_hat_k_p_2(k) = -e_2_f(k)*u(k);
   hat_k_p_2(k+1) = hat_k_p_2(k) + h*dot_hat_k_p_2(k);
   dot_hat_k_p_3(k) = -e_3_f(k)*u(k);
   hat_k_p_3(k+1) = hat_k_p_3(k) + h*dot_hat_k_p_3(k);
   
   E_f(1,:,k) = [e_1_f(k)-e_3_f(k) e_2_f(k)-e_3_f(k)];
   dot_alfa(:,k) = (-E_f(1,:,k)'*E_f(1,:,k)*alfa(:,k) - E_f(1,:,k)'*e_3_f(k))';
   alfa(:,k+1) = alfa(:,k) + h*dot_alfa(:,k);
   alfa_1(k+1) = alfa(1,k+1);
   alfa_2(k+1) = alfa(2,k+1);
   alfa_3(k+1) = 1-alfa_1(k+1)-alfa_2(k+1);
   
   hat_k_p_n2(k) = alfa_1(k)*hat_k_p_1(k)+alfa_2(k)*hat_k_p_2(k)+alfa_3(k)*hat_k_p_3(k);
   hat_a_p_n2(k) = alfa_1(k)*hat_a_p_1(k)+alfa_2(k)*hat_a_p_2(k)+alfa_3(k)*hat_a_p_3(k);
   
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
title('3 Modelos por Regressão Linear ')
end