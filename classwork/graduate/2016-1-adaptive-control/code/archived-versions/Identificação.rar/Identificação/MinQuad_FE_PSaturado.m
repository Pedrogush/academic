%Função referente a simulação de um sistema de identificação usando o
%método do mínimos quadrados com fator de esquecimento e matriz de ganhos
%adaptativos saturada.
%Alunos: Pedro Gushiken e Isaac Dantas
%Orientador: Aldayr Dantas de Araújo

%O argumento da função é uma estrutura de dados contendo tempo inicial de
%simulação, tempo final, passo de integração, matriz canônica A do filtro,
%matriz canônica A da planta b da planta, a ordem do sistema, a matriz P0
%dos ganhos adaptativos iniciais , a matriz Plinha do sinal de
%normalização, as condições iniciais da planta, condições iniciais para a
%estimativa da saída da planta, estimativas iniciais dos parâmetros teta,
%fator de esquecimento, amplitudes dos sinais de referência e frequência em
%radianos dos sinais de referência.

%a função retorna uma estrutura de dados contendo a evolução no tempo dos
%sinais considerados relevantes. para plotar use
%plot_adap_figures_Ident(estrutura_de_saida)
function estrutura_de_saida = MinQuad_FE_PSaturado(estrutura_de_entrada)

[t_inicial,t_final,h, Aw, Ap, bp, ordem, P0,Plinha,cond_inicial_p, ...
cond_inicial_est_p, teta_inicial,Beta,Pmax,~,refA,refF] = convert_struct(estrutura_de_entrada);

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
ns2(1) = transpose(fi(:,1,1))*Plinha*fi(:,1,1);
m(1) = sqrt(1+ns2(1));
teta(:,1,1) = teta_inicial;
z1e(1) = transpose(teta(:,1,1))*fi(:,1,1);
P(:,:,1)=P0;
hlinha(ordem,1) = 1;
h_transposto = transpose(hlinha);
saida_planta(1) = h_transposto(1,:)*xps(:,1,1);
z1(1) = Aw(ordem,:)*z_est(:,1,1) + saida_planta(1);
eo(1) = (z1(1)-z1e(1))/m(1)^2;
l(ordem,1) = 0; l(1,1)=1;
esf_adaptativo = 0;
bw(ordem,1) = 1;
%fim da inicialização
P_ponto(2*ordem,2*ordem,n) = 0; 
for k=1:n
tempo(k+1) = tempo(k) + h;
u(k) = refA*cos(tempo(k)*refF); %%sinal dentro do código, como tirar?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Medição de y(t);
%esp. estado
xps_p(:,1,k) = Ap*xps(:,1,k) + bp*u(k);
xps(:,1,k+1) = xps(:,1,k) + h*xps_p(:,1,k);
saida_planta(k) = h_transposto(1,:)*xps(:,1,k);

%Filtragem de y(t)

z_est_ponto(:,1,k) = Aw*z_est(:,1,k) + bw*saida_planta(k);
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
ns2(k) = transpose(fi(:,1,k))*Plinha*fi(:,1,k);
m(k) = sqrt(1+ns2(k));

%Cálculo da matriz de ganhos adaptativos P
P_ponto(:,:,k) = Beta*P(:,:,k)-P(:,:,k)*fi(:,1,k)*transpose(fi(:,1,k))*P(:,:,k)/m(k)^2;
if norm(P(:,:,k))>=Pmax
   P_ponto(:,:,k) = 0; 
end
P(:,:,k+1) = P(:,:,k) + h*P_ponto(:,:,k);


%lei adaptativa
z1e(k) = transpose(teta(:,1,k))*fi(:,1,k);
eo(k) = (z1(k)-z1e(k))/m(k)^2;
teta_p(:,1,k) = P(:,:,k)*eo(k)*fi(:,1,k);

teta(:,1,k+1) = teta(:,1,k) + h*teta_p(:,1,k);

end
estrutura_de_saida = make_struct_out                        ...
        (teta, tempo, z1, z1e, eo, saida_planta,m,u);

end
