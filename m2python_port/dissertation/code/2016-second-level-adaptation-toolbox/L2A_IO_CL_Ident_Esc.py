"""Port of dissertation/code/2016-second-level-adaptation-toolbox/L2A_IO_CL_Ident_Esc.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang,
Chen, Proceedings of the 2014 American Control Conference). UFRN / PPgEEC,
aluno Pedro Gushiken.

Second-level adaptation for identification of a SISO plant with zeros
(npar = 2n parameters per column of `modelos`: numerator then denominator),
with "concurrent learning" and an adaptive choice of the gain gamma
(Esc: if the Euler step matrix M0 - gamma*h*M0^2, M0 = M + E'E, has a negative eigenvalue, gamma is reset to (2/lambda_max(M0))/(10 h)).
The plant x_p' = A_p' x_p + C_p' u, the reference model and the npar+1 fixed
identification models x_i' = A_m' x_i + (A_i - A_m)' x_p + C_i' u are
integrated with explicit Euler steps. The second-level law uses the full state error matrix
E = [x_1 - x_{npar+1}, ..., x_npar - x_{npar+1}]:
    alfa' = gamma*(-E'E alfa - E'(x_{npar+1} - x_p)) + gamma*(-M alfa - vm),
with M += E'E, vm += E'(x_{npar+1} - x_p) whenever the first row E1 of E
increases the smallest singular value of M (and the norm of M by > 50%).
Projection keeps alfa and alfa_{npar+1} in [0, 1]; the PE reference is
switched off when eta_natural <= tol_eta. Diagnostics computed each step:
tilde_alfa = alfa - alfa_estrela (alfa_estrela: exact barycentric coordinates
of the plant), V = |tilde_alfa|^2, delta_V = sign(V(k+1) - V(k)) (plotted at
the end, as in MATLAB), garantia_robusta, garantia_exata.

Input: struct/dict args with fields (in order) t_0, t_final, h, modelos
(npar x (npar+1)), planta (npar column [b; a]), modelo_de_referencia (row),
cond_iniciais_p, cond_iniciais_m (n), cond_iniciais_i (n x (npar+1)), alfa0,
Q, gamma, P, (não usado), ref_amp, ref_freq, tol_eta, tau_ref.
Output: make_struct(...) with eta = eta_natural.

Porting notes:
- Indices are 0-based; output array sizes equal the final MATLAB sizes.
- can/convert_struct/make_struct from the "Toolbox Adaptacao L2" port (via
  _toolbox_l2). eig/svd follow MATLAB's LAPACK choices (syev for exactly
  symmetric matrices, geev otherwise; gesvd). Several tests compare
  eigenvalues/singular values that are at round-off level (E'E has rank n <
  npar), so the switching instants (M update, gamma change) can depend on
  floating-point details.
- Kept as in the original: y_i(j,k+1) = b'*x_i(:,j,k) uses the OLD state;
  alfa_ponto is always the natural law; 'if eta_natural<1e-10' acts on the
  whole growing vector (all(...)); the M-update test uses only E(1,:) while
  M itself accumulates the full E'E.
- The unused quantities point_collection_*, passo_int_revisado, x_p_obs, y_m,
  k_T, Ml are not stored (passo_int_revisado/Ml only where needed).
- Lines with ode45 alternatives (commented out in MATLAB) are not ported;
  the subfunctions calc_x_p/calc_x_i are kept.
"""
import numpy as np

from _toolbox_l2 import (TicToc, can, gmul, make_struct, mdiv, meig, minv, mlength, mmin,
                         norm2, parse_args, svdvals)
import matplotlib.pyplot as plt


def calc_x_p(t, x, u, A_p, C_p):
    """Subfunção (não usada: chamadas ode45 comentadas no original)."""
    return A_p.T @ x + C_p * u


def calc_x_i(t, x, u, x_p, A_i, A_m, C_i):
    """Subfunção (não usada: chamadas ode45 comentadas no original)."""
    return A_m.T @ x + (A_i - A_m).T @ x_p + C_i * u


