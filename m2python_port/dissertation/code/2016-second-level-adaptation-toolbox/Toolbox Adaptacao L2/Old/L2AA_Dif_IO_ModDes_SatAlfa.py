"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2AA_Dif_IO_ModDes_SatAlfa.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Input/output ("IO") attempt of L2AA_Dif_ModDes_SatAlfa: instead of the full plant state,
the identification models and the controller use w2 = [x_p(1); w1_dot], where w1 is the
plant output passed through the filter w1_dot = Lambdaf w1 + l y_p (Lambdaf = can(filtro),
l = [0..0 -filtro(1)]'). Everything else is the L2AA_Dif_ModDes_SatAlfa algorithm:
adaptive identification models (theta_i_dot = -e_i' P b w2), saturated differential alpha
law, eta-based switch-off of the PE reference (threshold 1e-2). Figures 1-7 as in MATLAB,
with the filtered signals added to figures 1 and 2.

Porting notes:
- ``can`` (../can.m) inlined. Arrays preallocated; r(1) = 0 as MATLAB's auto-fill.
- BUG kept: ``w_i_ponto(:,j,k) = Lambdaf*w_i(:,k) + ...`` uses 2-D linear indexing of the
  3-D array w_i, i.e. w_i(:, mod(k-1,N)+1, floor((k-1)/N)+1) - not w_i(:,j,k). Reproduced.
  (w_i is only an auxiliary filter state; it does not feed back into the loop.)
- ``w_i2`` (computed but never used in MATLAB) is omitted.
- The animatedline created at the top of the MATLAB function is never used; dropped.
- ``filtro`` must have n-1 entries (w2 must have n rows), as implied by the MATLAB code.
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


def _simulate(stoptime, h, modelos, planta, filtro, modelo_de_referencia, cond_iniciais_p,
              cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma, P):
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    filtro = np.asarray(filtro, dtype=float).ravel()
    modelo_de_referencia = np.asarray(modelo_de_referencia, dtype=float).ravel()
    Q = np.atleast_2d(np.asarray(Q, dtype=float))
    P = np.atleast_2d(np.asarray(P, dtype=float))
    cip = np.asarray(cond_iniciais_p, dtype=float).ravel()
    n = modelos.shape[0]
    N = max(modelos.shape)
    na = N - 1
    nf = filtro.size
    Lambdaf = can(filtro)
    l = np.zeros(nf)
    l[nf - 1] = -filtro[0]
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
    x_p[:, 0] = cip
    x_m[:, 0] = np.asarray(cond_iniciais_m, dtype=float).ravel()
    x_i[:, :, 0] = np.asarray(cond_iniciais_i, dtype=float).reshape(n, N)
    w1 = np.zeros((n - 1, endk + 1))
    w1[:, 0] = cip[:n - 1]
    w1_ponto = np.zeros((nf, endk))
    w2 = np.zeros((n, endk))
    w_i = np.zeros((n - 1, N, endk + 1))
    w_i[:, :, 0] = x_i[:n - 1, :, 0]
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
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = referencia + 0.2 * referencia * np.sin(tempo[k]) + 0.2 * referencia * np.sin(2 * tempo[k])
        if eta[k] <= 1e-2:
            r_ponto[k] = 10 * (-r[k] + referencia)
            r[k + 1] = r[k] + h * r_ponto[k]
        w1_ponto[:, k] = Lambdaf @ w1[:, k] + l * x_p[0, k]
        w1[:, k + 1] = w1[:, k] + h * w1_ponto[:, k]
        w2[:, k] = np.concatenate(([x_p[0, k]], w1_ponto[:, k]))
        e_i[:, :, k] = x_i[:, :, k] - w2[:, [k]]
        E = x_i[:, :na, k] - x_i[:, [N - 1], k]
        ap = gamma * (-E.T @ E @ alfa[:, k] - E.T @ e_i[:, N - 1, k])
        alfa_n1 = 1 - alfa[:, k].sum()
        alfa_ponto_n1 = -ap.sum()
        for i in range(na):
            if (alfa[i, k] >= 1 and ap[i] > 0) or (alfa[i, k] <= 0 and ap[i] < 0):
                ap[i] = 0.0
            if (alfa_n1 >= 1 and alfa_ponto_n1 > 0) or (alfa_n1 <= 0 and alfa_ponto_n1 < 0):
                for j in range(na):
                    if np.sign(alfa_ponto_n1) != np.sign(ap[j]):
                        ap[j] = 0.0
        alfa_ponto[:, k] = ap
        alfa[:, k + 1] = alfa[:, k] + h * ap
        qq = ap @ Q @ ap
        eta[k + 1] = qq / (1 + qq)
        alfa_barra[:, k] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k] = modelo_de_referencia - theta_BARRA[:, :, k] @ alfa_barra[:, k]
        u[k] = r[k] + k_T[:, k] @ w2[:, k]
        for j in range(N):
            theta_i_ponto = -(e_i[:, j, k] @ P @ b) * w2[:, k]
            theta_BARRA[:, j, k + 1] = theta_BARRA[:, j, k] + h * theta_i_ponto
        for j in range(N):
            A_i = can(theta_BARRA[:, j, k])
            x_i_ponto = A_m @ x_i[:, j, k] + (A_i - A_m) @ w2[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto
            # MATLAB w_i(:,k): linear 2-D indexing of the 3-D array (bug kept)
            w_i_ponto = Lambdaf @ w_i[:, k % N, k // N] + l * x_i[0, j, k]
            w_i[:, j, k + 1] = w_i[:, j, k] + h * w_i_ponto
            w_i[0, j, k + 1] = x_i[0, j, k + 1]
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

    return dict(tempo=tempo, r=r, eta=eta, alfa=alfa, alfa_ponto=alfa_ponto, alfa_barra=alfa_barra,
                k_T=k_T, u=u, x_p=x_p, x_m=x_m, x_i=x_i, e_i=e_i, theta_BARRA=theta_BARRA, w1=w1, w2=w2,
                w_i=w_i, e_o=e_o, norm_2_e_o=norm_2_e_o, theta_p_estimativa=theta_p_estimativa, endk=endk)


def _std_axes(ax, title):
    ax.grid(True)
    ax.set_xlabel('Tempo (s)', fontsize=14)
    ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title(title, fontsize=14)
    ax.tick_params(labelsize=14)


def L2AA_Dif_IO_ModDes_SatAlfa(stoptime, h, modelos, planta, filtro, modelo_de_referencia, cond_iniciais_p,
                               cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma, P):
    """Simulate and draw figures 1-7. Returns the simulation dict."""
    s = _simulate(stoptime, h, modelos, planta, filtro, modelo_de_referencia, cond_iniciais_p,
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
    ax.plot(tempo_acesso, s['w2'][0], color='g', lw=2, ls=':', label='Filtrado')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Saída do sistema (Método Diferencial)')

    plt.figure(2)
    ax = plt.gca()
    ax.plot(tempo, s['x_m'][1], color='k', lw=2, label='Modelo, $x_m(2)$')
    ax.plot(tempo, s['x_p'][1], color='r', lw=2, ls=':', label='Planta, $x_p(2)$')
    ax.plot(tempo_acesso, s['w2'][1], color='g', lw=2, ls=':', label='filtrado')
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
    # header example of the family, with a first-order output filter filtro = -1 (no
    # example call for this IO variant exists in the MATLAB source)
    s = L2AA_Dif_IO_ModDes_SatAlfa(18, 1e-3, [[-4, -3, 8], [-5, -2, -4]], [2.3, -3.6], [-1], [-4, -4],
                                   [0, 0], [0.2, 0.3], [[0, 0, 0], [0, 0, 0]], [0, 1], 5,
                                   [[1e4, 0], [0, 1e4]], 20, [[1, 0], [0, 1]])
    print('theta_p_estimativa(:,end) =', s['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
