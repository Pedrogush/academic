# Coq formalisation of Chapter 4 (eqs. 4.1–4.69) of DISSERT.pdf

Pedro Yochinori Gushiken, *"Adaptação de Segundo Nível como Técnica de Estimação de
Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de Referência"*,
MSc dissertation, UFRN, 2018 — Chapter 4, *Estimação de Parâmetros, Ordem n*
(document pages 55–78 = PDF pages 81–104).

Verified with **Coq 8.18.0**. `make` compiles all four files with no errors and
no `admit`/`Admitted`.

## Files

| File | Contents |
|---|---|
| `SLA_Prelim.v` | Finite sums, inner products, derivative plumbing over `Reals` |
| `SLA_Chapter4.v` | Equations 4.1–4.69 |
| `SLA_AppendixA.v` | Appendix A Theorems 1 and 2 (convex combinations), justifying `N = 2n+1` |
| `SLA_Instance.v` | A concrete model of *every* hypothesis — proves the development is not vacuous |

## Building

Coq 8.18 is already unpacked at `~/.local/coqroot` (rootless — no sudo used):

```bash
source ./coqenv.sh
make
```

If that directory is gone, re-create it with `./setup-coq.sh`, or install
system-wide with `sudo apt install coq` and just run `make`.

## Modelling choices

* Vectors of `R^n` are functions `nat -> R`; `Sum n f = f 0 + … + f (n-1)`.
* Derivatives are Coq's `derivable_pt_lim`, so every "derivando ao longo das
  trajetórias" step is a genuine analytic statement, not an axiom.
  `Deriv f f' := forall t, derivable_pt_lim f t (f' t)`.
* Equations 4.1–4.7 and 4.9 only *fix notation* for the filters that generate the
  regressor `φ`. Their entire mathematical content downstream is that `φ` is
  differentiable and that `z = θ*ᵖᵀ φ` — which is hypothesis `H_param` (4.8).
* `d = 2n = dim θ*ᵖ`; models are indexed `0 … N-1`, so the "last" model `N` of the
  text is index `M` with `N = S M`.
* The only axioms used are those Coq's own `Reals` library is built on
  (`Classical_Prop.classic`, `functional_extensionality_dep`,
  `ClassicalDedekindReals.*`). The development adds none of its own — checked with
  `Print Assumptions`.

## Equation → theorem map

