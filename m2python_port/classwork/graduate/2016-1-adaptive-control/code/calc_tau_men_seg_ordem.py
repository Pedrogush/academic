"""Port of classwork/graduate/2016-1-adaptive-control/code/calc_tau_men_seg_ordem.m

Returns -real(-theta3 - sqrt(theta3^2 - 4 theta4))/2 from theta*_seg_ordem(3:4):
the (negated real part of the) faster root ("tau menor") of s^2 + theta3 s + theta4.

Porting notes:
- MATLAB's 1-based theta(3), theta(4) -> Python [2], [3]; sqrt of a negative
  number is complex (as in MATLAB) before taking the real part.
"""
import numpy as np


def calc_tau_men_seg_ordem(theta_estrela_seg_ordem):
    th = np.ravel(theta_estrela_seg_ordem)
    tau_men_seg_ordem = -np.real(-th[2] - np.sqrt(complex(th[2] ** 2 - 4 * th[3]))) / 2
    return tau_men_seg_ordem
