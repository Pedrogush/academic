"""Port of dissertation/code/2016-second-level-adaptation-experiments/archived-versions/MATLAB_Files_Old.rar/rampa.m

Integrates a ramp with slope 0.1 by forward Euler (x(k+1) = x(k) + 0.1*passo)
from t = 0 to stoptime with step passo and plots x(t).  The MATLAB code displays
endk, t, x, d and r (statements without ';').

Porting notes:
- Displays -> print; plot -> matplotlib.  ``main()`` uses rampa(10, 0.01).
"""
import numpy as np
import matplotlib.pyplot as plt


def rampa(stoptime, passo):
    endk = int(np.floor(stoptime / passo))
    print("endk =", endk)
    t = np.zeros(endk + 1)
    print("t = 0")
    x = np.zeros(endk + 1)
    print("x = 0")
    d = 0
    print("d =", d)
    r = 1
    print("r =", r)
    for k in range(endk):
        t[k + 1] = t[k] + passo
        x[k + 1] = x[k] + 0.1 * passo
    plt.plot(t, x)
    return t, x


if __name__ == "__main__":
    rampa(10, 0.01)
    plt.show()
