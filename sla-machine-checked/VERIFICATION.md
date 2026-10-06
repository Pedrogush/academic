# Independent re-verification, 2026-08-17

Every proof in this repository was re-checked from a clean state on
2026-08-17 (UTC), on Linux (WSL2, 4 cores / 7 GB). Build artefacts were deleted
first, so nothing was accepted on the strength of a stale `.vo`, `.olean` or
heap image. Each system's own log files (`isabelle/verification-log.txt`,
`lean/verification-log.txt`, `keymaerax/verification-log.txt`) record the
original runs; this file records the re-run.

Alongside the machine checks, the two reported findings were checked directly
against the text of [`dissertation/final/gushiken-2018-dissertacao-formalization-reference.pdf`](../dissertation/final/gushiken-2018-dissertacao-formalization-reference.pdf). Equations (4.53), (4.57), (4.58), (4.67) and
(4.69) read there exactly as the formalisations quote them, and the six pages
cited in `NOTE_convex_uniqueness.md` (23, 28, 60, 64, 72, 83) do carry the
`N ≥ 2n + 1` form — while the worked example on page 72 uses `p₀ = N = 5` at
`n = 2`, i.e. `N = 2n + 1` exactly.

## Coq 8.18.0

```
COQDEP VFILES
COQC SLA_Prelim.v
COQC SLA_Chapter4.v
COQC SLA_AppendixA.v
COQC SLA_Instance.v
EXIT=0
```

No `Axiom`, `Parameter`, `Conjecture`, `admit` or `Admitted` occurs in any
`.v` file. `Print Assumptions` was run on 23 headline theorems —
`hull_invariance`, `theta_star_in_hull`, `ea_zero`, `E_alpha_star`,
`E_alpha_star_exact`, `Vb_dyn`, `Vr_dyn`, `Vb_deriv_differs_from_4_58`,
`Vb_deriv_can_be_positive`, `Mf_psd`, `qres_zero`, `VrF_dyn`, `VrF_nonpos`,
`V1_dyn`, `e_dyn`, `ev_convex`, `theorem1_uniqueness`, `theorem2_uniqueness`,
`design_rule_exact`, `more_vertices_not_unique`, `inst_astar_unique`,
`inst_hull_invariance`, `inst_E_nonzero` — and each depends only on the axioms
Coq's own `Reals` library is built on:

```
Classical_Prop.classic
FunctionalExtensionality.functional_extensionality_dep
ClassicalDedekindReals.sig_forall_dec
ClassicalDedekindReals.sig_not_dec
```

The development adds none of its own. `coq/annotated/` was checked to declare
exactly the same theorems, definitions, variables and hypotheses as `coq/`; it
differs only in commentary.

## Lean 4.33.0 / Mathlib v4.33.0

All previously built `.olean`s for this project were deleted and `lake build`
re-run:

```
✔ [2134/2139] Built SLA.Prelim (1522s)
✔ [2135/2139] Built SLA.AppendixA (722s)
✔ [2136/2139] Built SLA.Chapter4 (74s)
✔ [2137/2139] Built SLA.Instance (58s)
✔ [2138/2139] Built SLA (127s)
Build completed successfully (2139 jobs).
EXIT=0
```

No `sorry`, `admit`, `axiom` or `native_decide` occurs in any `.lean` file.
`#print axioms` was run on 21 headline theorems — `Hull.hull_invariance`,
`Hull.theta_star_in_hull`, `Hull.ea_zero`, `Hull.E_alpha_star`,
`SecondLevel.Vb_deriv`, `SecondLevel.Vr_deriv`, `SecondLevel.Vr_antitone`,
`rateExact_can_be_positive`, `rateExact_witness`, `Forgetting.Mf_psd`,
`Forgetting.qres_zero`, `Forgetting.VrF_deriv`, `Forgetting.VrF_nonpos`,
`AppendixA.theorem1_uniqueness`, `AppendixA.theorem2_uniqueness`,
`AppendixA.design_rule_exact`, `AppendixA.more_vertices_not_unique`,
`Instance.astar_unique`, `Instance.hull_invariance_inst`,
`Instance.E_nonzero`, `Instance.vf_ne_zero` — and every one reports exactly

```
depends on axioms: [propext, Classical.choice, Quot.sound]
```

## Isabelle2025-2 (HOL)

`isabelle build` on a cleaned session:

```
Running SLA ...
SLA: theory SLA.SLA_Prelim      100% (12.667s cumulated time)
SLA: theory SLA.SLA_AppendixA   100% (14.162s cumulated time)
SLA: theory SLA.SLA_Chapter4    100% (86.130s cumulated time)
SLA: theory SLA.SLA_Instance    100% (29.706s cumulated time)
SLA: theory SLA.SLA_Check       100% ( 7.920s cumulated time)
Finished SLA
EXIT=0
```

No `sorry`, `oops`, `axiomatization`, `nitpick` or `quickcheck` occurs in any
`.thy` file. `SLA_Check.thy` is an audit theory: it restates each headline
result verbatim and discharges it by a single `rule` from the theorem it claims
to be, so a drift between the advertised statement and the proved one would
break the build.

## KeYmaera X 5.1.2 with Z3 5.0.0

`./build.sh` re-run over all eight archives:

```
>>> 01_first_level.kyx:        PROVED   (3 entries)
>>> 02_hull_invariance.kyx:    PROVED   (4 entries)
>>> 03_second_level.kyx:       PROVED   (3 entries)
>>> 04_eq458_discrepancy.kyx:  PROVED   (5 entries)
>>> 05_eq458_dI_fails.kyx:     did not close, as expected (exit 255)   (2 entries)
>>> 06_slaff.kyx:              PROVED   (4 entries)
>>> 07_instance.kyx:           PROVED   (7 entries)
>>> 08_design_rule.kyx:        PROVED   (7 entries)
EXIT=0
```

33 `PROVED`, 2 `UNFINISHED` — matching `keymaerax/README.md` exactly. The two
unfinished entries are the deliberate negative observation of
`05_eq458_dI_fails.kyx`: `dI`/`ODE` failing to close a goal is *not* a
refutation, and the weight of the (4.58) finding rests on the quantifier-
elimination results in `04_eq458_discrepancy.kyx`, all of which closed in well
under a second.

## Two small caveats found during the review

Neither is an error; both are noted here so that readers do not have to
rediscover them.

1. **`qres_zero`, `VrF_nonpos`, `Vr_nonincreasing` / `Vr_antitone` assume
   `e_α ≡ 0` on all of `ℝ`**, whereas `hull_invariance` / `ea_zero` establish
   `e_α = 0` only for `t ≥ 0`. The gap is in the plumbing, not the mathematics:
   the mean-value lemmas are stated with a global sign hypothesis on the
   derivative rather than one restricted to `[0, t]`. The hypothesis is
   satisfiable — the concrete instance proves `e_α t = 0` for *every* `t` — so
   the instantiated corollaries are unconditional. The same shape appears in
   all three proof-assistant ports.

2. **`VrF` / `Vr` are the reduced Lyapunov functions**, `½ α̃ᵀα̃`, not the
   `ᾱ̃ᵀᾱ̃/2γ` of (4.57)/(4.68) — the dissertation's own candidate is `Vb`. The
   source comments say so; a couple of rows in the equation → theorem tables
   label `VrF` simply as "(4.68)", which reads as if it were the literal
   candidate.
