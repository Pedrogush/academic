"""Port of dissertation/code/2016-second-level-adaptation-experiments/phase.m

Phase portrait of the planar nonlinear system
du/dt = w*u^2 - B*u,  dw/dt = A - w - w*u^2  (A = B = 1):
200 random initial conditions in [-2.5, 2.5]^2 are integrated with ode45 over
t in [-5, 5] (starting at t = -5) and plotted in red, then the vector field is
drawn with quiver on the grid -4:0.5:4.

Porting notes:
- rand -> np.random.default_rng(seed) (stream differs from MATLAB).
- ode45 -> solve_ivp(RK45, rtol=1e-3, atol=1e-6); trajectories that blow up stop
  where the solver fails (MATLAB ode45 also stops with a warning).
- quiver(..., scale=5): MATLAB autoscale times 5 -> arrows scaled so the longest
  one is 5 grid spacings long (scale_units='xy').
"""
import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import solve_ivp


def EOM(t, y):
    u = y[0]
    w = y[1]
    A = 1
    B = 1
    return [w * u ** 2 - B * u, A - w - w * u ** 2]


def matlab_quiver(ax, X, Y, U, V, scale, **kw):
    """quiver with MATLAB-like autoscaling (longest arrow = scale * grid spacing)."""
    dx = np.min(np.diff(np.unique(X))) if np.unique(X).size > 1 else 1.0
    dy = np.min(np.diff(np.unique(Y))) if np.unique(Y).size > 1 else 1.0
    L = np.nanmax(np.hypot(U / dx, V / dy))  # longest arrow in grid spacings
    s = L / scale if L > 0 else 1.0  # data units per arrow unit
    return ax.quiver(X, Y, U, V, angles="xy", scale_units="xy", scale=s, **kw)


def phase(seed=None, n_ic=200):
    rng = np.random.default_rng(seed)
    IC = 5 * (rng.random((n_ic, 2)) - 0.5)
    fig, ax = plt.subplots()
    for ii in range(IC.shape[0]):
        with np.errstate(over="ignore", invalid="ignore"):
            sol = solve_ivp(EOM, [-5, 5], IC[ii, :], method="RK45", rtol=1e-3, atol=1e-6)
        u = sol.y[0]
        w = sol.y[1]
        ax.plot(u, w, "r")
    ax.set_xlabel("u")
    ax.set_ylabel("w")
    ax.grid(True)
    x = np.arange(-4, 4.0001, 0.5)
    y = np.arange(-4, 4.0001, 0.5)
    xg, yg = np.meshgrid(x, y)
    dxg = yg * xg ** 2 - xg
    dyg = np.ones((len(x), len(x))) - yg - yg * xg ** 2
    scale = 5
    matlab_quiver(ax, xg, yg, dxg, dyg, scale)
    return fig, ax


if __name__ == "__main__":
    phase(seed=0)
    plt.show()
