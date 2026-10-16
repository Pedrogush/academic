"""Port of dissertation/code/2016-second-level-adaptation-toolbox/_outras versões/L2A_IO_CL_Ident_V0 (MATLAB 2016-10-28).m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang,
Chen, ACC 2014). UFRN / PPgEEC, aluno Pedro Gushiken. MATLAB function L2A_IO_CL_Ident_V0(args).

Second-level adaptation (identification, input/output version) with an added
"concurrent learning" memory: besides the instantaneous gradient term built
from the output-error row E = [y_1 - y_{n+1}, ..., y_n - y_{n+1}], a matrix
M = sum E'E and vector vm = sum E'(y_{n+1} - y) are accumulated whenever the
new sample increases the smallest singular value of M (and the 2-norm of M by
more than 50%), giving the concurrent law alfa_dot = gamma*(-M alfa - vm).
Two figures of merit, eta_natural and eta_concorrente, are computed; the PE
reference is switched off when eta_natural <= tol_eta. Euler integration.

Input/output: same struct as L2A_IO_Ident (fields t_0, t_final, h, modelos,
planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
cond_iniciais_i, alfa0, Q, gamma, P, (não usado), ref_amp, ref_freq, tol_eta,
tau_ref); output make_struct(...) with eta = eta_natural.

Porting notes:
- Indices are 0-based; output array sizes equal the final MATLAB sizes.
- can/convert_struct/make_struct from the "Toolbox Adaptacao L2" port (via
  _toolbox_l2). svd uses LAPACK gesvd as MATLAB; the switching tests compare
  singular values that can be at round-off level, so tiny differences in
  floating point may change when M is updated.
- The first-level models are not adapted (theta constant).
- The natural law also contains the concurrent term; alfa_ponto is always the
  natural law (both branches of the eta comparison are identical in MATLAB).
- M and vm are reset when ||M alfa + vm|| < 1e-5 and ALL entries of the
  preallocated eta_natural vector are < 1e-5 (MATLAB 'if' on a vector).
- Older copy (2016-10-28) of ../L2A_IO_CL_Ident_V0.m: M is updated when
  min(svd(M)) < min(svd(M+E'E)) (no 1.5 factor), E(:,j,1) is initialised
  correctly, and M is displayed at the end.
- _toolbox_l2 is loaded from the parent folder via importlib.
"""
import numpy as np

import importlib.util as _ilu
import os as _os
import sys as _sys

if "_toolbox_l2" not in _sys.modules:
    _spec = _ilu.spec_from_file_location(
        "_toolbox_l2", _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))),
                                     "_toolbox_l2.py"))
    _mod = _ilu.module_from_spec(_spec)
    _sys.modules["_toolbox_l2"] = _mod
    _spec.loader.exec_module(_mod)
from _toolbox_l2 import TicToc, can, make_struct, mlength, parse_args, svdvals, norm2


