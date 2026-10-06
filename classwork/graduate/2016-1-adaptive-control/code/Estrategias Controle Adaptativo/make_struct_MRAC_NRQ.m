function estrutura = make_struct_MRAC_NRQ(stoptime, h, filtroL,     ...
 filtroM_num, filtroM_den, planta_numerador,planta_denominador,     ...
 cond_iniciais_p,cond_iniciais_m,referenciaEps,referenciaF,P,gamma, ...
 kp,km)

estrutura.stoptime = stoptime; estrutura.h=h; estrutura.filtroL=filtroL; 
estrutura.filtroM_num = filtroM_num; estrutura.filtroM_den=filtroM_den; 
estrutura.planta_numerador=planta_numerador; 
estrutura.planta_denominador=planta_denominador; 
estrutura.cond_iniciais_p=cond_iniciais_p;
estrutura.cond_iniciais_m = cond_iniciais_m; 
estrutura.referenciaEps=referenciaEps; estrutura.referenciaF = referenciaF; 
estrutura.P = P; estrutura.gamma = gamma; 
estrutura.est_theta_inic = est_theta_inic;
estrutura.kp = kp; estrutura.km=km;
end