"""Port of dissertation/code/2016-second-level-adaptation-toolbox/tabbedGUI.m

Tabbed GUI (work in progress in the original) for the second-level adaptation
toolbox. Tab 1 "Parametros de Simulação" has one edit box per simulation
parameter (filling the struct Sim_Par, whose field order is the one expected by
convert_struct in L2AA_Ident, L2A_IO_Ident, L2AA, ...), plus buttons to save /
load the parameters to a .mat file and to run the simulation. Tab 6 "Opções"
chooses the simulation type (identification only / identification and
control), the method (second-level adaptation / gradient with integral cost)
and the available measurements (state vector / SISO), which select the
simulation function. Tabs 2, 3, 4 (trajectory, control and identification
plots), 5 (simulation diagram) and 7 (animations) only contain placeholder
axes in the original, and so they do here.

Porting notes:
- uitabgroup/uitab/uicontrol -> matplotlib.widgets: a row of Buttons acts as
  the tab bar (switching the visibility of each tab's axes), TextBox for the
  edit boxes, RadioButtons for the popup menus, Button for push buttons.
- uisave / uigetfile have no matplotlib counterpart: Save/Load use the file
  name typed in an extra "Arquivo .mat" box (default 'Parameters.mat'); the
  file holds the struct 'Parameters', as in MATLAB (scipy.io.savemat/loadmat).
- str2num / mat2str are emulated for numeric matrix literals ("[1 2; 3 4]").
- BUG in the original: 'switch [sw_1,sw_2,sw_3]' with 'case [1,1,1]' is not
  valid MATLAB (switch needs a scalar or a char vector) and would error; the
  port implements the intended dispatch with a dict.
- Dispatched functions: L2AA_Ident, L2A_IO_Ident (this folder), L2AA
  ("Toolbox Adaptacao L2"), Gradiente_FCI (classwork/graduate/2016-1-adaptive-
  control/code/Identificação) and APPC (.../Estrategias Controle Adaptativo)
  are imported from their ports via importlib (the last two expect their own,
  different input structs, as in MATLAB). Gradiente_FCI_VE, L2A_IO and APPC_VE
  do not exist in the repository and raise NotImplementedError.
- The simulation output is stored in gui["Current_Simulation_Output"] (in the
  original it is a variable of the nested-function workspace, not plotted).
- The original file is missing one 'end' (nested functions); irrelevant here.
"""
import argparse
import os
import re
import textwrap

import numpy as np
import matplotlib.pyplot as plt
import scipy.io
from matplotlib.widgets import Button, RadioButtons, TextBox

from _toolbox_l2 import load_toolbox
from L2AA_Ident import L2AA_Ident
from L2A_IO_Ident import L2A_IO_Ident

SIM_PAR_FIELDS = ("t_0", "t_final", "h", "modelos", "planta", "modelo_ref", "cond_iniciais_p",
                  "cond_iniciais_m", "cond_iniciais_i", "alfa_0", "Q", "gamma", "P", "not_used",
                  "ref_amp", "ref_freq", "tol_eta", "tau_ref")
OUTPUT_FIELDS = ("x_p", "x_m", "eta", "theta_p_estimativa", "norm_2_e_o", "e_o", "u", "alfa_barra",
                 "r", "modelo_de_referencia", "planta", "theta_BARRA", "modelos", "tempo", "endk")

TAB_TITLES = ("Parametros de Simulação",
              "Plotagem de Trajetória no Espaço de Parâmetros da Planta",
              "Plotagem dos Sinais de Controle",
              "Plotagem dos Sinais de Identificação",
              "Diagrama de Simulação",
              "Opções",
              "Animações")


# ------------------------------------------------------------ str2num / mat2str
def str2num(s):
    """MATLAB str2num for numeric literals: '5', '[1 2;3 4]', '[0; 1]'. [] on failure."""
    s = s.strip()
    if not s:
        return np.array([])
    s = s.strip("[]")
    try:
        rows = [r for r in re.split(r"[;\n]", s) if r.strip()]
        data = [[float(x) for x in re.split(r"[,\s]+", r.strip()) if x] for r in rows]
        A = np.array(data, dtype=float)
    except ValueError:
        return np.array([])
    return A.item() if A.size == 1 else A


