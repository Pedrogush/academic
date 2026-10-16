"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/R_MIT.m

Regra do MIT, ordem N, sem zeros, b conhecido ("Precisa de um pouco de trabalho").
Direct MRAC with the MIT rule for a 3rd-order companion-form plant x' = A x + b u
(A = ``planta``) and reference model x_m' = Am x_m + bm r (Am = ``modelo_de_referencia``),
with b = bm = [0 0 1]' and output y = [0 0 1] x. The reference is
r = referencia + sin(t), the control law u = r + k_T' x with
k_T = Am(2,:)' - theta, and the MIT rule theta' = Gamma*e_o*y_filtrado, where
y_filtrado(j) is state x_j filtered by the reference model. Forward Euler with
step h for floor(stoptime/h) steps. Plots model x_m(1), plant x(1) and reference
(figure 1, "Saída do sistema (Método Diferencial)").

Porting notes:
- b, bm and h_t are hard-coded for order 3 in MATLAB (kept). k_T uses the 2nd row of
  Am (kept, as in the original, even though the 3rd row would be the natural choice).
- MATLAB preallocates with endk samples and the arrays then grow to endk+1; the port
  allocates endk+1 directly. r(1) = 0 (preallocation value) and r(k+1) is computed
  from tempo(k), as in the original; u, e_o, y, y_m have endk samples.
- Gamma may be a scalar or a matrix. ``cond_iniciais_m`` sets the state dimension.
- MATLAB returns nothing; the port returns a dict with the signals and the figure
  (extension). Run this file as a script for a demo with illustrative parameters
  (not from the original, which has no caller).
"""
import matplotlib.pyplot as plt
import numpy as np


def R_MIT(stoptime, h, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
          referencia, Gamma, teta0):
    endk = int(np.floor(stoptime / h))
    nm = len(np.ravel(cond_iniciais_m))

    # Prealocação
    u = np.zeros(endk)
    theta = np.zeros((nm, endk + 1))
    x = np.zeros((nm, endk + 1))
    r = np.zeros(endk + 1)
    k_T = np.zeros((nm, endk))
    y = np.zeros(endk); y_m = np.zeros(endk)
    x_m = np.zeros((nm, endk + 1))
    e_o = np.zeros(endk)
    x_filtrado = np.zeros((nm, nm, endk + 1))
    tempo = np.zeros(endk + 1)
    y_filtrado = np.zeros((nm, endk))

    # Inicialização
    x_m[:, 0] = np.ravel(cond_iniciais_m)
    x[:, 0] = np.ravel(cond_iniciais_p)
    theta[:, 0] = np.ravel(teta0)
    Am = np.atleast_2d(np.asarray(modelo_de_referencia, float))
    A = np.atleast_2d(np.asarray(planta, float))
    b = np.array([0., 0., 1.])
    bm = b
    h_t = np.array([0., 0., 1.])
    G = np.asarray(Gamma, float)

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        # referência
        r[k + 1] = referencia + np.sin(tempo[k])
        # lei de controle
        k_T[:, k] = Am[1, :] - theta[:, k]
        u[k] = r[k] + k_T[:, k] @ x[:, k]
        # planta
        x_ponto = A @ x[:, k] + b * u[k]
        x[:, k + 1] = x[:, k] + h * x_ponto
        y[k] = h_t @ x[:, k]
        # modelo de referência
        x_m_ponto = Am @ x_m[:, k] + bm * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto
        y_m[k] = h_t @ x_m[:, k]
        # erro de saída
        e_o[k] = y[k] - y_m[k]
        # filtrado das variáveis de estado
        for j in range(nm):
            x_filtrado_ponto = Am @ x_filtrado[:, j, k] + bm * x[j, k]
            x_filtrado[:, j, k + 1] = x_filtrado[:, j, k] + h * x_filtrado_ponto
            y_filtrado[j, k] = h_t @ x_filtrado[:, j, k]
        # leis adaptativas
        theta_ponto = (G * e_o[k]) * y_filtrado[:, k] if G.ndim == 0 else (G * e_o[k]) @ y_filtrado[:, k]
        theta[:, k + 1] = theta[:, k] + h * theta_ponto

    fig = plt.figure(1)
    fig.clf()   # MATLAB figure(1) followed by plot (hold off) replaces the content
    plt.plot(tempo, x_m[0, :], color=[0, 0, 0], linewidth=2.0)
    plt.plot(tempo, x[0, :], color=[1, 0, 0], linewidth=2.0, linestyle=':')
    plt.plot(tempo, r, color=[0, 0, 1], linewidth=2.0)
    plt.grid(True)
    plt.legend(['Modelo, $x_m(1)$', 'Planta, $x_p(1)$', 'Referencia'], fontsize=14)
    plt.xlabel('Tempo (s)', fontsize=14)
    plt.ylabel('Amplitude', fontsize=14)
    plt.title('Saída do sistema (Método Diferencial)', fontsize=14)
    plt.gca().tick_params(labelsize=14)
    return dict(tempo=tempo, x=x, x_m=x_m, r=r, u=u, theta=theta, e_o=e_o, fig=fig)


def main():
    # illustrative parameters (the original has no caller)
    Am = np.array([[0, 1, 0], [0, 0, 1], [-6, -11, -6.]])
    Ap = np.array([[0, 1, 0], [0, 0, 1], [-2, -3, -4.]])
    R_MIT(20, 1e-3, Ap, Am, [0, 0, 0], [0, 0, 0], 1, 1.0, [0, 0, 0])
    plt.show()


if __name__ == "__main__":
    main()
