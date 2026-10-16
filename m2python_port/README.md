# m2python_port

Python ports of every MATLAB `.m` file in this repository (183 files, 175 distinct). Each `.py` sits at the
same relative path as its source, so `dissertation/code/Algoritmos Capítulo 2/L2_3M_Filtragem_O1.m` lives at
`m2python_port/dissertation/code/Algoritmos Capítulo 2/L2_3M_Filtragem_O1.py`. Folder names are kept exactly;
file names are turned into valid Python module names (spaces, hyphens, parentheses and accents become `_`).

Only numpy, scipy and matplotlib are needed (`pip install -r m2python_port/requirements.txt`). The Control,
Signal and Communications Toolbox calls (`tf`, `step`, `bode`, `margin`, `rlocus`, `invfreqs`, `awgn`, …) are
re-implemented with numpy/scipy inside the modules that use them, and `ode45` is `scipy.integrate.solve_ivp`
(RK45, MATLAB's default tolerances).

## Running

```bash
cd "m2python_port/dissertation/code/Algoritmos Capítulo 2"
python L2_3M_Filtragem_O1.py                      # simulate, print final estimates, plot
python L2_3M_Filtragem_O1.py --animate            # parameter-space convergence animation
python L2_3M_Filtragem_O1.py --animate --save anim.gif   # or .mp4 (needs ffmpeg)
```

- MATLAB scripts become a `main()` run under `if __name__ == "__main__"`. MATLAB functions keep their name,
  positional arguments and outputs (a tuple when there are several), and each module's `main()` runs a demo call.
- Each module's docstring gives the original path, what the code does, and **Porting notes** (deviations,
  original bugs kept or fixed, missing dependencies).
- Random numbers come from `np.random.default_rng(seed)`, so random runs do not reproduce MATLAB's streams.
- Run with `MPLBACKEND=Agg` to skip opening windows.

## Animations

Parameter-convergence animations are `animate(...)` functions built on `matplotlib.animation.FuncAnimation`
(trajectories of each model's estimate, the level-2 estimate, the convex hull, the uncertainty region, and a
"N Segundos" legend title, with the same axis zooms as the MATLAB code). Scripts expose them with `--animate`
and `--save PATH.gif|.mp4`. Where the MATLAB animation was active, it plays by default; where it was commented
out, it is opt-in.

| Where | Files |
|---|---|
| `dissertation/code/Algoritmos Capítulo 2/` | every file (shared builder `_param_anim.py`); `L2_3M_Filtragem_O1_DEFESA` and `L2mod_3M_Filtragem_O1` animate by default |
| `.../Toolbox Adaptacao L2/` | `anim_trajetorias` (driven by `L2AA`, `L2AA_CL`, `L1A`), `exemplos` |
| `.../Toolbox Adaptacao L2/Old/` | `L2AA_Dif_Anim`, `L2AA_Dif_Anim_InputAsStruct`, `L2AA_Dif_ModDes_SatAlfa_longA`, `L2AA_Dif_ModDes_SatAlfa_theAnimation`, `genfigure` |
| `papers/2016-cba-second-level-adaptation-pe-switch-off/code/` | `anlinesample` |

## Verification

The originals were run in GNU Octave 8.4 (with small stand-ins for `tf2ss` and for plotting) and compared with
the ports. Deterministic Euler simulations agree to roughly 1e-12 relative error or better (most to ~1e-15);
`ode45` scripts agree to solver tolerance. Every port runs to completion headless except the two
`aprendizado_gamma*` scripts, which need a missing `theta_fromf.m` and Simulink models and stop with
`NotImplementedError`.

