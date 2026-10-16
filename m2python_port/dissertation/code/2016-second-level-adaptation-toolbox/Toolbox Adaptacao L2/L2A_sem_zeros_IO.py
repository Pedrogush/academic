"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/L2A_sem_zeros_IO.m

Draft of second-level adaptation using only INPUT/OUTPUT measurements (plant without
zeros): the identification models are NOT adapted (theta_i constant), the plant is driven
open loop (u = r), and alfa is computed from the scalar output errors
y_i - y_{n+1} (y = h^T x with h = [1 0 ... 0]):
alfa_dot = gamma(-E1^T E1 alfa - E1^T (y_{n+1} - y)), with the same simplex projection and
PE switch-off as L2AA.

Args: 17-field struct (stoptime, h, modelos, planta, modelo_de_referencia,
cond_iniciais_p, cond_iniciais_m, cond_iniciais_i, alfa0, Q, gamma, P, <unused>, ref_amp,
ref_freq, tol_eta, tau_ref), unpacked positionally. Returns the make_struct output.

Porting notes:
- h_transposto is built as in MATLAB: h_transposto(length(modelos)-1)=0; h_transposto(1)=1
  (length n when there are n+1 models).
- y_m is computed but unused (as in the original); u(k)=r(k) (open loop), k_T is only
  initialised.  0-based indexing; outputs trimmed to MATLAB sizes; tic/toc printed.
"""
import time

import numpy as np

from can import can
from convert_struct import convert_struct, as_vector, as_matrix
from make_struct import make_struct
from preallocate_memory import preallocate_memory


def L2A_sem_zeros_IO(args):
    tic = time.perf_counter()
    # declaração de variáveis:
    (stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
     cond_iniciais_m, cond_iniciais_i, alfa0, Q, gamma, P, _, ref_amp,
     ref_freq, tol_eta, tau_ref) = convert_struct(args)[:17]
    h = float(h)
    gamma = float(gamma)
    tol_eta = float(tol_eta)
    tau_ref = float(tau_ref)
    modelos = as_matrix(modelos)
    planta = as_vector(planta)
    modelo_de_referencia = as_vector(modelo_de_referencia)
    ref_amp = as_vector(ref_amp)
    ref_freq = as_vector(ref_freq)

    stoptime = float(stoptime)
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
    h_transposto = np.zeros(L - 1)
    h_transposto[0] = 1.0
    y = np.zeros(endk + 1)
    y_m = np.zeros(endk + 1)
    y_i = np.zeros((L, endk + 1))
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
    y[0] = h_transposto @ x_p[:, 0]
    x_m[:, 0] = as_vector(cond_iniciais_m)
    for j in range(L):
        x_i[:, j, 0] = cond_iniciais_i[:, j]
        y_i[j, 0] = h_transposto @ x_i[:, j, 0]
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
        u[k] = r[k]
        # Geração dos erros entre os modelos escolhidos e a planta
        for j in range(L):
            e_i[:, j, k] = x_i[:, j, k] - x_p[:, k]
        # geração de uma matriz E, tal que as colunas de E sejam e_i-e_{n+1}
        for j in range(n):
            E[0, j, k] = y_i[j, k] - y_i[n, k]
        # geração do vetor alfa
        E1 = E[0, :, k]  # linha 1 x n
        alfa_ponto[:, k] = gamma * (-np.outer(E1, E1) @ alfa[:, k] - E1 * (y_i[n, k] - y[k]))
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
        # Adaptação dos modelos de primeiro nível (desligada: modelos fixos)
        for j in range(n + 1):
            theta_i[:, j, k + 1] = theta_i[:, j, k]
            theta_BARRA[:, j, k + 1] = theta_i[:, j, k + 1]
            A_i[:, :, j, k + 1] = can(theta_BARRA[:, j, k + 1])
        # dinâmica dos modelos, da planta e do modelo de referência
        for j in range(n + 1):
            x_i_ponto[:, j, k] = A_m @ x_i[:, j, k] + (A_i[:, :, j, k] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto[:, j, k]
            y_i[j, k + 1] = h_transposto @ x_i[:, j, k + 1]
        x_m_ponto[:, k] = A_m @ x_m[:, k] + b * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto[:, k]
        y_m[k + 1] = h_transposto @ x_m[:, k + 1]
        x_p_ponto[:, k] = A_p @ x_p[:, k] + b * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto[:, k]
        y[k + 1] = h_transposto @ x_p[:, k + 1]
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
