"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/make_struct_out_MRAC.m

Packs the MRAC simulation outputs (plant output, model output, controller
parameters, output error, control, reference, time, number of steps) into a
struct (dict, field order kept) for plot_adap_figures_MRAC_NRQ.

Porting notes:
- ``theta`` arrives as an array of shape (npar, 1, K) (MATLAB 3-D) and is stored
  squeezed to (npar, K), like ``estrutura.theta(:,:) = theta(:,1,:)``. A scalar
  theta (as passed by Astrom_Hagglund) is stored as a scalar.
"""
import numpy as np


def make_struct_out_MRAC(x_p_out, x_m_out, theta, e_o, u, r, tempo, endk):
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
