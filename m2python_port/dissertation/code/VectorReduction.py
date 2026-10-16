"""Port of dissertation/code/VectorReduction.m

Marker thinning helper: given a curve (vec1, vec2) returns the subset of points
(redvec1, redvec2) where plot markers should be drawn so that consecutive markers
are at least ``eucl_dist_min`` apart, the distance being measured with the second
axis rescaled by (axis1 range)/(axis2 range) so that it is roughly isotropic on
the plot.  (Comments of the original, translated: main input is the vector pair;
output is the marker positions; eucl_dist_min is the minimum Euclidean distance
between markers; axis1min..axis2max are the plot axis limits.)

Porting notes:
- Same greedy scan (the first point is always kept).  Returns numpy arrays.
"""
import numpy as np


def VectorReduction(vec1, vec2, eucl_dist_min, axis1min, axis1max, axis2min, axis2max):
    vec1 = np.asarray(vec1, dtype=float).ravel()
    vec2 = np.asarray(vec2, dtype=float).ravel()
    scale = abs(axis1min - axis1max) / abs(axis2min - axis2max)
    redvec1 = [vec1[0]]
    redvec2 = [vec2[0]]
    for k in range(len(vec1)):
        eucl_dist = np.sqrt((vec1[k] - redvec1[-1]) ** 2 + scale ** 2 * (vec2[k] - redvec2[-1]) ** 2)
        if eucl_dist > eucl_dist_min:
            redvec1.append(vec1[k])
            redvec2.append(vec2[k])
    return np.array(redvec1), np.array(redvec2)


if __name__ == "__main__":
    t = np.linspace(0, 20, 2001)
    r1, r2 = VectorReduction(t, np.sin(t), 1.6, 0, 20, -1, 1)
    print(len(r1), "markers")
