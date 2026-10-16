"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/can.m

Builds the n x n companion ("canonical") matrix whose last row is ``vect`` and
which has ones on the superdiagonal (n = length(vect)).

Porting notes:
- Returns a float 2-D numpy array of shape (n, n). For n == 1 MATLAB returns the
  scalar vect(1); here a 1x1 array (it broadcasts the same way in products).
"""
import numpy as np


def can(vect):
    vect = np.ravel(np.asarray(vect, dtype=float))
    N = len(vect)
    A = np.zeros((N, N))
    for linha in range(N):
        for coluna in range(N):
            if linha < N - 1 and coluna == linha + 1:
                A[linha, coluna] = 1.0
            if linha == N - 1:
                A[linha, coluna] = vect[coluna]
    return A
