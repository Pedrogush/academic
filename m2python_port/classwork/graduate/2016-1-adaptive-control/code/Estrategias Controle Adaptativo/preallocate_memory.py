"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/preallocate_memory.m

Preallocates (with zeros) all the time-series arrays of a second-level
adaptation / multiple-model simulation of an n-th order system with n+1
identification models (time, reference, eta, control, alpha weights, states of
the identification models x_i, plant x_p, reference model x_m, parameters
theta_i, matrices A_i, gains k_T, alfa_barra, E, e_i, ...). It is not called by
any file of this folder.

Porting notes:
- Shapes reproduce what MATLAB auto-growth creates: row vectors become 1-D arrays
  (length endk or endk+1), "(:,endk)=zeros(n,1)" gives (n, endk), 3-D/4-D arrays
  keep MATLAB's dimension order. MATLAB drops trailing singleton dimensions, so
  theta_i_ponto(:,n+1,1) is (n, n+1).
"""
import numpy as np


def preallocate_memory(n_de_linhas, endk):
    N = int(n_de_linhas)
    endk = int(endk)
    tempo = np.zeros(endk)
    r = np.zeros(endk + 1)
    r_ponto = np.zeros(endk)
    eta = np.zeros(endk + 1)
    u = np.zeros(endk)
    alfa_ponto = np.zeros((N, endk))
    alfa_ponto_n1 = np.zeros(endk)
    alfa_n1 = np.zeros(endk)
    x_i_ponto = np.zeros((N, N + 1, endk))
    x_m_ponto = np.zeros((N, endk))
    x_p_ponto = np.zeros((N, endk))
    e_o = np.zeros((N, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((N, endk))
    x_i = np.zeros((N, N + 1, endk))
    x_p = np.zeros((N, endk))
    x_m = np.zeros((N, endk))
    theta_i = np.zeros((N, N + 1, endk))
    A_i = np.zeros((N, N, N + 1, endk))
    theta_i_ponto = np.zeros((N, N + 1))
    k_T = np.zeros((N, endk))
    alfa_barra = np.zeros((N + 1, endk))
    alfa = np.zeros((N, endk))
    E = np.zeros((N, N, endk))
    e_i = np.zeros((N, N + 1, endk))
    return (tempo, r, r_ponto, eta, u,
            alfa_ponto, alfa_ponto_n1, alfa_n1, x_i_ponto,
            x_m_ponto, x_p_ponto, e_o, norm_2_e_o,
            theta_p_estimativa, x_i, x_p, x_m, theta_i,
            A_i, theta_i_ponto, k_T, alfa_barra, alfa, E, e_i)
