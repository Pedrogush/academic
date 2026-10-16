"""Port of dissertation/code/2016-second-level-adaptation-toolbox/L2A_IO_Ident.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang,
Chen, Proceedings of the 2014 American Control Conference). UFRN / PPgEEC,
aluno Pedro Gushiken.

Second-level adaptation (identification only, input/output version): n+1 fixed
identification models (columns of `modelos`, companion form, no zeros) are run
in series-parallel form; the output errors y_i - y_{n+1} form the row E, and
the convex-combination weights alfa are adapted by the gradient law
    alfa_dot = gamma*(-E'E alfa - E'(y_{n+1} - y)),
with projection that keeps alfa (and alfa_{n+1} = 1 - sum(alfa)) inside [0, 1].
The PE reference r = ref_amp*cos(t*ref_freq) is smoothly switched off (first
order return to ref_amp(1) with constant tau_ref) while the figure of merit
eta = a'Qa/(1+a'Qa) is below tol_eta. Euler integration with step h.

Input: a struct/dict `args` whose fields (in this order) are
    t_0, t_final, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
    cond_iniciais_m, cond_iniciais_i, alfa0, Q, gamma, P, (não usado),
    ref_amp, ref_freq, tol_eta, tau_ref
(see the long header of the .m file). Output: make_struct(...) with fields
x_p, x_m, eta, theta_p_estimativa, norm_2_e_o, e_o, u, alfa_barra, r,
modelo_de_referencia, planta, theta_BARRA, modelos, tempo, endk.
Use plot_adap_figures_L2_VE (Toolbox Adaptacao L2) to plot the result.

Porting notes:
- Indices are 0-based; array sizes match the final MATLAB sizes (e.g. x_p is
  n x (endk+1), alfa_barra (n+1) x endk, u endk).
- can/convert_struct/make_struct come from the "Toolbox Adaptacao L2" port
  (via _toolbox_l2, importlib with inline fallback). The fields of `args` are
  taken by position, as convert_struct does in MATLAB.
- The first-level models are not adapted in this version (theta_i constant);
  intermediate variables that are never output (e_i, k_T, x_i history, A_i
  history) are not stored.
- As in the original, u(1) = ref_amp(1) is overwritten by u(1) = r(1) = 0.
"""
import numpy as np

from _toolbox_l2 import TicToc, can, make_struct, mlength, parse_args


def L2A_IO_Ident(args):
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
    eta = np.zeros(endk + 1)
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
    eta[0] = 0.0

    E = np.zeros(n)
    for k in range(endk):
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k + 1] = ref_amp @ np.cos(tempo[k] * ref_freq)
        if eta[k] <= tol_eta:
            r_ponto[k] = tau_ref * (-r[k] + ref_amp[0])
            r[k + 1] = r[k] + h * r_ponto[k]
        u[k] = r[k]

        for j in range(n_de_linhas):
            E[j] = y_i[j, k] - y_i[n_de_linhas, k]
        # geração do vetor alfa
        alfa_ponto = gmul(-np.outer(E, E) @ alfa[:, k] - E * (y_i[n_de_linhas, k] - y[k]))

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
        aqa = alfa_ponto @ Q @ alfa_ponto
        eta[k + 1] = aqa / (1 + aqa)

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

    estrutura = make_struct(x_p, x_m, eta, theta_p_estimativa, norm_2_e_o, e_o, u, alfa_barra, r,
                            modelo_de_referencia, planta, theta_BARRA, modelos, tempo, endk)
    tic.toc()
    return estrutura
