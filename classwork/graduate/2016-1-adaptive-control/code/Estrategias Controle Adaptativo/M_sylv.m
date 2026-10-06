function M = M_sylv( n, q,QmRs,Zs_chapeu)
%Montagem da matriz de sylvester para resoluçao da equação diofantina a
%partir dos vetores de coeficientes dos polinômios da equação
%QmR*L+Z*P=A_estrela,dado o grau n da planta e o grau q do polinômio
%referente ao principio do modelo interno
n_Ls = n-1;
n_Ps = n+q-1;

for s1=1:(n_Ls+1);
    M(:,s1) = [zeros(s1-1,1) ;QmRs; zeros(n_Ls+1-s1,1)];
end
for s2=1:(n_Ps+1);
    M(:,s2+n) = [zeros(s2,1);Zs_chapeu;zeros(n+q-s2,1)];
end
end

