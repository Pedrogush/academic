"""Port of dissertation/code/2016-second-level-adaptation-toolbox/L2AA_CL_Ident.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang,
Chen, Proceedings of the 2014 American Control Conference). UFRN / PPgEEC,
aluno Pedro Gushiken.

Second-level adaptation for identification of a SISO plant with zeros
(npar = 2n parameters: numerator b (first n entries) and denominator a (last
n entries) of each column of `modelos`), with "concurrent learning". The plant
x_p' = A_p' x_p + C_p' u (observer-type canonical form, y = x_p(1)), the
reference model and npar+1 fixed identification models
x_i' = A_m' x_i + (A_i - A_m)' x_p + C_i' u are integrated with Euler steps.
The second-level weights alfa are adapted with the instantaneous output-error
term (E1 = first row of E = [x_1 - x_{npar+1}, ...]) plus the concurrent
term gamma*(-M alfa - vm), where M, vm accumulate samples that increase the
smallest singular value of M (and the norm of M by more than 50%). M and vm are
reset when the concurrent gradient vanishes and eta_natural < 1e-10. The PE
reference is smoothly switched off when eta_natural <= tol_eta.

Input: struct/dict args with fields (in order) t_0, t_final, h, modelos
(npar x (npar+1)), planta (npar column: [b; a]), modelo_de_referencia (row),
cond_iniciais_p (n), cond_iniciais_m (n), cond_iniciais_i (n x (npar+1)),
alfa0 (npar), Q, gamma, P, (não usado), ref_amp, ref_freq, tol_eta, tau_ref.
Output: make_struct(...) with eta = eta_natural. Also prints
theta_p_estimativa(:,endk) and svd(M), as the MATLAB code does.

Porting notes:
- Indices are 0-based; output array sizes equal the final MATLAB sizes.
- can/convert_struct/make_struct from the "Toolbox Adaptacao L2" port (via
  _toolbox_l2). svd via LAPACK gesvd. The M-update test compares singular
  values that may be at round-off level (E1'E1 has rank 1), so the switching
  instants can be sensitive to floating point details.
- Kept as in the original: y_i(j,k+1) = b'*x_i(:,j,k) uses the OLD state; the
  reference model uses A_m (not A_m') and b; alfa_ponto is always the natural
  law (both branches of the eta comparison are identical); 'if eta_natural<1e-10'
  is a MATLAB 'if' on the whole (growing) vector, i.e. all(...).
"""
import numpy as np

from _toolbox_l2 import TicToc, can, make_struct, mlength, norm2, parse_args, svdvals


def L2AA_CL_Ident(args):
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
    n = (mlength(modelos) - 1) // 2
    npar = mlength(modelos) - 1

    # Sistemas em forma canônica controlável
    A_p = can(planta[n:npar])
    C_p = planta[:n].copy()
    A_m = can(modelo_de_referencia[n:npar])
    C_m = modelo_de_referencia[:n][::-1].copy()  # noqa: F841 (y_m não é usado)
    A_i = [can(modelos[n:npar, i]) for i in range(npar + 1)]
    C_i = [modelos[:n, i][::-1].copy() for i in range(npar + 1)]
    b = np.zeros(n)
    b[0] = 1.0

    tempo = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    r_ponto = np.zeros(endk)
    eta_natural = np.zeros(endk + 1)
    eta_concorrente = np.zeros(endk + 1)
    u = np.zeros(endk)
    alfa = np.zeros((npar, endk + 1))
    alfa_barra = np.zeros((npar + 1, endk))
    x_p = np.zeros((n, endk + 1))
    x_m = np.zeros((n, endk + 1))
    y = np.zeros(endk + 1)
    y_i = np.zeros((npar + 1, endk + 1))
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((npar, endk))
    theta_BARRA = np.zeros((npar, npar + 1, endk + 1))
    theta_BARRA[:, :, 0] = modelos

    # condições iniciais
    x_p[:, 0] = p["cond_iniciais_p"]
    y[0] = C_p @ x_p[:, 0]
    x_m[:, 0] = p["cond_iniciais_m"]
    x_i = p["cond_iniciais_i"].reshape(n, -1)[:, :npar + 1].astype(float).copy()
    for j in range(npar + 1):
        y_i[j, 0] = C_i[j] @ x_i[:, j]

    alfa[:, 0] = p["alfa0"]
    alfa_barra[:, 0] = np.concatenate([alfa[:, 0], [1 - np.sum(alfa[:, 0])]])
    if endk > 0:
        u[0] = ref_amp[0]

    M = np.zeros((npar, npar))
    vm = np.zeros(npar)
    E = np.zeros((n, npar))
    for k in range(endk):
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k + 1] = ref_amp @ np.cos(tempo[k] * ref_freq)
        if eta_natural[k] <= tol_eta:
            r_ponto[k] = tau_ref * (-r[k] + ref_amp[0])
            r[k + 1] = r[k] + h * r_ponto[k]
        u[k] = r[k]

        for j in range(npar):
            E[:, j] = x_i[:, j] - x_i[:, npar]
        E1 = E[0, :]
        E1tE1 = np.outer(E1, E1)
        erro_y = y_i[npar, k] - y[k]

        alfa_ponto_natural = gmul(-E1tE1 @ alfa[:, k] - E1 * erro_y) + gmul(-M @ alfa[:, k] - vm)
        alfa_ponto_concorrente = gmul(-M @ alfa[:, k] - vm)

        if np.min(svdvals(M)) < np.min(svdvals(M + E1tE1)):
            if 1.5 * norm2(M) < norm2(M + E1tE1):
                M = M + E1tE1
                vm = vm + E1 * (y_i[n_de_linhas, k] - y[k])

        if norm2(-M @ alfa[:, k] - vm) < 1e-5:
            if np.all(eta_natural[:k + 1] < 1e-10):
                M = np.zeros((npar, npar))
                vm = np.zeros(npar)

        if eta_concorrente[k] < eta_natural[k]:
            alfa_ponto = alfa_ponto_natural.copy()
        else:
            alfa_ponto = alfa_ponto_natural.copy()

        alfa_n1 = 1 - np.sum(alfa[:, k])
        alfa_ponto_n1 = -np.sum(alfa_ponto)
        for i in range(npar):
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

        # Adaptação dos modelos de primeiro nível (modelos fixos)
        theta_BARRA[:, :, k + 1] = theta_BARRA[:, :, k]

        for j in range(npar + 1):
            x_i_ponto = A_m.T @ x_i[:, j] + (A_i[j] - A_m).T @ x_p[:, k] + C_i[j] * u[k]
            y_i[j, k + 1] = b @ x_i[:, j]  # usa x_i(:,j,k), como no original
            x_i[:, j] = x_i[:, j] + h * x_i_ponto

        # dinâmica do modelo de referência e da planta
        x_m_ponto = A_m @ x_m[:, k] + b * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto
        x_p_ponto = A_p.T @ x_p[:, k] + C_p * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        y[k + 1] = b @ x_p[:, k + 1]

        # cálculo da norma 2 do erro
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

    estrutura = make_struct(x_p, x_m, eta_natural, theta_p_estimativa, norm_2_e_o, e_o, u,
                            alfa_barra, r, modelo_de_referencia, planta, theta_BARRA, modelos,
                            tempo, endk)
    if endk > 0:
        print("ans =\n", theta_p_estimativa[:, endk - 1])
    print("ans =\n", svdvals(M))
    tic.toc()
    return estrutura
