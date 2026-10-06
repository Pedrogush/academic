%Função referente a simulação de um sistema de identificação usando o
%método do gradiente puro com projeção. 
%Alunos: Pedro Gushiken e Isaac Dantas
%Orientador: Aldayr Dantas de Araújo

%O argumento da função é uma estrutura de dados contendo tempo inicial de
%simulação, tempo final, passo de integração, matriz canônica A do filtro,
%matriz canônica A da planta b da planta, a ordem do sistema, a matriz P do
%sinal de normalização, a matriz gama dos ganhos adaptativos, as condições
%iniciais da planta, condições iniciais para a estimativa da saída da
%planta, estimativas iniciais dos parâmetros teta, -fator de esquecimento-,
%amplitudes dos sinais de referência e frequência em radianos dos sinais de
%referência. Embora o fator de esquecimento não seja usado na simulação,
%sua inclusão na estrutura de dados compatibiliza o uso de uma mesma
%estrutura de dados para as funções de gradiente com função de custo
%integral

%a função retorna uma estrutura de dados contendo a evolução no tempo dos
%sinais considerados relevantes. para plotar use
%plot_adap_figures_Ident(estrutura_de_saida)


function estrutura_de_saida = Gradiente_Proj(estrutura_de_entrada)

%conversão da estrutura de dados para variáveis internas da função
[t_inicial,t_final,h, Aw, Ap, bp, ordem, P, gama,cond_inicial_p, ...
cond_inicial_est_p, teta_inicial,~,refA,refF] = convert_struct(estrutura_de_entrada);



%inicialização
n = (t_final-t_inicial)/h;
tempo(1) = t_inicial;
x_acesso(1) = tempo(1);
y(1) = tempo(1);
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
%fim da inicialização

%inicio do laço
for k=1:n
%atualização da variável referente ao tempo de simulação
tempo(k+1) = tempo(k) + h;

%geração do sinal de referência
u(k) = refA*cos(tempo(k)*refF);

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

%projeção
if (n_tetas <= n_raio_prj) && (norm(transpose(gama*eo(k)*fi(:,1,k)))<=0) 
teta_p(:,1,k) = gama*eo(k)*fi(:,1,k);
else
teta_p(:,1,k) = gama*eo(k)*fi(:,1,k)-gama*g_teta_p(:,1,k)*((transpose(g_teta_p(:,1,k))*gama*g_teta_p(:,1,k))^-1)*transpose(g_teta_p(:,1,k))*gama*eo(k)*fi(:,1,k);
end
    
teta(:,1,k+1) = teta(:,1,k) + h*teta_p(:,1,k);

%saída do modelo da planta/ estimativa de z

end

%conversão dos dados relevantes para a estrutura de saída
estrutura_de_saida = make_struct_out                        ...
        (teta, tempo, z1, z1e, eo, saida_planta,m,u);


end