def L2A_IO_CL_Ident_V0(args):
    tic = TicToc()
    p = parse_args(args)
    t_0, t_final, h = p["t_0"], p["t_final"], p["h"]
    modelos, planta, modelo_de_referencia = p["modelos"], p["planta"], p["modelo_de_referencia"]
    Q, gamma = p["Q"], p["gamma"]
    ref_amp, ref_freq, tol_eta, tau_ref = p["ref_amp"], p["ref_freq"], p["tol_eta"], p["tau_ref"]
    gmul = (lambda v: gamma @ v) if np.ndim(gamma) == 2 else (lambda v: gamma * v)

    stoptime = t_final - t_0
    endk = int(np.floor(stoptime / h))
    n_de_linhas = modelos.shape[0]
    nmod = mlength(modelos)  # length(modelos) = n+1
    n = n_de_linhas

    # matrizes na forma canônica (companion form):
    h_transposto = np.zeros(nmod - 1)
    h_transposto[0] = 1.0
    A_p = can(planta)
    A_m = can(modelo_de_referencia)
    A_i = [can(modelos[:, i]) for i in range(nmod)]
    # b é considerado conhecido, os sistemas não contém zeros.
    b = np.zeros(n)
    b[n - 1] = 1.0

    # prealocação (tamanhos finais do MATLAB)
    tempo = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    r_ponto = np.zeros(endk)
    eta_natural = np.zeros(endk + 1)
    eta_concorrente = np.zeros(endk + 1)
    u = np.zeros(endk)
    alfa = np.zeros((n, endk + 1))
    alfa_barra = np.zeros((n + 1, endk))
    x_p = np.zeros((n, endk + 1))
    x_m = np.zeros((n, endk + 1))
    y = np.zeros(endk + 1)
    y_i = np.zeros((nmod, endk + 1))
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))
    theta_BARRA = np.zeros((n, nmod, endk + 1))
    theta_BARRA[:, :, 0] = modelos

    # condições iniciais
    x_p[:, 0] = p["cond_iniciais_p"]
    y[0] = h_transposto @ x_p[:, 0]
    x_m[:, 0] = p["cond_iniciais_m"]
    cond_i = p["cond_iniciais_i"].reshape(n, -1)
    x_i = np.zeros((n, nmod))
    for j in range(nmod):
        x_i[:, j] = cond_i[:, j]
        y_i[j, 0] = h_transposto @ x_i[:, j]

    # condições iniciais do vetor de combinação linear alfa_barra
    alfa[:, 0] = p["alfa0"]
    alfa_barra[:, 0] = np.concatenate([alfa[:, 0], [1 - np.sum(alfa[:, 0])]])
    # inicialização da entrada da planta (sobrescrita em k=1, como no original)
    if endk > 0:
        u[0] = ref_amp[0]
    tempo[0] = 0.0
    eta_natural[0] = 0.0
    eta_concorrente[0] = 0.0

    E = np.zeros(n)
    M = np.zeros((nmod - 1, nmod - 1))
    vm = np.zeros(nmod - 1)
    for k in range(endk):
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k + 1] = ref_amp @ np.cos(tempo[k] * ref_freq)
        if eta_natural[k] <= tol_eta:
            r_ponto[k] = tau_ref * (-r[k] + ref_amp[0])
            r[k + 1] = r[k] + h * r_ponto[k]
        u[k] = r[k]

        for j in range(n_de_linhas):
            E[j] = y_i[j, k] - y_i[n_de_linhas, k]
        # geração do vetor alfa
        EtE = np.outer(E, E)
        alfa_ponto_natural = (gmul(-EtE @ alfa[:, k] - E * (y_i[n_de_linhas, k] - y[k]))
                              + gmul(-M @ alfa[:, k] - vm))
        alfa_ponto_concorrente = gmul(-M @ alfa[:, k] - vm)

        if np.min(svdvals(M)) < np.min(svdvals(M + EtE)):
            if 1.5 * norm2(M) < norm2(M + EtE):
                M = M + EtE
                vm = vm + E * (y_i[n_de_linhas, k] - y[k])

        if norm2(-M @ alfa[:, k] - vm) < 1e-5:
            # 'if eta_natural<1e-5' acts on the whole (preallocated) vector:
            # true only if every element is < 1e-5
            if np.all(eta_natural < 1e-5):
                M = np.zeros((nmod - 1, nmod - 1))
                vm = np.zeros(nmod - 1)

        if eta_concorrente[k] < eta_natural[k]:
            alfa_ponto = alfa_ponto_natural.copy()
        else:
            alfa_ponto = alfa_ponto_natural.copy()

        alfa_n1 = 1 - np.sum(alfa[:, k])
        alfa_ponto_n1 = -np.sum(alfa_ponto)
        for i in range(n_de_linhas):
            if (alfa[i, k] >= 1 and alfa_ponto[i] > 0) or (alfa[i, k] <= 0 and alfa_ponto[i] < 0):
                alfa_ponto[i] = 0.0
            if (alfa_n1 >= 1 and alfa_ponto_n1 > 0) or (alfa_n1 <= 0 and alfa_ponto_n1 < 0):
                for j in range(len(alfa_ponto)):
                    if np.sign(alfa_ponto_n1) != np.sign(alfa_ponto[j]):
                        alfa_ponto[j] = 0.0
        alfa[:, k + 1] = alfa[:, k] + h * alfa_ponto
        aqa = alfa_ponto_natural @ Q @ alfa_ponto_natural
        eta_natural[k + 1] = aqa / (1 + aqa)
        aqa = alfa_ponto_concorrente @ Q @ alfa_ponto_concorrente
        eta_concorrente[k + 1] = aqa / (1 + aqa)

        alfa_barra[:, k] = np.concatenate([alfa[:, k], [1 - np.sum(alfa[:, k])]])

        # Adaptação dos modelos de primeiro nível (constantes nesta versão)
        theta_BARRA[:, :, k + 1] = theta_BARRA[:, :, k]

        for j in range(nmod):
            x_i_ponto = A_m @ x_i[:, j] + (A_i[j] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j] = x_i[:, j] + h * x_i_ponto
            y_i[j, k + 1] = h_transposto @ x_i[:, j]

        # dinâmica do modelo de referência e da planta
        x_m_ponto = A_m @ x_m[:, k] + b * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto
        x_p_ponto = A_p @ x_p[:, k] + b * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        y[k + 1] = h_transposto @ x_p[:, k + 1]

        # cálculo da norma 2 do erro
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

    estrutura = make_struct(x_p, x_m, eta_natural, theta_p_estimativa, norm_2_e_o, e_o, u, alfa_barra, r,
                            modelo_de_referencia, planta, theta_BARRA, modelos, tempo, endk)
    tic.toc()
    print("M =")
    print(M)
    return estrutura
