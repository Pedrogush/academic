"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2A_Inv.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Second-level adaptation with fixed identification models and the INVERSE method: at
each step alpha = -E^{-1} e_{n+1}, with E = [e_1 - e_{n+1}, ..., e_n - e_{n+1}] (alpha = alfa0
for the first two steps). Controller k = theta_m - THETA_BARRA*alpha_bar, constant
reference r = referencia. Note the one-step shifts of the MATLAB code: alfa_barra(:,k+1)
is built from alfa(:,k), k_T(:,k+1) from alfa_barra(:,k), and u(k+1) from k_T(:,k) and
x_p(:,k), while the plant at step k uses u(k) (u(1) = 0). Draws figures 1-6.

Porting notes:
- Arrays preallocated; r(1) = 0, e_o(:,1) = 0 and norm_2_e_o(1) = 0 are MATLAB auto-fill
  values, kept. ``E^-1`` -> np.linalg.inv; a singular E gives an all-Inf inverse as in MATLAB.
- Figure 6 is drawn unconditionally, as in MATLAB (needs 2 parameters).
"""
import numpy as np
import matplotlib.pyplot as plt


def _matlab_inv(E):
    """E^-1 like MATLAB/Octave: a singular matrix gives an all-Inf inverse (plus a warning)."""
    try:
        return np.linalg.inv(E)
    except np.linalg.LinAlgError:
        print('warning: matrix singular to machine precision')
        return np.full(E.shape, np.inf)


def can(vect):
    """Companion matrix: ones on the super-diagonal, last row = vect (copy of ../can.m)."""
    vect = np.asarray(vect, dtype=float).ravel()
    n = vect.size
    A = np.zeros((n, n))
    for linha in range(n - 1):
        A[linha, linha + 1] = 1.0
    A[n - 1, :] = vect
    return A


def _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
              cond_iniciais_i, alfa0, referencia, inv_from_k=3, r_const_len_endk=False):
    """Inverse-method Euler loop shared with Narendra_Sim_Geral_Inversa.py.

    inv_from_k: first (1-based) step using the inverse (L2A_Inv: 3; Narendra: 1).
    """
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    modelo_de_referencia = np.asarray(modelo_de_referencia, dtype=float).ravel()
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
    alfa0 = np.asarray(alfa0, dtype=float).ravel()

    x_p = np.zeros((n, endk + 1))
    x_m = np.zeros((n, endk + 1))
    x_i = np.zeros((n, N, endk + 1))
    x_p[:, 0] = np.asarray(cond_iniciais_p, dtype=float).ravel()
    x_m[:, 0] = np.asarray(cond_iniciais_m, dtype=float).ravel()
    x_i[:, :, 0] = np.asarray(cond_iniciais_i, dtype=float).reshape(n, N)
    e_i = np.zeros((n, N, endk))
    alfa = np.zeros((na, endk))
    alfa[:, 0] = alfa0
    alfa_barra = np.zeros((N, endk + 1))
    alfa_barra[:, 0] = np.append(alfa0, 1 - alfa0.sum())
    k_T = np.zeros((n, endk + 1))
    k_T[:, 0] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, 0]
    u = np.zeros(endk + 1)
    tempo = np.zeros(endk + 1)
    r = np.zeros(endk if r_const_len_endk else endk + 1)
    e_o = np.zeros((n, endk + 1))
    norm_2_e_o = np.zeros(endk + 1)
    theta_p_estimativa = np.zeros((n, endk))

    for k in range(endk):
        k1 = k + 1  # MATLAB index
        tempo[k + 1] = tempo[k] + h
        if r_const_len_endk:
            r[k] = referencia          # Narendra_Sim_Geral_Inversa: r(k) = referencia
        else:
            r[k + 1] = referencia      # L2A_Inv: r(k+1) = referencia
        e_i[:, :, k] = x_i[:, :, k] - x_p[:, [k]]
        E = e_i[:, :na, k] - e_i[:, [N - 1], k]
        alfa[:, k] = alfa0
        if k1 >= inv_from_k:
            alfa[:, k] = -_matlab_inv(E) @ e_i[:, N - 1, k]
        alfa_barra[:, k + 1] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k + 1] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, k]
        u[k + 1] = r[k] + k_T[:, k] @ x_p[:, k]
        for j in range(N):
            x_i_ponto = A_m @ x_i[:, j, k] + (A_i[j] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])
        e_o[:, k + 1] = x_m[:, k + 1] - x_p[:, k + 1]
        norm_2_e_o[k + 1] = np.sqrt(e_o[:, k + 1] @ e_o[:, k + 1])
        theta_p_estimativa[:, k] = theta_BARRA @ alfa_barra[:, k]

    return dict(tempo=tempo, r=r, alfa=alfa, alfa_barra=alfa_barra, k_T=k_T, u=u, x_p=x_p, x_m=x_m,
                x_i=x_i, e_i=e_i, e_o=e_o, norm_2_e_o=norm_2_e_o, theta_p_estimativa=theta_p_estimativa,
                endk=endk)


def _std_axes(ax, title):
    ax.grid(True)
    ax.set_xlabel('Tempo (s)', fontsize=14)
    ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title(title, fontsize=14)
    ax.tick_params(labelsize=14)


def L2A_Inv(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
            cond_iniciais_i, alfa0, referencia):
    s = _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                  cond_iniciais_i, alfa0, referencia)
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    tempo = s['tempo']
    plt.figure(1)
    ax = plt.gca()
    ax.plot(tempo, s['x_m'][0], color='k', lw=2, label='Modelo, $x_m(1)$')
    ax.plot(tempo, s['x_p'][0], color='r', lw=2, ls=':', label='Planta, $x_p(1)$')
    ax.plot(tempo, s['r'], color='b', lw=2, label='Referencia')
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
    lines = ax.plot(tempo, s['alfa_barra'].T, lw=2)
    ax.legend(lines[:1], [r'$\alpha_{barra}$'], fontsize=14)
    _std_axes(ax, 'Valores dos alfas')
    plt.figure(4)
    ax = plt.gca()
    ax.plot(tempo, s['u'], color='k', lw=2, label='Sinal de Controle')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Sinal de Controle')
    plt.figure(5)
    ax = plt.gca()
    ax.plot(tempo, s['norm_2_e_o'], color='k', lw=2, label='Norma 2 do Erro de Saída')
    ax.legend(fontsize=14)
    _std_axes(ax, 'Norma 2 do erro de Saída entre o modelo de referência e a planta')
    plt.figure(6)
    ax = plt.gca()
    ax.grid(True)
    ax.plot(planta[0], planta[1], lw=2, marker='o')
    ax.plot(np.append(modelos[0], modelos[0, 0]), np.append(modelos[1], modelos[1, 0]))
    ax.plot(s['theta_p_estimativa'][0], s['theta_p_estimativa'][1])
    return s


def main():
    # exemplo 1 of the MATLAB header
    s = L2A_Inv(1, 1e-3, [[3, -2, 7], [-6, -2, -3]], [1.7, -3.1], [-1, -3], [0.1, 0.2], [1.5, -2.44],
                [[0.1, 0.1, 0.1], [0.2, 0.2, 0.2]], [1, 0], 5)
    print('theta_p_estimativa(:,end) =', s['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
