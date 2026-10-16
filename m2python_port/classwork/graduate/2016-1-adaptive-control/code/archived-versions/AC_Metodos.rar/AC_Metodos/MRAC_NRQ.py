"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/AC_Metodos.rar/AC_Metodos/MRAC_NRQ.m

MRAC_NRQ: controle adaptativo por modelo de referência para uma planta de grau
relativo qualquer ("NRQ"), using the classic augmented-error scheme. The plant
kp*planta_numerador/planta_denominador and the reference model
M(s) = km*filtroM_num/filtroM_den are realised with tf2ss and integrated with
forward Euler (step h, floor(stoptime/h) steps). The filters v1' = Lambda v1 + g u,
v2' = Lambda v2 + g y (Lambda = can(fliplr(-filtroM_num)), g = [0..0 1]') build the
regressor w = [v1; y; v2; r], the control is u = theta' w, and with the
L^-1(s)-filtered regressor the augmented output y_a = M L [theta_2n+1 (L^-1 theta'w
- theta' L^-1 w) + alfa e_a |L^-1 w|^2] gives the augmented error
e_a = e_o - y_a. Adaptive laws: theta' = -P e_a L^-1 w and
theta_2n+1' = gamma e_a (L^-1 theta'w - theta' L^-1 w). The reference is
r = referenciaEps * cos(t*referenciaF) (sum of cosines).

The argument is a struct (dict) with fields, in order: stoptime, h, filtroL,
filtroM_num, filtroM_den, planta_numerador, planta_denominador, cond_iniciais_p,
cond_iniciais_m, referenciaEps, referenciaF, P, gamma, est_theta_inic,
theta_2nm1_0, alfa, kp, km. Returns make_struct_out(x_p_out, x_m_out, theta,
e_o, u, r, tempo, endk) (the local archived make_struct_out); plot with
plot_adap_figures_MRAC_NRQ.

Porting notes:
- Archived version: identical to "Estrategias Controle Adaptativo/MRAC_NRQ.m"
  except that it calls the local make_struct_out (same content as
  make_struct_out_MRAC). can and convert_struct are not in the archive; they are
  loaded from the main "Estrategias Controle Adaptativo" ports with importlib.
- Dimensions: the preallocations of the original (v1, v2, L1tw with n-1 rows,
  y_a state with n rows) only work when len(filtroL) = n, len(filtroM_den) = n+1
  and filtroM_num is a scalar (then Lambda is 1x1 and multiplies v as a scalar,
  as in MATLAB). The port reproduces MATLAB's scalar-times-vector rule (_mtimes).
- BUG KEPT: ``w = [v_1; x_p(k+1); v_2; r]`` uses LINEAR indexing x_p(k+1) into the
  (n x 1 x K) state array, i.e. not the plant output at k+1 but element k+1 in
  column-major order; reproduced exactly.
- Arrays that MATLAB grows are preallocated with zeros (the values MATLAB fills in),
  e.g. w(:,1,1), tL1w(:,1,1), y_aumentado(1), x_p_out(1), x_m_out(1), r(1) are 0.
- Matrix products follow MATLAB's left-to-right order, e.g. (b*theta')*w.
"""
import importlib.util
import os
import sys
import warnings

import numpy as np
from scipy import signal

from make_struct_out import make_struct_out


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


_EST = "../../../Estrategias Controle Adaptativo/"
can = _import_from(_EST + "can.py", "can")
convert_struct = _import_from(_EST + "convert_struct.py", "convert_struct")


def _tf2ss(num, den):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", signal.BadCoefficients)
        A, B, C, D = signal.tf2ss(np.atleast_1d(np.ravel(np.asarray(num, float))),
                                  np.ravel(np.asarray(den, float)))
    return A, B[:, 0], C[0, :], float(D[0, 0]) if D.size else 0.0


def _mtimes(A, v):
    """MATLAB ``A*v``: scalar (1x1) A multiplies element-wise, otherwise matrix product."""
    A = np.asarray(A)
    return A.item() * v if A.size == 1 else A @ v


def _gain_times(G, v):
    G = np.asarray(G)
    return G * v if G.ndim == 0 else G @ v


def MRAC_NRQ(Estr_Dados_Entrada):
    # algoritmo de conversão da estrutura de dados colocada no argumento
    (stoptime, h, filtroL, filtroM_num, filtroM_den, planta_numerador,
     planta_denominador, cond_iniciais_p, cond_iniciais_m, referenciaEps,
     referenciaF, P, gamma, est_theta_inic, theta_2nm1_0, alfa, kp, km) = \
        convert_struct(Estr_Dados_Entrada, 18)
    filtroL = np.ravel(np.asarray(filtroL, float))
    filtroM_num = np.ravel(np.asarray(filtroM_num, float))
    filtroM_den = np.ravel(np.asarray(filtroM_den, float))
    planta_numerador = np.ravel(np.asarray(planta_numerador, float))
    planta_denominador = np.ravel(np.asarray(planta_denominador, float))
    referenciaEps = np.ravel(np.asarray(referenciaEps, float))
    referenciaF = np.ravel(np.asarray(referenciaF, float))
    P = np.asarray(P, float)

    # número de passos da simulação
    endk = int(np.floor(stoptime / h))

    # matrizes da planta (D_p é sempre 0: grau relativo >= 1)
    A_p, b_p, C_p, _ = _tf2ss(kp * planta_numerador, planta_denominador)
    # Matrizes de M(s)*L(s)
    A_ML, b_ML, C_ML, D_ML = _tf2ss(km * filtroM_num * filtroL, filtroM_den)
    # Matrizes de M(s)
    A_M, b_M, C_M, D_M = _tf2ss(km * filtroM_num, filtroM_den)
    # Matrizes de L^-1(s)
    A_Lm1, b_Lm1, C_Lm1, D_Lm1 = _tf2ss(1, filtroL)
    # Matriz canônica de LAMBDA
    Lambda = can(-filtroM_num[::-1])

    # ordem da planta
    n = len(planta_denominador) - 1
    nw = 2 * n

    # condições iniciais e preallocação
    theta = np.zeros((nw, endk + 1)); theta[:, 0] = np.ravel(est_theta_inic)
    x_p = np.zeros((n, endk + 1)); x_p[:, 0] = np.ravel(cond_iniciais_p)
    x_m = np.zeros((len(np.ravel(cond_iniciais_m)), endk + 1)); x_m[:, 0] = np.ravel(cond_iniciais_m)
    u = np.zeros(endk + 1)
    v_1 = np.zeros((n - 1, endk + 1))
    v_2 = np.zeros((n - 1, endk + 1))
    g = np.zeros(n - 1); g[n - 2] = 1
    L1tw = np.zeros((n - 1, endk + 1))
    tempo = np.zeros(endk + 1)
    tL1w_d = np.zeros((n - 1, nw, endk + 1))
    tL1w = np.zeros((nw, endk + 1))
    theta_2nm1 = np.zeros(endk + 1); theta_2nm1[0] = theta_2nm1_0
    e_a = np.zeros(endk + 1)
    y_aumentado_interno = np.zeros((n, endk + 1))
    r = np.zeros(endk + 1)
    x_m_out = np.zeros(endk + 1)
    x_p_out = np.zeros(endk + 1)
    w = np.zeros((nw, endk + 1))
    L1tw_out = np.zeros(endk + 1)
    L1wTL1w = np.zeros(endk + 1)
    p_int = np.zeros(endk + 1)
    y_aumentado = np.zeros(endk + 1)
    e_o = np.zeros(endk)

    for k in range(endk):       # k = MATLAB k-1
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal referência r(t) = a1*cos(f1*t)+...+an*cos(fn*t)
        r[k + 1] = referenciaEps @ np.cos(tempo[k] * referenciaF)
        # modelo de referência
        x_m_ponto = A_M @ x_m[:, k] + b_M * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto
        x_m_out[k + 1] = C_M @ x_m[:, k] + D_M * r[k]
        # planta
        x_p_ponto = A_p @ x_p[:, k] + b_p * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        x_p_out[k + 1] = C_p @ x_p[:, k + 1]
        # filtrados da planta e do sinal de entrada
        v_1_ponto = _mtimes(Lambda, v_1[:, k]) + g * u[k]
        v_1[:, k + 1] = v_1[:, k] + h * v_1_ponto
        v_2_ponto = _mtimes(Lambda, v_2[:, k]) + g * x_p_out[k]
        v_2[:, k + 1] = v_2[:, k] + h * v_2_ponto
        # montagem do vetor w; x_p(k+1) is a LINEAR index into x_p (bug kept)
        lin = k + 1
        x_p_lin = x_p[lin % n, lin // n]
        w[:, k + 1] = np.concatenate([v_1[:, k + 1], [x_p_lin], v_2[:, k + 1], [r[k + 1]]])
        # parcela = L^-1*theta'*w
        L1tw_ponto = _mtimes(A_Lm1, L1tw[:, k]) + np.outer(b_Lm1, theta[:, k]) @ w[:, k]
        L1tw[:, k + 1] = L1tw[:, k] + h * L1tw_ponto
        L1tw_out[k + 1] = C_Lm1 @ L1tw[:, k + 1] + (D_Lm1 * theta[:, k]) @ w[:, k]
        # parcela = L^-1*w
        for d in range(nw):
            tL1w_d_ponto = _mtimes(A_Lm1, tL1w_d[:, d, k]) + b_Lm1 * w[d, k]
            tL1w_d[:, d, k + 1] = tL1w_d[:, d, k] + h * tL1w_d_ponto
            tL1w[d, k + 1] = C_Lm1 @ tL1w_d[:, d, k + 1] + D_Lm1 * w[d, k]
        # parcela = (L^-1*w)' * (L^-1*w)
        L1wTL1w[k + 1] = tL1w[:, k + 1] @ tL1w[:, k + 1]
        # parcela interna de y_aumentado
        p_int[k + 1] = (theta_2nm1[k] * (L1tw_out[k + 1] - theta[:, k] @ tL1w[:, k + 1])
                        + alfa * e_a[k] * L1wTL1w[k + 1])
        # y aumentado em espaço de estados
        y_aumentado_ponto = A_ML @ y_aumentado_interno[:, k] + b_ML * p_int[k]
        y_aumentado_interno[:, k + 1] = y_aumentado_interno[:, k] + h * y_aumentado_ponto
        y_aumentado[k + 1] = C_ML @ y_aumentado_interno[:, k + 1] + D_ML * p_int[k + 1]
        # erro de saída
        e_o[k] = x_p_out[k] - x_m_out[k]
        # erro de saída aumentado
        e_a[k + 1] = e_o[k] - y_aumentado[k]
        # lei adaptativa para os parâmetros do controlador
        theta_ponto = _gain_times(-P * e_a[k], tL1w[:, k])
        theta[:, k + 1] = theta[:, k] + h * theta_ponto
        # lei adaptativa adicional para theta_(2n+1)
        theta_2nm1_ponto = gamma * e_a[k + 1] * (L1tw_out[k + 1] - theta[:, k] @ tL1w[:, k + 1])
        theta_2nm1[k + 1] = theta_2nm1[k] + h * theta_2nm1_ponto
        # lei de controle
        u[k + 1] = theta[:, k + 1] @ w[:, k + 1]

    Estr_Dados_saida = make_struct_out(x_p_out, x_m_out, theta[:, None, :], e_o,
                                       u, r, tempo, endk)
    return Estr_Dados_saida
