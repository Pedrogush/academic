function estrutura = make_struct(t_inicial,t_final,h, Aw, Ap, bp, ordem,     ...
                                 P0,Plinha,cond_inicial_p,cond_inicial_est_p,...
                                 teta_inicial,Beta,Pmax,minp )
estrutura.t_inicial = t_inicial; estrutura.t_final=t_final; 
estrutura.h=h; estrutura.Aw = Aw; estrutura.Ap=Ap; estrutura.bp=bp;
estrutura.ordem=ordem;
estrutura.alfa_barra=alfa_barra; estrutura.tempo=tempo; estrutura.r=r;
estrutura.modelo_de_referencia = modelo_de_referencia; 
estrutura.planta=planta; estrutura.theta_BARRA = theta_BARRA; 
estrutura.modelos = modelos; estrutura.endk = endk; 
end