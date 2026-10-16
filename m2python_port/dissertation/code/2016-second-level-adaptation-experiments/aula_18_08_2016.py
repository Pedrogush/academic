"""Port of dissertation/code/2016-second-level-adaptation-experiments/aula_18_08_2016.m

Notes from the Linear Systems lecture of 18 Aug 2016 on transfer functions of
discrete-time systems (original comments, in Portuguese, kept below).  The only
code is ``x_ex1(2,1) = 0`` (displayed, creating a 2x1 zero vector) and an empty
``for k=1:20`` loop.

Notas da aula (traduzidas do comentário original):
Y(z) = G(z)*U(z).  Para sistemas de parâmetros concentrados causais
G(z) = N(z)/D(z) (função de transferência racional), com
N(z) = b_0*z^m + b_1*z^(m-1) + ... + b_m e D(z) = z^n + a_1*z^(n-1) + ... + a_n,
m <= n (a_0 = 1 por convenção).  As m raízes de N(z) são os zeros e as n raízes de
D(z) os polos do sistema.  g(k) = Z^-1{G(z)} é a resposta ao impulso.
D(z) = prod(z - lambda_k); G(z)/z = sum a_i/(z - lambda_i) (polos distintos)
-> g(k) = sum a_i*lambda_i^k.

Porting notes:
- MATLAB display of x_ex1 -> print.
"""
import numpy as np


def aula_18_08_2016():
    x_ex1 = np.zeros((2, 1))
    print("x_ex1 =\n", x_ex1)
    for k in range(1, 21):
        pass
    return None


if __name__ == "__main__":
    aula_18_08_2016()
