"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/M_sylv.m

Montagem da matriz de Sylvester para resolução da equação diofantina
Qm*R*L + Z*P = A_estrela, a partir dos vetores de coeficientes de QmR e Z,
dado o grau n da planta e o grau q do polinômio do princípio do modelo interno.
The first n columns are shifted copies of QmRs, the next n+q columns shifted
copies of Zs_chapeu (each starting one row lower than in MATLAB's "s2" loop, as
in the original).

Porting notes:
- Coefficient vectors are treated as 1-D arrays (MATLAB required columns).
- If the column heights do not agree MATLAB errors on the concatenation; here a
  ValueError is raised.
"""
import numpy as np


def M_sylv(n, q, QmRs, Zs_chapeu):
    QmRs = np.ravel(np.asarray(QmRs, dtype=float))
    Zs_chapeu = np.ravel(np.asarray(Zs_chapeu, dtype=float))
    n_Ls = n - 1
    n_Ps = n + q - 1
    cols = []
    for s1 in range(1, n_Ls + 2):
        cols.append(np.concatenate([np.zeros(s1 - 1), QmRs, np.zeros(n_Ls + 1 - s1)]))
    for s2 in range(1, n_Ps + 2):
        cols.append(np.concatenate([np.zeros(s2), Zs_chapeu, np.zeros(n + q - s2)]))
    heights = {len(c) for c in cols}
    if len(heights) != 1:
        raise ValueError("M_sylv: dimensions of arrays being concatenated are not consistent")
    # MATLAB writes column s2+n, which coincides with the column order above
    return np.column_stack(cols)
