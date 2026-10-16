"""Port of dissertation/code/2016-second-level-adaptation-toolbox/L2A_IO_CL_Ident_V0_Completo.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang,
Chen, Proceedings of the 2014 American Control Conference). UFRN / PPgEEC,
aluno Pedro Gushiken.

Second-level adaptation for identification of a SISO plant with zeros
(npar = 2n parameters per column of `modelos`: numerator then denominator),
with "concurrent learning" and an adaptive choice of the gain gamma
(V0_Completo: if gamma > (2/lambda_max(M + E1'E1))/h, gamma is reset to one tenth of that bound; the dynamics are integrated with ode45 over each step).
The plant x_p' = A_p' x_p + C_p' u, the reference model and the npar+1 fixed
identification models x_i' = A_m' x_i + (A_i - A_m)' x_p + C_i' u are
integrated with ode45 over each step h (RelTol 1e-8 for the plant and the identification models, default options for the reference model) -> scipy solve_ivp(RK45). The second-level law uses the full state error matrix
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
- ode45 -> solve_ivp(method='RK45') with rtol=1e-8/atol=1e-6 (x_i, x_p) and the
  MATLAB defaults rtol=1e-3/atol=1e-6 (x_m). Results agree with MATLAB/Octave
  only up to the ODE tolerances (different step-size control). This version
  is slow (npar+3 ODE solves per step).
- The reference model is integrated with calc_x_p(A_m, C_m) driven by u(k)
  (not r(k)), as in the original.
- point_collection_* (2*npar memory) are allocated but unused in MATLAB;
  not ported.
"""
import numpy as np
from scipy.integrate import solve_ivp

from _toolbox_l2 import (TicToc, can, gmul, make_struct, mdiv, meig, minv, mlength, mmin,
                         norm2, parse_args, svdvals)
import matplotlib.pyplot as plt


def calc_x_p(t, x, u, A_p, C_p):
    """Subfunção usada nas chamadas ode45."""
    return A_p.T @ x + C_p * u


def calc_x_i(t, x, u, x_p, A_i, A_m, C_i):
    """Subfunção usada nas chamadas ode45."""
    return A_m.T @ x + (A_i - A_m).T @ x_p + C_i * u


def L2A_IO_CL_Ident_V0_Completo(args):
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
            passo_calculado[k] = mdiv(2, np.max(meig(M + E1tE1).real))
            if np.all(gamma > passo_calculado[k] / h):
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

            # opt = odeset('RelTol',1e-8)
            for j in range(npar + 1):
                sol = solve_ivp(calc_x_i, [tempo[k], tempo[k] + h], x_i[:, j], method="RK45",
                                rtol=1e-8, atol=1e-6,
                                args=(u[k], x_p[:, k], A_i[j], A_m, C_i[j]))
                y_i[j, k + 1] = b @ x_i[:, j]  # usa x_i(:,j,k), como no original
                x_i[:, j] = sol.y[:, -1]

            # dinâmica do modelo de referência (ode45 com opções padrão) e da planta
            sol = solve_ivp(calc_x_p, [tempo[k], tempo[k] + h], x_m[:, k], method="RK45",
                            rtol=1e-3, atol=1e-6, args=(u[k], A_m, C_m))
            x_m[:, k + 1] = sol.y[:, -1]
            y_m = b @ x_m[:, k + 1]  # noqa: F841
            sol = solve_ivp(calc_x_p, [tempo[k], tempo[k] + h], x_p[:, k], method="RK45",
                            rtol=1e-8, atol=1e-6, args=(u[k], A_p, C_p))
            x_p[:, k + 1] = sol.y[:, -1]
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
            Ml = np.diag(ev)
            garantia_exata[k] = mdiv(2 * tilde_alfa[:, k] @ Ml @ tilde_alfa[:, k],
                                     tilde_alfa[:, k] @ (Ml @ Ml) @ tilde_alfa[:, k])

    plt.plot(delta_V)
    estrutura = make_struct(x_p, x_m, eta_natural, theta_p_estimativa, norm_2_e_o, e_o, u,
                            alfa_barra, r, modelo_de_referencia, planta, theta_BARRA, modelos,
                            tempo, endk)
    tic.toc()
    return estrutura
