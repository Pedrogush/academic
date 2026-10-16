"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/make_struct_Grad.m

Packs the parameters of the gradient identifiers (Gradiente, Gradiente_FCI,
Gradiente_Proj): t_inicial, t_final, h, filter (Aw), Ap, bp, ordem, P, gama,
initial conditions, initial theta, beta, refA, refF, into a struct whose field
order is the one those functions unpack.

Porting notes:
- Struct = dict; field names given explicitly (see convert_names_to_fields).
"""
from convert_names_to_fields import convert_names_to_fields


def make_struct_Grad(t_inicial, t_final, h, Aw, Ap, bp, ordem, P, gama, cond_inicial_p,
                     cond_inicial_est_p, teta_inicial, beta, refA, refF):
    estrutura = convert_names_to_fields(
        t_inicial, t_final, h, Aw, Ap, bp, ordem, P, gama, cond_inicial_p,
        cond_inicial_est_p, teta_inicial, beta, refA, refF,
        names=["t_inicial", "t_final", "h", "Aw", "Ap", "bp", "ordem", "P", "gama",
               "cond_inicial_p", "cond_inicial_est_p", "teta_inicial", "beta", "refA", "refF"])
    return estrutura
