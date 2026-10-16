"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/backup_of_make_struct.m

Old (backup) version of make_struct, written for a first-level-adaptation simulation
(fields t_inicial, t_final, h, Aw, Ap, bp, ordem, ...).

Porting notes:
- The MATLAB file declares ``function estrutura = make_struct(...)`` but, being saved as
  backup_of_make_struct.m, it is called as ``backup_of_make_struct``; that is the Python
  name.
- Bug kept: the original assigns fields from variables that are not arguments
  (alfa_barra, tempo, r, modelo_de_referencia, planta, theta_BARRA, modelos, endk), so in
  MATLAB it always fails with "Undefined function or variable 'alfa_barra'" after filling
  the first seven fields. The port raises NameError at the same point. The arguments
  P0, Plinha, cond_inicial_p, cond_inicial_est_p, teta_inicial, Beta, Pmax, minp are unused
  in the original too.
"""
from convert_struct import Struct


def backup_of_make_struct(t_inicial, t_final, h, Aw, Ap, bp, ordem,
                          P0, Plinha, cond_inicial_p, cond_inicial_est_p,
                          teta_inicial, Beta, Pmax, minp):
    estrutura = Struct()
    estrutura.t_inicial = t_inicial
    estrutura.t_final = t_final
    estrutura.h = h
    estrutura.Aw = Aw
    estrutura.Ap = Ap
    estrutura.bp = bp
    estrutura.ordem = ordem
    # Original: estrutura.alfa_barra = alfa_barra; ... (variables not defined here)
    raise NameError("backup_of_make_struct: 'alfa_barra' is undefined "
                    "(bug in the original MATLAB file, kept)")
