%função referente ao controle adaptativo de uma planta de grau qualquer
%usando o método do posicionamento de polos combinado com identificação dos
%parâmetros da planta via uso da adaptação de segundo nível do professor
%Narendra
%Aluno: Pedro Gushiken
%Orientador: Aldayr Dantas de Araújo

%O argumento da função é uma uma estrutura de dados contendo os polinômios
%da planta, modelo interno, polinômio A* desejado, filtro Lambda, a
%referência expressa como soma de senoides, tempo de simulação, passo de
%integração fixo, condições iniciais, modelos de identificação, estimativa
%inicial do vetor alfa e ganho da eq. adaptativa para alfa.

%Qm*R*L + Z*P = A_estrela, Qm é conhecido, R e Z são estimados, A_estrela é
%conhecido
function estrutura_de_saida = APPC( estrutura_de_entrada )

[t_inicial,t_final,h, Aw, ~, ~, ordem, P0,Plinha,cond_inicial_p, ...
cond_inicial_est_p, teta_inicial,Beta,~,~,refF,refA,Qms,Zs_estrela,...
Rs_estrela,A_estrela,Lambda] = convert_struct(estrutura_de_entrada);
[Ap,bp,Cp,Dp] = tf2ss(Zs_estrela, Rs_estrela);
q = length(Qms)-1;
n = length(Rs_estrela)-1;
P(:,:,1) = P0;teta(:,1,1) = teta_inicial;
tempo(1) = t_inicial;
z_est(:,1) = cond_inicial_est_p;
fi1(ordem,1,1) = 0; 
fi2(ordem,1,1) = 0;
x_p_ponto(ordem,1,1) = 0;
u(1) = 1; 
x_p(:,1,1) = cond_inicial_p;
    x_fil1(ordem,1,1) = 0;
    x_fil2(ordem,1,1) = 0;
x_p_ponto(:,1,1) = Ap*x_p(:,1,1) + bp*u(1);
fi(:,1,1) = [fi1(:,1,1);fi2(:,1,1)];
ns2(1) = transpose(fi(:,1,1))*Plinha*fi(:,1,1);
m(1) = sqrt(1+ns2(1));
teta(:,1,1) = teta_inicial;
z1e(1) = transpose(teta(:,1,1))*fi(:,1,1);
P(:,:,1)=P0;
hlinha(ordem,1) = 1;
h_transposto = transpose(hlinha);
x_p_out(1) = h_transposto(1,:)*x_p(:,1,1);
z1(1) = Aw(ordem,:)*z_est(:,1,1) + x_p_out(1);
eo(1) = (z1(1)-z1e(1))/m(1)^2;
l(ordem,1) = 0; l(1,1)=1;
bw(ordem,1) = 1;
e(1) = 0;
x_fil1_out(1)=0;
x_fil2_out(1)=0;
x_c_out(1)=0;

endk = (t_final-t_inicial)/h;
for k=1:endk
   
tempo(k+1) = tempo(k) + h;
r(k+1) = refA*cos(tempo(k)*refF);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%algoritmo de estimação
%Filtragem de y(t)
z_est_ponto(:,1,k) = Aw*z_est(:,1,k) + bw*x_p_out(k);
z_est(:,1,k+1) = z_est(:,1,k) + h*z_est_ponto(:,1,k);
z1(k) = Aw(ordem,:)*z_est(:,1,k) + x_p_out(k);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Geração do Vetor fi;
fi1_p(:,1,k) = Aw*fi1(:,1,k) + l*u(k);
fi1(:,1,k+1) = fi1(:,1,k) + h*fi1_p(:,1,k);
fi2_p(:,1,k) = Aw*fi2(:,1,k) + l*x_p_out(k);
fi2(:,1,k+1) = fi2(:,1,k) + h*fi2_p(:,1,k);
fi(:,1,k) = [fi1(:,1,k); -fi2(:,1,k)];


%sinal de normalização
ns2(k) = transpose(fi(:,1,k))*Plinha*fi(:,1,k);
m(k) = sqrt(1+ns2(k));

%Cálculo da matriz de ganhos adaptativos P
P_ponto(:,:,k) = Beta*P(:,:,k)-P(:,:,k)*fi(:,1,k)*transpose(fi(:,1,k))*P(:,:,k)/m(k)^2;
P(:,:,k+1) = P(:,:,k) + h*P_ponto(:,:,k);


%lei adaptativa
z1e(k) = transpose(teta(:,1,k))*fi(:,1,k);
eo(k) = (z1(k)-z1e(k))/m(k)^2;
teta_p(:,1,k) = P(:,:,k)*eo(k)*fi(:,1,k);

teta(:,1,k+1) = teta(:,1,k) + h*teta_p(:,1,k);
Zs_chapeu(:,1) = teta(1:n,1,k+1);
Rs_chapeu(:,1) = [1;teta(n+1:2*n,1,k+1)];


%fim do algoritmo de estimação

%APPC
    QmRs=conv(Qms,Rs_chapeu);
    M = M_sylv(n,q,QmRs,Zs_chapeu);
    if abs(det(M))>=0.1
    coefs = (M^-1)*A_estrela;
    end
    Ls = coefs(1:n);
    Ps = coefs(n+1:2*n+q);
     
    [Afil1,bfil1,Cfil1,Dfil1] = tf2ss((Ps)',(Lambda)');

    [Afil2,bfil2,Cfil2,Dfil2] = tf2ss((Lambda-conv(Qms,Ls))',(Lambda)');

    x_fil1_ponto(:,1,k) = Afil1*x_fil1(:,1,k) + bfil1*e(k);
    x_fil1(:,1,k+1) = x_fil1(:,1,k)+h*x_fil1_ponto(:,1,k);
    x_fil1_out(k+1) = Cfil1*x_fil1(:,1,k+1) + Dfil1*x_fil1_out(k);
    
    x_fil2_ponto(:,1,k) = Afil2*x_fil2(:,1,k) + bfil2*u(k);
    x_fil2(:,1,k+1) = x_fil2(:,1,k)+h*x_fil2_ponto(:,1,k);
    x_fil2_out(k+1) = Cfil2*x_fil2(:,1,k+1) + Dfil2*u(k);
    
    u(k+1) = x_fil2_out(k+1) + x_fil1_out(k+1);
    
    x_p_ponto(:,1,k) = Ap*x_p(:,1,k) + bp*u(k);
    x_p(:,1,k+1) = x_p(:,1,k)+h*x_p_ponto(:,1,k);
    x_p_out(k+1) = Cp*x_p(:,1,k+1) + Dp*u(k);
    
    e(k+1) = r(k+1) - x_p_out(k+1);
    
end
estrutura_de_saida = make_struct_out                        ...
        (teta, tempo, z1, z1e, e, x_p_out,m,u);


end

