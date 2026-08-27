#!/usr/bin/env python3
"""Independent numerical check of the trajectory used by ../coq/T03_witness_458.v.

The Coq file proves that a particular closed form satisfies every hypothesis of
Chapter 4 and that the dissertation's Lyapunov function (4.57) has derivative
+1 at t = 0 there.  A proof cannot catch a modelling mistake -- if the Coq
model were not the system of Chapter 4, the proof would still go through.

So here the ODEs are integrated numerically, from the differential equations
as the dissertation writes them, with no reference to the closed form:

  phi = (1,0),  theta*_p = 0,  Gamma = 2I,  m^2 = 1 + phi.phi = 2
  (4.19)  thetahat_i' = -Gamma eps_i phi,      eps_i = (thetahat_i.phi - z)/m^2
  (4.52)  alpha_f'     = -gamma E^T (E alpha_f) - gamma E^T eps_N
  (4.50)  E_i          = eps_i - eps_N
  (4.57)  V            = (|alphatilde|^2 + (1.alphatilde)^2) / (2 gamma)

Three things are checked against the Coq file:
  * the closed forms agree with the integrator,
  * V(4.57) increases,  Vdot(0) = +1,
  * (4.58) would predict -3.
Requires nothing but the standard library.
"""
import math

import sys

N, M, gamma = 3, 2, 1.0
GAM = [2.0, 2.0]
astar = [1/3, 1/3, 1/3]

# witness A (../coq/T03_witness_458.v): E_f(0) = (2,-1), alphatilde(0) = (-1/3,-5/3)
# witness B (../coq/T06_witness_simplex.v): E_f(0) = (1,3), alpha_f(0) = (1,0),
#                                           a VERTEX of the simplex
WITNESS = sys.argv[1].upper() if len(sys.argv) > 1 else "A"
if WITNESS == "A":
    th0 = [[10/3, 1.0], [-8/3, -1.0], [-2/3, 0.0]]  # thetahat_i(0), theta*_p = 0
    alp0 = [0.0, -4/3]
    EXACT0, CLAIMED0 = 1.0, -3.0
else:
    th0 = [[-2/3, 1.0], [10/3, -1.0], [-8/3, 0.0]]
    alp0 = [1.0, 0.0]
    EXACT0, CLAIMED0 = 1/3, -1/3
phi = [1.0, 0.0]
msq = 1 + phi[0]**2 + phi[1]**2


def eps(th, i):
    return (th[i][0]*phi[0] + th[i][1]*phi[1]) / msq          # z = 0


def deriv(state):
    th = [state[0:2], state[2:4], state[4:6]]
    alp = state[6:8]
    E = [eps(th, i) - eps(th, M) for i in range(M)]
    Ealp = sum(E[i]*alp[i] for i in range(M))
    dth = []
    for i in range(N):
        dth += [-(GAM[j] * eps(th, i) * phi[j]) for j in range(2)]
    dalp = [-gamma*(E[i]*Ealp) - gamma*(E[i]*eps(th, M)) for i in range(M)]
    return dth + dalp


def V457(state):
    at = [state[6+i] - astar[i] for i in range(M)]
    return (sum(a*a for a in at) + sum(at)**2) / (2*gamma)


def rates(state):
    th = [state[0:2], state[2:4], state[4:6]]
    at = [state[6+i] - astar[i] for i in range(M)]
    E = [eps(th, i) - eps(th, M) for i in range(M)]
    Ea = sum(E[i]*at[i] for i in range(M))
    ea = sum(eps(th, i)*msq*astar[i] for i in range(N))        # e_alpha
    exact = -((Ea + sum(at)*sum(E)) * (Ea + ea/msq))
    claimed = -(N * Ea*Ea) - N*(Ea*(ea/msq))
    return Ea, sum(at), sum(E), ea, exact, claimed


def rk4(state, h):
    def add(s, k, c): return [s[i] + c*k[i] for i in range(len(s))]
    k1 = deriv(state)
    k2 = deriv(add(state, k1, h/2))
    k3 = deriv(add(state, k2, h/2))
    k4 = deriv(add(state, k3, h))
    return [state[i] + h*(k1[i] + 2*k2[i] + 2*k3[i] + k4[i])/6 for i in range(len(state))]


def closed_form(t):
    """what the Coq witness files say the solution is"""
    c = [1.0, -1.0, 0.0]
    if WITNESS == "A":
        s = [10/3, -8/3, -2/3]
        w = math.exp(-5/2 + (5/2)*math.exp(-2*t))
        u = (w - 1)/5
        at = [-1/3 + 2*u, -5/3 - u]
    else:
        s = [-2/3, 10/3, -8/3]
        w = math.exp(-5 + 5*math.exp(-2*t))
        f = -(w - 1)/30
        at = [2/3 + f*1, -1/3 + f*3]
    th = [[s[i]*math.exp(-t), c[i]] for i in range(N)]
    return [x for p in th for x in p] + [at[0] + astar[0], at[1] + astar[1]]


state = th0[0] + th0[1] + th0[2] + alp0
h, T = 1e-4, 1.0
print("t        V(4.57)      max|numeric-closedform|")
worst = 0.0
t = 0.0
for step in range(int(T/h) + 1):
    if step % 2000 == 0:
        cf = closed_form(t)
        err = max(abs(state[i] - cf[i]) for i in range(len(state)))
        worst = max(worst, err)
        print("%.2f   %10.6f   %.2e" % (t, V457(state), err))
    state = rk4(state, h)
    t += h

s0 = th0[0] + th0[1] + th0[2] + alp0
Ea, Sb, SE, ea, exact, claimed = rates(s0)
V0, V1 = V457(s0), V457(closed_form(0.05))
num = (V457(closed_form(1e-6)) - V0) / 1e-6

print()
print("at t = 0:  E.alphatilde = %.6f   1.alphatilde = %.6f   1.E = %.6f   e_alpha = %.2e"
      % (Ea, Sb, SE, ea))
print("exact derivative of (4.57)      = %+.6f   (Coq: %+.6f)" % (exact, EXACT0))
print("value predicted by (4.58)       = %+.6f   (Coq: %+.6f)" % (claimed, CLAIMED0))
print("finite difference of V at 0     = %+.6f" % num)
print("V(0) = %.6f  ->  V(0.05) = %.6f   (%s)"
      % (V0, V1, "INCREASES" if V1 > V0 else "decreases"))
print("max deviation integrator vs closed form over [0,1]: %.2e" % worst)

ok = (abs(exact - EXACT0) < 1e-9 and abs(claimed - CLAIMED0) < 1e-9
      and abs(num - EXACT0) < 1e-4
      and V1 > V0 and worst < 1e-8 and abs(ea) < 1e-12)
print("\n[witness %s] %s" % (WITNESS,
               "CHECKS PASSED - the numerics agree with the Coq witness"
               if ok else "CHECKS FAILED"))
raise SystemExit(0 if ok else 1)
