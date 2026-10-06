function [hat_a_p, hat_k_p, tempo_1]=L1_Filtragem_O1(t,h)

endk = t/h;
y(1) = 0.2;
y_hat(1) = 0;
a_p = 1.5;
a_p_M = 4;
a_p_m = 0.5;
k_p_M = 6;
k_p_m = 1;
k_p = 3;
lambda = 2.2261;
hat_a_p(1) = 0.5;
hat_k_p(1) = 6;
phi_1(1) = 0.2;
phi_2(1) = 0;
tilde_kp1 = hat_k_p(1,1)-k_p;
tilde_ap1 = hat_a_p(1,1)-a_p;
   z(1) = y(1) - lambda*phi_1(1);
   z_hat(1) = -hat_a_p(1)*phi_1(1) + hat_k_p(1)*phi_2(1);
e_1_f(1) = z(1)-z_hat(1);
lyap1(1) = (e_1_f(1)^2+tilde_kp1^2+tilde_ap1^2)*0.5;
lyap1v(1) = lyap1(1);
lyap2v(1) = lyap1(1);
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
   z_hat(k) = -hat_a_p(k)*phi_1(k) + hat_k_p(k)*phi_2(k);
   e_1_f(k) = z_hat(k) - z(k);
   dot_hat_a_p(k) = e_1_f(k)*y(k);
   hat_a_p(k+1) = hat_a_p(k) + h*dot_hat_a_p(k);
   dot_hat_k_p(k) = -e_1_f(k)*u(k);
   hat_k_p(k+1) = hat_k_p(k) + h*dot_hat_k_p(k);
   
   
   vy(k) = y(k)*phi_1(k);
   vu(k) = u(k)*phi_2(k);
   tilde_kp1 = hat_k_p(1,k)-k_p;
   tilde_ap1 = hat_a_p(1,k)-a_p;
   lyap1(k) = (e_1_f(1,k)^2+tilde_kp1^2+tilde_ap1^2)*0.5;
   dot_lyap1v(k) = -(lambda+vy(k)+vu(k))*(e_1_f(k)^2);
   lyap1v(k+1) = lyap1v(k) + h*dot_lyap1v(k);
   dot_lyap2v(k) = -lambda*(e_1_f(k)^2);
   lyap2v(k+1) = lyap2v(k) + h*dot_lyap2v(k);
end

%figure(1)
%plot(0.5,6,'Marker','*','LineWidth',3.0,'Color',[0.5 0 0.5],'LineStyle','none');
%hold on
%grid on
%plot(a_p,k_p,'Marker','x','LineWidth',2.0,'Color', [0 0 0],'LineStyle','none');
%hold on
%    line([a_p_M a_p_M a_p_m a_p_m a_p_M], ...
%         [k_p_M k_p_m k_p_m k_p_M k_p_M], ...
%                      'Color', [1 0 0],'LineWidth',2.0)
%axis([a_p_m a_p_M k_p_m k_p_M])
%linha_anim = animatedline('LineWidth',3.0,'Color',[0.35 0.5 0],'LineStyle','-');
%pontos_est = animatedline('MaximumNumPoints',1,'Marker','*','MarkerSize',12,'LineWidth',1.0,'Color', [0.2 0.3 0.4],'LineStyle','none');
%skip = 10000;
%   grid on

%addpoints(pontos_est,hat_a_p(1),hat_k_p(1))
%lgd = legend('Estimativas Iniciais','a_p,k_p Verdadeiros','Região de Incerteza','Trajetória','a_p,k_p Estimados');
%title(lgd,'0 Segundos')
%for k=1:endk   
%   addpoints(linha_anim,hat_a_p(k),hat_k_p(k));
%   if floor(k/skip)==ceil(k/skip)
%   addpoints(pontos_est,hat_a_p(k),hat_k_p(k))
%   str_title = num2str(tempo(k));
%   title(lgd, [str_title ' Segundos'])
%   end
%end
%set(gca,'fontsize',20)
%title('Modelo por Regressão Linear')

%figure(5)
%grid on
%hold on
%plot(tempo, e_1_f,'LineWidth',2.0)
%plot(tempo, zeros(1,endk),'LineStyle','--','LineWidth',2.0)
%legend('e_{1,f}');

%hold on
%plot(tempo_1,y);
%plot(tempo_1,hat_a_p);
%hold on
%plot(tempo_1,a_p*ones(1,endk+1));

%plot(tempo_1,hat_k_p);
%hold on
%plot(tempo_1,k_p*ones(1,endk+1));

%plot(hat_a_p,hat_k_p,'LineWidth',2.0);
%hold on
%fig1 = figure(1);
%plot(a_p,k_p,'Marker','x','LineWidth',2.0,'Color', [0 0 0],'LineStyle','none');
%hold on
%    line([a_p_M a_p_M a_p_m a_p_m a_p_M], ...
%         [k_p_M k_p_m k_p_m k_p_M k_p_M], ...
%                      'Color', [1 0 0],'LineWidth',2.0)
%axis([0 5 0 7])
%linha_anim = animatedline('LineWidth',3.0,'Color',[0.35 0.5 0],'LineStyle','-');
%pontos_est = animatedline('MaximumNumPoints',1,'Marker','*','MarkerSize',12,'LineWidth',1.0,'Color', [0.2 0.3 0.4],'LineStyle','none');
%skip = 10000;
%   grid on
%
%addpoints(pontos_est,hat_a_p(1),hat_k_p(1))
%lgd = legend('a_p,k_p Verdadeiros','Região de Incerteza','Trajetória','a_p,k_p Estimados');
%title(lgd,'0 Segundos')
%gif('L1_Filtragem_O1_Anim_cmp.gif');
%for k=1:endk   
%   addpoints(linha_anim,hat_a_p(k),hat_k_p(k));
%   if floor(k/skip)==ceil(k/skip)
%   addpoints(pontos_est,hat_a_p(k),hat_k_p(k))
%   str_title = num2str(tempo(k));
%   title(lgd, [str_title ' Segundos'])
%   drawnow
%   gif
%   end
%end

end