def L2A_IO_CL_Ident_Esc(args):
    tic = TicToc()
    p = parse_args(args)
    t_0, t_final, h = p["t_0"], p["t_final"], p["h"]
    modelos, planta, modelo_de_referencia = p["modelos"], p["planta"], p["modelo_de_referencia"]
    Q, gamma, P = p["Q"], p["gamma"], p["P"]
    ref_amp, ref_freq, tol_eta, tau_ref = p["ref_amp"], p["ref_freq"], p["tol_eta"], p["tau_ref"]

    stoptime = t_final - t_0
    endk = int(np.floor(stoptime / h))
    n_de_linhas = modelos.shape[0]
    n = (mlength(modelos) - 1) // 2
    npar = mlength(modelos) - 1

    # Sistemas em forma canônica controlável
    A_p = can(planta[n:npar])
    C_p = planta[:n].copy()
    A_m = can(modelo_de_referencia[n:npar])
    C_m = modelo_de_referencia[:n][::-1].copy()
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
    passo_calculado = np.zeros(endk)
    tilde_alfa = np.zeros((npar, endk))
    V = np.zeros(endk + 1)
    delta_V = np.zeros(endk + 1)
    garantia_robusta = np.zeros(endk)
    garantia_exata = np.zeros(endk)

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
    TB = theta_BARRA[:, :, 0]
    alfa_estrela = minv(np.vstack([TB, np.ones((1, mlength(TB)))])) @ np.concatenate([planta, [1.0]])
    alfa_estrela = alfa_estrela[:len(alfa_estrela) - 1]
    E = np.zeros((n, npar))
    with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
        for k in range(endk):
            for j in range(npar):
                E[:, j] = x_i[:, j] - x_i[:, npar]
            EtE = E.T @ E
            E1 = E[0, :]
            E1tE1 = np.outer(E1, E1)
            passo_calculado[k] = mdiv(2, np.max(meig(M + EtE).real))
            M0 = M + EtE
            M0sq = M0 @ M0
            eig_s = meig(M0 - (M0sq @ gamma * h if np.ndim(gamma) == 2 else M0sq * gamma * h))
            if np.real(mmin(eig_s)) < 0:
                gamma = passo_calculado[k] / (10 * h)

            # tempo de simulação
            tempo[k + 1] = tempo[k] + h
            # sinal de referência
            r[k + 1] = ref_amp @ np.cos(tempo[k] * ref_freq)
            if eta_natural[k] <= tol_eta:
                r_ponto[k] = tau_ref * (-r[k] + ref_amp[0])
                r[k + 1] = r[k] + h * r_ponto[k]
            u[k] = r[k]

            erro_x = x_i[:, npar] - x_p[:, k]
            alfa_ponto_natural = (gmul(gamma, -EtE @ alfa[:, k] - E.T @ erro_x)
                                  + gmul(gamma, -M @ alfa[:, k] - vm))
            alfa_ponto_concorrente = gmul(gamma, -M @ alfa[:, k] - vm)

            s1 = svdvals(M)
            s2 = svdvals(M + E1tE1)
            if np.min(s1) < np.min(s2):
                if 1.5 * norm2(M) < norm2(M + E1tE1):
                    M = M + EtE
                    vm = vm + E.T @ (x_i[:, n_de_linhas] - x_p[:, k])

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
            y_m = b @ x_m[:, k + 1]  # noqa: F841
            x_p_ponto = A_p.T @ x_p[:, k] + C_p * u[k]
            x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
            y[k + 1] = b @ x_p[:, k + 1]

            # cálculo da norma 2 do erro
            e_o[:, k] = x_m[:, k] - x_p[:, k]
            norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
            theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

            tilde_alfa[:, k] = alfa[:, k] - alfa_estrela
            V[k + 1] = tilde_alfa[:, k] @ tilde_alfa[:, k]
            delta_V[k + 1] = np.sign(V[k + 1] - V[k])
            ev = meig(M + E.T @ E)
            garantia_robusta[k] = mdiv(2 * mmin(ev).real, np.max(ev.real) ** 2)
            garantia_exata[k] = mdiv(tilde_alfa[:, k] @ M0 @ tilde_alfa[:, k],
                                     h * tilde_alfa[:, k] @ (M0 @ M0) @ tilde_alfa[:, k])

    plt.plot(delta_V)
    estrutura = make_struct(x_p, x_m, eta_natural, theta_p_estimativa, norm_2_e_o, e_o, u,
                            alfa_barra, r, modelo_de_referencia, planta, theta_BARRA, modelos,
                            tempo, endk)
    tic.toc()
    return estrutura
