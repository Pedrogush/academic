"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/make_struct_MQ.m

Packs the parameters of the least-squares identifiers (MinQuad_*): t_inicial,
t_final, h, filter (Aw), Ap, bp, ordem, P0, Plinha, initial conditions, initial
theta, Beta, PMax, minp into a struct.

Porting notes:
- BUG KEPT: refA and refF are not included, although every MinQuad_* function
  unpacks 17 fields (…, Beta, Pmax, minp, refA, refF). A struct made with this
  function makes the MinQuad_* functions fail (MATLAB "Too many output
  arguments"; here ValueError from convert_struct). Add the two keys
  ``refA`` and ``refF`` to the returned dict to use it.
"""
from convert_names_to_fields import convert_names_to_fields


def make_struct_MQ(t_inicial, t_final, h, Aw, Ap, bp, ordem, P0, Plinha,
                   cond_inicial_p, cond_inicial_est_p, teta_inicial,
                   Beta, PMax, minp):
    estrutura = convert_names_to_fields(
        t_inicial, t_final, h, Aw, Ap, bp, ordem, P0, Plinha,
        cond_inicial_p, cond_inicial_est_p, teta_inicial, Beta, PMax, minp,
        names=["t_inicial", "t_final", "h", "Aw", "Ap", "bp", "ordem", "P0", "Plinha",
               "cond_inicial_p", "cond_inicial_est_p", "teta_inicial", "Beta", "PMax", "minp"])
    return estrutura
