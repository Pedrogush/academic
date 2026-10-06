# Lean 4 / Mathlib formalisation of Chapter 4 (eqs. 4.1–4.69) of the dissertation ([`dissertation/final/gushiken-2018-dissertacao-formalization-reference.pdf`](../../dissertation/final/gushiken-2018-dissertacao-formalization-reference.pdf))

Pedro Yochinori Gushiken, *"Adaptação de Segundo Nível como Técnica de Estimação de
Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de Referência"*,
MSc dissertation, UFRN, 2018 — Chapter 4, *Estimação de Parâmetros, Ordem n*
(document pages 55–78 = PDF pages 81–104), plus Appendix A.

This is a port of the Coq development in `../coq/`.  It is **not** a
transliteration: the encoding was redone in idiomatic Lean/Mathlib (see
*Modelling choices* below).  All results of the Coq development are present, and
in a few places the Lean version is slightly stronger (noted below).

> **Amendment (design rule).**  The dissertation's `N ≥ 2n + 1` has been tightened
> to **`N = 2n + 1 = d + 1` exactly**.  `≥` gives *existence* of a convex
> representation `θ*ᵖ = Σ αᵢ* θ̂ᵢ(0)` — which is all the text's own justification
> argues for — but the second level *identifies* `α*_f`, so `α*_f` must be a
> single point, and that needs uniqueness, which holds only at `N = d + 1`.
> Nothing is lost: Appendix A always constructed exactly `d + 1` affinely
> independent vertices.  Full argument, the hexagon counterexample and the
> affected dissertation pages: [`../NOTE_convex_uniqueness.md`](../NOTE_convex_uniqueness.md).
> In Lean this is `Model.hN_exact`, `AppendixA.design_rule_exact`,
> `AppendixA.more_vertices_not_unique` and `Instance.astar_unique`.
> **The two findings about (4.58) and (4.69) are unaffected and unchanged.**

## Versions

| item | value |
|---|---|
| Lean | `4.33.0` (`leanprover/lean4:v4.33.0`, commit `d8b18978322de05a8f3dba51ef03cf5461676c17`) |
| Lake | `5.0.0-src+d8b1897` |
| Mathlib | tag `v4.33.0`, revision `db584cd6d46c92f209a44c0f1c829460d327499d` |
| elan | `4.2.3` |

The toolchain is pinned by `lean-toolchain`; the Mathlib revision is pinned by
`lakefile.toml` (`version = "git#v4.33.0"`) and recorded exactly in
`lake-manifest.json`, so the build is reproducible.

## Where things live

* **Sources** are in this folder: `SLA.lean` and `SLA/*.lean`.
* **Build artefacts are NOT here.**  `lean/.lake` is a *symlink* to
  `$HOME/sla-lean-build/.lake`.  `/mnt/c` is a slow Windows mount and the
  Mathlib oleans are ~7 GB, so everything Lake writes (the Mathlib checkout, its
  oleans, and our own `.olean`s) lives on the Linux filesystem under `$HOME`.
  `.gitignore` excludes `.lake/` so the symlink target can never be committed.
* If the symlink is missing, recreate it before building:

  ```bash
  mkdir -p "$HOME/sla-lean-build/.lake"
  ln -sfn "$HOME/sla-lean-build/.lake" lean/.lake
  ```

## How the toolchain was installed (rootless, no sudo)

```bash
curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o elan-init.sh
sh elan-init.sh -y --default-toolchain none      # installs into ~/.elan
export PATH=$HOME/.elan/bin:$PATH
elan toolchain install stable                    # -> leanprover/lean4:v4.33.0
elan default leanprover/lean4:v4.33.0
```

Mathlib was fetched and its prebuilt oleans downloaded (never compiled from
source) with:

```bash
cd lean
lake update          # clones mathlib @ v4.33.0 into $HOME/sla-lean-build/.lake/packages
lake exe cache get   # downloads ~8300 prebuilt .olean files
```

## How to build

