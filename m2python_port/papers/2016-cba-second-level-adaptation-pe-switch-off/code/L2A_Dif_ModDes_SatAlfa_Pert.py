"""Port of papers/2016-cba-second-level-adaptation-pe-switch-off/code/L2A_Dif_ModDes_SatAlfa_Pert.m

Variant of L2A_Dif_ModDes_SatAlfa with an input DISTURBANCE ("Pert" = perturbação):
p(t) = -1 for 16 < t <= 22 s (else 0) enters the plant as b*p. r = ref(1 + 0.2 sin t); the
PE switch-off condition is eta <= 1e-2 || contador > 1 (contador is never incremented,
the increment is commented out). Figure 6 draws the estimate trajectory up to 16 s in
blue and from 16 s to 60 s in green. Displays planta - theta_BARRA*alfa_barra(:,endk),
x_m(1,endk) and contador. (Idea noted in the source: if the plant is LTI, why not freeze
alfa_dot after the adaptation?)

Header example: L2A_Dif_ModDes_SatAlfa_Pert(18,1e-3,[-4 -3 8; -5 -2 -4], [2.3; -3.6],[-4 -4],
[0; 0], [0.2; 0.3], [0 0 0 ;0 0 0], [0 1], 5,[1e4 0;0 1e4],20).

Porting notes:
- Same structure/notes as L2A_Dif_ModDes_SatAlfa.py (literal Euler loop, 0-based indexing,
  MATLAB-sized outputs; the function returns a dict of signals, an addition; MATLAB
  displays are printed). Run the file to execute the example call from the header.
- This file is byte-identical to Toolbox Adaptacao L2/Old/L2A_Dif_ModDes_SatAlfa_Pert.m.
- Figure 6 indexes theta_p_estimativa(:,1:16/h) and (:,16/h:60/h); for stoptime < 60 s
  (e.g. the 18 s header example) MATLAB stops there with "Index exceeds matrix dimensions"
  and the final displays are never shown. The port clips the ranges to endk, prints a
  warning and continues.
"""
import sys
import time

import numpy as np
import matplotlib.pyplot as plt


EXAMPLES = {
    "cabecalho": (18, 1e-3, [[-4, -3, 8], [-5, -2, -4]], [[2.3], [-3.6]], [-4, -4], [0, 0],
                  [0.2, 0.3], [[0, 0, 0], [0, 0, 0]], [0, 1], 5, [[1e4, 0], [0, 1e4]], 20),
    "60s": (60, 1e-3, [[-4, -3, 8], [-5, -2, -4]], [[2.3], [-3.6]], [-4, -4], [0, 0],
            [0.2, 0.3], [[0, 0, 0], [0, 0, 0]], [0, 1], 5, [[1e4, 0], [0, 1e4]], 20),
}


def _companion(modelos, planta, modelo_de_referencia, n_de_linhas, L):
    A_i = np.zeros((n_de_linhas, n_de_linhas, L))
    A_p = np.zeros((n_de_linhas, n_de_linhas))
    A_m = np.zeros((n_de_linhas, n_de_linhas))
    for matriz in range(L):
        for linha in range(n_de_linhas - 1):
            A_i[linha, linha + 1, matriz] = 1
            A_p[linha, linha + 1] = 1
            A_m[linha, linha + 1] = 1
        A_i[n_de_linhas - 1, :, matriz] = modelos[:, matriz]
        A_p[n_de_linhas - 1, :] = planta[:n_de_linhas]
        A_m[n_de_linhas - 1, :] = modelo_de_referencia[:n_de_linhas]
    return A_i, A_p, A_m


