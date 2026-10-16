"""Port of classwork/graduate/2016-1-adaptive-control/code/pass_exp.m

Multiplicative step for the adaptive gains in the "aprendizado" experiments:
1.05 by default, then 1.02, 1.01 and 1.001 as the adaptation time tadpt drops
below 400, 40 and 4 times the plant time constant t. After 3 loop iterations
(contador_laco >= 3) it returns rand() as a crude escape from oscillation.

Porting notes:
- rand() -> numpy Generator.random(). Pass ``rng`` (a numpy Generator) or
  ``seed`` for reproducibility; otherwise a module-level unseeded generator is
  used. The random stream differs from MATLAB's.
"""
import numpy as np

_rng = np.random.default_rng()


def pass_exp(t, tadpt, contador_laco, seed=None, rng=None):
    if rng is None:
        rng = np.random.default_rng(seed) if seed is not None else _rng
    passo_exponencial = 1.05
    if tadpt <= 400 * t:
        passo_exponencial = 1.02
    if tadpt <= 40 * t:
        passo_exponencial = 1.01
    if tadpt <= 4 * t:
        passo_exponencial = 1.001
    if contador_laco >= 3:
        passo_exponencial = rng.random()
    return passo_exponencial
