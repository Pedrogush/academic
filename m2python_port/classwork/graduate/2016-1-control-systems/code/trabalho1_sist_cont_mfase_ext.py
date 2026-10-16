"""Port of classwork/graduate/2016-1-control-systems/code/trabalho1_sist_cont_mfase_ext.m

Phase portrait of the Van der Pol oscillator (mi = 1.5) starting OUTSIDE the limit
cycle, x1 = x2 = 2, integrated with ode45 over [0, 1000] s.

Porting notes:
- The MATLAB file declares `function my_phase()` with subfunction EOM; both are kept
  (my_phase() is what runs when the file is executed).
- ode45 -> scipy.integrate.solve_ivp(RK45, rtol=1e-3, atol=1e-6) with MATLAB's default
  output refinement (Refine = 4: 3 extra dense-output points per step). Step-size
  selection differs slightly from MATLAB, so the sampled points are not identical
  (the trajectory agrees to the integration tolerance).
- Dropped unused local variable(s): c = 2 (unused in the original).
"""
import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp


def _ode45(fun, tspan, y0, refine=4):
    """MATLAB-like ode45(fun, [t0 tf], y0): RK45 with MATLAB default tolerances and
    Refine=4 output (each step plus refine-1 interior dense-output points)."""
    sol = solve_ivp(fun, tspan, y0, method="RK45", rtol=1e-3, atol=1e-6,
                    dense_output=True)
    ts = sol.t
    s = (np.arange(1, refine) / refine)[None, :]
    inner = ts[:-1, None] + s * np.diff(ts)[:, None]
    t = np.concatenate([[ts[0]], np.column_stack([inner, ts[1:]]).ravel()])
    return t, sol.sol(t).T


def EOM(t, y):
    x1 = y[0]
    x2 = y[1]
    mi = 1.5
    return np.array([x2,
                     mi * (1 - x1 ** 2) * x2 - x1])


def my_phase():
    _, X = _ode45(EOM, [0, 1000], [2, 2])
    x1 = X[:, 0]
    x2 = X[:, 1]
    fig, ax = plt.subplots()
    ax.plot(x1, x2, linewidth=2.0, label='Mapa de Fase, Cond. Iniciais fora do ciclo, $x_1=x_2=2$')
    ax.legend(fontsize=14)
    ax.set_xlabel('x1')
    ax.set_ylabel('x2')
    ax.grid(True)
    return x1, x2


def main():
    my_phase()
    plt.show()


if __name__ == "__main__":
    main()
