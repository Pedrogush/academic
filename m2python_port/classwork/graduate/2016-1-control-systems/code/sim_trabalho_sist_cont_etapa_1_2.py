"""Port of classwork/graduate/2016-1-control-systems/code/sim_trabalho_sist_cont_etapa_1-2.m

Trabalho Referente a disciplina de Sistemas de Controle
Professor: Carlos Eduardo Trabuco Dorea
Alunos: Pedro Gushiken, Isaac Dantas, Luan Garcia

Simulação em malha aberta (Euler explícito, passo h) do sistema não linear de terceira
ordem (oscilador de Van der Pol forçado + sensor) e do modelo linearizado do mesmo
sistema. A entrada é um degrau para a posição referencia = 0.95 partindo do ponto de
equilíbrio u_barra.

Linha verde: posição real do oscilador. Linha vermelha: medição da posição (sensor de
velocidade com integrador saturado, F.T. s/((s+0.04)(s+9)); no projeto o zero na origem
e o polo próximo dela são desconsiderados - dinâmica não modelada). Linha preta:
sistema linearizado.

Exemplo do original: sim_trabalho_sist_cont_etapa_1(90,1e-3,1,0.5)

Porting notes:
- The MATLAB file is named "...etapa_1-2.m" but declares
  `function sim_trabalho_sist_cont_etapa_1`; the Python function keeps that name.
- 1-based -> 0-based indexing; arrays preallocated with their final MATLAB sizes.
  As in the original, y_medido(k) and y_lin_medido(k) are written at index k (so
  their initial values u_barra/0.36 and u_barra are overwritten at k=1) and have
  length endk.
- Here (unlike etapa_1) the oscillator term is -mi*(1-x^2)*x_ponto and the sensor is
  driven by x(k) (not x_ponto); kept as in the original.
- Extra keyword `plot`; the function returns a dict of signals.
"""
import numpy as np
import matplotlib.pyplot as plt


def sim_trabalho_sist_cont_etapa_1(stoptime, h, u_barra, mi, plot=True):
    referencia = 0.95
    A_linearizado = np.array([[-9.04, -0.36, 0, 1],
                              [1, 0, 0, 0],
                              [0, 0, 1, 0],
                              [0, 0, -mi * (1 - u_barra ** 2), -1]])
    b_linearizado = np.array([0.0, 0.0, 0.0, 1.0])
    C_linearizado = np.array([0.0, 0.0, 0.0, 1.0])
    D_linearizado = 0.0

    endk = int(np.floor(stoptime / h))

    # inicialização das variáveis em seus respectivos pontos de equilíbrio
    x_2_ponto = np.zeros(endk)
    x_ponto = np.zeros(endk + 1)
    x = np.zeros(endk + 1)
    x[0] = u_barra
    y_ponto = np.zeros((2, endk))
    y = np.zeros((2, endk + 1))
    y[:, 0] = [0, u_barra / 0.36]
    y_medido = np.zeros(endk)
    y_medido[0] = u_barra / 0.36

    x_lin_ponto = np.zeros((4, endk))
    x_lin = np.zeros((4, endk + 1))
    x_lin[:, 0] = [0, u_barra, 0, u_barra]
    y_lin_medido = np.zeros(endk)
    y_lin_medido[0] = u_barra
    A_sensor = np.array([[-9.04, -0.36], [1.0, 0.0]])
    b_sensor = np.array([1.0, 0.0])
    u = np.zeros(endk)

    tempo = np.zeros(endk + 1)
    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        u[k] = referencia

        # Oscilador de Van Der Pol (Euler)
        x_2_ponto[k] = -mi * (1 - x[k] ** 2) * x_ponto[k] - x[k] + u[k]
        x_ponto[k + 1] = x_ponto[k] + h * x_2_ponto[k]
        x[k + 1] = x[k] + h * x_ponto[k]
        # Sensor de Velocidade com integrador saturado: s/(s+0.04)(s+9)
        y_ponto[:, k] = A_sensor @ y[:, k] + b_sensor * x[k]
        y[:, k + 1] = y[:, k] + h * y_ponto[:, k]
        # [0 0.36] escolhido para compatibilizar as grandezas (ganho do sensor)
        y_medido[k] = np.array([0.0, 0.36]) @ y[:, k]

        # Sistema Linearizado
        x_lin_ponto[:, k] = A_linearizado @ x_lin[:, k] + b_linearizado * u[k]
        x_lin[:, k + 1] = x_lin[:, k] + h * x_lin_ponto[:, k]
        y_lin_medido[k] = C_linearizado @ x_lin[:, k] + D_linearizado * u[k]

    tempo_acesso = tempo[:endk]

    if plot:
        fig, ax = plt.subplots(num=1)
        ax.plot(tempo_acesso, y_lin_medido, color=(0, 0, 0), linewidth=2.0,
                label='Modelo linearizado, $x_l$')
        ax.plot(tempo_acesso, y_medido, color=(1, 0, 0), linewidth=2.0, linestyle=':',
                label='Medição Modelo real, $x_p$')
        ax.plot(tempo, x, color=(0, 1, 0), linewidth=2.0, linestyle=':',
                label='Modelo Real, posição real')
        ax.grid(True)
        ax.legend(fontsize=14)
        ax.set_xlabel('Tempo (s)', fontsize=14)
        ax.set_ylabel('Amplitude', fontsize=14)
        ax.set_title('Saída do sistema linearizado e sistema real', fontsize=14)
        ax.tick_params(labelsize=14)

    return dict(tempo=tempo, x=x, x_ponto=x_ponto, y=y, y_medido=y_medido, u=u,
                x_lin=x_lin, y_lin_medido=y_lin_medido)


def main():
    sim_trabalho_sist_cont_etapa_1(90, 1e-3, 1, 0.5)
    plt.show()


if __name__ == "__main__":
    main()
