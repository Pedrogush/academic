function plot_adap_figures_AstHagg(func)

[x_p_out, ~, ~, e0, u, r,tempo,endk] = convert_struct(func);

x_acesso = tempo(1:endk);
fig1 = figure;
set(fig1,'Position', [0, 0, 1024, 768])
subplot(3,1,1);

plot(tempo, x_p_out, '-r','linewidth', 2);
hold on; 
plot(tempo, r, '-b','linewidth', 2); 
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('saída da planta', 'referência'); 
grid on;

subplot(3,1,2);
plot(tempo, e0,'linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 
leg1 = legend('erro de saída');
set(leg1);
grid on;


subplot(3,1,3);
plot(x_acesso, u, '-r','linewidth', 2);
xlabel('Tempo'); 
ylabel('Amplitude'); 
legend('entrada da planta'); 
grid on;

end