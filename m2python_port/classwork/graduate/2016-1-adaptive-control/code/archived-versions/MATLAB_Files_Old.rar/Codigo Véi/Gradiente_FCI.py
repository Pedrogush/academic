"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/MATLAB_Files_Old.rar/Codigo Véi/Gradiente_FCI.m

Função referente à simulação de um sistema de identificação usando o método do gradiente
com função de custo integral (Alunos: Pedro Gushiken e Isaac Dantas; Orientador: Aldayr
Dantas de Araújo).

The plant x' = Ap x + bp u, y = [0 .. 0 1] x is excited by u and integrated with forward
Euler (step h). The filter is given directly as the companion matrix Aw: the regressor
states are driven through l = [1 0 .. 0]' (phi = [fi1; -fi2]) and the output filter
through bw = [0 .. 0 1]', with z1 = Aw(ordem,:) z_est + y. With m^2 = 1 + phi' P phi,
the normalised error is eo = (z1 - theta' phi)/m^2. Adaptive law (gradient with integral
cost): R' = -beta R + phi phi'/m^2, Q' = -beta Q - z1 phi/m^2, theta' = -gama (Q + R
theta). Positional arguments; the input is hard-coded as u = 1 + 0.3 sin(0.75 t) + 0.4
sin(3 t). Six figures are drawn (z1 vs z1e, theta, error, plant output, normalisation,
input) and the final values are echoed.

Porting notes:
- Arrays are preallocated (MATLAB grows them); teta has shape (2*ordem, N+1); u, z1,
  z1e, eo, saida_planta, m have N samples (sample 1 is overwritten in the first
  iteration, as in MATLAB).
- N = (t_final - t_inicial)/h is used like MATLAB's ``for k=1:n`` (floor, with a few-eps
  tolerance).
- gama may be a scalar or a matrix.
- R and Q are initialised with hard-coded 4x4 / 4x1 zeros in MATLAB, so only 2nd-order
  plants (4 parameters) work; kept (numpy raises otherwise).
- MATLAB returns nothing; the port also returns a dict with the signals and the figure
  handles (extension). The echoed values use MATLAB's 1-based page n, i.e. Python index
  N-1.
- Old ("Código véi") version of the identifier, before the struct interface.
- Also accumulates the 'adaptive effort' esf_adaptativo = sum ||theta'|| and echoes it.
- The forgetting factor B = 0.25 is hard-coded. Sample call from the header: Gradiente_F
  CI(0,90,1e-3,[[0,1],[-3,-2]],[[0,1],[-3,-
  2]],[1,0],2,eye(4),100*eye(4),[0,0],[0,0],[0,0,0,0]).
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


def Gradiente_FCI(t_inicial, t_final, h, Aw, Ap, bp, ordem, P, gama, cond_inicial_p, cond_inicial_est_p, teta_inicial):

    Aw = np.atleast_2d(np.asarray(Aw, float))
    Ap = np.atleast_2d(np.asarray(Ap, float)); bp = np.ravel(np.asarray(bp, float))
    P = np.atleast_2d(np.asarray(P, float))
    B = 0.25
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
    ns2[0] = fi @ P @ fi
    m[0] = np.sqrt(1 + ns2[0])
    teta = np.zeros((2 * ordem, N + 1)); teta[:, 0] = np.ravel(teta_inicial)
    z1e = np.zeros(L); z1e[0] = teta[:, 0] @ fi
    h_transposto = np.zeros(ordem); h_transposto[ordem - 1] = 1
    saida_planta = np.zeros(L); saida_planta[0] = h_transposto @ xps[:, 0]
    z1 = np.zeros(L); z1[0] = Aw[ordem - 1, :] @ z_est[:, 0] + saida_planta[0]
    eo = np.zeros(L); eo[0] = (z1[0] - z1e[0]) / m[0] ** 2
    l = np.zeros(ordem); l[0] = 1
    bw = np.zeros(ordem); bw[ordem - 1] = 1
    Q = np.zeros((4, N + 1))   # Q(:,1,1) = [0 0 0 0] (hard-coded for 4 parameters)
    R = np.zeros((4, 4, N + 1))
    esf_adaptativo = 0.0
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
        ns2[k] = fi @ P @ fi
        m[k] = np.sqrt(1 + ns2[k])
        # lei adaptativa
        z1e[k] = teta[:, k] @ fi
        eo[k] = (z1[k] - z1e[k]) / m[k] ** 2
        # matrizes relacionadas à solução homogênea das equações usando função de custo integral
        R_p = -B * R[:, :, k] + np.outer(fi, fi) / m[k] ** 2
        R[:, :, k + 1] = R[:, :, k] + h * R_p
        Q_p = -B * Q[:, k] - z1[k] * fi / m[k] ** 2
        Q[:, k + 1] = Q[:, k] + h * Q_p
        # geração da lei adaptativa
        teta_p = _gain_times(-np.asarray(gama, float), Q[:, k] + R[:, :, k] @ teta[:, k])
        teta[:, k + 1] = teta[:, k] + h * teta_p
        esf_adaptativo = esf_adaptativo + np.linalg.norm(teta_p)

    teta_acesso = teta
    x_acesso = x[:N]
    figs = []
    figs.append(plt.figure(1)); plt.clf(); plt.plot(x_acesso, z1, '-r', linewidth=2); plt.plot(x_acesso, np.real(z1e), '-b', linewidth=2)
    plt.xlabel('tempo'); plt.ylabel('amplitude'); plt.legend(['z1', 'z1e']); plt.grid(True)
    figs.append(plt.figure(2)); plt.clf(); plt.plot(x, np.real(teta_acesso).T, linewidth=2)
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
    print("esf_adaptativo =", esf_adaptativo)
    # extension: MATLAB returns nothing; the signals are returned for inspection
    return dict(x=x, teta=teta, z1=z1, z1e=z1e, eo=eo, saida_planta=saida_planta, m=m, u=u, xps=xps, z_est=z_est, figs=figs, esf_adaptativo=esf_adaptativo)
