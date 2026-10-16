"""Port of papers/2016-cba-second-level-adaptation-pe-switch-off/code/anlinesample.m

Small test of MATLAB's ``animatedline`` (used later in anim_trajetorias): an animated line
keeping only its last 4 points (MaximumNumPoints = 4, LineWidth 3) is fed, for
k = 1..400, with four points [k, (k+2)*1.01^-k, k+1, k] x [(k+3)*1.01^-k, -k, k+4,
(k+3)*1.01^-k]; two static lines are drawn first ([1 2 3 4 1],[3 4 5 6 3] and
[0 400],[40 0]); each frame is captured with getframe into the movie M.

Porting notes: script -> main() with ``animate(save=None, skip=1, interval=20)`` built on
FuncAnimation (the MaximumNumPoints=4 buffer is emulated by keeping the last 4 points).
The MATLAB movie M (getframe) corresponds to the returned animation; ``--save PATH``
writes it (.gif/.mp4). The animation is active in the original, so it runs by default
(``--animate`` accepted for uniformity). Axes autoscale as MATLAB's do.
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import animation


def animate(save=None, skip=1, interval=20):
    fig, ax = plt.subplots()
    h, = ax.plot([], [], linewidth=3.0)
    ax.plot([1, 2, 3, 4, 1], [3, 4, 5, 6, 3])
    ax.plot([0, 400], [40, 0])
    buf_x, buf_y = [], []

    def update(k):
        # addpoints adds the points of step k (and those skipped, to keep the buffer exact)
        for kk in range(max(1, k - skip + 1), k + 1):
            buf_x.extend([kk, (kk + 2) * 1.01 ** -kk, kk + 1, kk])
            buf_y.extend([(kk + 3) * 1.01 ** -kk, -kk, kk + 4, (kk + 3) * 1.01 ** -kk])
        del buf_x[:-4]
        del buf_y[:-4]
        h.set_data(buf_x, buf_y)
        ax.relim()
        ax.autoscale_view()
        return [h]

    anim = animation.FuncAnimation(fig, update, frames=range(skip, 401, skip),
                                   interval=interval, blit=False, repeat=False)
    if save:
        fps = max(1, int(round(1000 / interval)))
        writer = (animation.PillowWriter(fps=fps) if str(save).lower().endswith(".gif")
                  else animation.FFMpegWriter(fps=fps))
        anim.save(save, writer=writer)
    return anim


def main(argv=None):
    p = argparse.ArgumentParser(description="animatedline sample")
    p.add_argument("--animate", action="store_true")
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=1)
    p.add_argument("--interval", type=int, default=20)
    a = p.parse_args(argv)
    anim = animate(save=a.save, skip=a.skip, interval=a.interval)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