def L2A_Dif_ModDes_SatAlfa_Pert(stoptime, h, modelos, planta, modelo_de_referencia,
                           cond_iniciais_p, cond_iniciais_m, cond_iniciais_i, alfa0,
                           referencia, Q, gamma):
    tic = time.perf_counter()
    planta_in = np.asarray(planta, dtype=float)
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.ravel(planta_in)
    modelo_de_referencia = np.ravel(np.asarray(modelo_de_referencia, dtype=float))
    stoptime = float(stoptime); h = float(h); referencia = float(referencia); gamma = float(gamma)
    n_de_linhas = modelos.shape[0]
    n = n_de_linhas
    L = max(modelos.shape)  # length(modelos)
    Q = np.asarray(Q, dtype=float).reshape(n, n)
    cond_iniciais_i = np.asarray(cond_iniciais_i, dtype=float).reshape(n, -1)
    # matrizes na forma canônica (companion form):
    A_i, A_p, A_m = _companion(modelos, planta, modelo_de_referencia, n_de_linhas, L)
    theta_BARRA = modelos
    # b é considerado conhecido, os sistemas não contém zeros.
    b = np.zeros(n)
    b[n - 1] = 1.0

    endk = int(np.floor(stoptime / h))
    N = endk + 1
    tempo = np.zeros(N); r = np.zeros(N); r_ponto = np.zeros(N); eta = np.zeros(N)
    u = np.zeros(N); alfa = np.zeros((n, N)); alfa_ponto = np.zeros((n, N))
    alfa_n1 = np.zeros(N); alfa_ponto_n1 = np.zeros(N); alfa_barra = np.zeros((n + 1, N))
    k_T = np.zeros((n, N)); x_p = np.zeros((n, N)); x_m = np.zeros((n, N))
    x_i = np.zeros((n, L, N)); e_i = np.zeros((n, L, N)); E = np.zeros((n, L - 1, N))
    x_i_ponto = np.zeros((n, L, N)); x_m_ponto = np.zeros((n, N)); x_p_ponto = np.zeros((n, N))
    p = np.zeros(N)
    contador = 0
    e_o = np.zeros((n, N)); norm_2_e_o = np.zeros(N); theta_p_estimativa = np.zeros((n, N))

    # condições iniciais da planta, modelo de referência e modelos de identificação
    x_p[:, 0] = np.ravel(np.asarray(cond_iniciais_p, dtype=float))
    x_m[:, 0] = np.ravel(np.asarray(cond_iniciais_m, dtype=float))
    for j in range(L):
        x_i[:, j, 0] = cond_iniciais_i[:, j]
        e_i[:, j, 0] = x_i[:, j, 0] - x_p[:, 0]
    # inicialização da matriz E
    for j in range(L - 1):
        E[:, j, 0] = x_i[:, j, 0] - x_i[:, L - 1, 0]
    # condições iniciais do vetor de combinação linear alfa_barra
    alfa[:, 0] = np.ravel(np.asarray(alfa0, dtype=float))
    alfa_barra[:, 0] = np.concatenate([alfa[:, 0], [1 - np.ones(n) @ alfa[:, 0]]])
    # inicialização dos parâmetros do controlador
    k_T[:, 0] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, 0]
    # inicialização da entrada da planta
    u[0] = referencia
    tempo[0] = 0.0
    eta[0] = 0.0
    r_ponto[0] = 0.0
    # início
    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k + 1] = referencia + 0.2 * referencia * np.sin(tempo[k])
        if eta[k] <= 1e-2 or contador > 1:
            r_ponto[k] = 10 * (-r[k] + referencia)
            r[k + 1] = r[k] + h * r_ponto[k]
        # if k>1 && eta(k)<=1e-2 && eta(k-1)>1e-2, contador = contador+1; end  (comentado)
        p[k] = 0.0
        if tempo[k] > 16:
            p[k] = -1.0
        if tempo[k] > 22:
            p[k] = 0.0
        # Geração dos erros entre os modelos escolhidos e a planta
        for j in range(L):
            e_i[:, j, k] = x_i[:, j, k] - x_p[:, k]
        for j in range(L - 1):
            E[:, j, k] = x_i[:, j, k] - x_i[:, L - 1, k]
        Ek = E[:, :, k]
        alfa_ponto[:, k] = gamma * (-Ek.T @ Ek @ alfa[:, k] - Ek.T @ e_i[:, L - 1, k])
        alfa_n1[k] = 1 - np.ones(n) @ alfa[:, k]
        alfa_ponto_n1[k] = -np.ones(n) @ alfa_ponto[:, k]
        for i in range(n):
            if (alfa[i, k] >= 1 and alfa_ponto[i, k] > 0) or (alfa[i, k] <= 0 and alfa_ponto[i, k] < 0):
                alfa_ponto[i, k] = 0.0
            if (alfa_n1[k] >= 1 and alfa_ponto_n1[k] > 0) or (alfa_n1[k] <= 0 and alfa_ponto_n1[k] < 0):
                for j in range(n):
                    if np.sign(alfa_ponto_n1[k]) != np.sign(alfa_ponto[j, k]):
                        alfa_ponto[j, k] = 0.0
        alfa[:, k + 1] = alfa[:, k] + h * alfa_ponto[:, k]
        aQa = alfa_ponto[:, k] @ Q @ alfa_ponto[:, k]
        eta[k + 1] = aQa / (1 + aQa)
        # composição de alfa para gerar alfa_barra
        alfa_barra[:, k] = np.concatenate([alfa[:, k], [1 - np.ones(n) @ alfa[:, k]]])
        # parâmetros do controlador e lei de controle
        k_T[:, k] = modelo_de_referencia - theta_BARRA @ alfa_barra[:, k]
        u[k] = r[k] + k_T[:, k] @ x_p[:, k]
        # dinâmica dos modelos, da planta e do modelo de referência
        for j in range(L):
            x_i_ponto[:, j, k] = A_m @ x_i[:, j, k] + (A_i[:, :, j] - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto[:, j, k]
        x_m_ponto[:, k] = A_m @ x_m[:, k] + b * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto[:, k]
        x_p_ponto[:, k] = A_p @ x_p[:, k] + b * u[k] + b * p[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto[:, k]
        # cálculo da norma 2 do erro
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA @ alfa_barra[:, k]

    res = dict(tempo=tempo, r=r, eta=eta, u=u[:endk], alfa=alfa, alfa_barra=alfa_barra[:, :endk],
               x_p=x_p, x_m=x_m, x_i=x_i, e_o=e_o[:, :endk], norm_2_e_o=norm_2_e_o[:endk],
               theta_p_estimativa=theta_p_estimativa[:, :endk], endk=endk)
    i16 = int(round(16 / h)); i60 = int(round(60 / h))
    if i60 > endk:
        print(f"Aviso: theta_p_estimativa(:,16/h:60/h) excede endk={endk} (erro de índice no "
              "MATLAB); intervalo truncado.")
    _plots(res, planta, modelos, modelo_de_referencia, r_norm=abs(modelo_de_referencia[0]),
           traj_segments=[(0, min(i16, endk), [0, 0, 1]), (i16 - 1, min(i60, endk), [0, 1, 0])])
    # displays finais do original
    print("planta - theta_BARRA*alfa_barra(:,endk) =\n",
          _mat_minus(planta_in, theta_BARRA @ alfa_barra[:, endk - 1]))
    print("x_m(1,endk) =", x_m[0, endk - 1])
    print("contador =", contador)
    print(f"(elapsed {time.perf_counter() - tic:.3f} s)")
    return res


def _mat_minus(planta_in, col):
    """MATLAB ``planta - column`` with implicit expansion (row planta gives n x n)."""
    p = planta_in if planta_in.ndim == 2 else planta_in[None, :]
    return p - col[:, None]


def _plots(res, planta, modelos, modelo_de_referencia, r_norm=None, r_label="Referencia/Ganho Estático",
           alfa_legend=False, hull_lw=2.0, traj_segments=None):
    tempo = res["tempo"]; endk = res["endk"]; tempo_acesso = tempo[:endk]
    x_m = res["x_m"]; x_p = res["x_p"]; r = res["r"]
    if r_norm is None:
        r_norm = abs(modelo_de_referencia[0])
    fig = plt.figure(1)
    ax = fig.gca()
    ax.plot(tempo, x_m[0, :], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, x_p[0, :], color=[1, 0, 0], linewidth=2.0, linestyle=":")
    ax.plot(tempo, r / r_norm, color=[0, 0, 1], linewidth=2.0)
    ax.grid(True)
    ax.legend(["Modelo, $x_m(1)$", "Planta, $x_p(1)$", r_label], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Saída do sistema (Método Diferencial)", fontsize=14)

    if x_m.shape[0] >= 2:
        ax = plt.figure(2).gca()
        ax.plot(tempo, x_m[1, :], color=[0, 0, 0], linewidth=2.0)
        ax.plot(tempo, x_p[1, :], color=[1, 0, 0], linewidth=2.0, linestyle=":")
        ax.grid(True)
        ax.legend(["Modelo, $x_m(2)$", "Planta, $x_p(2)$"], fontsize=14)
        ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
        ax.set_title("Saída do sistema (Método Diferencial)", fontsize=14)

    ax = plt.figure(3).gca()
    ax.plot(tempo_acesso, res["alfa_barra"].T, linewidth=2.0)
    ax.grid(True)
    if alfa_legend:
        ax.legend([r"$\alpha_{barra}$"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Valores dos alfas", fontsize=14)

    ax = plt.figure(4).gca()
    ax.plot(tempo_acesso, res["u"], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(["Sinal de Controle"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Sinal de Controle", fontsize=14)

    ax = plt.figure(5).gca()
    ax.plot(tempo_acesso, res["norm_2_e_o"], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(["Norma 2 do Erro de Saída"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Norma 2 do erro de Saída entre o modelo de referência e a planta", fontsize=14)

    if len(planta) == 2:
        ax = plt.figure(6).gca()
        ax.grid(True)
        ax.plot(planta[0], planta[1], color=[0, 1, 1], linewidth=2.0, marker="o", linestyle="none")
        ax.plot(np.r_[modelos[0, :], modelos[0, 0]], np.r_[modelos[1, :], modelos[1, 0]],
                color=[1, 0, 0], linewidth=hull_lw)
        tpe = res["theta_p_estimativa"]
        if traj_segments is None:
            ax.plot(tpe[0, :], tpe[1, :], color=[0, 0, 1], linewidth=hull_lw)
        else:
            for (a, b_, c) in traj_segments:
                ax.plot(tpe[0, a:b_], tpe[1, a:b_], color=c, linewidth=2.0)

    ax = plt.figure(7).gca()
    ax.plot(tempo, res["eta"], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(["Fig. Mérito ETA"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Fig. Mérito ETA", fontsize=14)


def main(argv=None):
    import argparse
    p = argparse.ArgumentParser(description="L2A_Dif_ModDes_SatAlfa_Pert example from the header")
    p.add_argument("--example", default="cabecalho", choices=sorted(EXAMPLES))
    a = p.parse_args(argv)
    L2A_Dif_ModDes_SatAlfa_Pert(*EXAMPLES[a.example])
    plt.show()


if __name__ == "__main__":
    main()