| Eq. | Statement | Coq name |
|---|---|---|
| 4.1–4.7, 4.9 | plant, filters, `Λ(s)`, `z` | notation only (see above) |
| 4.8 | `z = θ*ᵖᵀ φ` | `H_param` (hypothesis) |
| 4.10, 4.24 | `ẑ_{i,f} = θ̂_{i,f}ᵀ φ` | `zh` |
| 4.11, 4.25 | `e_{i,f} = ẑ_{i,f} − z` | `e` |
| 4.12 | `m² = 1 + φᵀφ` | `msq`, `msq_pos` |
| 4.13, 4.27 | `ε_{i,f} = e_{i,f}/m²` | `eps` |
| 4.14, 4.26 | `θ̃_{i,f} = θ̂_{i,f} − θ*ᵖ` | `tht` |
| **4.15, 4.28** | `ε_{i,f} = θ̃ᵀ φ / m²` | `e_eq_dot_tht`, `eps_eq_dot_tht` |
| 4.16–4.18 | cost `J`, gradient `∇J = ε φ` | folded into 4.19 |
| 4.19, 4.29 | `θ̂̇_{i,f} = −Γ ε_{i,f} φ` | `H_law` (hypothesis) |
| **4.20, 4.21** | `θ̃̇_{i,f} = θ̂̇_{i,f}` | `tht_law` |
| 4.22 | `V = θ̃ᵀ Γ⁻¹ θ̃ / 2` | `V1` |
| **4.23** | `V̇ = −ε² m² ≤ 0` | `V1_dyn`, `V1_nonincreasing` |
| **4.30** | `ė_{i,f} = −ε_{i,f} φᵀΓφ + θ̃ᵀ φ̇` | `e_dyn` (via `gen_e_dyn`) |
| 4.31 | `θ̂_{v,f} = Σ θ̂_{i,f} β_i`, `Σβ = 1` | `thv`, `H_beta_sum` |
| 4.32, 4.33, 4.34 | virtual model, its error | `zhv`, `ev`, `thtv` |
| **4.35** | `θ̃_{v,f} = Σ θ̃_{i,f} β_i` | `thtv_convex` |
| **4.36, 4.40** | `θ̂̇_{v,f} = −Γ ε_{v,f} φ` | `thv_law`, `epsv_convex` |
| **4.37 = 4.39** | the two error dynamics coincide | `ev_convex`, `ev_dyn` |
| 4.41 | `θ*ᵖ = Σ θ̂_{i,f} α*_i` | `H_astar_init` (at `t = 0`) |
| 4.42, 4.43 | `Σ_{α,f}`, `e_{α,f}` | `ea` |
| **4.44** | `ė_{α,f} = −(e_{α,f}/m²) φᵀΓφ` | `ea_dyn`, `ea_dyn_general` |
| **4.45** | `Σ e_{i,f} α*_i → 0` | `ea_zero` (in fact `= 0` for `t ≥ 0`) |
| — | 4.41 propagates to all `t ≥ 0` | **`hull_invariance`**, `theta_star_in_hull` |
| 4.46, 4.47 | `Ē_f ᾱ*_f = Σ ε_i α*_i = 0` | `sum_eps_astar` |
| 4.48 | `α*_N = 1 − Σ_{i<N} α*_i` | inside `E_alpha_star` |
| **4.49, 4.51** | `E_f α*_f = −ε_{N,f}` | **`E_alpha_star`**, `E_alpha_star_exact` |
| 4.50 | `E_f = [ε_1−ε_N … ε_{N-1}−ε_N]` | `Ev` |
| 4.52 | `α̇_f = −γ EᵀE α_f − γ Eᵀ ε_N` | `H_sla` (hypothesis) |
| 4.53, 4.54, 4.55 | `ᾱ_f`, `α̃_f`, `α̃̇_f = α̇_f` | `alpt`, `Sb` |
| **4.56** | `α̃̇_f = −γ EᵀE α̃_f − γ Eᵀ e_{α,f}/m²` | `alpt_dyn` |
| 4.57 | `V = ᾱ̃ᵀᾱ̃ / 2γ` | `Vb` (dissertation's), `Vr` (reduced) |
| **4.58** | `V̇` | `Vb_dyn` (exact), `Vr_dyn` (reduced) — **see discrepancy 1** |
| 4.60, 4.61, 4.62, 4.63 | integral form of the SLAFF equation | folded into 4.65/4.66 |
| **4.64, 4.65 ↔ 4.66** | `M_f`, `v_f` convolution ↔ ODE | `Mf_integrating_factor`, `vf_integrating_factor` |
| 4.66 | `Ṁ_f = −σM_f + EᵀE`, `v̇_f = −σv_f + Eᵀε_N` | `H_Mf`, `H_vf` (hypotheses) |
| 4.67 | SLAFF law | `H_slaff` (hypothesis) |
| 4.68 | `V = ᾱ̃ᵀᾱ̃ / 2γ` | `VrF` |
| **4.69** | `V̇` | `VrF_dyn` (exact), `VrF_nonpos` — **see discrepancy 2** |
| — | `M_f ⪰ 0` (asserted implicitly by 4.65) | **`Mf_psd`** |
| — | residual `M_f α*_f + v_f ≡ 0` when `e_α ≡ 0` | **`qres_zero`** |
| 4.59 | `θ̂_{n2,f} = proj(Σ α_i θ̂_i)` | projection operator, not formalised |
| A.1–A.10 | Appendix A Theorem 1 | `theorem1_representation`, `theorem1_convexity` |
| A.11 | Appendix A Theorem 2 | `theorem2_representation`, `theorem2_convexity` |
| p. 64 | `N ≥ 2n+1` suffices (existence) | `design_rule_suffices` |
| p. 64 | **amended:** `N = 2n+1` gives existence **and** uniqueness | `design_rule_exact` |
| A (uniqueness) | the Appendix A vertices have unique convex coefficients | `theorem1_uniqueness`, `theorem2_uniqueness` |
| — | `N > d+1` admits two distinct representations | `more_vertices_not_unique` |

## Two results that do not hold as stated

Both were *proved* rather than assumed; they follow from the exact derivative
identities `Vb_dyn` and `VrF_dyn`.

**1. The factor `N` in (4.58) — and in (4.69) — does not follow.**

The dissertation uses the extended vector `ᾱ̃_f = [α̃_f ; −1⃗α̃_f]` in `V` (4.57) and
concludes

    V̇ = −N α̃ᵀEᵀE α̃ − N α̃ᵀEᵀ e_α/m² .

The exact derivative of that `V`, given the adaptive law (4.52), is

    V̇ = −(E α̃ + (1⃗α̃)(1⃗Eᵀ)) · (E α̃ + e_α/m²)        [`Vb_dyn`]

The cross term `(1⃗α̃)(1⃗Eᵀ)` is not `(N−1)·E α̃`, so the two disagree —
`Vb_deriv_differs_from_4_58` exhibits `N = 3`, `E α̃ = 1`, `1⃗α̃ = 1⃗Eᵀ = 1`,
`e_α = 0`, where the true value is `−2` and (4.58) gives `−3`.

Worse, the dissertation's `V̇` is **not negative semi-definite**:
`Vb_deriv_can_be_positive` gives `E α̃ = 1`, `1⃗α̃ = −2`, `1⃗Eᵀ = 1`, `e_α = 0`,
for which `V̇ = +1 > 0`. So (4.57)+(4.58) do not establish the boundedness of `α̃_f`
claimed on page 66.

The fix is the reduced Lyapunov function `V = α̃ᵀα̃/2` (`Vr`), for which

    V̇ = −γ (E α̃)² − γ (E α̃)(e_α/m²)   ≤ 0  when  e_α = 0     [`Vr_dyn`]

This is exactly eq. (24) of Narendra–Wang–Chen, *The Rationale for Second Level
Adaptation* (arXiv:1510.04989), which the dissertation follows. The stated
qualitative conclusion of Section 4.3 is therefore correct; only the route through
`ᾱ̃` is not. Note that the `N`-dependence of the convergence rate, which the
dissertation reads off from (4.58), is not supported by the corrected identity.

**2. Equation (4.69) omits `v_f` from its residual term.**

(4.69) writes the sign-indefinite term as `−N α̃ᵀ M_f α*_f`. The correct residual is
`M_f α*_f + v_f`, since `Eᵀ(E α*_f + ε_{N,f}) = Eᵀ e_α/m²` mixes both — see
`VrF_dyn`. The text's own justification one line later
(`N α̃ᵀ M_f α*_f = N ∫ e^{−σ(t−τ)} Eᵀ e_α dτ`) is the value of `M_f α*_f + v_f`, not
of `M_f α*_f`, so the intent is right and only the written expression is incomplete.

`qres_zero` shows the residual vanishes identically once `θ*ᵖ` is in the convex hull,
and `Mf_psd` supplies the missing proof that the quadratic term is sign definite;
together they give `VrF_nonpos`, the statement (4.69) is aiming at.

## Two places where the dissertation is more conservative than necessary

* Between (4.37) and (4.40) the text argues that `Σ β_i e_{i,f}` only converges
  *exponentially* to `e_{v,f}`, and that they coincide if `e_{v,f}(0) = Σ β_i e_{i,f}(0)`.
  With linear-regression models they are **identically equal by construction**, with
  no condition on initial values (`ev_convex`).
* (4.45) states `lim_{t→∞} Σ e_{i,f} α*_i = 0`. Under the stated hypotheses it is
  exactly `0` for every `t ≥ 0` (`ea_zero`), because `θ*ᵖ` never leaves the convex hull
  (`hull_invariance`). The dissertation's discussion of a non-zero `e_{α,f}(0)` applies
  to the practical case where the filter states are not initialised consistently — a
  situation outside the model (4.8).

## Non-vacuity

`SLA_Instance.v` builds `d = 1`, `N = 2`, `φ(t) = 1`, `Γ = 2`, giving
`θ̂_i(t) = 1 + (v_i − 1)e^{−t}` with `v = (0, 2)` and `α* = (1/2, 1/2)`, plus
closed-form `M_f(t) = c_{ij}(e^{−t} − e^{−2t})`, `v_f(t) = c_i(e^{−t} − e^{−2t})`,
`α_f ≡ α*`. It proves every hypothesis of `SLA_Chapter4` (`H_param_ok`,
`H_law_ok`, `H_Mf_ok`, `H_slaff_ok`, …), instantiates `hull_invariance` on them,
and cross-checks the result against a direct computation (`inst_hull_direct`).
`inst_models_are_distinct` and `inst_E_nonzero` confirm the instance is not
degenerate, and `inst_astar_unique` proves `α*` is the *only* convex
representation of `θ*_p`.

**Changed from `N = 3` to `N = 2`.** The earlier instance satisfied the rule as
written in the dissertation (`N ≥ 2n+1`) but violated the amended rule
`N = 2n+1 = d+1`, and it was degenerate: three points on a line admit a
one-parameter family `α* = (s, s, 1−2s)`, and correspondingly `E_f(t)` was rank 1
in `R²` at every `t`, so the second-level regression was under-determined. See
`../NOTE_convex_uniqueness.md`.

## What is deliberately not formalised

* Asymptotic arguments: Barbalat's lemma and its corollaries (Appendix C.4), the
  `L²` membership of `ε m`, persistency of excitation and the resulting parameter
  convergence. The dissertation itself cites Ioannou & Sun (1996) for these.
* The projection operator `proj_{S_θ,f}` of (4.59).
* The state-space/transfer-function correspondence of (4.1)–(4.7), i.e. that the
  filters `Λ_c, l` actually realise `s^i/Λ(s)`.
* The *necessity* half of `N ≥ 2n+1` (an affine-dimension argument, asserted on
  page 64).
* Persistency of excitation of the *second-level* regressor `E_f`. Uniqueness of
  `α*` (now proved) is necessary for `α_f → α*_f` but not sufficient; the
  convergence claim additionally needs PE of `E_f`, which is not formalised and
  which the instance does not exhibit (there `E_f(t) = −e^{−t}`, whose square
  integrates to a finite value).

## Sources consulted

* Z. Han & K. S. Narendra, "New concepts in adaptive control using multiple models",
  *IEEE TAC* 57(1):78–89, 2012.
* K. S. Narendra, Y. Wang, W. Chen, "The Rationale for Second Level Adaptation",
  arXiv:1510.04989 (the freely available version of Narendra et al. 2012/2015) —
  used to check the SLA framework, the convex-hull invariance claim, and the
  Lyapunov step `V̇ = −‖E α̃‖²`.
* P. Ioannou & J. Sun, *Robust Adaptive Control*, 1996 — normalized gradient
  estimator behind 4.12–4.23.
* G. Chowdhary, T. Yucelen, M. Mühlegg, E. N. Johnson, "Concurrent learning adaptive
  control of linear systems with exponentially convergent bounds", *IJACSP*
  27(4):280–301, 2013 — the recorded-data idea behind 4.60–4.69.
