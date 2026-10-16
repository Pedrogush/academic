"""Port of dissertation/code/2016-second-level-adaptation-toolbox/L2AA_Ident.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang,
Chen, Proceedings of the 2014 American Control Conference). UFRN / PPgEEC,
aluno Pedro Gushiken.

Second-level adaptation, identification only, with access to the plant state
vector (plant without zeros, companion form). n+1 identification models
x_i' = A_m x_i + (A_i - A_m) x_p + b u are adapted at the first level
(theta_i' = -(e_i' P b) x_p, e_i = x_i - x_p) and combined at the second level:
E = [x_1 - x_{n+1}, ..., x_n - x_{n+1}],
alfa' = gamma*(-E'E alfa - E' e_{n+1}), with projection keeping alfa and
alfa_{n+1} = 1 - sum(alfa) in [0, 1]. The PE reference is smoothly switched off
when eta = a'Qa/(1+a'Qa) <= tol_eta. Euler integration with step h.

Input: struct/dict args with fields (in order) t_0, t_final, h, modelos,
planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
cond_iniciais_i, alfa0, Q, gamma, P, (não usado), ref_amp, ref_freq, tol_eta,
tau_ref. Output: make_struct(...) (x_p, x_m, eta, theta_p_estimativa,
norm_2_e_o, e_o, u, alfa_barra, r, modelo_de_referencia, planta, theta_BARRA,
modelos, tempo, endk). Plot with plot_adap_figures_L2_VE.

Porting notes:
- Indices are 0-based; output array sizes equal the final MATLAB sizes.
- can/convert_struct/make_struct from the "Toolbox Adaptacao L2" port (via
  _toolbox_l2). The controller vector k_T is computed in MATLAB but never
  used/output (u = r); it is not computed here.
- As in the original, u(1) = ref_amp(1) is overwritten by u(1) = r(1) = 0.
"""
import numpy as np

from _toolbox_l2 import TicToc, can, make_struct, mlength, parse_args


def L2AA_Ident(args):
    tic = TicToc()
    p = parse_args(args)
    t_0, t_final, h = p["t_0"], p["t_final"], p["h"]
    modelos, planta, modelo_de_referencia = p["modelos"], p["planta"], p["modelo_de_referencia"]
    Q, gamma, P = p["Q"], p["gamma"], p["P"]
    ref_amp, ref_freq, tol_eta, tau_ref = p["ref_amp"], p["ref_freq"], p["tol_eta"], p["tau_ref"]
    gmul = (lambda v: gamma @ v) if np.ndim(gamma) == 2 else (lambda v: gamma * v)

    stoptime = t_final - t_0
    endk = int(np.floor(stoptime / h))
    n_de_linhas = modelos.shape[0]
    nmod = mlength(modelos)  # length(modelos) = n+1
    n = n_de_linhas

    # matrizes na forma canônica (companion form):
    A_p = can(planta)
    A_m = can(modelo_de_referencia)
    A_i = [can(modelos[:, i]) for i in range(nmod)]
    # b é considerado conhecido, os sistemas não contém zeros.
    b = np.zeros(n)
    b[n - 1] = 1.0
    Pb = P @ b

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
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))
    theta_BARRA = np.zeros((n, nmod, endk + 1))
    theta_BARRA[:, :, 0] = modelos
    theta_i = modelos.astype(float).copy()  # theta_i(:,:,k), only the current one is kept

    # condições iniciais
    x_p[:, 0] = p["cond_iniciais_p"]
    x_m[:, 0] = p["cond_iniciais_m"]
    x_i = p["cond_iniciais_i"].reshape(n, -1)[:, :nmod].astype(float).copy()

    alfa[:, 0] = p["alfa0"]
    alfa_barra[:, 0] = np.concatenate([alfa[:, 0], [1 - np.sum(alfa[:, 0])]])
    if endk > 0:
        u[0] = ref_amp[0]
    tempo[0] = 0.0
    eta[0] = 0.0

    e_i = np.zeros((n, nmod))
    E = np.zeros((n, n))
    for k in range(endk):
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k + 1] = ref_amp @ np.cos(tempo[k] * ref_freq)
        if eta[k] <= tol_eta:
            r_ponto[k] = tau_ref * (-r[k] + ref_amp[0])
            r[k + 1] = r[k] + h * r_ponto[k]
        # Geração dos erros entre os modelos escolhidos e a planta
        for j in range(nmod):
            e_i[:, j] = x_i[:, j] - x_p[:, k]
        for j in range(n_de_linhas):
            E[:, j] = x_i[:, j] - x_i[:, n_de_linhas]
        # geração do vetor alfa
        alfa_ponto = gmul(-E.T @ E @ alfa[:, k] - E.T @ e_i[:, n_de_linhas])
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
        # composição de alfa para gerar alfa_barra
        alfa_barra[:, k] = np.concatenate([alfa[:, k], [1 - np.sum(alfa[:, k])]])
        # lei de controle
        u[k] = r[k]  # + transpose(k_T(:,k))*x_p(:,k);

        # adaptação de primeiro nível
        A_i_k = A_i
        A_i = []
        for j in range(nmod):
            theta_i_ponto = -(e_i[:, j] @ Pb) * x_p[:, k]
            theta_i[:, j] = theta_i[:, j] + h * theta_i_ponto
            theta_BARRA[:, j, k + 1] = theta_i[:, j]
            A_i.append(can(theta_BARRA[:, j, k + 1]))

        for j in range(nmod):
            x_i_ponto = A_m @ x_i[:, j] + (A_i_k[j] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j] = x_i[:, j] + h * x_i_ponto
        x_m_ponto = A_m @ x_m[:, k] + b * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto
        x_p_ponto = A_p @ x_p[:, k] + b * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        # cálculo da norma 2 do erro
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

    estrutura = make_struct(x_p, x_m, eta, theta_p_estimativa, norm_2_e_o, e_o, u, alfa_barra, r,
                            modelo_de_referencia, planta, theta_BARRA, modelos, tempo, endk)
    tic.toc()
    return estrutura
