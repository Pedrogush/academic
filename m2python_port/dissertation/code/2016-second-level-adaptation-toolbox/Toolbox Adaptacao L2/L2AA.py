"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/L2AA.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang & Chen,
Proceedings of the 2014 American Control Conference). UFRN / PPgEEC, aluno Pedro Gushiken.

Second-level adaptation with smooth switch-off of the persistently-exciting (PE)
reference signal, for a plant whose state vector is accessible (companion form, no zeros,
b = [0 ... 0 1]^T known). n+1 identification models theta_i (columns of THETA_BARRA,
adapted by first-level laws theta_i_dot = -e_i^T P b x_p) span a convex hull containing
the plant; the second-level vector alfa (alfa_barra = [alfa; 1 - sum(alfa)]) is driven by
alfa_dot = gamma(-E^T E alfa - E^T e_{n+1}) with a projection that keeps alfa_barra in the
simplex, theta_p_hat = THETA_BARRA alfa_barra, and the controller k = theta_m - theta_p_hat
gives u = r + k^T x_p. When the merit figure eta = alfa_dot^T Q alfa_dot/(1+...) drops below
tol_eta the reference is smoothly driven to its DC level ref_amp(1) (time constant
1/tau_ref). Explicit Euler, step h.

Args (struct/dict, fields in THIS ORDER, as built by tabbedGUI / saved in CBA*.mat):
t_0, t_final, h, modelos (n x n+1), planta (1 x n), modelo_de_referencia (1 x n),
cond_iniciais_p (n), cond_iniciais_m (n), cond_iniciais_i (n x n+1), alfa0 (n), Q (n x n),
gamma, P (n x n), <unused>, ref_amp (1 x k), ref_freq (k), tol_eta, tau_ref.
r(t) = sum(ref_amp .* cos(ref_freq * t)).

Returns the output struct of make_struct (x_p, x_m, eta, theta_p_estimativa, norm_2_e_o,
e_o, u, alfa_barra, r, modelo_de_referencia, planta, theta_BARRA, modelos, tempo, endk);
use plot_adap_figures_L2_VE(estrutura) to plot it and anim_trajetorias(L2AA, args) to
animate the parameter trajectories.

Porting notes:
- Fields are unpacked positionally from the struct exactly like the MATLAB code
  (convert_struct), so the field ORDER matters, not the names.
- 0-based indexing: MATLAB step k (1..endk) is Python index k-1. Output arrays are trimmed
  to the MATLAB sizes: x_p, x_m, eta, r, tempo have endk+1 samples; u, norm_2_e_o, e_o,
  alfa_barra, theta_p_estimativa have endk; theta_BARRA is (n, n+1, endk+1).
