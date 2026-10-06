function [hat_a_p_n2, hat_k_p_n2,tempo]= L2_4M_Filtragem_O1(t,h)

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
      hat_a_p(2,1)=4;
   hat_k_p(2,1)=1;
      hat_a_p(3,1)=4;
   hat_k_p(3,1)=6;
      hat_a_p(4,1)=0.5;
   hat_k_p(4,1)=6;
for i=1:4
   z_hat(i,1) = 0;
end
alfa(1,1)=0;
alfa(2,1)=0;
alfa(3,1)=0;
alfa_4(1)=1;

a_m = 4;
phi_1(1) = 0;
phi_2(1) = 0;
lambda=4;
e_i_f(4,1)=0;
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
   %z(k) = -a_p*phi_1(k)+k_p*phi_2(k);
   z(k) = y(k)-lambda*phi_1(k);
   for i=1:4
   z_hat(i,k) = -phi_1(k)*hat_a_p(i,k) + phi_2(k)*hat_k_p(i,k);
   e_i_f(i,k) = z_hat(i,k) - z(k);
   dot_hat_a_p(i,k) = e_i_f(i,k)*y(k);
   %dot_hat_a_p(i,k) = 0;
   hat_a_p(i,k+1) = hat_a_p(i,k) + h*dot_hat_a_p(i,k);
   dot_hat_k_p(i,k) = -e_i_f(i,k)*u(k);
   %dot_hat_k_p(i,k) = 0;
   hat_k_p(i,k+1) = hat_k_p(i,k) + h*dot_hat_k_p(i,k);
   end

   E_f(1,:,k) = [e_i_f(1,k)-e_i_f(4,k) e_i_f(2,k)-e_i_f(4,k) e_i_f(3,k)-e_i_f(4,k)];

   dot_alfa(:,k) = (-(E_f(1,:,k)'*E_f(1,:,k))*alfa(:,k) - E_f(1,:,k)'*e_i_f(4,k))';
   alfa(:,k+1) = alfa(:,k) + h*dot_alfa(:,k);
   %dot_alfa_4(k) = -ones(1,3)*dot_alfa(:,k);
   %alfa_4(k+1) = alfa_4(k) + h*dot_alfa_4(k);
   alfa_4(k+1) = 1-alfa(1,k+1)-alfa(2,k+1)-alfa(3,k+1);
   
   for i=1:4
   Bar_Theta(:,i,k) = [hat_a_p(i,k); hat_k_p(i,k)];
   end
   theta_p(:,k) = Bar_Theta(:,:,k)*([alfa(:,k); alfa_4(k)]);
   hat_a_p_n2(k) = alfa(1,k)*hat_a_p(1,k)+alfa(2,k)*hat_a_p(2,k)+alfa(3,k)*hat_a_p(3,k)+alfa_4(k)*hat_a_p(4,k);
   hat_k_p_n2(k) = alfa(1,k)*hat_k_p(1,k)+alfa(2,k)*hat_k_p(2,k)+alfa(3,k)*hat_k_p(3,k)+alfa_4(k)*hat_k_p(4,k);
   
end
% 
% figure(2)
% grid on
% plot(tempo_1,alfa)
% hold on
% plot(tempo_1,alfa_4)
% axis([0 36 -1 2])
%plot(tempo_1,y_hat);
%hold on
%plot(tempo_1,y);
%plot(tempo_1,hat_a_p);
%hold on
%plot(tempo_1,a_p*ones(1,endk+1));

%plot(tempo_1,hat_k_p);
%hold on
%plot(tempo_1,k_p*ones(1,endk+1));

%plot(hat_a_p,hat_k_p,'LineWidth',2.0);
% %hold on
% fig1 = figure(1);
% figure('units','normalized','outerposition',[0 0 1 1])
% plot(a_p,k_p,'Marker','x','MarkerSize',18,'LineWidth',2.0,'Color', [0 0 0],'LineStyle','none');
% hold on
%     line([a_p_M a_p_M a_p_m a_p_m a_p_M], ...
%          [k_p_M k_p_m k_p_m k_p_M k_p_M], ...
%                       'Color', [1 0 0],'LineWidth',2.0)
% axis([0 5 0 7])
% for i=1:4
% pontos_est(i) = animatedline('MaximumNumPoints',1,'Marker','*','MarkerSize',6,'LineWidth',1,'Color', [0.7 0 0],'LineStyle','none');
% addpoints(pontos_est(i),hat_a_p(i,1),hat_k_p(i,1))
% end
% linha_anim_n2 = animatedline('LineWidth',3.0,'Color',[0.7 0 0.3],'LineStyle','-');
% linha_anim_fec = animatedline('MaximumNumPoints',5,'LineWidth',3.0,'Color','yellow','LineStyle','-');
% pontos_est_n2 = animatedline('MaximumNumPoints',1,'Marker','*','MarkerSize',22,'LineWidth',2,'Color', [0.5 0.1 0.1],'LineStyle','none');
% 
% skip = 2000;
%    grid on
% addpoints(pontos_est_n2,hat_a_p_n2(1),hat_k_p_n2(1))
% addpoints(linha_anim_fec,[hat_a_p(:,1)' hat_a_p(1,1)],...
%                           [hat_k_p(:,1)' hat_k_p(1,1)])
% lgd = legend('a_p,k_p Verdadeiros','Região de Incerteza','Trajetória 1','Trajetória 2',...
%      'Trajetória 3','Trajetória Nível 2','Fecho Convexo','a_{1,sp},k_{1,sp}','a_{2,sp},k_{2,sp}',...
%      'a_{3,sp},k_{3,sp}','a_{n2,sp},k_{n2,sp}');
% title(lgd,'0 Segundos')
% %gif('L2_4M_Filtragem_O1.gif');
% for k=2:endk
%    addpoints(linha_anim_n2,hat_a_p_n2(k),hat_k_p_n2(k));
%    if floor(k/skip)==ceil(k/skip)
%    for i=1:4
%    addpoints(pontos_est(i),hat_a_p(i,1),hat_k_p(i,1))    
%    end
%    addpoints(pontos_est_n2,hat_a_p_n2(k),hat_k_p_n2(k));
%    addpoints(linha_anim_fec,[hat_a_p(1,k) hat_a_p(:,k)' hat_a_p(1,k)],...
%                           [hat_k_p(1,k) hat_k_p(:,k)' hat_k_p(1,k)])
%    str_title = num2str(tempo(k));
%    title(lgd, [str_title ' Segundos'])
%    drawnow
%    %gif
%    end
% end

end