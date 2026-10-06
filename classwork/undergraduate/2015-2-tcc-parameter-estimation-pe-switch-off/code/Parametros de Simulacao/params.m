%variáveis relevantes:
ref                             = 1
it_MRAC_MIT                     = [10 1]
it                              = it_MRAC_MIT
b_MRAC_MIT                      = [0 11]
b                               = b_MRAC_MIT
a1                              = b_MRAC_MIT(2)
a2                              = it(1)*it(2)
a3                              = it(1)+it(2)
theta_c_estrela_MRAC_DIRETO_MIT = [0 1.5625 -0.5114 -0.25]
md_ref_MRAC_DIRETO_MIT          = [0 1.5625 -1.25*a2 -1.5625*a3]
gamma                           = [0 1 1 1] %mit
%gamma mit traj con 1e4seg      = 1e-3*[0    0.5000    0.4520    0.0700]
%gamma                          = 1e-3*[0 5 4.52 0.7] %grad
theta_c_ini                     = 0.85*theta_c_estrela_MRAC_DIRETO_MIT
%u = theta_1*r + theta_2*y + theta_3*y_ponto
%y2ponto = theta_1p*u - theta_2p*y - theta_3p*y_ponto 
%ym2ponto = theta_1m*r + theta_2m*y + theta_3m*y_ponto
%y2ponto = theta_1p*(theta_1*r+theta_2*y+theta_3*y_ponto) - theta_2p*y -
%theta_3p*y_ponto = t1p*t1*r + (t1p*t2-t2p)*y + (t1p*t3-t3p)*y_ponto 
%t1p*t1=t1m = 1.5625*t1p; t1* = 1.5625
%t1p*t2-t2p = t2m = -1.5625*t2p; t2* = -0.5625*t2p/t1p = -0.5114
%t1p*t3-t3p = t3m = -1.25*t3p = -0.25
