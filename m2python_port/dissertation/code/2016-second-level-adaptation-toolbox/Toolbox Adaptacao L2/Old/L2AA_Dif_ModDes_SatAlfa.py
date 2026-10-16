"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2AA_Dif_ModDes_SatAlfa.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Second-level adaptation ("L2AA": adaptive identification models) with the differential
method for alpha: n+1 identification models theta_i (columns of ``modelos``) are themselves
adapted by first-level laws (theta_i_dot = -e_i' P b x_p), while the convex-combination
weights alpha follow alpha_dot = gamma*(-E'E alpha - E' e_{n+1}) with saturation of every
alpha_bar component to [0, 1]. The controller is k = theta_m - THETA_BARRA*alpha_bar. The
PE reference r = ref(1 + 0.2 sin t + 0.2 sin 2t) is switched off (r -> ref through a first
order filter) whenever the merit figure eta = a'Qa/(1+a'Qa) of alpha_dot falls below 1e-2.
All systems are in companion form with b = [0 ... 0 1]'. Forward-Euler integration.

Porting notes:
- ``can`` (companion matrix, from ../can.m) is inlined as a small copy.
- MATLAB auto-growing arrays are preallocated; r(1) is 0 because MATLAB auto-fills it
  when r(2) is first assigned (kept). alfa_barra/u/k_T have endk columns as in MATLAB.
- The saturation loop (sign(alpha_dot_{n+1}) ~= sign(alpha_dot_j) -> zero) is kept literally,
  including its placement inside the ``for i`` loop.
- The ``animatedline`` created at the top of the MATLAB function is never fed with points
  (no animation in this file), so it is dropped.