Known limits:
- **Simulink** (`.slx`) models are not ported; code that calls `sim(...)` raises `NotImplementedError` and accepts a user-supplied replacement.
- **Round-off-driven switching:** the concurrent-learning `*_CL_Ident*` functions decide memory updates by comparing singular values of a rank-deficient matrix, so the exact switching instants depend on the LAPACK build (they match Octave's, but MATLAB/MKL may differ).
- **Originals that never ran** (`L2A.m`, `narendra_2015_sim1.m`, `Narendra_Sim_Geral_Inversa_2_var.m`, `backup_of_make_struct.m`) are ported faithfully and fail at the same statement; see their docstrings.
- `Narendra_Sim_Geral_Inversa` matches until ~2.4 s, after which the inverse method is ill-conditioned on its own example and rounding takes over (in Octave too).

## Per folder

**dissertation/code/**
- *Algoritmos Capítulo 2*: first- and second-level identification (filtered linear regression) of `dy/dt = -a_p y + k_p u` with 1, 3, 4 and 8 models, plus the L2mod integral variant. Two bugs in the original `L2_4M`/`L2_8M` animations are fixed (markers frozen at the initial estimates, `--faithful-markers` restores that; legend labels shifted). `Lista_de_Comandos_Ch2` calls three functions that are not in the repo and passes `None` for them.
- *Algoritmos Capítulo 3*: model-reference adaptive control of the first-order plant (known parameters, level 1, level 2 with N = 3, variable structure).
- *Algoritmos Capítulo 4*: identification of a 2nd-order SISO plant (level 1, 5-model level 2, level 2 with forgetting factor), with projection. `theta` is returned as (4, N) instead of 4×1×N.
- *Algoritmos Capítulo 5*: MRAC of an unstable 2nd-order plant (level 1, known parameters, variable structure, 5-model level 2 with and without forgetting factor).
- Top level: plotting functions for chapters 2–5 (each `main()` runs the chapter port) and `VectorReduction`.
- *2016-second-level-adaptation-experiments*: scratch experiments (try/catch, classdef, switch, SVD, phase portrait, lecture notes).
- *2016-second-level-adaptation-toolbox* (top level): second-level identification after Narendra, Wang & Chen (ACC 2014): `L2AA_Ident` (state access), `L2A_IO_Ident` (input/output), the `*_CL_Ident*` concurrent-learning variants (`_Esc`, `_Otimo`, `_V0_Completo` also adapt the gain), convex-hull helpers, and `tabbedGUI` rebuilt with matplotlib widgets (`--demo`). Shared helpers in `_toolbox_l2.py`. `_outras versões/` holds the 2016-10-25 and 2016-10-28 snapshots.
- *Toolbox Adaptacao L2*: `L2AA` (state-accessible second-level adaptation with PE switch-off), `L2AA_CL` (memory term), `L1A` (first-level baseline), `L2A_sem_zeros_IO`, the unfinished `L2A`, struct helpers (`convert_struct` also provides `Struct` and `load_struct` for the `.mat` parameter files), plotting, `anim_trajetorias` and `exemplos` (whose SIM1 struct targeted an older interface; the port adapts it and takes the missing fields from `param_sim_CBA.mat`).
- *Toolbox Adaptacao L2/Old*: earlier differential (`L2A_Dif*`) and inverse (`L2A_Inv`, `Narendra_Sim_*`) methods, `L2AA_*` versions with alpha saturation and PE switch-off, and the animations. Six `L2A_Dif_ModDes_SatAlfa*` files are byte-identical to the papers copies and are ported there (see the folder's README).

**papers/2016-cba-second-level-adaptation-pe-switch-off/code/**: the CBA 2016 simulations `L2A_Dif_ModDes_SatAlfa` and variants (`qo` multi-sine PE, `Alt` saturation, `Pert` input disturbance, `RMed` measurement noise, `Rui` noisy state); `--example` runs the call from the header. `Pert` clips a figure range that crashes MATLAB for runs shorter than 60 s. `ComLineDUMP17052016` replays the logged command history (`--list`, `--index I`, `--all`). The archived `L2AA` takes the older `stoptime`-first struct.

**classwork/graduate/**
- *2016-1-adaptive-control*: identifiers (gradient, integral gradient, projection, least squares with forgetting / saturated P / covariance resetting), R_MIT, APPC, Åström–Hägglund relay autotuning, MRAC_NRQ, helpers, and the archived versions (all distinct, all ported). Original algorithm bugs are kept and listed in the docstrings (e.g. main APPC uses the true plant for pole placement; `Gradiente_Proj` goes complex via `C.^C`).
- *2016-1-control-systems*: Van der Pol regulation project: Euler closed-loop simulations, root-locus and frequency-design walkthroughs with built-in tf/feedback/rlocus/bode/margin helpers, `invfreqs` re-implemented for `sensorexp`, and ode45 phase portraits.
- *2015-2-nonlinear-systems*: phase portraits. `mfase` reproduces the original's field (which evaluates to `x2' = -x1`); `--intended` gives Van der Pol.

**classwork/undergraduate/**: IEC relay curves (`ProtCurv`), TCC MRAC parameters (`params`), a conductor-sizing stub, and the digital-communications scripts with the Communications Toolbox objects re-implemented.