def mat2str(A):
    """MATLAB mat2str (15 significant digits)."""
    A = np.asarray(A, dtype=float)
    fmt = lambda x: "NaN" if np.isnan(x) else ("%.15g" % x)
    if A.size == 1:
        return fmt(A.item())
    A = np.atleast_2d(A)
    return "[" + ";".join(" ".join(fmt(x) for x in row) for row in A) + "]"


# ------------------------------------------------------------ dispatch
def _missing(name):
    def f(_args):
        raise NotImplementedError("%s.m does not exist in the repository" % name)
    return f


_PORT_ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))


def _external_fn(relpath, name):
    """Function from another folder of the port (loaded lazily via importlib)."""
    def f(args):
        import importlib.util
        import sys
        path = os.path.join(_PORT_ROOT, relpath)
        if not os.path.isfile(path):
            raise NotImplementedError("port %s not available" % relpath)
        d = os.path.dirname(path)
        if d not in sys.path:
            sys.path.append(d)
        spec = importlib.util.spec_from_file_location("ext_" + name, path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return getattr(mod, name)(args)
    return f


def _toolbox_fn(name):
    def f(args):
        mod = load_toolbox(name)
        if mod is None or not hasattr(mod, name):
            raise NotImplementedError("port of 'Toolbox Adaptacao L2/%s.m' not available" % name)
        return getattr(mod, name)(args)
    return f


SIMULATIONS = {
    (1, 1, 1): L2AA_Ident,                       # DONE
    (1, 1, 2): L2A_IO_Ident,                     # Zeros
    (1, 2, 1): _missing("Gradiente_FCI_VE"),     # ?
    (1, 2, 2): _external_fn("classwork/graduate/2016-1-adaptive-control/code/Identificação/"
                            "Gradiente_FCI.py", "Gradiente_FCI"),  # DONE
    (2, 1, 1): _toolbox_fn("L2AA"),              # DONE
    (2, 1, 2): _missing("L2A_IO"),               # Zeros
    (2, 2, 1): _missing("APPC_VE"),              # ?
    (2, 2, 2): _external_fn("classwork/graduate/2016-1-adaptive-control/code/"
                            "Estrategias Controle Adaptativo/APPC.py", "APPC"),  # DONE
}


def tabbedGUI():
    """Create the tabbed GUI. Returns a dict with the figure, widgets and state."""
    hFig = plt.figure(figsize=(13, 8))
    try:
        hFig.canvas.manager.set_window_title("tabbedGUI")
    except Exception:
        pass
    gui = {"fig": hFig,
           "Sim_Par": {k: np.nan for k in SIM_PAR_FIELDS},
           "Current_Simulation_Output": {k: np.nan for k in OUTPUT_FIELDS},
           "tabs": [[] for _ in TAB_TITLES]}
    W, H = 1000.0, 680.0  # MATLAB pixel positions -> figure fractions

    def pos(x, y, w, h):
        return [0.02 + x / W * 0.95, y / H * 0.88, w / W * 0.95, h / H * 0.88]

    # ---------------- tab bar
    tab_buttons = []
    bw = 0.96 / len(TAB_TITLES)
    for i, title in enumerate(TAB_TITLES):
        ax = hFig.add_axes([0.02 + i * bw, 0.93, bw - 0.004, 0.05])
        btn = Button(ax, title if len(title) < 26 else title[:24] + "…")
        btn.label.set_fontsize(7)
        btn.on_clicked(lambda _evt, i=i: select_tab(i))
        tab_buttons.append(btn)
    gui["tab_buttons"] = tab_buttons

    def select_tab(i):
        for t, artists in enumerate(gui["tabs"]):
            for a in artists:
                a.set_visible(t == i)
        for t, b in enumerate(tab_buttons):
            b.ax.set_facecolor("0.75" if t == i else "0.95")
        gui["SelectedTab"] = i
        hFig.canvas.draw_idle()

    gui["select_tab"] = select_tab

    def add(tab, ax):
        gui["tabs"][tab].append(ax)
        return ax

    # ---------------- tab 1: parameters
    edits = {}
    rows = [  # (field, label, x_txt, x_edt, y, w_edt)
        ("h", "Passo de Integração", 80, 270, 600, 150),
        ("t_0", "Tempo Inicial", 80, 270, 540, 200),
        ("t_final", "Tempo Final", 80, 270, 480, 200),
        ("modelos", "Modelos de Identificação", 80, 270, 420, 200),
        ("planta", "Modelo da Planta", 80, 270, 360, 200),
        ("modelo_ref", "Modelo de Referência", 80, 270, 300, 200),
        ("cond_iniciais_p", "Condições Iniciais da Planta", 80, 270, 240, 200),
        ("cond_iniciais_m", "Condições Iniciais do Modelo de Referência", 80, 270, 180, 200),
        ("cond_iniciais_i", "Condições Iniciais dos Modelos De Identificação", 80, 270, 120, 150),
        ("alfa_0", "Alfa 0, Estimativa Inicial do Modelo Virtual", 80, 270, 60, 150),
        ("Q", "Matriz Q de Avaliação da Taxa de Adaptação", 600, 790, 600, 150),
        ("gamma", "Ganho adaptativo do Modelo Virtual", 600, 790, 540, 150),
        ("P", "Matriz de Ganhos Adaptativos dos Modelos de Identificação", 600, 790, 480, 150),
        ("ref_amp", "Vetor de Amplitudes das Senóides de Referência", 600, 790, 420, 150),
        ("ref_freq", "Vetor de Frequências das Senóides de Referência", 600, 790, 360, 150),
        ("tol_eta", "Tolerância de Desligamento da parcela PE do Sinal de Referência", 600, 790, 300, 150),
        ("tau_ref", "Constante de Tempo de Retorno à Referência Constante", 600, 790, 240, 150),
    ]
    for field, label, xt, xe, y, we in rows:
        ax = add(0, hFig.add_axes(pos(xe, y, we, 30)))
        tb = TextBox(ax, "")
        lab = ax.text(-(xe - xt) / we, 0.5, textwrap.fill(label, 38), transform=ax.transAxes,
                      ha="left", va="center", fontsize=7)
        lab.set_clip_on(False)

        def callback(text, field=field):
            gui["Sim_Par"][field] = str2num(text)
            if field == "h":
                print("Sim_Par =", gui["Sim_Par"])  # (sem ';' no original)
        tb.on_submit(callback)
        edits[field] = tb
    gui["edits"] = edits

    ax_file = add(0, hFig.add_axes(pos(790, 210, 150, 25)))
    file_box = TextBox(ax_file, "Arquivo .mat ", initial="Parameters.mat")
    file_box.label.set_fontsize(7)
    gui["file_box"] = file_box

    def Update_Parameter_Fields(Parameters):
        for field, tb in edits.items():
            tb.set_val(mat2str(Parameters[field]))

    def SaveButtonCallback(_evt=None):
        Parameters = dict(gui["Sim_Par"])
        scipy.io.savemat(file_box.text, {"Parameters": Parameters})

    def LoadButtonCallback(_evt=None):
        fname = file_box.text
        if not os.path.isfile(fname):
            return
        P = scipy.io.loadmat(fname, squeeze_me=True, struct_as_record=False)["Parameters"]
        Parameters = {f: getattr(P, f) for f in P._fieldnames}
        gui["Sim_Par"] = {k: Parameters.get(k, np.nan) for k in SIM_PAR_FIELDS}
        Update_Parameter_Fields(gui["Sim_Par"])

    btns = []
    for label, y, cb in (("Save Simulation Parameters", 180, SaveButtonCallback),
                         ("Load Simulation Parameters", 150, LoadButtonCallback),
                         ("Run Simulation", 120, lambda _e=None: RunSimulationCallback())):
        ax = add(0, hFig.add_axes(pos(790, y - 5, 150, 27)))
        b = Button(ax, label)
        b.label.set_fontsize(7)
        b.on_clicked(cb)
        btns.append(b)
    gui["buttons"] = btns
    gui["SaveButtonCallback"] = SaveButtonCallback
    gui["LoadButtonCallback"] = LoadButtonCallback

    # ---------------- tab 6: options (popup menus -> radio buttons)
    popups = [
        ("Tipo_de_Sim", "Tipo de Simulação", 600,
         ("Identificação de Parâmetros de uma Planta Conhecida com Incertezas",
          "Identificação e Controle de uma Planta Conhecida com Incertezas")),
        ("Tipo_de_ident", "Método de Identificação", 480,
         ("Adaptação de Segundo Nível", "Método do Gradiente com Função de Custo Integral")),
        ("Tipo_de_acesso", "Medidas Disponíveis da Planta", 360,
         ("Vetor de Estados da Planta Acessível, Planta Sem Zeros", "Caso SISO")),
        ("Lang", "Línguagem", 240, ("Português", "Inglês")),
    ]
    radios = {}
    for key, label, y, options in popups:
        ax = add(5, hFig.add_axes(pos(270, y - 50, 450, 80)))
        rb = RadioButtons(ax, options, active=0)
        for t in rb.labels:
            t.set_fontsize(8)
        ax.set_title(label, fontsize=9, loc="left")
        radios[key] = rb
    gui["radios"] = radios

    def Value(key):
        rb = radios[key]
        return [t.get_text() for t in rb.labels].index(rb.value_selected) + 1

    def RunSimulationCallback():
        sw_1 = Value("Tipo_de_Sim")
        sw_2 = Value("Tipo_de_ident")
        sw_3 = Value("Tipo_de_acesso")
        sim = SIMULATIONS[(sw_1, sw_2, sw_3)]
        gui["Current_Simulation_Output"] = sim(gui["Sim_Par"])
        return gui["Current_Simulation_Output"]

    gui["RunSimulationCallback"] = RunSimulationCallback

    # ---------------- tabs 2, 3, 4: 4x2 subplot placeholders
    for tab in (2, 3, 1):  # controle, identificação, trajetória (ordem do original)
        gs = hFig.add_gridspec(4, 2, left=0.08, right=0.95, bottom=0.07, top=0.88,
                               hspace=0.5, wspace=0.25)
        a1 = add(tab, hFig.add_subplot(gs[0:2, 0]))
        a1.plot(np.nan, np.nan, color="r")
        for g in (gs[0:2, 1], gs[2:4, 0], gs[2:4, 1]):
            a = add(tab, hFig.add_subplot(g))
            a.plot([1, 1], [2, 2])
    # ---------------- tab 7 and tab 5
    hAx7 = add(6, hFig.add_axes([0.1, 0.1, 0.8, 0.75]))
    hAx7.plot([1, 1], [2, 2])
    hAx5 = add(4, hFig.add_axes([0.1, 0.1, 0.8, 0.75]))
    hAx5.plot([0, 0], [0, 0])

    select_tab(0)
    return gui


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--demo", action="store_true",
                        help="fill tab 1 with an example and run L2AA_Ident once")
    a = parser.parse_args(argv)
    gui = tabbedGUI()
    if a.demo:
        from _toolbox_l2 import example_args
        ex = example_args("IO", t_final=5.0, h=1e-3)
        for field, tb in gui["edits"].items():
            tb.set_val(mat2str(ex[field]))
            gui["Sim_Par"][field] = str2num(tb.text)
        gui["Sim_Par"]["not_used"] = ex["not_used"]
        out = gui["RunSimulationCallback"]()
        th = out["theta_p_estimativa"] if isinstance(out, dict) else out.theta_p_estimativa
        print("theta_p_estimativa(:,end) =", np.asarray(th)[:, -1])
    plt.show()
    return gui


if __name__ == "__main__":
    main()
