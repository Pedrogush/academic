"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/APPC.m

Controle adaptativo de uma planta de grau qualquer usando o método do
posicionamento de polos (APPC) combinado com identificação dos parâmetros da
planta (Aluno: Pedro Gushiken; Orientador: Aldayr Dantas de Araújo).

The plant Zs_estrela/Rs_estrela (tf2ss, forward Euler, step h) is identified by
continuous least squares with forgetting factor on filtered regressors
(phi = [W u; -W y], W(s) from filtroW, P' = Beta P - P phi phi' P/m^2,
theta' = P eo phi, estimates clamped to 0.1 when negative). The controller solves
Qm*R*L + Z*P = A_estrela through the Sylvester matrix (M_sylv) and implements
u = (P/Lambda) e + ((Lambda - Qm L)/Lambda) u with tf2ss filters, e = r - y,
r = refA*cos(t*refF). In THIS version the Diophantine equation is solved with the
TRUE plant polynomials Rs_estrela/Zs_estrela (the estimates Zs_chapeu/Rs_chapeu
are computed but unused), so the controller is not adaptive: a debugging step to
validate the pole-placement part.

The argument is a struct (dict) with fields, in order: t_inicial, t_final, h,
filtroW, ~, ~, ordem, P0, Plinha, cond_inicial_p, cond_inicial_est_p,
teta_inicial, Beta, ~, ~, refF, refA, Qms, Zs_estrela, Rs_estrela, A_estrela,
Lambda (22 fields; note refF comes before refA). Dimensions required by the
algebra: len(Rs_estrela) = n+1, len(Zs_estrela) = n, len(Qms) = q+1,
len(Lambda) = n+q, len(A_estrela) = 2n+q, 2*ordem = number of estimates.
Returns make_struct_out(teta, tempo, z1, z1e, e, x_p_out, m, u) (fields teta, x,
z1, z1e, eo, saida_planta, m, u); plot with plot_adap_figures_APPC.

Porting notes:
- make_struct_out is the identification one (original folder "Identificação"),
  loaded with importlib (this folder has none). The MATLAB code relied on both
  folders being on the path.
- BUGS KEPT: ``if abs(det(M)) >= 0`` is always true; the Ls clamp loop only checks
  Ls(n) (n times); x_fil1_out(k+1) uses the previous OUTPUT x_fil1_out(k) as the
  feed-through input instead of e(k+1); the plant output uses Dp*u(k).
- The initial x_p_out(1) uses h' = [0..0 1] (as the original), later samples use Cp.
- ``(M^-1)*A_estrela`` is computed as inv(M) @ A_estrela as in MATLAB.
- MATLAB echoes the initial fi(:,1,1) (missing semicolon); printed here too.
- Polynomials are 1-D arrays (MATLAB orientation does not matter here).
- N = (t_final-t_inicial)/h is used like MATLAB's ``for k=1:endk``.
"""
import importlib.util
import os
import sys
import warnings

import numpy as np
from scipy import signal

from convert_struct import convert_struct
from M_sylv import M_sylv


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


make_struct_out = _import_from("../Identificação/make_struct_out.py", "make_struct_out")


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def _tf2ss(num, den):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", signal.BadCoefficients)
        A, B, C, D = signal.tf2ss(np.ravel(np.asarray(num, float)), np.ravel(np.asarray(den, float)))
    return A, B[:, 0], C[0, :], float(D[0, 0]) if D.size else 0.0


def _ref(refA, refF, t):
    return float(np.dot(np.ravel(refA), np.cos(t * np.ravel(np.asarray(refF, float)))))


def APPC(estrutura_de_entrada):
    (t_inicial, t_final, h, filtroW, _, _, ordem, P0, Plinha, cond_inicial_p,
     cond_inicial_est_p, teta_inicial, Beta, _, _, refF, refA, Qms, Zs_estrela,
     Rs_estrela, A_estrela, Lambda) = convert_struct(estrutura_de_entrada, 22)
    Qms = np.ravel(np.asarray(Qms, float))
    Zs_estrela = np.ravel(np.asarray(Zs_estrela, float))
    Rs_estrela = np.ravel(np.asarray(Rs_estrela, float))
    A_estrela = np.ravel(np.asarray(A_estrela, float))
    Lambda = np.ravel(np.asarray(Lambda, float))
    filtroW = np.ravel(np.asarray(filtroW, float))
    P0 = np.atleast_2d(np.asarray(P0, float)); Plinha = np.atleast_2d(np.asarray(Plinha, float))
    ordem = int(ordem)

    Ap, bp, Cp, Dp = _tf2ss(Zs_estrela, Rs_estrela)
    Aw, bw, Cw, _ = _tf2ss([0, filtroW[-1]], filtroW)
    vaux = np.zeros(len(filtroW)); vaux[0] = 1
    Aw1, bw1, Cw1, Dw1 = _tf2ss(vaux, filtroW)
    q = len(Qms) - 1
    n = len(Rs_estrela) - 1
    endk = (t_final - t_inicial) / h
    K = _ncount(endk)
    L = max(K, 1)
    npar = 2 * ordem

    P = np.zeros((npar, npar, K + 1)); P[:, :, 0] = P0
    teta = np.zeros((npar, K + 1)); teta[:, 0] = np.ravel(teta_inicial)
    tempo = np.zeros(K + 1); tempo[0] = t_inicial
    r = np.zeros(K + 1)
    z_est = np.zeros((ordem, K + 1))
    fi1 = np.zeros((ordem, K + 1)); fi2 = np.zeros((ordem, K + 1))
    u = np.zeros(K + 1); u[0] = 1
    x_p = np.zeros((len(Rs_estrela) - 1, K + 1)); x_p[:, 0] = np.ravel(cond_inicial_p)
    nfil = len(Lambda) - 1
    x_fil1 = np.zeros((nfil, K + 1)); x_fil2 = np.zeros((nfil, K + 1))
    fi = np.concatenate([fi1[:, 0], fi2[:, 0]])
    print("fi(:,1,1) =", fi)
    ns2 = np.zeros(L); m = np.zeros(L)
    ns2[0] = fi @ Plinha @ fi
    m[0] = np.sqrt(1 + ns2[0])
    z1e = np.zeros(L); z1e[0] = teta[:, 0] @ fi
    h_transposto = np.zeros(ordem); h_transposto[ordem - 1] = 1
    x_p_out = np.zeros(K + 1); x_p_out[0] = h_transposto @ x_p[:, 0]
    z1 = np.zeros(L); z1[0] = Cw @ z_est[:, 0] + x_p_out[0]
    eo = np.zeros(L); eo[0] = (z1[0] - z1e[0]) / m[0] ** 2
    e = np.zeros(K + 1)
    x_fil1_out = np.zeros(K + 1)
    x_fil2_out = np.zeros(K + 1)
    coefs = np.zeros(2 * n + q); coefs[-1] = 0.1

    for k in range(K):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = _ref(refA, refF, tempo[k])
        # algoritmo de estimação: filtragem de y(t)
        z_est_ponto = Aw1 @ z_est[:, k] + bw1 * x_p_out[k]
        z_est[:, k + 1] = z_est[:, k] + h * z_est_ponto
        z1[k] = Cw1 @ z_est[:, k] + Dw1 * x_p_out[k]
        # Geração do vetor fi
        fi1_p = Aw @ fi1[:, k] + bw * u[k]
        fi1[:, k + 1] = fi1[:, k] + h * fi1_p
        fi2_p = Aw @ fi2[:, k] + bw * x_p_out[k]
        fi2[:, k + 1] = fi2[:, k] + h * fi2_p
        fi = np.concatenate([fi1[:, k], -fi2[:, k]])
        # sinal de normalização
        ns2[k] = fi @ Plinha @ fi
        m[k] = np.sqrt(1 + ns2[k])
        # Cálculo da matriz de ganhos adaptativos P
        Pk = P[:, :, k]
        P_ponto = Beta * Pk - np.outer(Pk @ fi, fi) @ Pk / m[k] ** 2
        P[:, :, k + 1] = Pk + h * P_ponto
        # lei adaptativa
        z1e[k] = teta[:, k] @ fi
        eo[k] = (z1[k] - z1e[k]) / m[k] ** 2
        teta_p = (Pk * eo[k]) @ fi
        teta[:, k + 1] = teta[:, k] + h * teta_p
        for j in range(2 * n):
            if teta[j, k + 1] < 0:
                teta[j, k + 1] = 0.1
        Zs_chapeu = teta[:n, k + 1]                                  # computed, unused
        Rs_chapeu = np.concatenate([[1.0], teta[n:2 * n, k + 1]])    # computed, unused
        # fim do algoritmo de estimação
        # APPC
        QmRs = np.convolve(Qms, Rs_estrela)
        M = M_sylv(n, q, QmRs, Zs_estrela)
        if abs(np.linalg.det(M)) >= 0:
            coefs = np.linalg.inv(M) @ A_estrela
        Ls = coefs[:n].copy()
        Ps = coefs[n:2 * n + q].copy()
        for j in range(n):
            if Ls[n - 1] < 0:
                Ls[n - 1] = 0
        for i in range(n + q):
            if Ps[i] < 0:
                Ps[i] = 0
        Afil1, bfil1, Cfil1, Dfil1 = _tf2ss(Ps, Lambda)
        Afil2, bfil2, Cfil2, Dfil2 = _tf2ss(Lambda - np.convolve(Qms, Ls), Lambda)

        x_fil1_ponto = Afil1 @ x_fil1[:, k] + bfil1 * e[k]
        x_fil1[:, k + 1] = x_fil1[:, k] + h * x_fil1_ponto
        x_fil1_out[k + 1] = Cfil1 @ x_fil1[:, k + 1] + Dfil1 * x_fil1_out[k]

        x_fil2_ponto = Afil2 @ x_fil2[:, k] + bfil2 * u[k]
        x_fil2[:, k + 1] = x_fil2[:, k] + h * x_fil2_ponto
        x_fil2_out[k + 1] = Cfil2 @ x_fil2[:, k + 1] + Dfil2 * u[k]

        u[k + 1] = x_fil2_out[k + 1] + x_fil1_out[k + 1]

        x_p_ponto = Ap @ x_p[:, k] + bp * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        x_p_out[k + 1] = Cp @ x_p[:, k + 1] + Dp * u[k]

        e[k + 1] = r[k + 1] - x_p_out[k + 1]

    estrutura_de_saida = make_struct_out(teta[:, None, :], tempo, z1, z1e, e, x_p_out, m, u)
    return estrutura_de_saida
