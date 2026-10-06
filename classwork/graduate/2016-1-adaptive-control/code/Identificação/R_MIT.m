%Regra do MIT Ordem N, sem zeros, b conhecido
%Precisa de um pouco de trabalho
%
function R_MIT(stoptime, h, planta, modelo_de_referencia, cond_iniciais_p,cond_iniciais_m,referencia,Gamma,teta0)

endk = floor(stoptime/h);

%Prealocação
u(endk) = 0; theta(1:length(cond_iniciais_m),1,endk)=0; x(1:length(cond_iniciais_m),1,endk)=0; r(endk)=0;
k_T(1:length(cond_iniciais_m),endk) = 0; x_ponto(1:length(cond_iniciais_m),1,endk)=0; y(endk)=0; y_m(endk)=0;
x_m_ponto(1:length(cond_iniciais_m),1,endk)=0; e_o(endk)=0; x_filtrado_ponto(1:length(cond_iniciais_m),length(cond_iniciais_m),endk)=0;
x_filtrado(1:length(cond_iniciais_m),length(cond_iniciais_m),endk)=0;theta_ponto(1:length(cond_iniciais_m),1,endk)=0;tempo(endk) = 0;
y_filtrado(1:length(cond_iniciais_m),endk)=0;

%Inicialização
x_m(:,1,1) = cond_iniciais_m;
x(:,1,1) = cond_iniciais_p;
theta(:,1,1) =teta0;
Am = modelo_de_referencia;
A = planta;
b = [0; 0; 1];
bm=b;
h_t = [0 0 1];


for k=1:endk
    tempo(k+1) = tempo(k) + h;
    
    %referencia
r(k+1) = referencia + sin(tempo(k));

%lei de controle
k_T(:,k) = transpose(Am(2,:)) - theta(:,1,k);
u(k) = r(k) + transpose(k_T(:,k))*x(:,1,k);

%planta
x_ponto(:,1,k) = A*x(:,1,k)+b*u(k);
x(:,1,k+1) = x(:,1,k) + h*x_ponto(:,1,k);
y(k) = h_t*x(:,1,k);

%modelo de referência
x_m_ponto(:,1,k) = Am*x_m(:,1,k) + bm*r(k);
x_m(:,1,k+1)= x_m(:,1,k) + h*x_m_ponto(:,1,k);
y_m(k) = h_t*x_m(:,1,k);

%erro de saída
e_o(k) = y(k) - y_m(k);

%filtrado das variáveis de estado

for j=1:length(x(:,1,k))
x_filtrado_ponto(:,j,k) = Am*x_filtrado(:,j,k) + bm*x(j,1,k);
x_filtrado(:,j,k+1) = x_filtrado(:,j,k) + h*x_filtrado_ponto(:,j,k);
y_filtrado(j,k)=h_t*x_filtrado(:,j,k);
end
%leis adaptativas
theta_ponto(:,1,k) = Gamma*e_o(k)*y_filtrado(:,k);
theta(:,1,k+1) = theta(:,1,k)+h*theta_ponto(:,1,k);

end

figure(1)
plot(tempo,x_m(1,:),'Color',[0 0 0],'LineWidth',2.0);
hold on, grid on
plot(tempo,x(1,:),'Color',[1 0 0],'LineWidth',2.0, 'LineStyle', ':');
hold on, grid on
plot(tempo,r, 'Color',[0 0 1],'LineWidth',2.0);
hold on, grid on
leg1 = legend('Modelo, x_m(1)','Planta, x_p(1)','Referencia');
set(leg1,'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 14);
ylabel('Amplitude', 'FontSize', 14);
title('Saída do sistema (Método Diferencial)', 'FontSize', 14);
axis1 = gca;
set(axis1, 'FontSize', 14); 


end