- The function returns a dict with the simulation arrays (MATLAB returned nothing).
- ``legend`` of figure 3 in MATLAB re-used the previous legend handle (no new legend); same here.
"""
import numpy as np
import matplotlib.pyplot as plt


def can(vect):
    """Companion matrix: ones on the super-diagonal, last row = vect (copy of ../can.m)."""
    vect = np.asarray(vect, dtype=float).ravel()
    n = vect.size
    A = np.zeros((n, n))
    for linha in range(n - 1):
        A[linha, linha + 1] = 1.0
    A[n - 1, :] = vect
    return A


def _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
              cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma, P):
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    modelo_de_referencia = np.asarray(modelo_de_referencia, dtype=float).ravel()
    Q = np.atleast_2d(np.asarray(Q, dtype=float))
    P = np.atleast_2d(np.asarray(P, dtype=float))
    n = modelos.shape[0]
    N = max(modelos.shape)  # length(modelos)
    na = N - 1
    A_p = can(planta)
    A_m = can(modelo_de_referencia)
    b = np.zeros(n)
    b[n - 1] = 1.0
    endk = int(np.floor(stoptime / h))

    theta_BARRA = np.zeros((n, N, endk + 1))
    theta_BARRA[:, :, 0] = modelos
    x_p = np.zeros((n, endk + 1))
    x_m = np.zeros((n, endk + 1))
    x_i = np.zeros((n, N, endk + 1))
    x_p[:, 0] = np.asarray(cond_iniciais_p, dtype=float).ravel()
    x_m[:, 0] = np.asarray(cond_iniciais_m, dtype=float).ravel()
    x_i[:, :, 0] = np.asarray(cond_iniciais_i, dtype=float).reshape(n, N)
    e_i = np.zeros((n, N, endk))
    alfa = np.zeros((na, endk + 1))
    alfa[:, 0] = np.asarray(alfa0, dtype=float).ravel()
    alfa_ponto = np.zeros((na, endk))
    alfa_barra = np.zeros((N, endk))
    alfa_barra[:, 0] = np.append(alfa[:, 0], 1 - alfa[:, 0].sum())
    k_T = np.zeros((n, endk))
    k_T[:, 0] = modelo_de_referencia - modelos @ alfa_barra[:, 0]
    u = np.zeros(endk)
    u[0] = referencia
    tempo = np.zeros(endk + 1)
    eta = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    r_ponto = np.zeros(endk)
    alfa_n1 = np.zeros(endk)
    alfa_ponto_n1 = np.zeros(endk)
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = referencia + 0.2 * referencia * np.sin(tempo[k]) + 0.2 * referencia * np.sin(2 * tempo[k])
        if eta[k] <= 1e-2:
            r_ponto[k] = 10 * (-r[k] + referencia)
            r[k + 1] = r[k] + h * r_ponto[k]
        e_i[:, :, k] = x_i[:, :, k] - x_p[:, [k]]
        E = x_i[:, :na, k] - x_i[:, [N - 1], k]
        ap = gamma * (-E.T @ E @ alfa[:, k] - E.T @ e_i[:, N - 1, k])
        alfa_n1[k] = 1 - alfa[:, k].sum()
        alfa_ponto_n1[k] = -ap.sum()
        for i in range(na):
            if (alfa[i, k] >= 1 and ap[i] > 0) or (alfa[i, k] <= 0 and ap[i] < 0):
                ap[i] = 0.0
            if (alfa_n1[k] >= 1 and alfa_ponto_n1[k] > 0) or (alfa_n1[k] <= 0 and alfa_ponto_n1[k] < 0):
                for j in range(na):
                    if np.sign(alfa_ponto_n1[k]) != np.sign(ap[j]):
                        ap[j] = 0.0
        alfa_ponto[:, k] = ap
        alfa[:, k + 1] = alfa[:, k] + h * ap
        qq = ap @ Q @ ap
        eta[k + 1] = qq / (1 + qq)
        alfa_barra[:, k] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k] = modelo_de_referencia - theta_BARRA[:, :, k] @ alfa_barra[:, k]
        u[k] = r[k] + k_T[:, k] @ x_p[:, k]
        for j in range(N):
            theta_i_ponto = -(e_i[:, j, k] @ P @ b) * x_p[:, k]
            theta_BARRA[:, j, k + 1] = theta_BARRA[:, j, k] + h * theta_i_ponto
        for j in range(N):
            A_i = can(theta_BARRA[:, j, k])
            x_i_ponto = A_m @ x_i[:, j, k] + (A_i - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

    return dict(tempo=tempo, r=r, eta=eta, alfa=alfa, alfa_ponto=alfa_ponto, alfa_barra=alfa_barra,
                k_T=k_T, u=u, x_p=x_p, x_m=x_m, x_i=x_i, e_i=e_i, theta_BARRA=theta_BARRA,
                e_o=e_o, norm_2_e_o=norm_2_e_o, theta_p_estimativa=theta_p_estimativa, endk=endk)


def _std_axes(ax, title, xlabel='Tempo (s)', ylabel='Amplitude'):
    ax.grid(True)
    ax.set_xlabel(xlabel, fontsize=14)
    ax.set_ylabel(ylabel, fontsize=14)
    ax.set_title(title, fontsize=14)
    ax.tick_params(labelsize=14)


def L2AA_Dif_ModDes_SatAlfa(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
                            cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma, P):
    """Simulate and draw figures 1-7 of the MATLAB function. Returns the simulation dict."""
    s = _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
                  cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma, P)
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    mref = np.asarray(modelo_de_referencia, dtype=float).ravel()
    tempo, endk = s['tempo'], s['endk']
    tempo_acesso = tempo[:endk]

    plt.figure(1)
    ax = plt.gca()
    ax.plot(tempo, s['x_m'][0], color='k', lw=2, label='Modelo, $x_m(1)$')
    ax.plot(tempo, s['x_p'][0], color='r', lw=2, ls=':', label='Planta, $x_p(1)$')
    ax.plot(tempo, s['r'] / abs(mref[0]), color='b', lw=2, label='Referencia/Ganho Estático')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Saída do sistema (Método Diferencial)')

    plt.figure(2)
    ax = plt.gca()
    ax.plot(tempo, s['x_m'][1], color='k', lw=2, label='Modelo, $x_m(2)$')
    ax.plot(tempo, s['x_p'][1], color='r', lw=2, ls=':', label='Planta, $x_p(2)$')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Saída do sistema (Método Diferencial)')

    plt.figure(3)
    ax = plt.gca()
    ax.plot(tempo_acesso, s['alfa_barra'].T, lw=2)
    _std_axes(ax, 'Valores dos alfas')

    plt.figure(4)
    ax = plt.gca()
    ax.plot(tempo_acesso, s['u'], color='k', lw=2, label='Sinal de Controle')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Sinal de Controle')

    plt.figure(5)
    ax = plt.gca()
    ax.plot(tempo_acesso, s['norm_2_e_o'], color='k', lw=2, label='Norma 2 do Erro de Saída')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Norma 2 do erro de Saída entre o modelo de referência e a planta')

    if planta.size == 2:
        plt.figure(6)
        ax = plt.gca()
        tb = s['theta_BARRA'][:, :, endk - 1]
        ax.plot(np.append(tb[0], tb[0, 0]), np.append(tb[1], tb[1, 0]), color='m', lw=2)
        ax.plot(planta[0], planta[1], color='c', lw=2, marker='o')
        ax.plot(np.append(modelos[0], modelos[0, 0]), np.append(modelos[1], modelos[1, 0]), color='r', lw=2)
        ax.plot(s['theta_p_estimativa'][0], s['theta_p_estimativa'][1], color='b', lw=2)
        ax.grid(True)

    plt.figure(7)
    ax = plt.gca()
    ax.plot(tempo, s['eta'], color='k', lw=2, label='Fig. Mérito ETA')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Fig. Mérito ETA')
    return s


def main():
    # exemplo 1, 2 parâmetros desconhecidos (from the MATLAB header)
    s = L2AA_Dif_ModDes_SatAlfa(18, 1e-3, [[-4, -3, 8], [-5, -2, -4]], [2.3, -3.6], [-4, -4], [0, 0],
                                [0.2, 0.3], [[0, 0, 0], [0, 0, 0]], [0, 1], 5,
                                [[1e4, 0], [0, 1e4]], 20, [[1, 0], [0, 1]])
    print('theta_p_estimativa(:,end) =', s['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
