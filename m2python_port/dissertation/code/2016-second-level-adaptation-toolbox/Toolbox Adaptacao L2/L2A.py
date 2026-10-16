"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/L2A.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang & Chen,
ACC 2014). UFRN / PPgEEC, aluno Pedro Gushiken.

UNFINISHED DRAFT in the original: an attempt to generalise L2AA to plants WITH zeros
(separate pole/zero parameter vectors for plant, reference model and identification
models, theta_i = [zeros; poles]). The args struct is unpacked positionally into 21
values: t0, t_final, h, modelos_polos, modelos_zeros, planta_polos, planta_zeros,
modelo_de_referencia_polos, modelo_de_referencia_zeros, cond_iniciais_p, cond_iniciais_m,
cond_iniciais_i, alfa0, Q, gamma, P, <unused>, ref_amp, ref_freq, tol_eta, tau_ref.

Porting notes (bugs of the original, kept):
- With non-empty zeros MATLAB already fails at ``theta_i(:,j,1) = [zeros; poles]``
  (dimension mismatch with the n-row preallocated theta_i); numpy raises ValueError at the
  same statement. With empty zeros (0 x n+1) it continues, but right before the main loop it uses
  ``modelo_de_referencia``, which is not defined (only ..._polos/_zeros are), so MATLAB
  stops with "Undefined function or variable 'modelo_de_referencia'". The port executes
  the same initialisation and raises NameError at the same statement.
- The rest of the body (main loop) is kept below the ``raise`` as unreachable code for
  reference; it also uses undefined names (``w_T``, ``b``), ``E(:,k)``/``e_i(n+1,k)`` with
  the wrong number of indices, and ``A_i`` is only built for the first model
  (``for i=1:length(modelos_polos)/2``).