```bash
export PATH=$HOME/.elan/bin:$PATH
cd lean
lake build
```

On a small machine (this one has 4 cores / 7 GB RAM) build politely and one
module at a time:

```bash
export LEAN_NUM_THREADS=1
nice -n 15 lake build SLA.Prelim
nice -n 15 lake build SLA.AppendixA
nice -n 15 lake build SLA.Chapter4
nice -n 15 lake build SLA.Instance
```

The real output of the successful build, the `grep sorry` result and an axiom
audit are recorded verbatim in [`verification-log.txt`](verification-log.txt).
There is **no `sorry`, no `admit` and no added axiom** anywhere: every theorem
listed there depends only on Lean's three standard axioms `propext`,
`Classical.choice`, `Quot.sound`.

## Files

| file | contents |
|---|---|
| `SLA/Prelim.lean` | `Deriv` (= `HasDerivAt` everywhere) and its calculus, MVT corollaries, the generic quadratic Lyapunov form `Wq` and `quad_zero` |
| `SLA/Chapter4.lean` | equations 4.1–4.69: `Model`, `Hull`, `SecondLevel`, `Forgetting` and all their theorems |
| `SLA/AppendixA.lean` | Appendix A Theorems 1 and 2 (existence **and** uniqueness of the convex coefficients), the amended design rule `N = 2n+1`, and the non-uniqueness counterexample at `N = d+2` |
| `SLA/Instance.lean` | a concrete model of *every* hypothesis at `d = 1, N = 2` — proves the development is not vacuous, with `α*` provably unique |
| `SLA.lean` | library root, imports the four modules |
| `verification-log.txt` | real `lake build` output, `grep sorry`, `#print axioms` |

## Modelling choices

* Vectors of `ℝ^d` are `Fin d → ℝ`; inner products are Mathlib's `dotProduct`
  (`⬝ᵥ`), so all `Finset.sum` lemmas apply directly.  (The Coq version used
  `nat → R` with a hand-rolled `Sum`.)
* `Deriv f f' := ∀ t, HasDerivAt f (f' t) t`.  Every "derivando ao longo das
  trajetórias" step is a genuine analytic statement, not an axiom.  The
  monotonicity steps go through Mathlib's mean-value corollaries
  `antitone_of_deriv_nonpos` / `monotone_of_deriv_nonneg`.
* **The `N` models are indexed by `Fin (M+1)`**, so `N = M + 1` holds by
  construction and the "last" model `N` of the text is `Fin.last M`.  The
  second-level regressor `E_f` is then indexed by `Fin M`, and the split
  `∑_{i<N} = ∑_{i<M} + (last)` that the chapter performs by hand between (4.46)
  and (4.49) is exactly Mathlib's `Fin.sum_univ_castSucc`.  The Coq version
  needed a separate hypothesis `N = S M`.
* The hypothesis bundles are **structures**, not long lists of section
  variables: `Model d M` (plant + first-level models + gradient law),
  `Hull S` (4.41), `SecondLevel H` (4.52), `Forgetting H` (4.66/4.67).  This is
  what makes `SLA/Instance.lean` short: it just builds four terms.
* Equations 4.1–4.7 and 4.9 only *fix notation* for the filters that generate
  the regressor `φ`.  Their entire mathematical content downstream is that `φ`
  is differentiable and that `z = θ*ᵖᵀ φ` — the fields `Model.hφ` and
  `Model.hparam` (4.8).
* `d = 2n = dim θ*ᵖ`.  The **amended** design rule `N = 2n+1 = d+1` is the field
  `Model.hN_exact : M + 1 = d + 1` (i.e. `N = d + 1`, since `N = M + 1` holds by
  construction).  As in the Coq version, no *identity* needs it — see
  *Identities vs. identifiability* below.

## Equation → theorem map

All names below are in namespace `SLA`.  `S : Model d M`, `H : Hull S`,
`L : SecondLevel H`, `F : Forgetting H`.

