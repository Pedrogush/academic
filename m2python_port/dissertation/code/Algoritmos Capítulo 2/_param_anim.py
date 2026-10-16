"""Shared helper for the Chapter 2 parameter-space animations (no MATLAB counterpart).

The MATLAB files of this folder build their animations with ``animatedline`` /
``addpoints`` / ``drawnow`` (and the File Exchange ``gif`` function).  The pattern is
always the same:

* static objects: the true parameters (``x`` marker), the uncertainty region
  (red rectangle), sometimes the initial estimates;
* trails: ``animatedline`` objects that receive one point per integration step;
* current-estimate markers: ``animatedline('MaximumNumPoints',1, ...)`` that receive
  a point only every ``skip`` steps;
* convex hull: ``animatedline('MaximumNumPoints',N+1, ...)`` that receives the N model
  estimates plus the first one again (closed polygon) every ``skip`` steps;
* the legend title shows ``'<tempo(k)> Segundos'`` and is refreshed every ``skip`` steps;
* sometimes the axis limits are changed when ``tempo(k)`` passes given thresholds.

``animate_param_space`` reproduces this with ``matplotlib.animation.FuncAnimation``.
One animation frame corresponds to one MATLAB ``drawnow``/``gif`` call, i.e. the steps
k = skip, 2*skip, ... (MATLAB 1-based k), preceded by the initial frame (k = 0) that
shows the state before the loop (initial markers / hull, empty trails, "0 Segundos").
"""
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter, FFMpegWriter


def num2str_tempo(t):
    """Mimic MATLAB num2str for the time stamps h*k (e.g. 0.2, 12, 25.75)."""
    return f"{round(float(t), 10):g}"


def save_animation(anim, save, interval):
    """Save ``anim`` to ``save`` (.gif -> PillowWriter, .mp4 -> FFMpegWriter)."""
    if not save:
        return
    fps = max(1, int(round(1000.0 / interval)))
    low = str(save).lower()
    if low.endswith(".gif"):
        writer = PillowWriter(fps=fps)
    elif low.endswith(".mp4"):
        writer = FFMpegWriter(fps=fps)
    else:
        raise ValueError("save must end with .gif or .mp4")
    anim.save(str(save), writer=writer)


def animate_param_space(tempo, elements, *, skip, axis0, axis_schedule=(),
                        interval=100, title=None, xlabel=None, ylabel=None,
                        fontsize=None, figsize=(10, 8), trail_start=1, save=None,
                        legend_loc="best", k_start=1):
    """Build (and optionally save) a parameter-space animation.

    Parameters
    ----------
    tempo : array, tempo[k-1] = h*k for MATLAB k = 1..endk.
    elements : list of dicts, drawn in order (legend order = MATLAB creation order):
        {'kind': 'static', 'x', 'y', 'kw', 'label'}       plotted once
        {'kind': 'trail',  'x', 'y', 'kw', 'label'}       x[trail_start-1:k]
        {'kind': 'marker', 'x', 'y', 'kw', 'label'}       x[k-1] (x[0] at frame 0)
        {'kind': 'hull',   'xs', 'ys', 'kw', 'label'}     xs: (nverts, N) closed polygon
        'label' None -> not in the legend.
    skip : frames at MATLAB k = skip, 2*skip, ... (as ``floor(k/skip)==ceil(k/skip)``).
    axis0 : initial [xmin, xmax, ymin, ymax].
    axis_schedule : sequence of (t_threshold, [xmin, xmax, ymin, ymax]); the last one
        with tempo(k) >= t_threshold is applied (same as the MATLAB ``if`` chain).
    k_start : first MATLAB k of the drawing loop (trails start there too).
    """
    tempo = np.asarray(tempo, dtype=float)
    endk = len(tempo)
    frames = [0] + [k for k in range(max(skip, k_start), endk + 1) if k % skip == 0]
    trail_start = max(trail_start, k_start)

    fig, ax = plt.subplots(figsize=figsize)
    ax.grid(True)
    artists = []
    handles = []
    for el in elements:
        kind = el["kind"]
        kw = dict(el.get("kw", {}))
        if kind == "static":
            (ln,) = ax.plot(el["x"], el["y"], **kw)
        elif kind == "trail":
            (ln,) = ax.plot([], [], **kw)
        elif kind == "marker":
            kw.setdefault("linestyle", "none")
            (ln,) = ax.plot([el["x"][0]], [el["y"][0]], **kw)
        elif kind == "hull":
            xs = np.asarray(el["xs"])
            ys = np.asarray(el["ys"])
            (ln,) = ax.plot(np.r_[xs[:, 0], xs[0, 0]], np.r_[ys[:, 0], ys[0, 0]], **kw)
        else:
            raise ValueError(kind)
        artists.append((el, ln))
        if el.get("label") is not None:
            ln.set_label(el["label"])
            handles.append(ln)
    ax.axis(axis0)
    if title:
        ax.set_title(title, fontsize=fontsize)
    if xlabel:
        ax.set_xlabel(xlabel, fontsize=fontsize)
    if ylabel:
        ax.set_ylabel(ylabel, fontsize=fontsize)
    if fontsize:
        ax.tick_params(labelsize=fontsize)
    lgd = ax.legend(handles=handles, title="0 Segundos", loc=legend_loc,
                    fontsize=(fontsize * 0.6 if fontsize else None))

    def update(k):
        for el, ln in artists:
            kind = el["kind"]
            if kind == "trail":
                if k == 0:
                    ln.set_data([], [])
                else:
                    ln.set_data(el["x"][trail_start - 1:k], el["y"][trail_start - 1:k])
            elif kind == "marker":
                i = 0 if k == 0 else k - 1
                ln.set_data([el["x"][i]], [el["y"][i]])
            elif kind == "hull":
                i = 0 if k == 0 else k - 1
                xs = np.asarray(el["xs"])[:, i]
                ys = np.asarray(el["ys"])[:, i]
                ln.set_data(np.r_[xs, xs[0]], np.r_[ys, ys[0]])
        lims = axis0
        if k > 0:
            for thr, lim in axis_schedule:
                if tempo[k - 1] >= thr:
                    lims = lim
        ax.axis(lims)
        lgd.set_title(("0" if k == 0 else num2str_tempo(tempo[k - 1])) + " Segundos")
        return [ln for _, ln in artists]

    anim = FuncAnimation(fig, update, frames=frames, interval=interval, blit=False,
                         repeat=False)
    anim._param_fig = fig
    save_animation(anim, save, interval)
    return anim