- Consequently L2A cannot drive anim_trajetorias (neither in MATLAB nor here); use L2AA.
"""
import time

import numpy as np

from can import can
from convert_struct import convert_struct, as_vector, as_matrix
from make_struct import make_struct
from preallocate_memory import preallocate_memory


def L2A(args):
    tic = time.perf_counter()
    # declaração de variáveis:
    (t0, t_final, h, modelos_polos, modelos_zeros, planta_polos, planta_zeros,
     modelo_de_referencia_polos, modelo_de_referencia_zeros,
     cond_iniciais_p, cond_iniciais_m, cond_iniciais_i, alfa0, Q,
     gamma, P, _, ref_amp, ref_freq, tol_eta, tau_ref) = convert_struct(args)[:21]
    h = float(h)
    modelos_polos = as_matrix(modelos_polos)
    modelos_zeros = as_matrix(modelos_zeros)
    # prealocação de memória: número de passos a serem dados na simulação
    stoptime = float(t_final) - float(t0)
    endk = int(np.floor(stoptime / h))
    n_de_linhas = modelos_polos.shape[0]
    n = n_de_linhas
    L = max(modelos_polos.shape)
    cond_iniciais_i = as_matrix(cond_iniciais_i, n)

    (tempo, r, r_ponto, eta, u,
     alfa_ponto, alfa_ponto_n1, alfa_n1, x_i_ponto,
     x_m_ponto, x_p_ponto, e_o, norm_2_e_o,
     theta_p_estimativa, x_i, x_p, x_m, theta_i,
     A_i, theta_i_ponto, k_T, alfa_barra, alfa, E, e_i) = preallocate_memory(n_de_linhas, endk)

    # matrizes na forma canônica (companion form):
    A_p = can(planta_polos)
    A_m = can(modelo_de_referencia_polos)
    for i in range(int(np.floor(L / 2))):  # for i=1:length(modelos_polos)/2
        A_i[:, :, i, 0] = can(modelos_polos[:, i])
    nz = modelos_zeros.shape[0]
    theta_BARRA = np.zeros((nz + n, L, endk + 1))
    theta_BARRA[:, :, 0] = np.vstack([modelos_zeros, modelos_polos])
    for j in range(L):
        # theta_i was preallocated with n rows: with non-empty zeros this raises a
        # dimension-mismatch error, exactly like MATLAB's subscripted assignment.
        theta_i[:, j, 0] = np.concatenate([modelos_zeros[:, j], modelos_polos[:, j]])
    # b é considerado conhecido, os sistemas não contém zeros.
    b_p = as_vector(planta_zeros)
    b_m = as_vector(modelo_de_referencia_zeros)
    b_i = np.zeros((nz, L))
    for j in range(max(modelos_zeros.shape)):
        b_i[:, j] = modelos_zeros[:, j]
    # condições iniciais da planta, modelo de referência e modelos de identificação
    x_p[:, 0] = as_vector(cond_iniciais_p)
    x_m[:, 0] = as_vector(cond_iniciais_m)
    for j in range(L):
        x_i[:, j, 0] = cond_iniciais_i[:, j]
        e_i[:, j, 0] = x_i[:, j, 0] - x_p[:, 0]
    # inicialização da matriz E
    for j in range(L - 1):
        E[:, j, 0] = x_i[:, j, 0] - x_i[:, n, 0]
    # condições iniciais do vetor de combinação linear alfa_barra
    alfa[:, 0] = as_vector(alfa0)
    alfa_barra[:, 0] = np.concatenate([alfa[:, 0], [1 - np.ones(n) @ alfa[:, 0]]])

    # inicialização dos parâmetros do controlador
    # k_T(:,1) = transpose(modelo_de_referencia) - theta_BARRA*alfa_barra(:,1);
    raise NameError("L2A: Undefined function or variable 'modelo_de_referencia' "
                    "(the original L2A.m is an unfinished draft and stops here)")

    # ---- unreachable: remainder of the original draft, kept for reference ----
    k_T[:, 0] = modelo_de_referencia - theta_BARRA[:, :, 0] @ alfa_barra[:, 0]  # noqa: F821
    u[0] = as_vector(ref_amp)[0]
    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = as_vector(ref_amp) @ np.cos(tempo[k] * as_vector(ref_freq))
        if eta[k] <= tol_eta:
            r_ponto[k] = tau_ref * (-r[k] + as_vector(ref_amp)[0])
            r[k + 1] = r[k] + h * r_ponto[k]
        for j in range(L):
            e_i[:, j, k] = x_i[:, j, k] - x_p[:, k]
        for j in range(n):
            E[:, j, k] = x_i[:, j, k] - x_i[:, n, k]
        # original: alfa_ponto(:,k) = gamma*(-E(:,k)'*E(:,k)*alfa(:,k)-E(:,k)'*e_i(n+1,k))
        alfa_ponto[:, k] = gamma * (-E[:, k].T @ E[:, k] * alfa[:, k] - E[:, k].T * e_i[n, k])
        alfa_n1[k] = 1 - np.ones(n) @ alfa[:, k]
        alfa_ponto_n1[k] = -np.ones(n) @ alfa_ponto[:, k]
        for i in range(n):
            if (alfa[i, k] >= 1 and alfa_ponto[i, k] > 0) or (alfa[i, k] <= 0 and alfa_ponto[i, k] < 0):
                alfa_ponto[i, k] = 0
            if (alfa_n1[k] >= 1 and alfa_ponto_n1[k] > 0) or (alfa_n1[k] <= 0 and alfa_ponto_n1[k] < 0):
                for j in range(n):
                    if np.sign(alfa_ponto_n1[k]) != np.sign(alfa_ponto[j, k]):
                        alfa_ponto[j, k] = 0
        alfa[:, k + 1] = alfa[:, k] + h * alfa_ponto[:, k]
        aQa = alfa_ponto[:, k] @ Q @ alfa_ponto[:, k]
        eta[k + 1] = aQa / (1 + aQa)
        alfa_barra[:, k] = np.concatenate([alfa[:, k], [1 - np.ones(n) @ alfa[:, k]]])
        # Adaptação dos modelos de primeiro nível
        for j in range(n + 1):
            theta_i_ponto[:, j, k] = -(e_i[j, k]) * w_T[:, k]  # noqa: F821
            theta_i[:, j, k + 1] = theta_i[:, j, k] + h * theta_i_ponto[:, j, k]
            theta_BARRA[:, j, k + 1] = theta_i[:, j, k + 1]
        for j in range(n + 1):
            x_i_ponto[:, j, k] = A_m @ x_i[:, j, k] + (A_i[:, :, j, k] - A_m) @ x_p[:, k] + b * u[k]  # noqa: F821
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto[:, j, k]
        x_m_ponto[:, k] = A_m @ x_m[:, k] + b_m * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto[:, k]
        x_p_ponto[:, k] = A_p @ x_p[:, k] + b_p * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto[:, k]
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]
    estrutura = make_struct(x_p, x_m, eta, theta_p_estimativa, norm_2_e_o,
                            e_o, u, alfa_barra, r, modelo_de_referencia,  # noqa: F821
                            planta_polos, theta_BARRA, modelos_polos, tempo, endk)
    print(f"Elapsed time is {time.perf_counter() - tic:.6f} seconds.")
    return estrutura
