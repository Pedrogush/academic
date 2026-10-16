"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2A_Dif_ModDes_ModEnm1.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Variant of L2A_Dif_ModDes (fixed models, differential alpha law with gain gamma, PE
switch-off while eta <= 1e-4) that additionally runs an "(n+1)-th"/estimated-plant
model x_p_chapeu_dot = A_p_chapeu x_p + b u with A_p_chapeu = can(THETA_BARRA*alpha_bar),
and plots its state (figure 1) and the estimation error e_est = x_p_chapeu - x_p
(figure 8). In this file the switch-off filter is r_dot = (referencia - r) (gain 1).

Porting notes:
- Numerical loop shared with L2A_Dif_ModDes.py (``_simulate`` with eta_thr=1e-4,
  r_gain=1, x_p_chapeu=True); verified against Octave.
- Figure 8 legend/title in MATLAB say 'Fig. Mérito ETA' (copy-paste); kept.
"""
import numpy as np
import matplotlib.pyplot as plt

from L2A_Dif import plot_common, _std_axes
from L2A_Dif_ModDes import _simulate, plot_eta


def L2A_Dif_ModDes_ModEnm1(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
                           cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma):
    s = _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                  cond_iniciais_i, alfa0, referencia, Q, gamma, eta_thr=1e-4, r_gain=1.0, x_p_chapeu=True)

    def extra(ax):
        ax.plot(s['tempo'], s['x_p_chapeu'][0], color='r', lw=2, ls=':', label='Est. da Planta')

    plot_common(s, modelos, planta, extra_fig1=extra)
    plot_eta(s)
    plt.figure(8)
    ax = plt.gca()
    lines = ax.plot(s['tempo'][:s['endk']], s['e_est'].T, color='k', lw=2)
    ax.legend(lines[:1], ['Fig. Mérito ETA'], fontsize=14)
    _std_axes(ax, 'Fig. Mérito ETA')
    return s


def main():
    # parameters of the L2A_Dif_ModDes header example (none given in this file)
    s = L2A_Dif_ModDes_ModEnm1(25, 1e-3, [[7, -2, 3], [-3, -2, -6]], [0.8, -3], [-4, -4], [0.001, 0.002],
                               [0, 0], [[0.001, 0.001, 0.001], [0.002, 0.002, 0.002]], [0, 0], 5,
                               [[1e4, 0], [0, 1e4]], 1)
    print('theta_p_estimativa(:,end) =', s['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
