
it            = [10 1]
b             = [0 10]
p             = 20
ref           = 100
K             = 1
theta_estrela = theta_fromf(it, b)
tadpt         = +Inf
contador_laco = 0
loop          = 1
modelo_ref    = [0 1.5625*b(2) (it(1)+it(2))*1.25 it(2)*it(1)*1.25]
theta_c_ini   = 0*(-theta_estrela+modelo_ref)
gamma         = calc_gamma_0(K, ref, min(it), max(it), theta_estrela)


while p~=0
    for i=1:length(theta_estrela)
        while loop~=0           
             sim('MRACDiretoTrab1AutoCriterio2')
             temposim = max(SimStopTime)  
             if temposim<tadpt
             gamma(i) = gamma(i)*pass_exp(min(it), tadpt, contador_laco)
             end             
             if temposim>=tadpt
             gamma(i) = gamma(i)/pass_exp(min(it), tadpt, contador_laco)
             loop=0
             end
             tadpt = max(SimStopTime)
             contador_laco = contador_laco+1
        end
        contador_laco = 0
        loop=1
    end
    p = p-1
end
