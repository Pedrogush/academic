"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2A_Dif_ModDes.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

L2A_Dif (fixed identification models, differential alpha law) with two modifications:
1) a gain ``gamma`` in the alpha differential equation (does not move the equilibrium);
2) a PE switch-off scheme ("ModDes" = modo desligamento, as in the author's TCC): the
merit figure eta = a'Qa/(1+a'Qa) of alpha_dot is computed and, while eta <= 1e-4, the
sinusoidal reference r = referencia*sin(t) is replaced by a first-order approach
r_dot = 10(referencia - r). Draws figures 1-7 (7 = eta).

Porting notes:
- Arrays preallocated; r(1) = 0 as MATLAB's auto-fill; returns the simulation dict.
- Plotting of figures 1-6 reused from L2A_Dif.py (identical code in MATLAB).
"""
import numpy as np
import matplotlib.pyplot as plt

from L2A_Dif import can, plot_common, _std_axes


def _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
              cond_iniciais_i, alfa0, referencia, Q, gamma, eta_thr=1e-4, r_gain=10.0, x_p_chapeu=False):
    """Euler loop of L2A_Dif_ModDes.m (eta_thr/r_gain/x_p_chapeu let ModEnm1 reuse it)."""
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    modelo_de_referencia = np.asarray(modelo_de_referencia, dtype=float).ravel()
    Q = np.atleast_2d(np.asarray(Q, dtype=float))
    n = modelos.shape[0]
    N = max(modelos.shape)
    na = N - 1
    A_i = [can(modelos[:, j]) for j in range(N)]
    A_p = can(planta)
    A_m = can(modelo_de_referencia)
    theta_BARRA = modelos
    b = np.zeros(n)
    b[n - 1] = 1.0
    endk = int(np.floor(stoptime / h))

    x_p = np.zeros((n, endk + 1))
    x_m = np.zeros((n, endk + 1))
    x_i = np.zeros((n, N, endk + 1))
    x_p[:, 0] = np.asarray(cond_iniciais_p, dtype=float).ravel()
    x_m[:, 0] = np.asarray(cond_iniciais_m, dtype=float).ravel()
    x_i[:, :, 0] = np.asarray(cond_iniciais_i, dtype=float).reshape(n, N)
    xpc = np.zeros((n, endk + 1))
    xpc[:, 0] = x_p[:, 0]
    e_est = np.zeros((n, endk))
    e_i = np.zeros((n, N, endk))
    alfa = np.zeros((na, endk + 1))
    alfa[:, 0] = np.asarray(alfa0, dtype=float).ravel()
    alfa_ponto = np.zeros((na, endk))
    alfa_barra = np.zeros((N, endk))
    alfa_barra[:, 0] = np.append(alfa[:, 0], 1 - alfa[:, 0].sum())
    k_T = np.zeros((n, endk))
    k_T[:, 0] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, 0]
    u = np.zeros(endk)
    u[0] = referencia
    tempo = np.zeros(endk + 1)
    eta = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    r_ponto = np.zeros(endk)
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = referencia * np.sin(tempo[k])
        if eta[k] <= eta_thr:
            r_ponto[k] = r_gain * (-r[k] + referencia)
            r[k + 1] = r[k] + h * r_ponto[k]
        e_i[:, :, k] = x_i[:, :, k] - x_p[:, [k]]
        E = x_i[:, :na, k] - x_i[:, [N - 1], k]
        e_est[:, k] = xpc[:, k] - x_p[:, k]
        ap = gamma * (-E.T @ E @ alfa[:, k] - E.T @ e_i[:, N - 1, k])
        alfa_ponto[:, k] = ap
        alfa[:, k + 1] = alfa[:, k] + h * ap
        qq = ap @ Q @ ap
        eta[k + 1] = qq / (1 + qq)
        alfa_barra[:, k] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, k]
        u[k] = r[k] + k_T[:, k] @ x_p[:, k]
        for j in range(N):
            x_i_ponto = A_m @ x_i[:, j, k] + (A_i[j] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])
        if x_p_chapeu:
            A_p_chapeu = can(theta_BARRA @ alfa_barra[:, k])
            xpc[:, k + 1] = xpc[:, k] + h * (A_p_chapeu @ x_p[:, k] + b * u[k])
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA @ alfa_barra[:, k]

    s = dict(tempo=tempo, r=r, eta=eta, alfa=alfa, alfa_ponto=alfa_ponto, alfa_barra=alfa_barra, k_T=k_T,
             u=u, x_p=x_p, x_m=x_m, x_i=x_i, e_i=e_i, e_o=e_o, norm_2_e_o=norm_2_e_o,
             theta_p_estimativa=theta_p_estimativa, endk=endk)
    if x_p_chapeu:
        s.update(x_p_chapeu=xpc, e_est=e_est)
    return s


def plot_eta(s):
    plt.figure(7)
    ax = plt.gca()
    ax.plot(s['tempo'], s['eta'], color='k', lw=2, label='Fig. Mérito ETA')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Fig. Mérito ETA')


def L2A_Dif_ModDes(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                   cond_iniciais_i, alfa0, referencia, Q, gamma):
    s = _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                  cond_iniciais_i, alfa0, referencia, Q, gamma)
    plot_common(s, modelos, planta)
    plot_eta(s)
    return s


def main():
    # first example of the MATLAB header (two other orderings of the same models are listed there)
    s = L2A_Dif_ModDes(25, 1e-3, [[7, -2, 3], [-3, -2, -6]], [0.8, -3], [-4, -4], [0.001, 0.002], [0, 0],
                       [[0.001, 0.001, 0.001], [0.002, 0.002, 0.002]], [0, 0], 5, [[1e4, 0], [0, 1e4]], 1)
    print('theta_p_estimativa(:,end) =', s['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
