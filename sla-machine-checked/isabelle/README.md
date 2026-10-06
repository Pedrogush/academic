# Isabelle/HOL formalisation of Chapter 4 (eqs. 4.1–4.69) of the dissertation ([`dissertation/final/gushiken-2018-dissertacao-formalization-reference.pdf`](../../dissertation/final/gushiken-2018-dissertacao-formalization-reference.pdf))

Pedro Yochinori Gushiken, *"Adaptação de Segundo Nível como Técnica de Estimação de
Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de Referência"*,
MSc dissertation, UFRN, 2018 — Chapter 4, *Estimação de Parâmetros, Ordem n*
(document pages 55–78 = PDF pages 81–104), plus Appendix A.

Ported from the Coq development in `../coq`. Everything below **builds cleanly**;
there is no `sorry` and no `oops` anywhere in the sources.

## Isabelle version and how it was installed

**Isabelle2025-2** (`polyml-5.9.2`, `x86_64_32-linux`), installed rootlessly — no
`sudo` was used at any point:

```bash
mkdir -p $HOME/isabelle-install && cd $HOME/isabelle-install
# NB: https://isabelle.in.tum.de/dist/... 301-redirects to a PLAIN-HTTP mirror.
# Fetch the mirror over HTTPS directly instead.
curl -o Isabelle2025-2_linux.tar.gz \
  "https://dist.isabelle.cit.tum.de/dist/Isabelle2025-2_linux.tar.gz?token=Isabelle"
tar xzf Isabelle2025-2_linux.tar.gz -C $HOME       # -> $HOME/Isabelle2025-2
```

The tarball bundles its own JDK and Poly/ML, so no system Java is needed, **and it
ships a prebuilt `HOL` heap image** (`$HOME/Isabelle2025-2/heaps/polyml-.../HOL`,
209 MB). The session below has `HOL` as its parent, so **nothing beyond the five
SLA theories ever has to be compiled** — a full clean build is about 30 seconds.
No `HOL-Analysis` heap is built (see "Why not HOL-Analysis" below).

## Building

```bash
./build.sh          # = isabelle build -d . -o threads=2 -o document=false -v SLA
```

`build.sh` deliberately caps parallelism (`-o threads=2`, `nice -n 15`, hard
`timeout`) because the machine this was produced on has 4 cores / 7 GB RAM.

Real output of a forced clean rebuild (`isabelle build -c`), copied from
`verification-log.txt`:

```
===== Tue Aug 11 17:52:01 UTC 2026 : FINAL CLEAN BUILD (isabelle build -c, all 5 theories) =====
Started at Tue Aug 11 14:52:05 GMT-3 2026 (polyml-5.9.2_x86_64_32-linux on DESKTOP-0BDDLV6)
Session Pure/Pure
Session Misc/Tools
Session HOL/HOL (main)
Session Unsorted/SLA
Cleaned SLA
Running SLA ...
SLA: theory SLA.SLA_Prelim
SLA: theory SLA.SLA_AppendixA
SLA: theory SLA.SLA_Chapter4
SLA: theory SLA.SLA_Prelim 100% (1.409s cumulated time)
SLA: theory SLA.SLA_Instance
SLA: theory SLA.SLA_Check
SLA: theory SLA.SLA_AppendixA 100% (2.303s cumulated time)
SLA: theory SLA.SLA_Chapter4 100% (6.568s cumulated time)
SLA: theory SLA.SLA_Instance 100% (1.891s cumulated time)
SLA: theory SLA.SLA_Check 100% (0.634s cumulated time)
Timing SLA (2 threads, 8.474s elapsed time, 10.867s cpu time, 0.426s GC time, factor 1.28)
Finished SLA (0:00:16 elapsed time, 0:00:12 cpu time, factor 0.77)
Finished at Tue Aug 11 14:52:32 GMT-3 2026
0:00:27 elapsed time, 0:00:12 cpu time, factor 0.46
```

