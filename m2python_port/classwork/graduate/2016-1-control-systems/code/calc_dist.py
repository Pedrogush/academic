"""Port of classwork/graduate/2016-1-control-systems/code/calc_dist.m

Euclidean distance between the points (a, b) and (a1, b1).

Porting notes:
- Direct translation; works elementwise for numpy arrays as well.
"""
import numpy as np


def calc_dist(a, b, a1, b1):
    numb = np.sqrt((a - a1) ** 2 + (b - b1) ** 2)
    return numb


if __name__ == "__main__":
    print(calc_dist(0, 0, 3, 4))