- MATLAB ``tic``/``toc`` -> elapsed time printed at the end.
"""
import time

import numpy as np

from can import can
from convert_struct import convert_struct, as_vector, as_matrix
from make_struct import make_struct
from preallocate_memory import preallocate_memory


def L2AA(args):
    tic = time.perf_counter()
    # declaração de variáveis:
    (t_0, t_final, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
     cond_iniciais_m, cond_iniciais_i, alfa0, Q, gamma, P, _, ref_amp,
     ref_freq, tol_eta, tau_ref) = convert_struct(args)[:18]
    h = float(h)
    gamma = float(gamma)
    tol_eta = float(tol_eta)
    tau_ref = float(tau_ref)
    modelos = as_matrix(modelos)
    planta = as_vector(planta)
    modelo_de_referencia = as_vector(modelo_de_referencia)
    ref_amp = as_vector(ref_amp)
    ref_freq = as_vector(ref_freq)

    stoptime = float(t_final) - float(t_0)
    # prealocação de memória / número de passos a serem dados na simulação
    endk = int(np.floor(stoptime / h))
    n_de_linhas = modelos.shape[0]
    n = n_de_linhas
    L = max(modelos.shape)  # length(modelos)
    Q = as_matrix(Q, n)
    P = as_matrix(P, n)
    cond_iniciais_i = as_matrix(cond_iniciais_i, n)

    (tempo, r, r_ponto, eta, u,
     alfa_ponto, alfa_ponto_n1, alfa_n1, x_i_ponto,
     x_m_ponto, x_p_ponto, e_o, norm_2_e_o,
     theta_p_estimativa, x_i, x_p, x_m, theta_i,
     A_i, theta_i_ponto, k_T, alfa_barra, alfa, E, e_i) = preallocate_memory(n_de_linhas, endk)

    # matrizes na forma canônica (companion form):
    A_p = can(planta)
    A_m = can(modelo_de_referencia)
    for i in range(L):
        A_i[:, :, i, 0] = can(modelos[:, i])
    theta_BARRA = np.zeros((n, L, endk + 1))
    theta_BARRA[:, :, 0] = modelos
    for j in range(L):
        theta_i[:, j, 0] = modelos[:, j]
    # b é considerado conhecido, os sistemas não contém zeros.
    b = np.zeros(n)
    b[n - 1] = 1.0

    # condições iniciais da planta, modelo de referência e modelos de identificação
    x_p[:, 0] = as_vector(cond_iniciais_p)
    x_m[:, 0] = as_vector(cond_iniciais_m)
    for j in range(L):
        x_i[:, j, 0] = cond_iniciais_i[:, j]
        # inicialização dos erros
        e_i[:, j, 0] = x_i[:, j, 0] - x_p[:, 0]

    # inicialização da matriz E
    for j in range(L - 1):
        E[:, j, 0] = x_i[:, j, 0] - x_i[:, n, 0]

    # condições iniciais do vetor de combinação linear alfa_barra
    alfa[:, 0] = as_vector(alfa0)
    alfa_barra[:, 0] = np.concatenate([alfa[:, 0], [1 - np.ones(n) @ alfa[:, 0]]])

    # inicialização dos parâmetros do controlador
    k_T[:, 0] = modelo_de_referencia - theta_BARRA[:, :, 0] @ alfa_barra[:, 0]

    # inicialização da entrada da planta
    u[0] = ref_amp[0]
    # inicialização do tempo de simulação
    tempo[0] = 0.0
    eta[0] = 0.0
    r_ponto[0] = 0.0

    # início
    for k in range(endk):
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k + 1] = ref_amp @ np.cos(tempo[k] * ref_freq)
        if eta[k] <= tol_eta:
            r_ponto[k] = tau_ref * (-r[k] + ref_amp[0])
            r[k + 1] = r[k] + h * r_ponto[k]
        # Geração dos erros entre os modelos escolhidos e a planta
        for j in range(L):
            e_i[:, j, k] = x_i[:, j, k] - x_p[:, k]
        # geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
        for j in range(n):
            E[:, j, k] = x_i[:, j, k] - x_i[:, n, k]
        # geração do vetor alfa
        Ek = E[:, :, k]
        alfa_ponto[:, k] = gamma * (-Ek.T @ Ek @ alfa[:, k] - Ek.T @ e_i[:, n, k])
        alfa_n1[k] = 1 - np.ones(n) @ alfa[:, k]
        alfa_ponto_n1[k] = -np.ones(n) @ alfa_ponto[:, k]
        for i in range(n):
            if (alfa[i, k] >= 1 and alfa_ponto[i, k] > 0) or (alfa[i, k] <= 0 and alfa_ponto[i, k] < 0):
                alfa_ponto[i, k] = 0.0
            if (alfa_n1[k] >= 1 and alfa_ponto_n1[k] > 0) or (alfa_n1[k] <= 0 and alfa_ponto_n1[k] < 0):
                for j in range(n):
                    if np.sign(alfa_ponto_n1[k]) != np.sign(alfa_ponto[j, k]):
                        alfa_ponto[j, k] = 0.0
        alfa[:, k + 1] = alfa[:, k] + h * alfa_ponto[:, k]
        aQa = alfa_ponto[:, k] @ Q @ alfa_ponto[:, k]
        eta[k + 1] = aQa / (1 + aQa)
        # composição de alfa para gerar alfa_barra, que é uma parametrização da planta
        alfa_barra[:, k] = np.concatenate([alfa[:, k], [1 - np.ones(n) @ alfa[:, k]]])
        # geração dos parâmetros do controlador (theta_BARRA*alfa_barra = theta_p_chapéu)
        k_T[:, k] = modelo_de_referencia - theta_BARRA[:, :, k] @ alfa_barra[:, k]
        # lei de controle
        u[k] = r[k] + k_T[:, k] @ x_p[:, k]
        # adaptação de primeiro nível dos modelos
        for j in range(n + 1):
            theta_i_ponto[:, j, k] = -(e_i[:, j, k] @ P @ b) * x_p[:, k]
            theta_i[:, j, k + 1] = theta_i[:, j, k] + h * theta_i_ponto[:, j, k]
            theta_BARRA[:, j, k + 1] = theta_i[:, j, k + 1]
            A_i[:, :, j, k + 1] = can(theta_BARRA[:, j, k + 1])
        # dinâmica dos modelos, da planta e do modelo de referência
        for j in range(n + 1):
            x_i_ponto[:, j, k] = A_m @ x_i[:, j, k] + (A_i[:, :, j, k] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto[:, j, k]
        x_m_ponto[:, k] = A_m @ x_m[:, k] + b * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto[:, k]
        x_p_ponto[:, k] = A_p @ x_p[:, k] + b * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto[:, k]
        # cálculo da norma 2 do erro
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]
        # fim do laço principal

    estrutura = make_struct(x_p, x_m, eta, theta_p_estimativa[:, :endk], norm_2_e_o[:endk],
                            e_o[:, :endk], u[:endk], alfa_barra[:, :endk], r,
                            modelo_de_referencia, planta, theta_BARRA, modelos, tempo, endk)
    print(f"Elapsed time is {time.perf_counter() - tic:.6f} seconds.")
    return estrutura
