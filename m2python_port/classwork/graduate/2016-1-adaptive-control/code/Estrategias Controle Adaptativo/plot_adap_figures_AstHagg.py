"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/plot_adap_figures_AstHagg.m

Plots the relay (Åström-Hägglund) auto-tuned PID output struct (unpacked by
field order: x_p_out, ~, ~, e0, u, r, tempo, endk) in a 3x1 figure: plant
output vs reference, output error and plant input.

Porting notes:
- endk may be a non-integer float (stoptime/h); it is floored for indexing.
- Returns the Figure (MATLAB returns nothing).
"""
import matplotlib.pyplot as plt
import numpy as np

from convert_struct import convert_struct


def plot_adap_figures_AstHagg(func):
    x_p_out, _, _, e0, u, r, tempo, endk = convert_struct(func, 8)
    tempo = np.ravel(tempo)
    x_acesso = tempo[:int(np.floor(endk + 1e-9))]
    fig1 = plt.figure(figsize=(10.24, 7.68))
    ax = fig1.add_subplot(3, 1, 1)
    ax.plot(tempo, x_p_out, '-r', linewidth=2)
    ax.plot(tempo, r, '-b', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['saída da planta', 'referência']); ax.grid(True)

    ax = fig1.add_subplot(3, 1, 2)
    ax.plot(tempo, e0, linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['erro de saída']); ax.grid(True)

    ax = fig1.add_subplot(3, 1, 3)
    ax.plot(x_acesso, u, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['entrada da planta']); ax.grid(True)
    fig1.tight_layout()
    return fig1
