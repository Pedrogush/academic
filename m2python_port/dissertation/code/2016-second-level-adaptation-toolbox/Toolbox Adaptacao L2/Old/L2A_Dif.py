"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2A_Dif.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Basic second-level adaptation with FIXED identification models (columns of ``modelos``)
and the differential method for the combination weights:
alpha_dot = -E'E alpha - E' e_{n+1}, E = [x_i - x_{n+1}], alpha_bar = [alpha; 1-sum(alpha)].
The plant estimate is THETA_BARRA*alpha_bar and the controller k = theta_m - THETA_BARRA*alpha_bar,
u = r + k'x_p, with sinusoidal reference r = referencia*sin(t). Companion-form systems,
b = [0..0 1]', forward Euler. Draws figures 1-6.

Porting notes:
- MATLAB auto-growing arrays preallocated; r(1) = 0 (MATLAB auto-fill) is kept.
- Function returns a dict with the simulation arrays (MATLAB returned nothing).
- Figure 6 (parameter plane) is only drawn for 2 parameters, as in MATLAB.
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


def _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
              cond_iniciais_i, alfa0, referencia):
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
    k_T[:, 0] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, 0]
    u = np.zeros(endk)
    u[0] = referencia
    tempo = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = referencia * np.sin(tempo[k])
        e_i[:, :, k] = x_i[:, :, k] - x_p[:, [k]]
        E = x_i[:, :na, k] - x_i[:, [N - 1], k]
        alfa_ponto[:, k] = -E.T @ E @ alfa[:, k] - E.T @ e_i[:, N - 1, k]
        alfa[:, k + 1] = alfa[:, k] + h * alfa_ponto[:, k]
        alfa_barra[:, k] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, k]
        u[k] = r[k] + k_T[:, k] @ x_p[:, k]
        for j in range(N):
            x_i_ponto = A_m @ x_i[:, j, k] + (A_i[j] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA @ alfa_barra[:, k]

    return dict(tempo=tempo, r=r, alfa=alfa, alfa_ponto=alfa_ponto, alfa_barra=alfa_barra, k_T=k_T, u=u,
                x_p=x_p, x_m=x_m, x_i=x_i, e_i=e_i, e_o=e_o, norm_2_e_o=norm_2_e_o,
                theta_p_estimativa=theta_p_estimativa, endk=endk)


def _std_axes(ax, title):
    ax.grid(True)
    ax.set_xlabel('Tempo (s)', fontsize=14)
    ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title(title, fontsize=14)
    ax.tick_params(labelsize=14)


def plot_common(s, modelos, planta, ref_label='Referencia', r_scale=1.0, extra_fig1=None):
    """Figures 1-6 shared by L2A_Dif, L2A_Dif_ModDes and L2A_Dif_ModDes_ModEnm1."""
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    tempo, endk = s['tempo'], s['endk']
    tempo_acesso = tempo[:endk]
    plt.figure(1)
    ax = plt.gca()
    ax.plot(tempo, s['x_m'][0], color='k', lw=2, label='Modelo, $x_m(1)$')
    ax.plot(tempo, s['x_p'][0], color='r', lw=2, ls=':', label='Planta, $x_p(1)$')
    ax.plot(tempo, s['r'] * r_scale, color='b', lw=2, label=ref_label)
    if extra_fig1 is not None:
        extra_fig1(ax)
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
    lines = ax.plot(tempo_acesso, s['alfa_barra'].T, lw=2)
    ax.legend(lines[:1], [r'$\alpha_{barra}$'], fontsize=14)
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
        ax.grid(True)
        ax.plot(planta[0], planta[1], lw=2, marker='o')
        ax.plot(np.append(modelos[0], modelos[0, 0]), np.append(modelos[1], modelos[1, 0]))
        ax.plot(s['theta_p_estimativa'][0], s['theta_p_estimativa'][1])


def L2A_Dif(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
            cond_iniciais_i, alfa0, referencia):
    s = _simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                  cond_iniciais_i, alfa0, referencia)
    plot_common(s, modelos, planta)
    return s


def main():
    # exemplo 1, 2 parâmetros desconhecidos
    s = L2A_Dif(25, 1e-3, [[3, -2, 7], [-6, -2, -3]], [0.8, -3], [-1, -3], [0.001, 0.002], [0, 0],
                [[0.001, 0.001, 0.001], [0.002, 0.002, 0.002]], [0.1, 0.8], 5)
    print('theta_p_estimativa(:,end) =', s['theta_p_estimativa'][:, -1])
    # exemplo 2, 3 parâmetros desconhecidos:
    # L2A_Dif(25, 1e-4, [[-3,-2,-7,-8],[-4,-4,-1,-2],[-5,-7,-9,-1]], [-4.8,-2.6,-6.8], [-9,-10,-12],
    #         [0.1,0.2,0.3], [0,0,0], [[0.02,0.02,0.01,0.04],[0.02,0,0.01,-0.01],[0.05,0.07,0,0.01]], [0,0,0], 5)
    plt.show()


if __name__ == "__main__":
    main()
