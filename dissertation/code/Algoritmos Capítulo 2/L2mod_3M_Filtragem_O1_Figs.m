function L2mod_3M_Filtragem_O1_Figs(t,h)

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
lambda=4;
phi_1(1) = 0;
phi_2(1) = 0;
M(:,:,1) = zeros(2,2);
v(:,1) = zeros(2,1);
for k=1: endk
   u(k) = 1;
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
   %dot_z(k) = -lambda*z(k)-a_p*y(k)+k_p*u(k);
   z_hat_1(k) = -phi_1(k)*hat_a_p_1(k) + phi_2(k)*hat_k_p_1(k);
   z_hat_2(k) = -phi_1(k)*hat_a_p_2(k) + phi_2(k)*hat_k_p_2(k);
   z_hat_3(k) = -phi_1(k)*hat_a_p_3(k) + phi_2(k)*hat_k_p_3(k);
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
   M_dot(:,:,k) = E_f(1,:,k)'*E_f(1,:,k);
   M(:,:,k+1) = M(:,:,k) + h*M_dot(:,:,k);
   v_dot(:,k) = E_f(1,:,k)'*e_3_f(k);
   v(:,k+1) = v(:,k) + h*v_dot(:,k);
   dot_alfa(:,k) = (-(E_f(1,:,k)'*E_f(1,:,k)+M(:,:,k))*alfa(:,k) - E_f(1,:,k)'*e_3_f(k)-v(:,k))';
   alfa(:,k+1) = alfa(:,k) + h*dot_alfa(:,k);
   alfa_1(k+1) = alfa(1,k+1);
   alfa_2(k+1) = alfa(2,k+1);
   alfa_3(k+1) = 1-alfa_1(k+1)-alfa_2(k+1);
   
   hat_k_p_n2(k) = alfa_1(k)*hat_k_p_1(k)+alfa_2(k)*hat_k_p_2(k)+alfa_3(k)*hat_k_p_3(k);
   hat_a_p_n2(k) = alfa_1(k)*hat_a_p_1(k)+alfa_2(k)*hat_a_p_2(k)+alfa_3(k)*hat_a_p_3(k);
   
end

figure(1)
plot(tempo,z_hat_1,'LineStyle','-.','LineWidth',3.0);
hold on
plot(tempo,z_hat_2,'LineStyle','--','LineWidth',3.0);
hold on
plot(tempo,z_hat_3,'LineStyle',':','LineWidth',3.0);
hold on
plot(tempo,z,'LineWidth',2.0);
lgdf1 = legend('z estimado 1','z estimado 2','z estimado 3','z');
grid on

figure(2)

plot(tempo_1,hat_a_p_1,'LineWidth',2.0);
hold on
plot(tempo_1,hat_a_p_2,'LineWidth',2.0);
hold on
plot(tempo_1,hat_a_p_3,'LineWidth',2.0);
hold on
plot(tempo,hat_a_p_n2,'LineWidth',2.0);
hold on
plot(tempo_1,a_p*ones(1,endk+1),'LineStyle','--','LineWidth',2.0);
lgdf1 = legend('a_p estimado 1','a_p estimado 2','a_p estimado 3','a_p estimado nivel 2','a_p');
grid on
axis([0 36 0 7])

figure(3)

plot(tempo_1,hat_k_p_1,'LineWidth',2.0);
hold on
plot(tempo_1,hat_k_p_2,'LineWidth',2.0);
hold on
plot(tempo_1,hat_k_p_3,'LineWidth',2.0);
hold on
plot(tempo,hat_k_p_n2,'LineWidth',2.0);
hold on
plot(tempo_1,k_p*ones(1,endk+1),'LineStyle','--','LineWidth',2.0);
lgdf1 = legend('k_p estimado 1','k_p estimado 2','k_p estimado 3','k_p estimado nivel 2','k_p');
axis([0 36 0 7])
grid on
%plot(tempo_1,hat_k_p);
%hold on
%plot(tempo_1,k_p*ones(1,endk+1));

%plot(hat_a_p,hat_k_p,'LineWidth',2.0);
%hold on
%fig1 = figure(4);
figure(4)
grid on
plot(a_p,k_p,'Marker','x','LineWidth',2.0,'Color', [0 0 0],'LineStyle','none');
hold on
    line([a_p_M a_p_M a_p_m a_p_m a_p_M], ...
         [k_p_M k_p_m k_p_m k_p_M k_p_M], ...
                      'Color', [1 0 0],'LineWidth',2.0)
axis([0 5 0 7])
linha_anim = animatedline('LineWidth',3.0,'Color',[0.35 0.5 0],'LineStyle','-');
pontos_est = animatedline('MaximumNumPoints',1,'Marker','*','MarkerSize',12,'LineWidth',1.0,'Color', [0.2 0.3 0.4],'LineStyle','none');
skip = 10000;
   grid on

addpoints(pontos_est,hat_a_p_n2(1),hat_k_p_n2(1))
lgd = legend('a_p,k_p Verdadeiros','Região de Incerteza','Trajetória','a_p,k_p Estimados');
title(lgd,'0 Segundos')
for k=1:endk   
   addpoints(linha_anim,hat_a_p_n2(k),hat_k_p_n2(k));
   if floor(k/skip)==ceil(k/skip)
   addpoints(pontos_est,hat_a_p_n2(k),hat_k_p_n2(k))
   str_title = num2str(tempo(k));
   title(lgd, [str_title ' Segundos'])
   end
end

figure(5)
grid on
hold on
plot(tempo, e_1_f,'LineWidth',2.0)
plot(tempo, e_2_f,'LineWidth',2.0)
plot(tempo, e_3_f,'LineWidth',2.0)
plot(tempo, zeros(1,endk),'LineStyle','--','LineWidth',2.0)
legend('e_{1,f}','e_{2,f}','e_{3,f}');



end