"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/Astrom_Hagglund_Thales.m

Relay (Åström-Hägglund) auto-tuned PID, "Thales" variant: identical to
Astrom_Hagglund.m except that the plant is fixed, planta_num/(s^2 + 2 s) (an
integrating plant). A real PID with derivative filter
(state space from tf2ss of kp*(N Td Ti s^2 + (Ti + N Td) s + 1)/(N Td Ti s^2 + Ti s))
controls the plant (re-realised with tf2ss at every step as in the original;
forward Euler, step h), with constant reference r0. When |e| exceeds ``lim`` after the waiting
period (``espera``, in steps) the loop switches to relay control u = +/-M. Each
change of sign of the output slope is a peak; after three peaks it estimates
Tcr = 2 (t_pico2 - t_pico1) and Kcr = 4 M/(pi X) (X = |e| at the peak) and
re-tunes by Ziegler-Nichols (kp = 0.6 Kcr, Ti = Tcr/2, Td = Tcr/8), returning to
PID control.

The argument is a struct (dict) with fields, in order: stoptime, h, planta_num,
N0, Td0, Ti0, kp0, d0 (initial relay flag "deterioracao"), lim, espera0, r0, M.
Returns make_struct_out(x_p_out, 0, 0, e, u, r, tempo, endk) (fields x_p_out,
x_m_out, theta, e_o, u, r, tempo, endk); plot with plot_adap_figures_AstHagg.

Porting notes:
- The make_struct_out with this signature is the one of the archived
  AC_Metodos.rar (make_struct_out_MRAC.m in this folder is a renamed identical
  copy); it is loaded from the archived port with importlib.
- In relay mode the original zeroes only the 2nd PID state (``u_int(2,1,k)=0``);
  kept. Peaks are detected also during PID mode (kept).
- endk = stoptime/h is stored as computed (float); the loop runs floor(endk) times
  (MATLAB ``1:endk``). r(1) = 0 and x_p_out(1) = 0 (MATLAB auto-fill).
- tf2ss -> scipy.signal.tf2ss (same canonical form; non-monic denominators are
  normalised the same way).
"""
import importlib.util
import os
import sys
import warnings

import numpy as np
from scipy import signal

from convert_struct import convert_struct


def _import_from(relpath, name):
    path = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), relpath))
    d = os.path.dirname(path)
    sys.path.insert(0, d)
    try:
        spec = importlib.util.spec_from_file_location("_m2p_%x" % (hash(path) & 0xFFFFFFFF), path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    finally:
        sys.path.remove(d)
    return getattr(mod, name)


make_struct_out = _import_from("../archived-versions/AC_Metodos.rar/AC_Metodos/make_struct_out.py",
                               "make_struct_out")


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def _tf2ss(num, den):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", signal.BadCoefficients)
        A, B, C, D = signal.tf2ss(np.ravel(np.asarray(num, float)), np.ravel(np.asarray(den, float)))
    return A, B[:, 0], C[0, :], float(D[0, 0]) if D.size else 0.0


def _planta_den(t):
    return [1, 2, 0]


def Astrom_Hagglund_Thales(estrutura_de_entrada):
    (stoptime, h, planta_num, N0, Td0, Ti0, kp0, d0, lim, espera0, r0, M) = \
        convert_struct(estrutura_de_entrada, 12)
    endk = stoptime / h
    K = _ncount(endk)
    deterioracao = d0
    N = N0
    Td = Td0
    Ti = Ti0
    kp = kp0
    var_aux = 0
    e = np.zeros(K + 1)
    tempo = np.zeros(K + 1)
    r = np.zeros(K + 1)
    u = np.zeros(K)
    ent_cont = np.zeros(K)
    x_p_out = np.zeros(K + 1)
    espera = espera0
    u_int = np.zeros((2, K + 1))
    x_p = np.zeros((2, K + 1))
    tempos_de_pico = {}
    for k in range(K):          # k = MATLAB k-1
        # PID REAL, Espaço de estados, N<<1
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = r0
        A_pid, b_pid, C_pid, D_pid = _tf2ss(kp * np.array([N * Td * Ti, Ti + N * Td, 1]),
                                            [N * Td * Ti, Ti, 0])
        if deterioracao == 1:
            ent_cont[k] = 0
            u_int[1, k] = 0
        else:
            ent_cont[k] = e[k]

        u_int_ponto = A_pid @ u_int[:, k] + b_pid * ent_cont[k]
        u_int[:, k + 1] = u_int[:, k] + h * u_int_ponto
        u[k] = C_pid @ u_int[:, k] + D_pid * e[k]

        if deterioracao == 1:
            if e[k] < 0:
                u[k] = M
            else:
                u[k] = -M
        planta_den = _planta_den(tempo[k])

        A_p, b_p, C_p, D_p = _tf2ss(planta_num, planta_den)
        x_p_ponto = A_p @ x_p[:, k] + b_p * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        x_p_out[k + 1] = C_p @ x_p[:, k + 1] + D_p * u[k]

        e[k + 1] = r[k + 1] - x_p_out[k + 1]

        if k > 0 and deterioracao == 0 and abs(e[k]) > lim and espera < 0:
            deterioracao = 1
        if k > 0:
            if np.sign(x_p_out[k + 1] - x_p_out[k]) != np.sign(x_p_out[k] - x_p_out[k - 1]):
                var_aux = var_aux + 1
                tempos_de_pico[var_aux] = tempo[k]
                X = abs(e[k])
                if var_aux == 3:
                    Tcr = 2 * (tempos_de_pico[2] - tempos_de_pico[1])
                    Kcr = 4 * M / (np.pi * X)
                    deterioracao = 0
                    espera = espera0
                    kp = 0.6 * Kcr
                    Ti = Tcr / 2
                    Td = Tcr / 8
                    var_aux = 0
        espera = espera - 1
    estrutura_de_saida = make_struct_out(x_p_out, 0, 0, e, u, r, tempo, endk)
    return estrutura_de_saida
