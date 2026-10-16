"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/preallocate_memory.m

Preallocates (with zeros) all the arrays used by the toolbox simulations (L1A, L2AA,
L2AA_CL, L2A_sem_zeros_IO, ...), for a system of order ``n_de_linhas`` (n) with n+1
identification models and ``endk`` integration steps.

Porting notes:
- Same outputs, same order. MATLAB preallocates most arrays with ``endk`` columns and lets
  them grow to ``endk+1`` inside the loops (index k+1); numpy cannot auto-grow, so here
  EVERY time dimension has ``endk+1`` entries. The callers trim the arrays to the final
  MATLAB sizes before calling make_struct.
- Time is always the LAST axis (as in MATLAB): vectors -> (endk+1,), matrices ->
  (n, endk+1), x_i/theta_i/e_i/x_i_ponto/theta_i_ponto -> (n, n+1, endk+1),
  E -> (n, n, endk+1), A_i -> (n, n, n+1, endk+1), alfa_barra -> (n+1, endk+1).
"""
import numpy as np


def preallocate_memory(n_de_linhas, endk):
    n = int(n_de_linhas)
    N = int(endk) + 1
    tempo = np.zeros(N)
    r = np.zeros(N)
    r_ponto = np.zeros(N)
    eta = np.zeros(N)
    u = np.zeros(N)
    alfa_ponto = np.zeros((n, N))
    alfa_ponto_n1 = np.zeros(N)
    alfa_n1 = np.zeros(N)
    x_i_ponto = np.zeros((n, n + 1, N))
    x_m_ponto = np.zeros((n, N))
    x_p_ponto = np.zeros((n, N))
    e_o = np.zeros((n, N))
    norm_2_e_o = np.zeros(N)
    theta_p_estimativa = np.zeros((n, N))
    x_i = np.zeros((n, n + 1, N))
    x_p = np.zeros((n, N))
    x_m = np.zeros((n, N))
    theta_i = np.zeros((n, n + 1, N))
    A_i = np.zeros((n, n, n + 1, N))
    theta_i_ponto = np.zeros((n, n + 1, N))
    k_T = np.zeros((n, N))
    alfa_barra = np.zeros((n + 1, N))
    alfa = np.zeros((n, N))
    E = np.zeros((n, n, N))
    e_i = np.zeros((n, n + 1, N))
    return (tempo, r, r_ponto, eta, u,
            alfa_ponto, alfa_ponto_n1, alfa_n1, x_i_ponto,
            x_m_ponto, x_p_ponto, e_o, norm_2_e_o,
            theta_p_estimativa, x_i, x_p, x_m, theta_i,
            A_i, theta_i_ponto, k_T, alfa_barra, alfa, E, e_i)
