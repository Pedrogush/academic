function plot_adap_figures_Ident(func)

[teta, x, z1, z1e, eo, saida_planta,m,u] = convert_struct(func);
endk = length(u);
teta_acesso(:,:) = teta(:,1,:);
x_acesso = x(1:endk);
fig1 = figure;
set(fig1,'Position', [0, 0, 1024, 768])
subplot(3,2,1);
plot(x_acesso, z1, '-r','linewidth', 2);
hold on; 
plot(x_acesso, z1e, '-b','linewidth', 2); 
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('z1(t)', 'z1e(t)'); 
grid on;

subplot(3,2,2);
plot(x, teta_acesso,'linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 

for c=1:length(teta_acesso(:,1))
var_aux(c,:) = strcat('Theta{ }',num2str(c),'(t)');
end
leg1 = legend(var_aux);
set(leg1);
grid on;


subplot(3,2,3);
plot(x_acesso, eo, '-r','linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('e0(t)'); 
grid on;

subplot(3,2,4);
plot(x_acesso, saida_planta, '-r','linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('y(t)'); 
grid on;

subplot(3,2,5);
plot(x_acesso, m, '-r','linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('m(t)'); 
grid on;

subplot(3,2,6);
plot(x_acesso, u, '-r','linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('u(t)'); 
grid on;
end