"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/graph_arrow_2D.m

Draws, on the current axes, a thick black segment from ``thetak`` to ``thetak_mais_1`` and
a small filled black triangular arrow head at ``thetak`` (head size 1% of the segment,
rotated +-225 degrees), used to show the direction of a parameter trajectory in the 2-D
parameter plane.

Porting notes: ``thetak``/``thetak_mais_1`` are 2-element row vectors (as in MATLAB, the
row vector multiplies the rotation matrix from the left). Optional ``ax`` argument added
(default: plt.gca()). The unused MATLAB variable ``tamanho`` is kept.
"""
import numpy as np
import matplotlib.pyplot as plt


def graph_arrow_2D(thetak, thetak_mais_1, ax=None):
    if ax is None:
        ax = plt.gca()
    thetak = np.ravel(np.asarray(thetak, dtype=float))
    thetak_mais_1 = np.ravel(np.asarray(thetak_mais_1, dtype=float))

    vetor = thetak - thetak_mais_1
    tamanho = np.linalg.norm(vetor) / 70  # noqa: F841  (unused in the original)

    a = 225 / 180 * np.pi
    R1 = np.array([[np.cos(a), -np.sin(a)], [np.sin(a), np.cos(a)]])
    R2 = np.array([[np.cos(-a), -np.sin(-a)], [np.sin(-a), np.cos(-a)]])
    p1_seta = thetak
    p2_seta = thetak + 0.01 * vetor @ R1
    p3_seta = thetak + 0.01 * vetor @ R2
    ax.fill([p1_seta[0], p2_seta[0], p3_seta[0], p1_seta[0]],
            [p1_seta[1], p2_seta[1], p3_seta[1], p1_seta[1]], color=[0, 0, 0])

    ax.plot([thetak[0], thetak_mais_1[0]], [thetak[1], thetak_mais_1[1]],
            linewidth=2, color=[0, 0, 0])
