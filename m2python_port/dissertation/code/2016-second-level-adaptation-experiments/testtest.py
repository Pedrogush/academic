"""Port of dissertation/code/2016-second-level-adaptation-experiments/testtest.m

Scratch plot: the gradient field (2x, 400y) of V = x^2 + 200 y^2 on the grid
-5:5 drawn with quiver (scale 1), the very flat ellipse y = +/- sqrt(16 - x^2)/200,
and, for 4 random points (px, py) in [0, 2]^2, the point and the straight line
p - k*grad(V)(p) for k in [-1, 1] (gradient direction through the point).

Porting notes:
- rand -> np.random.default_rng(seed) (stream differs from MATLAB).
- quiver(...,1) -> MATLAB-style autoscaled quiver (see phase.matlab_quiver,
  inlined here).
"""
import numpy as np
import matplotlib.pyplot as plt


def _matlab_quiver(ax, X, Y, U, V, scale):
    dx = np.min(np.diff(np.unique(X)))
    dy = np.min(np.diff(np.unique(Y)))
    L = np.nanmax(np.hypot(U / dx, V / dy))
    return ax.quiver(X, Y, U, V, angles="xy", scale_units="xy", scale=L / scale)


def main(seed=None):
    rng = np.random.default_rng(seed)
    x = np.arange(-5, 6, 1.0)
    y = np.arange(-5, 6, 1.0)
    xg, yg = np.meshgrid(x, y)
    dxg = 2 * xg
    dyg = 400 * yg
    fig, ax = plt.subplots()
    _matlab_quiver(ax, xg, yg, dxg, dyg, 1)
    M = 2  # noqa: F841 (unused, as in MATLAB)
    x = np.arange(-4, 4.0001, 0.05)
    x = x[x <= 4 + 1e-12]
    y1 = np.sqrt(np.clip(16 - x ** 2, 0, None)) / 200
    y2 = -np.sqrt(np.clip(16 - x ** 2, 0, None)) / 200
    ax.plot(x, y1)
    ax.plot(x, y2)
    for i in range(4):
        px = 2 * rng.random()
        py = 2 * rng.random()
        ax.plot(px, py, ".")
        k = np.arange(-1, 1.0001, 0.01)
        pxl = px - k * 2 * px
        pyl = py - k * 400 * py
        ax.plot(pxl, pyl)
        ax.plot(0, 0, ".")
    plt.show()


if __name__ == "__main__":
    main(seed=0)
