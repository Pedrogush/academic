function narendra_2015_sim1()
%a31 considerado desconhecido
A_p = [-11.62 -15.73 9.47 ;...
       -15.38 -24.27 14.52;...
       -30.48 -47.92 27.89];
%b3 considerado desconhecido
b_p = [3;...
       4;...
       8];
%valores de referência constante
a31_bar = -10;
b3_bar  = 2;

%parâmetros a serem estimados:
alpha_estrela = -20.48;
beta_estrela = 6;

alpha1 = -10;
alpha2 = -10;
alpha3 = -70;
beta1  =  2;
beta2  =  24;
beta3  =  2;

b_m = [3; 4; 2];
A_m = [-11.62 -15.73 9.47 ;...
       -15.38 -24.27 14.52;...
       -10 -47.92 27.89];
Theta_BARRA = [alpha1 alpha2 alpha3; beta1 beta2 beta3];
h= 0.001;
for k=1:25000
    
x_p_ponto(:,k) = A_p*x_p(:,k) + b_p*u(k);
x_p(:,k+1)       = x_p(:,k)     + h*x_p_ponto(:,k);
for i=1:3
x_i_chapeu_ponto(:,i,k) = A_m*x_i(:,i,k) + b_m*u(k) + [0; 0; alpha1*x_p(3,i,k)+beta1*u(k)];
x_i(:,i,k+1)            = x_i(i,k) + h*x_i_chapeu_ponto(i,k);
end


end

end

end