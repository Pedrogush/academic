"""Port of classwork/graduate/2016-1-adaptive-control/code/aprendizado_gamma.m

Gamma auto-tuning ("aprendizado") experiment for the direct MRAC of Trabalho 1.
It repeatedly simulates the Simulink model MRACDiretoTrab1AutoCriterio2.slx
(which stops itself by an auto-stop criterion and returns SimStopTime) and, for
each adaptive gain gamma(i), multiplies it by the exponential step pass_exp while
the run gets shorter (time to adapt decreases) and divides it back once it gets
longer, for 20 passes over all parameters. The plant is it = [10 1] (time
constants), b = [0 10]; the reference model is modelo_ref = [0 1.5625 b2
1.25 (it1+it2) 1.25 it1 it2], ref = 100, K = 1, and the initial gains come from
calc_gamma_0.

Porting notes:
- CANNOT RUN AS IS: ``theta_fromf.m`` is missing from the repository and the
  Simulink model (``sim('MRACDiretoTrab1AutoCriterio2')``) cannot be ported.
  ``main()`` accepts both as callables: ``theta_fromf(it, b)`` returning
  theta_estrela, and ``sim(workspace)`` taking a dict with the workspace variables
  the model reads (it, b, ref, K, theta_estrela, modelo_ref, theta_c_ini, gamma,
  ...) and returning a dict with at least ``SimStopTime``. Without them
  NotImplementedError is raised (theta_fromf first, as in the MATLAB order).
- MATLAB echoes almost every assignment (no semicolons); the port prints the main
  quantities (theta_estrela, modelo_ref, gamma, temposim, gamma(i) updates).
- pass_exp uses rand() after 3 iterations; ``seed`` seeds the numpy generator
  (stream differs from MATLAB's).
- ``max_inner_iter`` (default None = unlimited, as the original) bounds the inner
  ``while loop`` per parameter, for testing with stub models.
"""
import argparse

import numpy as np

from calc_gamma_0 import calc_gamma_0
from pass_exp import pass_exp


def theta_fromf(it, b):
    raise NotImplementedError("theta_fromf.m is missing from the repository (called by aprendizado_gamma.m)")


def sim_MRACDiretoTrab1AutoCriterio2(workspace):
    raise NotImplementedError("needs Simulink model MRACDiretoTrab1AutoCriterio2.slx "
                              "(Simulink/Trabalho 1/MRACDiretoTrab1AutoCriterio2.slx)")


def main(theta_fromf=theta_fromf, sim=sim_MRACDiretoTrab1AutoCriterio2, seed=None,
         max_inner_iter=None):
    rng = np.random.default_rng(seed)
    it = np.array([10., 1.])
    b = np.array([0., 10.])
    p = 20
    ref = 100
    K = 1
    theta_estrela = np.ravel(np.asarray(theta_fromf(it, b), float))
    print("theta_estrela =", theta_estrela)
    tadpt = np.inf
    contador_laco = 0
    loop = 1
    modelo_ref = np.array([0, 1.5625 * b[1], (it[0] + it[1]) * 1.25, it[1] * it[0] * 1.25])
    print("modelo_ref =", modelo_ref)
    theta_c_ini = 0 * (-theta_estrela + modelo_ref)
    gamma = np.array(calc_gamma_0(K, ref, np.min(it), np.max(it), theta_estrela), dtype=complex)
    if np.all(gamma.imag == 0):
        gamma = gamma.real.copy()
    print("gamma =", gamma)

    while p != 0:
        for i in range(len(theta_estrela)):
            n_inner = 0
            while loop != 0:
                ws = dict(it=it, b=b, p=p, ref=ref, K=K, theta_estrela=theta_estrela,
                          tadpt=tadpt, contador_laco=contador_laco, loop=loop,
                          modelo_ref=modelo_ref, theta_c_ini=theta_c_ini, gamma=gamma.copy(), i=i + 1)
                out = sim(ws)
                SimStopTime = np.ravel(out["SimStopTime"])
                temposim = np.max(SimStopTime)
                print("temposim =", temposim)
                if temposim < tadpt:
                    gamma[i] = gamma[i] * pass_exp(np.min(it), tadpt, contador_laco, rng=rng)
                    print("gamma =", gamma)
                if temposim >= tadpt:
                    gamma[i] = gamma[i] / pass_exp(np.min(it), tadpt, contador_laco, rng=rng)
                    print("gamma =", gamma)
                    loop = 0
                tadpt = np.max(SimStopTime)
                contador_laco = contador_laco + 1
                n_inner += 1
                if max_inner_iter is not None and n_inner >= max_inner_iter:
                    break
            contador_laco = 0
            loop = 1
        p = p - 1
    return gamma


if __name__ == "__main__":
    argparse.ArgumentParser(description=__doc__.splitlines()[0]).parse_args()
    main()
