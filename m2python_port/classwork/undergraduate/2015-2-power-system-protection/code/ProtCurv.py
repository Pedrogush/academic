"""Port of classwork/undergraduate/2015-2-power-system-protection/code/ProtCurv.m

Curvas de tempo inverso de relés de sobrecorrente (IEC): tempo de atuação em função
do múltiplo da corrente M = 1.1 .. 20 (passo 0.1) para multiplicadores de tempo
TMS = 0.1 .. 1.0, para as curvas muito inversa (MI: 13.5/(M-0.9)),
normalmente inversa (NI: 0.14/(M^0.02-0.9)) e extremamente inversa
(EI: 80/(M^2-0.9)). Plota log(t) para as três famílias em subplots.

Porting notes:
- Formulas kept exactly as in the original, including the "-0.9" in the denominators
  (the IEC standard uses "-1"); M = 1 + 0.1*L with L = 1..190.
- t1/t2/t3 are 10x190 (row T-1 = TMS index, column L-1).
"""
import numpy as np
import matplotlib.pyplot as plt


def main():
    t1 = np.zeros((10, 190))
    t2 = np.zeros((10, 190))
    t3 = np.zeros((10, 190))
    # tempo em função do múltiplo da corrente, MI
    for T in range(1, 11):
        for L in range(1, 191):
            v = (13.5 * T / 10) / ((1 + 0.1 * L) ** 1 - 0.9)
            t1[T - 1, L - 1] = v
    # NI
    for T in range(1, 11):
        for L in range(1, 191):
            v = (0.14 * T / 10) / ((1 + 0.1 * L) ** 0.02 - 0.9)
            t2[T - 1, L - 1] = v
    # EI
    for T in range(1, 11):
        for L in range(1, 191):
            v = (80 * T / 10) / ((1 + 0.1 * L) ** 2 - 0.9)
            t3[T - 1, L - 1] = v

    M = np.arange(11, 201) / 10
    fig = plt.figure()
    ax = fig.add_subplot(3, 1, 1)
    ax.plot(M, np.log(t3[0:10, :]).T)
    ax.set_title('EI')
    ax = fig.add_subplot(3, 1, 2)
    ax.plot(M, np.log(t2[0:10, :]).T)
    ax.set_title('NI')
    ax = fig.add_subplot(3, 1, 3)
    ax.plot(M, np.log(t1[0:10, :]).T)
    ax.set_title('MI')
    plt.show()
    return t1, t2, t3


if __name__ == "__main__":
    main()
