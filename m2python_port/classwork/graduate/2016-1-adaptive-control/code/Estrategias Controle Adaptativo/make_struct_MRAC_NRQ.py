"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/make_struct_MRAC_NRQ.m

Packs the MRAC_NRQ simulation parameters (stop time, step, filters L(s) and
M(s), plant numerator/denominator, initial conditions, reference, adaptive
gains P and gamma, gains kp and km) into a struct (dict, field order kept).

Porting notes:
- BUG KEPT: the MATLAB code assigns ``estrutura.est_theta_inic = est_theta_inic``
  although ``est_theta_inic`` is not an argument, so calling it in MATLAB always
  errors ("Undefined function or variable 'est_theta_inic'"). It also omits
  ``theta_2nm1_0`` and ``alfa``, which MRAC_NRQ unpacks between est_theta_inic
  and kp. The positional signature is kept; to make the function usable,
  optional keyword-only arguments ``est_theta_inic``, ``theta_2nm1_0`` and
  ``alfa`` were added. Without ``est_theta_inic`` a NameError is raised (same
  failure as MATLAB). When ``theta_2nm1_0`` and ``alfa`` are given they are
  inserted right after est_theta_inic, producing the field order MRAC_NRQ needs.
"""


def make_struct_MRAC_NRQ(stoptime, h, filtroL, filtroM_num, filtroM_den,
                         planta_numerador, planta_denominador, cond_iniciais_p,
                         cond_iniciais_m, referenciaEps, referenciaF, P, gamma,
                         kp, km, *, est_theta_inic=None, theta_2nm1_0=None, alfa=None):
    estrutura = {}
    estrutura["stoptime"] = stoptime
    estrutura["h"] = h
    estrutura["filtroL"] = filtroL
    estrutura["filtroM_num"] = filtroM_num
    estrutura["filtroM_den"] = filtroM_den
    estrutura["planta_numerador"] = planta_numerador
    estrutura["planta_denominador"] = planta_denominador
    estrutura["cond_iniciais_p"] = cond_iniciais_p
    estrutura["cond_iniciais_m"] = cond_iniciais_m
    estrutura["referenciaEps"] = referenciaEps
    estrutura["referenciaF"] = referenciaF
    estrutura["P"] = P
    estrutura["gamma"] = gamma
    if est_theta_inic is None:
        raise NameError("Undefined function or variable 'est_theta_inic' "
                        "(bug in the original make_struct_MRAC_NRQ.m; pass est_theta_inic=...)")
    estrutura["est_theta_inic"] = est_theta_inic
    if theta_2nm1_0 is not None:
        estrutura["theta_2nm1_0"] = theta_2nm1_0
    if alfa is not None:
        estrutura["alfa"] = alfa
    estrutura["kp"] = kp
    estrutura["km"] = km
    return estrutura
