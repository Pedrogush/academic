"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/AC_Metodos.rar/AC_Metodos/make_struct_out.m

Packs x_p_out, x_m_out, theta (squeezed), e_o, u, r, tempo, endk into a struct
(dict, field order kept) for the MRAC_NRQ / Astrom_Hagglund plot functions.
(Same as "Estrategias Controle Adaptativo/make_struct_out_MRAC.m"; not the
identification make_struct_out of the "Identificação" folder.)

Porting notes:
- theta given as (npar, 1, K) is stored as (npar, K) (``theta(:,:) = theta(:,1,:)``);
  a scalar theta (Astrom_Hagglund passes 0) is stored as is.
"""
import numpy as np


def make_struct_out(x_p_out, x_m_out, theta, e_o, u, r, tempo, endk):
    estrutura = {}
    estrutura["x_p_out"] = x_p_out
    estrutura["x_m_out"] = x_m_out
    theta = np.asarray(theta)
    estrutura["theta"] = theta[:, 0, :] if theta.ndim == 3 else theta
    estrutura["e_o"] = e_o
    estrutura["u"] = u
    estrutura["tempo"] = tempo
    estrutura["r"] = r
    estrutura["endk"] = endk
    return estrutura