`isabelle build -d . -o threads=2 SLA` exits with status 0. `grep -rn "sorry\|oops" *.thy`
returns no matches.

The full transcript of every build attempt, including the failures along the way,
is in `verification-log.txt`.

## Files

| File | Contents |
|---|---|
| `SLA_Prelim.thy` | `Deriv` (on top of the library's `has_real_derivative`), differentiation rules, MVT corollaries, `dot`, the generic quadratic Lyapunov form `Wq` and `quad_zero` |
| `SLA_Chapter4.thy` | Equations 4.1–4.69, as a chain of locales |
| `SLA_AppendixA.thy` | Appendix A Theorems 1 and 2, their **uniqueness** halves, and the design rule |
| `SLA_Instance.thy` | A concrete model of *every* assumption — proves the development is not vacuous |
| `SLA_Check.thy` | Audit theory: restates the headline results verbatim and proves each by a single `rule`. If any claim in the table below were wrong, this would not compile |
| `ROOT`, `build.sh` | Session and build script |
| `verification-log.txt` | Real terminal output of every build |

## Modelling choices (this is not a transliteration)

* **Derivatives are the library predicate.** `Deriv f f'` is an *abbreviation* for
  `∀t. (f has_real_derivative f' t) (at t)`, so every goal and every fact is
  literally a statement about `has_real_derivative` from `HOL.Deriv`. Every
  "derivando ao longo das trajetórias" step is a genuine analytic obligation.
* **Sums are the library's `sum` over `{..<n}`.** The Coq development carried its
  own `Sum` fixpoint plus a dozen lemmas (`Sum_plus`, `Sum_scal_l`, `Sum_swap`,
  `Sum_select`, …); all of those are library facts here (`sum.distrib`,
  `sum_distrib_left`, `sum.swap`, `sum.delta`, …) and simply disappear.
  `sum.lessThan_Suc` peels the **last** summand exactly like the Coq `Sum`, so the
  elimination of `α_N` in (4.48) is still a one-step rewrite.
* **Monotonicity is the library MVT** (`DERIV_nonpos_imp_nonincreasing`), not a
  bespoke argument.
* **Locales replace Coq's one long section of `Variable`s.** Each locale adds
  exactly the parameters and hypotheses of its block of the chapter, so every
  theorem is stated under the weakest hypotheses that support it, and
  `SLA_Instance` discharges the whole hypothesis set by `interpretation` instead
  of threading a dozen explicit arguments through every statement (compare the
  Coq `eps 1 PHI Z TH 2 t`). The chain is
  `plant < first_level_sig < first_level < {virtual_model, hull_models} < second_level < {sla_sig < sla, slaff_sig < slaff}`.
* **`D_ext` collapses.** Coq needed an eight-line hand unfolding of the ε/δ
  definition to rewrite under a derivative statement without assuming an axiom.
  Isabelle/HOL has functional extensionality, so this is the one-line
  `Deriv_cong` / `Deriv_cong_deriv`.

### Why not `HOL-Analysis`

`has_real_derivative` is defined in `HOL.Deriv`, part of the `HOL` session, and is
*the same predicate* `HOL-Analysis` builds on. Every signal in Chapter 4 is a
scalar function of time (vectors are handled componentwise, as in the source), so
`has_real_derivative` is exactly the right library notion and the Fréchet-style
`has_derivative` would add nothing. Importing `Complex_Main` rather than
`HOL-Analysis.Analysis` also means the prebuilt `HOL` heap suffices — relevant on
a 7 GB machine, where building a `HOL-Analysis` heap is the one job likely to
wedge it.

## Amendment to the design rule: `N = 2n + 1`, not `N ≥ 2n + 1`

**Read `../NOTE_convex_uniqueness.md`.** The dissertation writes `N ≥ 2n+1`. That
inequality is correct for the *existence* of `θ*ₚ = Σ αᵢ* θ̂ᵢ(0)`, which is what the
text's own justification argues for, but it is not sufficient for *uniqueness*:
with `N` unknowns against `d+1` equations the solution family has dimension
`N − (d+1)`, zero iff `N = d+1`. The second level identifies `α*_f`, so `α*_f` must
be a point. This port therefore assumes `H_N_exact : N = Suc d` (locale
`first_level`), and Appendix A proves both halves. Nothing is lost: Appendix A's
Theorem 2 always constructed exactly `d+1` affinely independent vertices.

## Equation → theorem map

Names are given relative to their locale (e.g. `first_level.V1_dyn`).

| Eq. | Statement | Isabelle name |
|---|---|---|
| 4.1–4.7, 4.9 | plant, filters, `Λ(s)`, `z` | notation only; content is `H_phi` + `H_param` |
| 4.8 | `z = θ*ᵀφ` | `plant.H_param` (assumption) |
| 4.10, 4.24 | `ẑᵢ = θ̂ᵢᵀφ` | `first_level_sig.zh` |
| 4.11, 4.25 | `eᵢ = ẑᵢ − z` | `first_level_sig.e` |
| 4.12 | `m² = 1 + φᵀφ` | `plant.msq`, `plant.msq_pos` |
| 4.13, 4.27 | `εᵢ = eᵢ/m²` | `first_level_sig.eps` |
| 4.14, 4.26 | `θ̃ᵢ = θ̂ᵢ − θ*` | `first_level_sig.tht` |
| **4.15, 4.28** | `eᵢ = θ̃ᵢᵀφ`, `εᵢ = θ̃ᵢᵀφ/m²` | `e_eq_dot_tht`, `eps_eq_dot_tht` |
| 4.16–4.18 | cost `J`, `∇J = εφ` | folded into 4.19 |
| 4.19, 4.29 | `θ̂̇ᵢ = −Γεᵢφ` | `first_level.H_law` (assumption) |
| **4.20, 4.21** | `θ̃̇ᵢ = θ̂̇ᵢ` | `first_level.tht_law` |
| 4.22 | `V = θ̃ᵀΓ⁻¹θ̃/2` | `first_level.V1` (via generic `Wq`) |
| **4.23** | `V̇ = −ε²m² ≤ 0` | `V1_dyn`, `V1_nonincreasing` |
| **4.30** | `ėᵢ = −εᵢφᵀΓφ + θ̃ᵀφ̇` | `e_dyn` (via `gen_e_dyn`) |
| 4.31 | `θ̂ᵥ = Σθ̂ᵢβᵢ`, `Σβ = 1` | `virtual_model.thv`, `H_beta_sum` |
| 4.32–4.34 | virtual model and its error | `zhv`, `ev`, `thtv` |
| **4.35** | `θ̃ᵥ = Σθ̃ᵢβᵢ` | `thtv_convex` |
| **4.36, 4.40** | `θ̂̇ᵥ = −Γεᵥφ` | `thv_law`, `epsv_convex` |
| **4.37 = 4.39** | the two error dynamics coincide | `ev_convex`, `ev_dyn` |
| 4.41 | `θ* = Σθ̂ᵢα*ᵢ` at `t = 0` | `hull_models.H_astar_init` (assumption) |
| 4.42, 4.43 | `Σ_α`, `e_α` | `hull_models.ea` |
| **4.44** | `ė_α = −(e_α/m²)φᵀΓφ` | `ea_dyn`, `ea_dyn_general` |
| **4.45** | `Σeᵢα*ᵢ → 0` | `ea_zero` (in fact `= 0` for all `t ≥ 0`) |
| — | 4.41 propagates to all `t ≥ 0` | **`hull_invariance`**, `theta_star_in_hull` |
| 4.46, 4.47 | `Ēᾱ* = Σεᵢα*ᵢ = 0` | `second_level.sum_eps_astar` |
| 4.48 | `α*_N = 1 − Σ_{i<N} α*ᵢ` | inside `E_alpha_star` (`sum.lessThan_Suc`) |
| **4.49, 4.51** | `E α* = −ε_N` | **`E_alpha_star`**, `E_alpha_star_exact` |
| 4.50 | `E = [ε₁−ε_N … ε_{N−1}−ε_N]` | `second_level.Ev` |
| 4.52 | `α̇ = −γEᵀEα − γEᵀε_N` | `sla.H_sla` (assumption) |
| 4.53–4.55 | `ᾱ`, `α̃`, `α̃̇ = α̇` | `sla_sig.alpt`, `sla.Sb` |
| **4.56** | `α̃̇ = −γEᵀEα̃ − γEᵀe_α/m²` | `sla.alpt_dyn` |
| 4.57 | `V = ᾱ̃ᵀᾱ̃/2γ` | `sla.Vb` (dissertation's), `sla.Vr` (reduced) |
| **4.58** | `V̇` | `Vb_dyn` (exact), `Vr_dyn` (reduced) — **see discrepancy 1** |
| 4.60–4.63 | integral form of the SLAFF equation | folded into 4.65/4.66 |
| **4.64, 4.65 ↔ 4.66** | `M_f`, `v_f` convolution ↔ ODE | `Mf_integrating_factor`, `vf_integrating_factor` |
| 4.66 | `Ṁ_f = −σM_f + EᵀE`, `v̇_f = −σv_f + Eᵀε_N` | `slaff.H_Mf`, `slaff.H_vf` (assumptions) |
| 4.67 | SLAFF law | `slaff.H_slaff` (assumption) |
| 4.68 | `V = ᾱ̃ᵀᾱ̃/2γ` | `slaff.VrF` |
| **4.69** | `V̇` | `VrF_dyn` (exact), `VrF_nonpos` — **see discrepancy 2** |
| — | `M_f ⪰ 0` (asserted implicitly by 4.65) | **`Mf_psd`** (via `MQ_dyn`) |
| — | residual `M_f α* + v_f ≡ 0` when `e_α ≡ 0` | **`qres_zero`** |
| 4.59 | `θ̂_{n2} = proj(Σαᵢθ̂ᵢ)` | projection operator, **not formalised** |
| A.1–A.10 | Appendix A Theorem 1 | `theorem1_representation`, `theorem1_convexity` |
| A.11 | Appendix A Theorem 2 | `theorem2_representation`, `theorem2_convexity` |
| — | uniqueness of the coefficients | **`theorem1_uniqueness`, `theorem2_uniqueness`** |
| — | `N > d+1` destroys uniqueness | **`more_vertices_not_unique`** |
| p. 64 | `N = 2n+1` suffices (existence) | `design_rule_suffices` |
| p. 64 (amended) | `N = 2n+1` gives existence **and** uniqueness | **`design_rule_exact`** |
| — | `N = d+1` as a chapter assumption | `first_level.H_N_exact`, `second_level.M_eq_d` |

## Two results that do not hold as stated

Both are **proved**, not assumed; they follow from the exact derivative identities
`Vb_dyn` and `VrF_dyn`.

### 1. The factor `N` in (4.58) — and in (4.69) — does not follow

The dissertation uses the extended vector `ᾱ̃ = [α̃ ; −1⃗α̃]` in `V` (4.57) and
concludes `V̇ = −N α̃ᵀEᵀEα̃ − N α̃ᵀEᵀe_α/m²`. The exact derivative of that `V`,
given the adaptive law (4.52), is

```
V̇ = −(E α̃ + (1⃗α̃)(1⃗Eᵀ)) · (E α̃ + e_α/m²)        [sla.Vb_dyn]
```

The cross term `(1⃗α̃)(1⃗Eᵀ)` is not `(N−1)·Eα̃`, so the two disagree, and the
dissertation's `V̇` is **not negative semi-definite**:

* `Vb_deriv_differs_from_4_58` — `M = 2`, `Eα̃ = 1`, `1⃗α̃ = 1⃗Eᵀ = 1`, `e_α = 0`:
  true value `−2`, (4.58) gives `−3`.
* `Vb_deriv_can_be_positive` — `Eα̃ = 1`, `1⃗α̃ = −2`, `1⃗Eᵀ = 1`, `e_α = 0`:
  `V̇ = +1 > 0`.
* `Vb_deriv_positive_witness` — the same in terms of the underlying **vectors**:
  `M = 2`, `E_f = (2, −1)`, `α̃_f = (−1/3, −5/3)` gives `Eα̃ = 1`, `1⃗α̃ = −2`,
  `1⃗E = 1`, hence exact `+1` where (4.58) predicts `−3`. (The Coq, Lean and
  KeYmaera X ports use this same witness.)

So (4.57)+(4.58) do not establish the boundedness of `α̃_f` claimed on page 66, and
the `N`-dependence of the convergence rate read off from (4.58) is not supported.
The fix is the reduced `V = α̃ᵀα̃/2` (`sla.Vr`), for which `Vr_dyn` gives
`V̇ = −γ(Eα̃)² − γ(Eα̃)(e_α/m²) ≤ 0` when `e_α = 0` (`Vr_nonincreasing`) — exactly
eq. (24) of Narendra–Wang–Chen, which the dissertation follows. The stated
qualitative conclusion of Section 4.3 is therefore correct; only the route through
`ᾱ̃` is not.

### 2. (4.69) omits `v_f` from its residual term

(4.69) writes the sign-indefinite term as `−N α̃ᵀ M_f α*_f`. The correct residual is
`M_f α*_f + v_f` (`slaff.qres`), since `Eᵀ(Eα*_f + ε_N) = Eᵀe_α/m²` mixes both — see
`VrF_dyn`. The text's own justification one line later
(`N α̃ᵀ M_f α*_f = N ∫ e^{−σ(t−τ)} Eᵀe_α dτ`) is the value of `M_f α*_f + v_f`, not
of `M_f α*_f`, so the intent is right and only the written expression is
incomplete. `qres_zero` shows the residual vanishes identically once `θ*` is in the
convex hull, and `Mf_psd` supplies the missing proof that the quadratic term is
sign definite; together they give `VrF_nonpos`, the statement (4.69) is aiming at.

The instance (below) has `v_f ≢ 0` (`inst_vf_nonzero`), so this term is genuinely
exercised rather than vacuously zero.

## Two places where the dissertation is more conservative than necessary

* Between (4.37) and (4.40) the text argues that `Σβᵢeᵢ` only converges
  *exponentially* to `e_v`, and that they coincide if `e_v(0) = Σβᵢeᵢ(0)`. With
  linear-regression models they are **identically equal by construction**, with no
  condition on initial values (`ev_convex`).
* (4.45) states `lim_{t→∞} Σeᵢα*ᵢ = 0`. Under the stated hypotheses it is exactly
  `0` for every `t ≥ 0` (`ea_zero`), because `θ*` never leaves the convex hull
  (`hull_invariance`). The dissertation's discussion of a non-zero `e_α(0)` applies
  to the practical case where the filter states are not initialised consistently —
  a situation outside the model (4.8).

## Non-vacuity

`SLA_Instance.thy` builds `d = 1`, `N = 2` (`M = 1`), `φ(t) = 1`, `Γ = 2`, giving
`θ̂ᵢ(t) = 1 + (vᵢ−1)e^{−t}` with `v = (0, 2)` and `α* = (1/2, 1/2)`, plus closed-form
`M_f(t)ᵢⱼ = (vᵢ−2)(vⱼ−2)/4·(e^{−t}−e^{−2t})` and `v_f(t)ᵢ = (vᵢ−2)/4·(e^{−t}−e^{−2t})`
with `σ = 1`, and `α_f ≡ α*`. It discharges **every** assumption of the locale chain
by nine `interpretation`s (`first_level_sig`, `first_level`, `virtual_model`,
`hull_models`, `second_level`, `sla_sig`, `sla`, `slaff_sig`, `slaff`), then
instantiates the main theorem (`inst_hull_invariance`,
`inst_theta_star_in_hull`, `inst_ea_zero`) and cross-checks it against a direct
computation (`inst_hull_direct`, which moreover holds for *every* real `t`, not
just `t ≥ 0`).

It obeys the amended rule `N = d+1 = 2` exactly, and `inst_astar_unique` proves the
representation `α* = (1/2,1/2)` is the **only** one — not even merely the only
convex one: no nonnegativity of the competing `a` is assumed. (The pre-amendment
`N = 3` instance admitted a one-parameter family of `α*`, and its second-level
regressor was correspondingly rank deficient.)

Non-degeneracy: `inst_models_are_distinct`, `inst_e_nonzero`, `inst_E_nonzero`,
`inst_vf_nonzero`.

## What could NOT be ported, and why

Honest list. Nothing below is hidden in the sources; nothing is `sorry`-ed.

1. **Asymptotic arguments** — Barbalat's lemma and its corollaries (Appendix C.4),
   the `L²` membership of `εm`, persistency of excitation and the resulting
   parameter convergence. *Deliberately out of scope*: the dissertation itself
   cites Ioannou & Sun (1996) for these, and the Coq original excludes them too.
2. **The projection operator `proj_{S_θ,f}` of (4.59).** Not formalised. It is a
   modelling device for parameter-bound enforcement and carries no identity that
   Chapter 4 uses.
3. **The state-space/transfer-function correspondence of (4.1)–(4.7)** — that the
   filters `Λ_c, l` actually realise `sⁱ/Λ(s)`. Not formalised; (4.1)–(4.7) and
   (4.9) enter only through `H_phi` and `H_param`, as in the Coq version.
4. **The *necessity* half of `N ≥ 2n+1`** (that fewer than `d+1` points cannot
   cover a full-dimensional box). This is an affine-dimension argument asserted on
   page 64. The *sufficiency* half and the whole *uniqueness* side are formalised
   (`design_rule_suffices`, `design_rule_exact`, `theorem{1,2}_uniqueness`), and
   `more_vertices_not_unique` proves the converse direction of the amendment, but
   the necessity statement itself is not proved.
5. **The hexagon counterexample of `../NOTE_convex_uniqueness.md` §4** is present
   only in its 1-dimensional shadow (`more_vertices_not_unique`: three points
   `(0,2,1)` on a line, target `1`, two distinct convex representations). This is
   the smallest instance of the same failure; the 6-vertex `R²` computation is not
   reproduced. Same choice as the Coq development.
6. **`H_N_exact` is recorded but unused inside Chapter 4.** Like the Coq
   `H_N_min` before it, no identity of the chapter consumes it — what they consume
   is the *existence* of `α*` (`H_astar_init`). Its role is to make `α*` unique,
   which is proved in `SLA_AppendixA`, not in `SLA_Chapter4`. `second_level.M_eq_d`
   records the consequence `M = d`.

## Things Isabelle surfaced that the Coq version glossed over

* **`sum.delta`, `sum.swap`, `sum_nonneg_eq_0_iff`, `DERIV_nonpos_imp_nonincreasing`
  are all library facts.** About 200 lines of the Coq preliminaries (the whole
  `Sum` API and the MVT plumbing) have no counterpart here.
* **`Deriv_cong` needs no axiom.** The Coq `D_ext` had to unfold ε/δ by hand
  specifically to avoid assuming functional extensionality; in HOL it is free.
* **The dissertation's `V̇` sign defect is visible in vector terms.**
  `Vb_deriv_positive_witness` exhibits actual vectors `E_f = (2,−1)`,
  `α̃_f = (−1/3,−5/3)` rather than three abstract scalars, so the counterexample is
  demonstrably realisable and not an artefact of treating `Eα̃`, `1⃗α̃`, `1⃗E` as
  independent.
* **Locales made the non-vacuity proof structural.** In Coq the instance had to
  repeat every parameter at every use site (`eps 1 PHI Z TH 2 t`); here
  `interpretation` discharges the assumptions once and `Inst.eps` is available
  directly, which is why the amended `N = 2` instance was a small edit rather than
  a rewrite.
