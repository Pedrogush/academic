function GradienteProj(t_inicial,t_final,h, Aw, Ap, bp, ordem, P, gama,cond_inicial_p,cond_inicial_est_p, teta_inicial)
%inicialização
n = (t_final-t_inicial)/h;
x(1) = t_inicial;
x_acesso(1) = x(1);
y(1) = x(1);
z_est(:,1) = cond_inicial_est_p;
fi1(ordem,1,1) = 0; 
fi2(ordem,1,1) = 0;
xps_p(ordem,1,1) = 0;
u(1) = 1; 
xps(:,1,1) = cond_inicial_p;
xps_p(:,1,1) = Ap*xps(:,1,1) + bp*u(1);
fi(:,1,1) = [fi1(:,1,1);fi2(:,1,1)];
ns2(1) = transpose(fi(:,1,1))*P*fi(:,1,1);
m(1) = sqrt(1+ns2(1));
teta(:,1,1) = teta_inicial;
z1e(1) = transpose(teta(:,1,1))*fi(:,1,1);

hlinha(ordem,1) = 1;
h_transposto = transpose(hlinha);
saida_planta(1) = h_transposto(1,:)*xps(:,1,1);
z1(1) = Aw(ordem,:)*z_est(:,1,1) + saida_planta(1);
eo(1) = (z1(1)-z1e(1))/m(1)^2;
l(ordem,1) = 0; l(1,1)=1;

bw(ordem,1) = 1;
teta_planta(:,1,1) = [0 1 3 2]; 
raio_prj(:,1,1) = [0.2 0.2 0.2 0.2];
A = teta(:,1,1)-teta_planta(:,1,1);
B = raio_prj(:,1,1);
g_teta(:,1,1)= power(A,A)-power(B,B);
g_teta_p(:,1,1) = 3*power(A,A);
esf_adaptativo = 0;
%fim da inicialização

for k=1:n
x(k+1) = x(k) + h;
u(k) = 1+0.3*sin(0.75*x(k))+0.4*sin(3*x(k)); %%sinal dentro do código, como tirar?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Medição de y(t);
%esp. estado
xps_p(:,1,k) = Ap*xps(:,1,k) + bp*u(k);
xps(:,1,k+1) = xps(:,1,k) + h*xps_p(:,1,k);
saida_planta(k) = h_transposto(1,:)*xps(:,1,k);

%Filtragem de y(t)

z_est_ponto(:,1,k) = Aw*z_est(:,1,k) + bw*(saida_planta(k));
z_est(:,1,k+1) = z_est(:,1,k) + h*z_est_ponto(:,1,k);
z1(k) = Aw(ordem,:)*z_est(:,1,k) + saida_planta(k);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Geração do Vetor fi;
fi1_p(:,1,k) = Aw*fi1(:,1,k) + l*u(k);
fi1(:,1,k+1) = fi1(:,1,k) + h*fi1_p(:,1,k);
fi2_p(:,1,k) = Aw*fi2(:,1,k) + l*saida_planta(k);
fi2(:,1,k+1) = fi2(:,1,k) + h*fi2_p(:,1,k);
fi(:,1,k) = [fi1(:,1,k); -fi2(:,1,k)];


%sinal de normalização
ns2(k) = transpose(fi(:,1,k))*P*fi(:,1,k);
m(k) = sqrt(1+ns2(k));

%lei adaptativa
z1e(k) = transpose(teta(:,1,k))*fi(:,1,k);
eo(k) = (z1(k)-z1e(k))/m(k)^2;

%Definição de g(teta(:,1,k)), função de projeção;

teta_planta(:,1,k) = [0 1 3 2]; 
raio_prj(:,1,k) = [0.2 0.2 0.2 0.2];

C = teta(:,1,k)-teta_planta(:,1,k);

g_teta_p(:,1,k) = 3*power(C,C);

g_teta(:,1,k+1) = g_teta(:,1,k) + h*g_teta_p(:,1,k);

n_tetas = norm(teta(:,1,k)-teta_planta(:,1,k));
n_raio_prj = norm(raio_prj(:,1,k));

if (n_tetas <= n_raio_prj) && (norm(transpose(gama*eo(k)*fi(:,1,k)))<=0) 
teta_p(:,1,k) = gama*eo(k)*fi(:,1,k);
else
teta_p(:,1,k) = gama*eo(k)*fi(:,1,k)-gama*g_teta_p(:,1,k)*((transpose(g_teta_p(:,1,k))*gama*g_teta_p(:,1,k))^-1)*transpose(g_teta_p(:,1,k))*gama*eo(k)*fi(:,1,k);
end
    
teta(:,1,k+1) = teta(:,1,k) + h*teta_p(:,1,k);

%saída do modelo da planta/ estimativa de z


%erro entre a saída a planta e a saída do modelo da planta
esf_adaptativo = esf_adaptativo + norm(teta_p(:,1,k));

end

teta_acesso(:,:) = teta(:,1,:);
x_acesso = x(1:n);
figure(1);
plot(x_acesso, z1, '-r','linewidth', 2);
hold on; 
plot(x_acesso, z1e, '-b','linewidth', 2); 
xlabel('tempo'); 
ylabel('amplitude'); 
legend('z1', 'z1e'); 
grid on;

figure(2);
plot(x, teta_acesso, '-r','linewidth', 2);
xlabel('tempo'); 
ylabel('amplitude'); 
grid on;

figure(3);
plot(x_acesso, eo, '-r','linewidth', 2);
xlabel('tempo'); 
ylabel('amplitude'); 
legend('erro'); 
grid on;

figure(4);
plot(x_acesso, saida_planta, '-r','linewidth', 2);
xlabel('tempo'); 
ylabel('amplitude'); 
legend('saida planta'); 
grid on;


figure(5);
plot(x_acesso, m, '-r','linewidth', 2);
xlabel('tempo'); 
ylabel('amplitude'); 
legend('sinal de normalizacao'); 
grid on;

figure(6);
plot(x_acesso, u, '-r','linewidth', 2);
xlabel('tempo'); 
ylabel('amplitude'); 
legend('entrada'); 
grid on;

xps(:,1,n)
z_est(:,n)
teta(:,1,n)
esf_adaptativo

end
