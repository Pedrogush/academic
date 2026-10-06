
it            = [10 1];
b             = [0 11];
p             = 20;
ref           = 100;
K             = 1e5;
theta_estrela = theta_fromf(it, b);
tadpt         = +Inf;
contador_laco = 0;
loop          = 1;
modelo_ref    = [0 1.4205*b(2) (it(1)+it(2))*1.25 it(2)*it(1)*1.5625];
theta_c_ini   = 0.7*([0 1.4205 -0.25 -5.625/11]);
gamma         = calc_gamma_0(K, ref, min(it), max(it), theta_estrela);
norma2_t      = +Inf;
passo_atual   = 1.1;
i             = 4;

%%1. COMO DEFINIR UMA FUNÇÃO DE CUSTO J PARA O TEMPO DE SIMULAÇÃO
%%2. COMO DEFINIR UMA COMBINAÇÃO DE CRITÉRIOS DE PARADA PARA A SIMULAÇÃO
%%2.a NORMA DE THETA_PONTO?
%%2.b NORMA DE THETA-THETA_PONTO?
%%2.c NORMA DE \Varepsilon? 
%%3. QUAL ALGORITMO DE OTIMIZAÇÃO USAR QUANDO NÃO SE CONHECE O ESPAÇO DE
%%   BUSCA (POR ENQUANTO: NUVEM DE PARTÍCULAS)
while p~=0
        while loop~=0           
             sim('MRACDireto_Trab1_Regra_MIT_Pedro')
             norma2_t_anterior = norma2_t;
             norma2_t = norma2_tmt(1)
             passo_anterior = passo_atual;
             passo_atual    = pass_exp(min(it), tadpt, contador_laco);
             if pass_exp(min(it), tadpt, contador_laco)<=1
                 contador_laco = 0
             end
             if fiddle_gamma4==1
                i=4 ;
             else if fiddle_gamma3==1
                i=3;                             
                 else
                     i=2;                               
                 end
             end
             if norma2_t<=norma2_t_anterior
             gamma(i) = gamma(i)*passo_atual
             end             
             if norma2_t>norma2_t_anterior
             gamma(i) = gamma(i)/passo_anterior
             contador_laco = contador_laco+1;
             loop=0;
             end
             tadpt = max(SimStopTime);

        loop=1;
    end
    p = p-1;
end
