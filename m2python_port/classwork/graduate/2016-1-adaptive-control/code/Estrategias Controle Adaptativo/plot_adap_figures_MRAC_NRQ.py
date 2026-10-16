"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/plot_adap_figures_MRAC_NRQ.m

Plots the MRAC_NRQ output struct in one 2x2 figure (figure 1): model output,
plant output and reference; the controller parameters; the control signal; and
the output error between reference model and plant.

Porting notes:
- The struct is accessed by field name (func['tempo'], ...), like the original.
- MATLAB's TeX labels x_m(1)/x_p(1) -> mathtext. The stray ``set(leg1,...)`` of the
  parameters subplot (it re-styles the previous legend) is dropped.
- Returns the Figure (MATLAB returns nothing).
"""
import matplotlib.pyplot as plt
import numpy as np


def plot_adap_figures_MRAC_NRQ(func):
    endk = int(func['endk'])
    tempo = np.ravel(func['tempo'])
    tempo_acesso = tempo[:endk]
    fig = plt.figure(1, figsize=(12, 9))
    fig.clf()   # MATLAB figure(1)+subplot replaces previous content
    fig.set_size_inches(12, 9)
    # saídas referentes à planta e ao modelo de referência, e a referência
    ax = fig.add_subplot(2, 2, 1)
    ax.plot(tempo, func['x_m_out'], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, func['x_p_out'], color=[1, 0, 0], linewidth=2.0, linestyle=':')
    ax.plot(tempo, func['r'], color=[0, 0, 1], linewidth=2.0)
    ax.grid(True)
    ax.legend(['Modelo, $x_m(1)$', 'Planta, $x_p(1)$', 'Referencia'], fontsize=14)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Saída do sistema', fontsize=14); ax.tick_params(labelsize=14)
    # adaptação dos parâmetros no tempo
    ax = fig.add_subplot(2, 2, 2)
    ax.plot(tempo, np.atleast_2d(func['theta']).T, linewidth=2.0)
    ax.grid(True)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Valores dos parâmetros', fontsize=14); ax.tick_params(labelsize=14)
    # sinal de controle no tempo
    ax = fig.add_subplot(2, 2, 3)
    ax.plot(tempo, func['u'], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(['Sinal de Controle'], fontsize=14)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Sinal de Controle', fontsize=14); ax.tick_params(labelsize=14)
    # erro de saída
    ax = fig.add_subplot(2, 2, 4)
    ax.plot(tempo_acesso, func['e_o'], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(['Erro de Saída'], fontsize=14)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Erro de Saída entre o modelo de referência e a planta', fontsize=14)
    ax.tick_params(labelsize=14)
    fig.tight_layout()
    return fig
