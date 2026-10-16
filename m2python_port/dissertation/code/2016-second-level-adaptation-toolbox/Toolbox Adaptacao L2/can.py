"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/can.m

``A = can(vect)`` builds the n x n companion (controllable canonical) matrix whose
super-diagonal is 1 and whose last row is ``vect``.

Porting notes: returns a float numpy array; ``vect`` may be a row/column/1-D vector.
"""
import numpy as np


def can(vect):
    vect = np.ravel(np.asarray(vect, dtype=float))
    n = len(vect)
    A = np.zeros((n, n))
    for linha in range(n - 1):
        A[linha, linha + 1] = 1.0
    A[n - 1, :] = vect
    return A
