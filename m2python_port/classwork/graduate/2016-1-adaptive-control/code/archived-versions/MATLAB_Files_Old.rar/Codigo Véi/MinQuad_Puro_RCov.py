"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/MATLAB_Files_Old.rar/Codigo Véi/MinQuad_Puro_RCov.m

Função referente à simulação de um sistema de identificação usando o método dos mínimos
quadrados puro com reinicialização de covariância (Alunos: Pedro Gushiken e Isaac
Dantas; Orientador: Aldayr Dantas de Araújo).

The plant x' = Ap x + bp u, y = [0 .. 0 1] x is excited by u and integrated with forward
Euler (step h). The filter is given directly as the companion matrix Aw: the regressor
states are driven through l = [1 0 .. 0]' (phi = [fi1; -fi2]) and the output filter
through bw = [0 .. 0 1]', with z1 = Aw(ordem,:) z_est + y. With m^2 = 1 + phi' Plinha
phi, the normalised error is eo = (z1 - theta' phi)/m^2. Adaptive law (pure least
squares with covariance resetting): P' = -P phi phi' P/m^2, P reset to P0 when
min(eig(P)) <= minp; theta' = P eo phi. Positional arguments; the input is hard-coded as
u = 1 + 0.3 sin(0.75 t) + 0.4 sin(3 t). Six figures are drawn (z1 vs z1e, theta, error,
plant output, normalisation, input) and the final values are echoed.

Porting notes:
- Arrays are preallocated (MATLAB grows them); teta has shape (2*ordem, N+1); u, z1,
  z1e, eo, saida_planta, m have N samples (sample 1 is overwritten in the first
  iteration, as in MATLAB).
- N = (t_final - t_inicial)/h is used like MATLAB's ``for k=1:n`` (floor, with a few-eps
  tolerance).
- min(eig(P)) follows MATLAB: symmetric solver when P is exactly symmetric, otherwise
  general eig (complex spectra compared by magnitude).
- MATLAB returns nothing; the port also returns a dict with the signals and the figure
  handles (extension). The echoed values use MATLAB's 1-based page n, i.e. Python index
  N-1.
- Old ("Código véi") version of the identifier, before the struct interface.
"""

import matplotlib.pyplot as plt
import numpy as np


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def _gain_times(G, v):
    """MATLAB ``G*v`` for a scalar or matrix gain G and a column vector v."""
    G = np.asarray(G)
    return G * v if G.ndim == 0 else G @ v


def _min_eig(M):
    """MATLAB ``min(eig(M))``: real eigenvalues for an exactly symmetric M; for a
    complex spectrum MATLAB's min compares absolute values (then angles)."""
    if np.array_equal(M, M.T):
        return float(np.min(np.linalg.eigvalsh(M)))
    ev = np.linalg.eigvals(M)
    if np.all(np.imag(ev) == 0):
        return float(np.min(np.real(ev)))
    i = np.lexsort((np.angle(ev), np.abs(ev)))[0]
    return ev[i]


def MinQuad_Puro_RCov(t_inicial, t_final, h, Aw, Ap, bp, ordem, P0, Plinha, minp, cond_inicial_p, cond_inicial_est_p, teta_inicial):

    Aw = np.atleast_2d(np.asarray(Aw, float))
    Ap = np.atleast_2d(np.asarray(Ap, float)); bp = np.ravel(np.asarray(bp, float))
    Plinha = np.atleast_2d(np.asarray(Plinha, float))
    P0 = np.atleast_2d(np.asarray(P0, float))
    ordem = int(ordem)

    # inicialização
    n = (t_final - t_inicial) / h
    N = _ncount(n)
    L = max(N, 1)
    x = np.zeros(N + 1); x[0] = t_inicial
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
    bw = np.zeros(ordem); bw[ordem - 1] = 1
    # fim da inicialização

    for k in range(N):
        x[k + 1] = x[k] + h
        u[k] = 1 + 0.3 * np.sin(0.75 * x[k]) + 0.4 * np.sin(3 * x[k])
        # Medição de y(t); esp. estado
        xps_p = Ap @ xps[:, k] + bp * u[k]
        xps[:, k + 1] = xps[:, k] + h * xps_p
        saida_planta[k] = h_transposto @ xps[:, k]
        # Filtragem de y(t)
        z_est_ponto = Aw @ z_est[:, k] + bw * saida_planta[k]
        z_est[:, k + 1] = z_est[:, k] + h * z_est_ponto
        z1[k] = Aw[ordem - 1, :] @ z_est[:, k] + saida_planta[k]
        # Geração do vetor fi
        fi1_p = Aw @ fi1[:, k] + l * u[k]
        fi1[:, k + 1] = fi1[:, k] + h * fi1_p
        fi2_p = Aw @ fi2[:, k] + l * saida_planta[k]
        fi2[:, k + 1] = fi2[:, k] + h * fi2_p
        fi = np.concatenate([fi1[:, k], -fi2[:, k]])
        # sinal de normalização
        ns2[k] = fi @ Plinha @ fi
        m[k] = np.sqrt(1 + ns2[k])
        # Cálculo da matriz de ganhos adaptativos P
        P_ponto = -np.outer(P[:, :, k] @ fi, fi) @ P[:, :, k] / m[k] ** 2
        P[:, :, k + 1] = P[:, :, k] + h * P_ponto
        if np.real(_min_eig(P[:, :, k + 1])) <= minp:
            P[:, :, k + 1] = P0
        # lei adaptativa
        z1e[k] = teta[:, k] @ fi
        eo[k] = (z1[k] - z1e[k]) / m[k] ** 2
        teta_p = (P[:, :, k] * eo[k]) @ fi
        teta[:, k + 1] = teta[:, k] + h * teta_p

    teta_acesso = teta
    x_acesso = x[:N]
    figs = []
    figs.append(plt.figure(1)); plt.clf(); plt.plot(x_acesso, z1, '-r', linewidth=2); plt.plot(x_acesso, np.real(z1e), '-b', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.legend(['z1', 'z1e']); plt.grid(True)
    figs.append(plt.figure(2)); plt.clf(); plt.plot(x, np.real(teta_acesso).T, '-r', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.grid(True)
    figs.append(plt.figure(3)); plt.clf(); plt.plot(x_acesso, np.real(eo), '-r', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.legend(['erro']); plt.grid(True)
    figs.append(plt.figure(4)); plt.clf(); plt.plot(x_acesso, saida_planta, '-r', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.legend(['saida planta']); plt.grid(True)
    figs.append(plt.figure(5)); plt.clf(); plt.plot(x_acesso, m, '-r', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.legend(['sinal de normalizacao']); plt.grid(True)
    figs.append(plt.figure(6)); plt.clf(); plt.plot(x_acesso, u, '-r', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.legend(['entrada']); plt.grid(True)
    # MATLAB echoes xps(:,1,n), z_est(:,n), teta(:,1,n) (1-based page n -> index N-1)
    print("xps(:,1,n) =", xps[:, N - 1])
    print("z_est(:,n) =", z_est[:, N - 1])
    print("teta(:,1,n) =", teta[:, N - 1])
    # extension: MATLAB returns nothing; the signals are returned for inspection
    return dict(x=x, teta=teta, z1=z1, z1e=z1e, eo=eo, saida_planta=saida_planta, m=m, u=u, xps=xps, z_est=z_est, figs=figs)
