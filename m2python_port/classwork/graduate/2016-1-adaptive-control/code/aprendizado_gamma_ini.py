"""Port of classwork/graduate/2016-1-adaptive-control/code/aprendizado_gamma_ini.m

Gamma auto-tuning ("aprendizado") experiment for the direct MRAC of Trabalho 1,
error-norm version. It repeatedly simulates the Simulink model
MRACDireto_Trab1_Regra_MIT_Pedro.slx (MIT rule), reads the error norm
norma2_tmt(1) and the flags fiddle_gamma4 / fiddle_gamma3 that select which gain
to tune (i = 4, 3 or 2), and multiplies gamma(i) by the exponential step
pass_exp while the norm decreases, dividing it back by the previous step when the
norm increases. It also defines the workspace for the model: it = [10 1],
b = [0 11], ref = 100, K = 1e5, modelo_ref = [0 1.4205 b2 1.25 (it1+it2)
1.5625 it1 it2], theta_c_ini = 0.7 [0 1.4205 -0.25 -5.625/11]. The header
comments list the open questions (cost function for the simulation time, stop
criteria, which optimiser to use - "por enquanto: nuvem de partículas").

Porting notes:
- CANNOT RUN AS IS: ``theta_fromf.m`` is missing from the repository and the
  Simulink model (``sim('MRACDireto_Trab1_Regra_MIT_Pedro')``) cannot be ported.
  ``main()`` accepts both as callables: ``theta_fromf(it, b)`` and
  ``sim(workspace)`` returning a dict with ``norma2_tmt``, ``fiddle_gamma4``,
  ``fiddle_gamma3`` and ``SimStopTime``. Without them NotImplementedError is
  raised (theta_fromf first, as in the MATLAB order).
- BUG KEPT: ``loop = 1`` is reset INSIDE the inner ``while loop ~= 0`` (the
  indentation of the original is misleading), so the inner loop never ends and
  ``p`` is never decremented. ``max_inner_iter`` (default None = unlimited, as the
  original) bounds it, for testing with stub models.
- MATLAB's 1-based gain index i (4, 3, 2) -> Python index i-1.
- pass_exp uses rand() after 3 iterations; ``seed`` seeds the numpy generator.
- The echoed values (norma2_t, gamma, contador_laco) are printed.
"""
import argparse

import numpy as np

from calc_gamma_0 import calc_gamma_0
from pass_exp import pass_exp


def theta_fromf(it, b):
    raise NotImplementedError("theta_fromf.m is missing from the repository (called by aprendizado_gamma_ini.m)")


def sim_MRACDireto_Trab1_Regra_MIT_Pedro(workspace):
    raise NotImplementedError("needs Simulink model MRACDireto_Trab1_Regra_MIT_Pedro.slx "
                              "(Simulink/Trabalho 1/MRACDireto_Trab1_Regra_MIT_Pedro.slx)")


def main(theta_fromf=theta_fromf, sim=sim_MRACDireto_Trab1_Regra_MIT_Pedro, seed=None,
         max_inner_iter=None):
    rng = np.random.default_rng(seed)
    it = np.array([10., 1.])
    b = np.array([0., 11.])
    p = 20
    ref = 100
    K = 1e5
    theta_estrela = np.ravel(np.asarray(theta_fromf(it, b), float))
    tadpt = np.inf
    contador_laco = 0
    loop = 1
    modelo_ref = np.array([0, 1.4205 * b[1], (it[0] + it[1]) * 1.25, it[1] * it[0] * 1.5625])
    theta_c_ini = 0.7 * np.array([0, 1.4205, -0.25, -5.625 / 11])
    gamma = np.array(calc_gamma_0(K, ref, np.min(it), np.max(it), theta_estrela), dtype=complex)
    if np.all(gamma.imag == 0):
        gamma = gamma.real.copy()
    norma2_t = np.inf
    passo_atual = 1.1
    i = 4

    # 1. COMO DEFINIR UMA FUNÇÃO DE CUSTO J PARA O TEMPO DE SIMULAÇÃO
    # 2. COMO DEFINIR UMA COMBINAÇÃO DE CRITÉRIOS DE PARADA PARA A SIMULAÇÃO
    # 2.a NORMA DE THETA_PONTO?  2.b NORMA DE THETA-THETA_PONTO?  2.c NORMA DE \Varepsilon?
    # 3. QUAL ALGORITMO DE OTIMIZAÇÃO USAR QUANDO NÃO SE CONHECE O ESPAÇO DE
    #    BUSCA (POR ENQUANTO: NUVEM DE PARTÍCULAS)
    n_inner = 0
    while p != 0:
        while loop != 0:
            ws = dict(it=it, b=b, p=p, ref=ref, K=K, theta_estrela=theta_estrela, tadpt=tadpt,
                      contador_laco=contador_laco, loop=loop, modelo_ref=modelo_ref,
                      theta_c_ini=theta_c_ini, gamma=gamma.copy(), norma2_t=norma2_t,
                      passo_atual=passo_atual, i=i)
            out = sim(ws)
            norma2_t_anterior = norma2_t
            norma2_t = float(np.ravel(out["norma2_tmt"])[0])
            print("norma2_t =", norma2_t)
            passo_anterior = passo_atual
            passo_atual = pass_exp(np.min(it), tadpt, contador_laco, rng=rng)
            if pass_exp(np.min(it), tadpt, contador_laco, rng=rng) <= 1:
                contador_laco = 0
                print("contador_laco =", contador_laco)
            if out["fiddle_gamma4"] == 1:
                i = 4
            elif out["fiddle_gamma3"] == 1:
                i = 3
            else:
                i = 2
            if norma2_t <= norma2_t_anterior:
                gamma[i - 1] = gamma[i - 1] * passo_atual
                print("gamma =", gamma)
            if norma2_t > norma2_t_anterior:
                gamma[i - 1] = gamma[i - 1] / passo_anterior
                print("gamma =", gamma)
                contador_laco = contador_laco + 1
                loop = 0
            tadpt = np.max(np.ravel(out["SimStopTime"]))

            loop = 1          # (sic) inside the inner while: it never terminates
            n_inner += 1
            if max_inner_iter is not None and n_inner >= max_inner_iter:
                return gamma
        p = p - 1
    return gamma


if __name__ == "__main__":
    argparse.ArgumentParser(description=__doc__.splitlines()[0]).parse_args()
    main()
