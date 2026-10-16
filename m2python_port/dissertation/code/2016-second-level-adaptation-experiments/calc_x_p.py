"""Port of dissertation/code/2016-second-level-adaptation-experiments/calc_x_p.m

State derivative of the linear system dx/dt = [-1 1; 0 -1]*x + [0; 1]*u, in the
ode45-style signature f(t, x, u).

Porting notes:
- x is a length-2 array; returns a length-2 array.
"""
import numpy as np


def calc_x_p(t, x, u):
    return np.array([[-1.0, 1.0], [0.0, -1.0]]) @ np.asarray(x, dtype=float) + np.array([0.0, 1.0]) * u


if __name__ == "__main__":
    print(calc_x_p(0.0, [1.0, 2.0], 1.0))
