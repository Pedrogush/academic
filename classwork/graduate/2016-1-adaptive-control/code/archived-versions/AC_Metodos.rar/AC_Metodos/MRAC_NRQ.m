function Estr_Dados_saida = MRAC_NRQ(Estr_Dados_Entrada)
%MRAC_NRQ, retorna uma estrutura de dados contendo resultados da simulação
%de um sistema de controle adaptativo por modelo de referência para uma
%planta de grau relativo qualquer dado como argumento uma estrutura de
%dados contendo os filtros, planta, referência expressa como soma de
%senoides, tempo de simulação, passo de integração fixo, condições iniciais
%e estimativas iniciais dos parâmetros, além dos ganhos adaptativos da matriz
%P(=Gamma) e do escalar gamma.


%algoritmo de conversão da  estrutura de dados colocada no argumento
[stoptime, h, filtroL, filtroM_num, filtroM_den, planta_numerador,  ...
 planta_denominador,cond_iniciais_p,cond_iniciais_m,referenciaEps,  ...   
 referenciaF,P,gamma,est_theta_inic,theta_2nm1_0,alfa,kp,km]                                ...
 = convert_struct(Estr_Dados_Entrada);

%número de passos da simulação
endk = floor(stoptime/h);

%matrizes relacionadas à planta, ~ representa uma variável cujo valor não
%importa e portanto não precisa ser assinalado, no caso a matriz D_p da
%planta que é sempre 0 pois a planta deve ter grau relativo pelo menos 1
[A_p,b_p,C_p,~] = tf2ss(kp*planta_numerador,planta_denominador);

%matrizes relacionadas aos filtros M(s) e L(s)
    %Matrizes de M(s)*L(s)
    [A_ML,b_ML,C_ML,D_ML] = tf2ss(km*filtroM_num.*filtroL,filtroM_den);
    %Matrizes de M(s)
    [A_M,b_M,C_M,D_M] = tf2ss(km*filtroM_num,filtroM_den);
    %Matrizes de L^-1(s)
    [A_Lm1,b_Lm1,C_Lm1,D_Lm1] = tf2ss(1,filtroL);
%Matriz canônica de LAMBDA, tal que det(sI-Lambda) = numerador de M(s)
     Lambda = can(fliplr(-filtroM_num));
    
%ordem da planta
n = length(planta_denominador) - 1;