| Eq. | Statement | Lean name |
|---|---|---|
| 4.1–4.7, 4.9 | plant, filters, `Λ(s)`, `z` | notation only (see above) |
| 4.8 | `z = θ*ᵖᵀ φ` | `Model.hparam` (structure field) |
| 4.10, 4.24 | `ẑ_{i,f} = θ̂_{i,f}ᵀ φ` | `Model.zh` |
| 4.11, 4.25 | `e_{i,f} = ẑ_{i,f} − z` | `Model.e` |
| 4.12 | `m² = 1 + φᵀφ` | `Model.msq`, `Model.msq_pos` |
| 4.13, 4.27 | `ε_{i,f} = e_{i,f}/m²` | `Model.eps` |
| 4.14, 4.26 | `θ̃_{i,f} = θ̂_{i,f} − θ*ᵖ` | `Model.tht` |
| **4.15, 4.28** | `e = θ̃ᵀφ`, `ε = θ̃ᵀφ/m²` | **`Model.e_eq_dot_tht`**, `Model.eps_eq_dot_tht` |
| 4.16–4.18 | cost `J`, `∇J = ε φ` | folded into 4.19 |
| 4.19, 4.29 | `θ̂̇_{i,f} = −Γ ε_{i,f} φ` | `Model.hlaw` (field), `Model.law` |
| **4.20, 4.21** | `θ̃̇_{i,f} = θ̂̇_{i,f}` | **`Model.tht_law`** |
| 4.22 | `V = θ̃ᵀ Γ⁻¹ θ̃ / 2` | `Model.V1` (= `Wq S.γ (S.tht i)`) |
| **4.23** | `V̇ = −ε² m² ≤ 0` | **`Model.V1_deriv`**, `Model.V1_antitone` |
| **4.30** | `ė_{i,f} = −ε_{i,f} φᵀΓφ + θ̃ᵀ φ̇` | **`Model.e_deriv`** (via `Model.gen_e_deriv`) |
| 4.31 | `θ̂_{v,f} = Σ θ̂_{i,f} β_i`, `Σβ = 1` | `Model.thv`, hypothesis `hβ` |
| 4.32, 4.33, 4.34 | virtual model, its error, its parametric error | `Model.zhv`, `Model.ev`, `Model.thtv` |
| **4.35** | `θ̃_{v,f} = Σ θ̃_{i,f} β_i` | **`Model.thtv_convex`** |
| **4.36, 4.40** | `θ̂̇_{v,f} = −Γ ε_{v,f} φ` | **`Model.thv_law`**, `Model.epsv_convex` |
| **4.37 = 4.39** | the two error dynamics coincide | **`Model.ev_convex`**, `Model.ev_deriv` |
| 4.41 | `θ*ᵖ = Σ θ̂_{i,f} α*_i` at `t = 0` | `Hull` (structure), field `Hull.init` |
| 4.42, 4.43 | `Σ_{α,f}`, `e_{α,f}` | `Hull.ea` |
| **4.44** | `ė_{α,f} = −(e_{α,f}/m²) φᵀΓφ` | **`Hull.ea_deriv`**, `Hull.ea_deriv_general` |
| **4.45** | `Σ e_{i,f} α*_i → 0` | **`Hull.ea_zero`** (in fact `= 0` for all `t ≥ 0`) |
| — | 4.41 propagates to all `t ≥ 0` | **`Hull.hull_invariance`**, `Hull.theta_star_in_hull` |
| 4.46, 4.47 | `Ē_f ᾱ*_f = Σ ε_i α*_i` | `Hull.sum_eps_alpha` |
| 4.48 | `α*_N = 1 − Σ_{i<N} α*_i` | inside `Hull.E_alpha_star` (via `Fin.sum_univ_castSucc`) |
| **4.49, 4.51** | `E_f α*_f = −ε_{N,f}` | **`Hull.E_alpha_star`**, `Hull.E_alpha_star_exact` |
| 4.50 | `E_f = [ε_1−ε_N … ε_{N-1}−ε_N]` | `Model.Ev` |
| 4.52 | `α̇_f = −γ EᵀE α_f − γ Eᵀ ε_N` | `SecondLevel` (structure), field `law` |
| 4.53, 4.54, 4.55 | `ᾱ_f`, `α̃_f`, `α̃̇_f = α̇_f` | `SecondLevel.alpt`, `SecondLevel.Sb` |
| **4.56** | `α̃̇_f = −γ EᵀE α̃_f − γ Eᵀ e_{α,f}/m²` | **`SecondLevel.alpt_deriv`** |
| 4.57 | `V = ᾱ̃ᵀᾱ̃ / 2γ` | `SecondLevel.Vb` (dissertation's), `SecondLevel.Vr` (reduced) |
| **4.58** | `V̇` | **`SecondLevel.Vb_deriv`** (exact), `SecondLevel.Vr_deriv` (reduced) — **see finding 1** |
| 4.60–4.63 | integral form of the SLAFF equation | folded into 4.65/4.66 |
| **4.64, 4.65 ↔ 4.66** | `M_f`, `v_f` convolution ↔ ODE | **`Forgetting.Mf_integrating_factor`**, `Forgetting.vf_integrating_factor` |
| 4.66 | `Ṁ_f = −σM_f + EᵀE`, `v̇_f = −σv_f + Eᵀε_N` | `Forgetting` fields `Mf_law`, `vf_law` |
| 4.67 | SLAFF law | `Forgetting` field `law`; `Forgetting.alpt_deriv` |
| 4.68 | `V = ᾱ̃ᵀᾱ̃ / 2γ` | `Forgetting.VrF` |
| **4.69** | `V̇` | **`Forgetting.VrF_deriv`** (exact), `Forgetting.VrF_nonpos` — **see finding 2** |
| — | `M_f ⪰ 0` (asserted implicitly by 4.65) | **`Forgetting.Mf_psd`** (via `Forgetting.MQ_deriv`) |
| — | residual `M_f α*_f + v_f ≡ 0` when `e_α ≡ 0` | **`Forgetting.qres_zero`** |
| 4.59 | `θ̂_{n2,f} = proj(Σ α_i θ̂_i)` | projection operator, **not formalised** |
| A.1–A.10 | Appendix A Theorem 1 | `AppendixA.theorem1_representation`, `AppendixA.theorem1_convexity`, **`AppendixA.theorem1_uniqueness`** |
| A.11 | Appendix A Theorem 2 | `AppendixA.theorem2_representation`, `AppendixA.theorem2_convexity`, **`AppendixA.theorem2_uniqueness`** |
| p. 64 (as written) | `N ≥ 2n+1` suffices (existence) | `AppendixA.design_rule_suffices` |
| p. 64, **amended** | `N = 2n+1`: existence **and** uniqueness | **`AppendixA.design_rule_exact`**, `Model.hN_exact` |
| — | `N = d+2` already destroys uniqueness | **`AppendixA.more_vertices_not_unique`** |

Non-vacuity (`SLA/Instance.lean`), now at `d = 1, N = 2, M = 1`:
`Instance.M0 : Model 1 1`, `Instance.H0 : Hull M0`,
`Instance.L0 : SecondLevel H0`, `Instance.F0 : Forgetting H0`, plus
**`Instance.astar_unique`**, `Instance.hull_invariance_inst`,
`Instance.E_alpha_star_inst`, `Instance.hull_direct`,
`Instance.models_are_distinct`, `Instance.E_nonzero`,
`Instance.eps_last_ne_zero`, `Instance.vf_ne_zero`, `Instance.qres_direct`,
`Instance.Vr_antitone_inst`, `Instance.qres_zero_inst`.

## Identities vs. identifiability — why the design rule had to be tightened

Every identity of Chapter 4 consumes only *"let `α*` be **some** vector with
`Σ α* = 1` and `θ*ᵖ = Σ θ̂ᵢ(0) α*ᵢ`"*.  That is why `Model.hN_exact` and the
range bounds `Hull.mem_Icc` (`0 ≤ α*ᵢ ≤ 1`) are, as identities go, decorative:
nothing in `hull_invariance`, `E_alpha_star`, `Vr_deriv`, `VrF_nonpos`, … refers
to them.  (`hull_invariance` is proved *from* `Σ α* = 1` and the initial
representation alone.)

What *does* need the geometry is **identifiability**.  The second level regresses
onto `α*_f`, so `α*_f` has to be a well-defined point.  Counting: `N` unknowns
against `d + 1` equations (`d` coordinates plus sum-to-one), so the solution
family has dimension `N − (d+1)`, zero iff `N = d + 1`.  Hence:

| | requires |
|---|---|
| hull has nonzero `d`-volume | `N ≥ d + 1` |
| coefficients are unique | `N ≤ d + 1` (with affine independence) |
| **both** | **`N = d + 1 = 2n + 1`** |

`AppendixA.more_vertices_not_unique` is the smallest failure (`d = 1`, three
points `(0,2,1)`, target `1`, two nonneg representations `(1/2,1/2,0)` and
`(0,0,1)`) — the 1-D shadow of the hexagon in the note.  Notably, those two
vectors are the coefficient vector of the **previous** `N = 3` instance of this
development and a degenerate alternative; the old instance was therefore not
identifiable, which is why `SLA/Instance.lean` was rebuilt at `N = 2 = d + 1`,
where `Instance.astar_unique` proves `α*` is forced.

An independent KeYmaera X port of the same chapter confirms this by quantifier
elimination: at `N = 3, d = 1` the regressor satisfies `E_f · (1,1) = 0` for
every `t` — rank 1 forever — and its null direction is exactly the direction
along which the family of valid `α*` runs.

## Two results that do not hold as stated

Both are **proved**, not assumed; they follow from the exact derivative
identities `SecondLevel.Vb_deriv` and `Forgetting.VrF_deriv`.  They are results
of this work, deliberately preserved rather than "fixed".

### 1. The factor `N` in (4.58) — and in (4.69) — does not follow

The dissertation uses the extended vector `ᾱ̃_f = [α̃_f ; −1⃗α̃_f]` in `V` (4.57)
and concludes

    V̇ = −N α̃ᵀEᵀE α̃ − N α̃ᵀEᵀ e_α/m² .

The exact derivative of that `V`, given the adaptive law (4.52), is

    V̇ = −(E α̃ + (1⃗α̃)(1⃗Eᵀ)) · (E α̃ + e_α/m²)        [`SecondLevel.Vb_deriv`]

The cross term `(1⃗α̃)(1⃗Eᵀ)` is not `(N−1)·E α̃`, so the two disagree.
`rateExact_ne_rate458` exhibits `N = 3`, `E α̃ = 1`, `1⃗α̃ = 1⃗Eᵀ = 1`, `e_α = 0`,
where the true value is `−2` and (4.58) gives `−3`.

Worse, the dissertation's `V̇` is **not negative semi-definite**:
`rateExact_can_be_positive` gives `E α̃ = 1`, `1⃗α̃ = −2`, `1⃗Eᵀ = 1`, `e_α = 0`,
for which `V̇ = +1 > 0`.  So (4.57)+(4.58) do not establish the boundedness of
`α̃_f` claimed on page 66.

`rateExact_witness` states the same counterexample by explicit vectors,
`E_f = (2, −1)` and `α̃_f = (−1/3, −5/3)` in `ℝ²` — **the identical witness that
the independent KeYmaera X port of this chapter produced by quantifier
elimination**, so the two formalisations agree on the counterexample.
`Vb_deriv_differs_from_4_58` and `Vb_deriv_can_be_positive` give the same two
facts in the conditional form used by the Coq development, tied directly to the
statement of `Vb_deriv`.

The fix is the reduced Lyapunov function `V = α̃ᵀα̃/2` (`SecondLevel.Vr`), for
which

    V̇ = −γ (E α̃)² − γ (E α̃)(e_α/m²)   ≤ 0  when  e_α = 0   [`SecondLevel.Vr_deriv`,
                                                              `SecondLevel.Vr_antitone`]

This is exactly eq. (24) of Narendra–Wang–Chen, *The Rationale for Second Level
Adaptation* (arXiv:1510.04989), which the dissertation follows.  The stated
qualitative conclusion of Section 4.3 is therefore correct; only the route
through `ᾱ̃` is not.  Note that the `N`-dependence of the convergence rate, which
the dissertation reads off from (4.58), is not supported by the corrected
identity.

### 2. Equation (4.69) omits `v_f` from its residual term

(4.69) writes the sign-indefinite term as `−N α̃ᵀ M_f α*_f`.  The correct
residual is `M_f α*_f + v_f` (`Forgetting.qres`), since
`Eᵀ(E α*_f + ε_{N,f}) = Eᵀ e_α/m²` mixes both — see `Forgetting.VrF_deriv`.  The
text's own justification one line later
(`N α̃ᵀ M_f α*_f = N ∫ e^{−σ(t−τ)} Eᵀ e_α dτ`) is the value of `M_f α*_f + v_f`,
not of `M_f α*_f`, so the intent is right and only the written expression is
incomplete.

`Forgetting.qres_zero` shows the residual vanishes identically once `θ*ᵖ` is in
the convex hull, and `Forgetting.Mf_psd` supplies the missing proof that the
quadratic term is sign definite; together they give `Forgetting.VrF_nonpos`, the
statement (4.69) is aiming at.

## Two places where the dissertation is more conservative than necessary

* Between (4.37) and (4.40) the text argues that `Σ β_i e_{i,f}` only converges
  *exponentially* to `e_{v,f}`, and that they coincide if
  `e_{v,f}(0) = Σ β_i e_{i,f}(0)`.  With linear-regression models they are
  **identically equal by construction**, with no condition on initial values
  (`Model.ev_convex`).
* (4.45) states `lim_{t→∞} Σ e_{i,f} α*_i = 0`.  Under the stated hypotheses it
  is exactly `0` for every `t ≥ 0` (`Hull.ea_zero`), because `θ*ᵖ` never leaves
  the convex hull (`Hull.hull_invariance`).  The dissertation's discussion of a
  non-zero `e_{α,f}(0)` applies to the practical case where the filter states
  are not initialised consistently — a situation outside the model (4.8).

## What Lean/Mathlib exposed that the Coq version glossed over

* **`AppendixA.theorem1_representation` does not need the box bounds.**  The Coq
  `theorem1_representation` carries the hypothesis `0 ≤ w i ≤ 1`; it is never
  used.  Only the *convexity* of the coefficients (`theorem1_convexity`) needs
  it.  Same for `theorem2_representation`, which needs `wlo i < whi i` (to
  divide) but not `wlo i ≤ w i ≤ whi i`; and same again for the two uniqueness
  theorems and for `Instance.astar_unique`, none of which needs nonnegativity —
  `Σ a = 1` plus the representation identity already forces the coefficients.
  The Lean statements drop the unused hypotheses, so they are strictly stronger.
* **`N = S M` disappears.**  The Coq development needs an explicit hypothesis
  `H_NM : N = S M` relating the number of models to the length of `E_f`.
  Indexing by `Fin (M+1)` makes it hold definitionally, and `Fin.sum_univ_castSucc`
  discharges the α_N-elimination bookkeeping of (4.46)–(4.49) in one lemma.
* **Section variables must be `include`d.**  Lean 4.33 does not auto-generalise
  a hypothesis that appears only in a proof, so `hβ : Σβ = 1` had to be
  `include`d explicitly.  This made visible that `Model.ev_eq_dot_thtv` and
  `Model.dot_lincomb` hold *without* `Σβ = 1` — again slightly stronger than the
  Coq statements, which sit under the same hypothesis block.
* **`funext` is used, deliberately.**  The Coq `D_ext` was proved from the
  ε/δ definition specifically to avoid functional extensionality.  In Lean
  `funext` is a theorem of the core logic (from `Quot.sound`), so `Deriv.congr`
  is proved with `HasDerivAt.congr_of_eventuallyEq` and `Deriv.sum` with
  `funext`; the axiom audit above confirms nothing beyond the three standard
  axioms is used.

## What is deliberately **not** ported

Everything in the Coq development is ported.  What is missing is what was
missing there too, plus one addition:

* **Asymptotic arguments**: Barbalat's lemma and its corollaries (Appendix C.4),
  the `L²` membership of `ε m`, persistency of excitation and the resulting
  parameter convergence.  The dissertation itself cites Ioannou & Sun (1996) for
  these.  Not formalised in Coq either.
* **The projection operator `proj_{S_θ,f}` of (4.59).**  Not formalised in Coq
  either.
* **The state-space/transfer-function correspondence of (4.1)–(4.7)**, i.e. that
  the filters `Λ_c, l` actually realise `s^i/Λ(s)`.  Not formalised in Coq
  either.
* **The counterexamples `Vb_deriv_differs_from_4_58` / `Vb_deriv_can_be_positive`
  are conditional**, exactly as in Coq: they say "at any time where
  `E α̃ = 1, 1⃗α̃ = −2, 1⃗Eᵀ = 1, e_α = 0`, the exact rate is positive".  Neither
  development proves that such a configuration is *reachable* by the closed-loop
  dynamics from an admissible initial condition.  The unconditional content is
  in `rateExact_can_be_positive` / `rateExact_witness`, which are statements
  about the algebraic form of the derivative (the form established by
  `Vb_deriv`), not about a trajectory.  This is a real gap in *both*
  formalisations and is stated here rather than papered over.
* `Model.hN_exact` (the amended design rule `M + 1 = d + 1`) is recorded but
  unused *by the identities*, as in Coq.  `Hull.mem_Icc` (`0 ≤ α*_i ≤ 1`) and the
  analogous `β` bounds are likewise recorded and unused: every identity needs
  only `Σ = 1`.  This is not a defect — see *Identities vs. identifiability*
  above: the geometry is what makes `α*_f` a well-defined estimation target, not
  what makes the algebra work.  Chapter 4 is therefore unaffected by the
  amendment, exactly as `../NOTE_convex_uniqueness.md` §7 claims.
* **The `N > d+1` failure is exhibited, not characterised.**
  `AppendixA.more_vertices_not_unique` gives two explicit representations at
  `d = 1, N = 3`.  Neither this port nor the Coq one proves the general statement
  *"for `N > d+1` and `θ*ᵖ` interior, the solution set is
  `(N−d−1)`-dimensional"*, nor the converse half of the design rule
  (*"fewer than `d+1` points cannot span the box"*, an affine-dimension argument
  asserted on page 64).  The hexagon of `../NOTE_convex_uniqueness.md` §4 is not
  formalised in `ℝ²` here either — only its 1-D shadow.

## Sources consulted

* Z. Han & K. S. Narendra, "New concepts in adaptive control using multiple
  models", *IEEE TAC* 57(1):78–89, 2012.
* K. S. Narendra, Y. Wang, W. Chen, "The Rationale for Second Level Adaptation",
  arXiv:1510.04989 — used to check the SLA framework, the convex-hull invariance
  claim, and the Lyapunov step `V̇ = −‖E α̃‖²`.
* P. Ioannou & J. Sun, *Robust Adaptive Control*, 1996 — normalized gradient
  estimator behind 4.12–4.23.
* G. Chowdhary, T. Yucelen, M. Mühlegg, E. N. Johnson, "Concurrent learning
  adaptive control of linear systems with exponentially convergent bounds",
  *IJACSP* 27(4):280–301, 2013 — the recorded-data idea behind 4.60–4.69.
