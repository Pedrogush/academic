"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/MinQuad_FE_PSaturado.m

Função referente à simulação de um sistema de identificação usando o método dos mínimos
quadrados com fator de esquecimento e matriz de ganhos adaptativos saturada (Alunos:
Pedro Gushiken e Isaac Dantas; Orientador: Aldayr Dantas de Araújo).

The plant x' = Ap x + bp u, y = [0 .. 0 1] x is excited by u and integrated with forward
Euler (step h). The filter W(s) = filtroW(end)/filtroW(s) (tf2ss) builds the regressor
phi = [W u; -W y] and z1 = (s^n/filtroW(s)) y is the filtered output (second tf2ss
realisation, with feedthrough). With m^2 = 1 + phi' Plinha phi, the normalised error is
eo = (z1 - theta' phi)/m^2. Adaptive law (least squares with forgetting factor and
saturated P): P' = Beta P - P phi phi' P/m^2, frozen (P' = 0) when norm(P) >= Pmax;
theta' = P eo phi. The argument is a struct (dict) whose fields are, in order:
t_inicial, t_final, h, filtroW (filter denominator polynomial), Ap, bp, ordem, P0,
Plinha, cond_inicial_p, cond_inicial_est_p, teta_inicial, Beta, Pmax, minp, refA, refF;
u = refA*cos(t*refF). Returns the struct of make_struct_out (teta, tempo, z1, z1e, eo,
saida_planta, m, u); plot it with plot_adap_figures_Ident.

Porting notes:
- convert_struct comes from the original "Estrategias Controle Adaptativo" folder and is
  loaded from the sibling port with importlib.
- tf2ss -> scipy.signal.tf2ss (same controller canonical form as MATLAB).
- Arrays are preallocated (MATLAB grows them); teta has shape (2*ordem, N+1) and is
  returned as (2*ordem, 1, N+1) like MATLAB's 3-D array; u, z1, z1e, eo, saida_planta, m
  have N samples (sample 1 is overwritten in the first iteration, as in MATLAB).
- N = (t_final - t_inicial)/h is used like MATLAB's ``for k=1:n`` (floor, with a few-eps
  tolerance).
- norm(P) is the matrix 2-norm (largest singular value), as in MATLAB.
- make_struct_MQ omits refA/refF, so its structs are two fields short for this function
  (bug of the original helper, see make_struct_MQ.py).
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

convert_struct = _import_from("../Estrategias Controle Adaptativo/convert_struct.py", "convert_struct")


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def _tf2ss(num, den):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", signal.BadCoefficients)
        A, B, C, D = signal.tf2ss(np.ravel(np.asarray(num, float)), np.ravel(np.asarray(den, float)))
    return A, B[:, 0], C[0, :], float(D[0, 0]) if D.size else 0.0


def _ref(refA, refF, t):
    """MATLAB ``refA*cos(t*refF)`` (scalars, or row refA times column refF)."""
    return float(np.dot(np.ravel(refA), np.cos(t * np.ravel(np.asarray(refF, float)))))


def _gain_times(G, v):
    """MATLAB ``G*v`` for a scalar or matrix gain G and a column vector v."""
    G = np.asarray(G)
    return G * v if G.ndim == 0 else G @ v