%condições iniciais dos parâmetros
theta(:,1,1) = est_theta_inic;
x_p(:,1,1) = cond_iniciais_p;
x_m(:,1,1) = cond_iniciais_m;
u(1) = 0;
v_1(:,1,1) = zeros(n-1,1);
v_2(:,1,1) = zeros(n-1,1);
g(n-1,1) = 1;
L1tw(:,1,1) = zeros(n-1,1); 
tempo(endk) = 0;
tL1w_d(n-1,2*n,1) = 0;
theta_2nm1(1) = theta_2nm1_0;
e_a(1) = 0;
y_aumentado_interno(n,1,1) = 0;
for k=1:endk
    %tempo de simulação
   tempo(k+1) = tempo(k) + h;
   
   %sinal referência, tal que r(t) = a1*sin(f1*t)+...+an*sin(fn*t), onde os
   %vetores referenciaEps e referenciaF são respectivamente vetores linha e
   %coluna de mesmo tamanho. 
   r(k+1) = referenciaEps*cos(tempo(k)*referenciaF);
   
   %equações de espaço de estado do modelo de referência
   x_m_ponto(:,1,k) = A_M*x_m(:,1,k) + b_M*r(k);
   x_m(:,1,k+1) = x_m(:,1,k) + h*x_m_ponto(:,1,k);
   x_m_out(k+1) = C_M*x_m(:,1,k) + D_M*r(k);
   
   %equações de estado da planta
   x_p_ponto(:,1,k) = A_p*x_p(:,1,k) + b_p*u(k);
   x_p(:,1,k+1) = x_p(:,1,k) + h*x_p_ponto(:,1,k);
   x_p_out(k+1) = C_p*x_p(:,1,k+1);
   
   %geração dos filtrados da planta e do sinal de entrada
   v_1_ponto(:,1,k) = Lambda*v_1(:,1,k) + g*u(k);
   v_1(:,1,k+1) = v_1(:,1,k) + h*v_1_ponto(:,1,k);
   v_2_ponto(:,1,k) = Lambda*v_2(:,1,k) + g*x_p_out(k);
   v_2(:,1,k+1) = v_2(:,1,k) + h*v_2_ponto(:,1,k);
   
   %montagem do vetor w
   w(:,1,k+1) = [v_1(:,1,k+1); x_p(k+1); v_2(:,1,k+1); r(k+1)];
   
   %Geração de ya, sinal de saída aumentado, através de suas sub variáveis
   %devido ao fato de haver vários filtros encadeados, para implementar a
   %equação é necessário calcular suas parcelas separadamente em espaço de
   %estados
   
   %parcela = L^-1*theta_transposto*w
   L1tw_ponto(:,1,k) = A_Lm1*L1tw(:,1,k) + b_Lm1*        ...
                       transpose(theta(:,1,k))*w(:,1,k);
   L1tw(:,1,k+1) = L1tw(:,1,k) + h*L1tw_ponto(:,1,k);
   L1tw_out(k+1) = C_Lm1*L1tw(:,1,k+1)+                  ...
                   D_Lm1*transpose(theta(:,1,k))*w(:,1,k);
   
   %parcela = L^-1*w
   for d=1:length(w(:,1,k))
       tL1w_d_ponto(:,d,k) = A_Lm1*tL1w_d(:,d,k) + b_Lm1*w(d,1,k);
       tL1w_d(:,d,k+1) = tL1w_d(:,d,k) + h*tL1w_d_ponto(:,d,k);
       tL1w(d,1,k+1) = C_Lm1*tL1w_d(:,d,k+1)+D_Lm1*w(d,1,k);
   end
   
   %parcela = (L^-1*w) transposto * (L^-1*w)
   
   L1wTL1w(k+1) = transpose(tL1w(:,1,k+1))*tL1w(:,1,k+1);
   
   %parcela interna de y_aumentado:
   p_int(k+1) =                                                           ...
   theta_2nm1(k)*(L1tw_out(k+1)-transpose(theta(:,1,k))*tL1w(:,1,k+1))    ...
   +alfa*e_a(k)*L1wTL1w(k+1);
   
   %geração de y aumentado em espaço de estados
   y_aumentado_ponto(:,1,k) = A_ML*y_aumentado_interno(:,1,k) + b_ML*p_int(k);
   y_aumentado_interno(:,1,k+1) = y_aumentado_interno(:,1,k) + ...
                                  h*y_aumentado_ponto(:,1,k);
   y_aumentado(k+1) = C_ML*y_aumentado_interno(:,1,k+1) + D_ML*p_int(k+1);
   
   %erro de saída
   e_o(k) = x_p_out(k) - x_m_out(k);
   
   %erro de saída aumentado através da predição
   e_a(k+1) = e_o(k) - y_aumentado(k);
   
   %geração da lei adaptativa para os parâmetros do controlador
   theta_ponto(:,1,k) = -P*e_a(k)*tL1w(:,1,k);
   %atualização dos parâmetros
   theta(:,1,k+1) = theta(:,1,k) + h*theta_ponto(:,1,k);
   
   %geração da lei adaptativa adicional para theta_(2n+1)
   theta_2nm1_ponto(k) = gamma*e_a(k+1)*(L1tw_out(k+1) -           ...
                         transpose(theta(:,1,k))*tL1w(:,1,k+1)); ...
   %atualização do parâmetro theta_(2n+1)
   theta_2nm1(k+1) = theta_2nm1(k)+h*theta_2nm1_ponto(k);
                
   %lei de controle
   u(k+1) = transpose(theta(:,1,k+1))*w(:,1,k+1);
    
end
Estr_Dados_saida = make_struct_out(x_p_out,x_m_out,theta,e_o, ...
                                 u, r,tempo,endk);
end

