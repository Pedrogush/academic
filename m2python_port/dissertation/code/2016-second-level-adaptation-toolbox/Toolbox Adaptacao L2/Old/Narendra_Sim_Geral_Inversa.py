"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/Narendra_Sim_Geral_Inversa.m

Simulação 1 referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

General (n-parameter) version of the inverse-method simulation: fixed identification
models, alpha = -E^{-1} e_{n+1} at every step (from k = 1), E = [e_i - e_{n+1}],
controller k = theta_m - THETA_BARRA*alpha_bar with the same one-step shifts as L2A_Inv,
constant reference r(k) = referencia. Plots ||x_m - x_p|| versus time.

Porting notes:
- Numerical loop shared with L2A_Inv.py (``_simulate`` with inv_from_k=1 and r(k)
  instead of r(k+1)). Verified against Octave: agreement ~1e-9 up to t ~ 2.4 s; for the
  header example E becomes ill-conditioned (cond ~1e4, |alpha| ~ 500) and the inverse
  method then amplifies round-off, so the trajectories diverge from Octave afterwards
  (sensitivity of the algorithm, not a porting difference).
- The commented alternative plots (x_p/x_m, alfa_barra, u) are available in the returned dict.
"""
import numpy as np
import matplotlib.pyplot as plt

from L2A_Inv import _simulate


def Narendra_Sim_Geral_Inversa(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
                               cond_iniciais_m, cond_iniciais_i, alfa0, referencia):
    s = _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                  cond_iniciais_i, alfa0, referencia, inv_from_k=1, r_const_len_endk=True)
    plt.figure()
    plt.plot(s['tempo'], s['norm_2_e_o'])
    # plt.plot(s['tempo'], s['x_p'].T, s['tempo'], s['x_m'].T)
    # plt.plot(s['tempo'], s['alfa_barra'].T)
    # plt.plot(s['tempo'], s['u'])
    return s


def main():
    # exemplo 1
    s = Narendra_Sim_Geral_Inversa(16, 1e-3, [[3, -2, 7], [-6, -2, -3]], [-2, -1], [-1, -3], [0.1, 0.2],
                                   [0, 0], [[2, 2, 1], [0, -1, 0]], [1, 0], 5)
    print('norm_2_e_o(end) =', s['norm_2_e_o'][-1])
    # exemplo 2 (3 parâmetros):
    # Narendra_Sim_Geral_Inversa(16, 1e-3, [[-3,-2,-7,-8],[-4,-4,-1,-2],[-5,-7,-9,-1]], [-7,-9,-2],
    #     [-3,-3,-1], [0.1,0.2,0.3], [0,0,0], [[2,2,1,4],[2,0,1,-1],[5,7,0,1]], [1,0,0], 5)
    plt.show()


if __name__ == "__main__":
    main()