def final_static_plot(tempo, elements, *, skip, axis0, title=None, xlabel=None,
                      ylabel=None, fontsize=None, figsize=(10, 8), legend_title=True,
                      k_start=1):
    """Draw the state an animatedline loop leaves after it finishes (no animation).

    This is what the MATLAB "*_Figs" functions show: the complete trails, markers at the
    last multiple of ``skip`` and the legend title with that time.
    """
    tempo = np.asarray(tempo, dtype=float)
    endk = len(tempo)
    klast = (endk // skip) * skip
    fig, ax = plt.subplots(figsize=figsize)
    ax.grid(True)
    handles = []
    for el in elements:
        kind = el["kind"]
        kw = dict(el.get("kw", {}))
        if kind == "static":
            (ln,) = ax.plot(el["x"], el["y"], **kw)
        elif kind == "trail":
            (ln,) = ax.plot(el["x"][k_start - 1:endk], el["y"][k_start - 1:endk], **kw)
        elif kind == "marker":
            kw.setdefault("linestyle", "none")
            i = klast - 1 if klast >= 1 else 0
            (ln,) = ax.plot([el["x"][i]], [el["y"][i]], **kw)
        elif kind == "hull":
            i = klast - 1 if klast >= 1 else 0
            xs = np.asarray(el["xs"])[:, i]
            ys = np.asarray(el["ys"])[:, i]
            (ln,) = ax.plot(np.r_[xs, xs[0]], np.r_[ys, ys[0]], **kw)
        if el.get("label") is not None:
            ln.set_label(el["label"])
            handles.append(ln)
    ax.axis(axis0)
    if title:
        ax.set_title(title, fontsize=fontsize)
    if xlabel:
        ax.set_xlabel(xlabel, fontsize=fontsize)
    if ylabel:
        ax.set_ylabel(ylabel, fontsize=fontsize)
    if fontsize:
        ax.tick_params(labelsize=fontsize)
    ttl = None
    if legend_title:
        ttl = (num2str_tempo(tempo[klast - 1]) if klast >= 1 else "0") + " Segundos"
    ax.legend(handles=handles, title=ttl, fontsize=(fontsize * 0.6 if fontsize else None))
    return fig, ax


# Common style dictionaries (MATLAB colors / sizes)
def true_point(a_p, k_p, label=r"$a_p,k_p$ Verdadeiros", ms=18, lw=2.0):
    return {"kind": "static", "x": [a_p], "y": [k_p], "label": label,
            "kw": dict(marker="x", markersize=ms, markeredgewidth=lw, color=(0, 0, 0),
                       linestyle="none")}


def region(a_p_m, a_p_M, k_p_m, k_p_M, label="Região de Incerteza"):
    return {"kind": "static", "x": [a_p_M, a_p_M, a_p_m, a_p_m, a_p_M],
            "y": [k_p_M, k_p_m, k_p_m, k_p_M, k_p_M], "label": label,
            "kw": dict(color=(1, 0, 0), linewidth=2.0)}