def MinQuad_FE_PSaturado(estrutura_de_entrada):
    # conversão da estrutura de dados para variáveis internas da função
    (t_inicial, t_final, h, filtroW, Ap, bp,
     ordem, P0, Plinha, cond_inicial_p, cond_inicial_est_p, teta_inicial,
     Beta, Pmax, _, refA, refF) = convert_struct(estrutura_de_entrada, 17)

    filtroW = np.ravel(np.asarray(filtroW, float))
    Aw, bw, Cw, _ = _tf2ss([0, filtroW[-1]], filtroW)
    vaux = np.zeros(len(filtroW)); vaux[0] = 1
    Aw1, bw1, Cw1, Dw1 = _tf2ss(vaux, filtroW)
    Ap = np.atleast_2d(np.asarray(Ap, float)); bp = np.ravel(np.asarray(bp, float))
    Plinha = np.atleast_2d(np.asarray(Plinha, float))
    P0 = np.atleast_2d(np.asarray(P0, float))
    ordem = int(ordem)

    # inicialização
    n = (t_final - t_inicial) / h
    N = _ncount(n)
    L = max(N, 1)
    tempo = np.zeros(N + 1); tempo[0] = t_inicial
    z_est = np.zeros((ordem, N + 1)); z_est[:, 0] = np.ravel(cond_inicial_est_p)
    fi1 = np.zeros((ordem, N + 1))
    fi2 = np.zeros((ordem, N + 1))
    u = np.zeros(L); u[0] = 1
    xps = np.zeros((ordem, N + 1)); xps[:, 0] = np.ravel(cond_inicial_p)
    fi = np.concatenate([fi1[:, 0], fi2[:, 0]])
    ns2 = np.zeros(L); m = np.zeros(L)
    ns2[0] = fi @ Plinha @ fi
    m[0] = np.sqrt(1 + ns2[0])
    teta = np.zeros((2 * ordem, N + 1)); teta[:, 0] = np.ravel(teta_inicial)
    z1e = np.zeros(L); z1e[0] = teta[:, 0] @ fi
    P = np.zeros((2 * ordem, 2 * ordem, N + 1)); P[:, :, 0] = P0
    h_transposto = np.zeros(ordem); h_transposto[ordem - 1] = 1
    saida_planta = np.zeros(L); saida_planta[0] = h_transposto @ xps[:, 0]
    z1 = np.zeros(L); z1[0] = Aw[ordem - 1, :] @ z_est[:, 0] + saida_planta[0]
    eo = np.zeros(L); eo[0] = (z1[0] - z1e[0]) / m[0] ** 2
    l = np.zeros(ordem); l[0] = 1
    # fim da inicialização

    for k in range(N):
        tempo[k + 1] = tempo[k] + h
        # geração do sinal de referência
        u[k] = _ref(refA, refF, tempo[k])
        # Medição de y(t); esp. estado
        xps_p = Ap @ xps[:, k] + bp * u[k]
        xps[:, k + 1] = xps[:, k] + h * xps_p
        saida_planta[k] = h_transposto @ xps[:, k]
        # Filtragem de y(t)
        z_est_ponto = Aw1 @ z_est[:, k] + bw1 * saida_planta[k]
        z_est[:, k + 1] = z_est[:, k] + h * z_est_ponto
        z1[k] = Cw1 @ z_est[:, k] + Dw1 * saida_planta[k]
        # Geração do vetor fi
        fi1_p = Aw @ fi1[:, k] + bw * u[k]
        fi1[:, k + 1] = fi1[:, k] + h * fi1_p
        fi2_p = Aw @ fi2[:, k] + bw * saida_planta[k]
        fi2[:, k + 1] = fi2[:, k] + h * fi2_p
        fi = np.concatenate([fi1[:, k], -fi2[:, k]])
        # sinal de normalização
        ns2[k] = fi @ Plinha @ fi
        m[k] = np.sqrt(1 + ns2[k])
        # Cálculo da matriz de ganhos adaptativos P
        P_ponto = Beta * P[:, :, k] - np.outer(P[:, :, k] @ fi, fi) @ P[:, :, k] / m[k] ** 2
        if np.linalg.norm(P[:, :, k], 2) >= Pmax:
            P_ponto = np.zeros_like(P_ponto)
        P[:, :, k + 1] = P[:, :, k] + h * P_ponto
        # lei adaptativa
        z1e[k] = teta[:, k] @ fi
        eo[k] = (z1[k] - z1e[k]) / m[k] ** 2
        teta_p = (P[:, :, k] * eo[k]) @ fi
        teta[:, k + 1] = teta[:, k] + h * teta_p

    # conversão dos dados relevantes para a estrutura de saída
    estrutura_de_saida = make_struct_out(teta[:, None, :], tempo, z1, z1e, eo, saida_planta, m, u)
    return estrutura_de_saida
