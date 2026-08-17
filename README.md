# Second Level Adaptation, formalised

Machine-checked formalisations — in **Coq**, **Lean 4 / Mathlib**,
**Isabelle/HOL** and **KeYmaera X** — of Chapter 4 (equations 4.1–4.69) and
Appendix A of

> Pedro Yochinori Gushiken, *"Adaptação de Segundo Nível como Técnica de
> Estimação de Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de
> Referência"*, MSc dissertation, UFRN, 2018.
> Chapter 4, *Estimação de Parâmetros, Ordem n* (document pages 55–78 =
> PDF pages 81–104). The dissertation is included as [`DISSERT.pdf`](DISSERT.pdf).

Second Level Adaptation (SLA), following Han–Narendra and Narendra–Wang–Chen,
runs `N` first-level identification models in parallel and then identifies the
*convex-combination coefficients* `α*` that reproduce the true plant parameters
`θ*ᵖ` from the model estimates. The chapter develops the first level, the
convex-hull argument, the second-level adaptive law, and a forgetting-factor
variant (SLAFF).

## Results of the formalisation

Everything in Chapter 4 that is a mathematical statement — as opposed to a
modelling assumption or an asymptotic argument via Barbalat's lemma /
persistency of excitation — is formalised, in all four systems. Three things
came out of doing it:

**1. Two results do not hold as stated.** Both are *proved*, not assumed; they
follow from exact derivative identities.

* **(4.58)**: the dissertation's Lyapunov candidate (4.57), built on the
  extended vector `ᾱ̃_f = [α̃_f ; −1⃗α̃_f]`, does not have the claimed derivative
  `V̇ = −N α̃ᵀEᵀE α̃ − N α̃ᵀEᵀ e_α/m²`. Its exact derivative along (4.56) is
  `V̇ = −(E α̃ + (1⃗α̃)(1⃗Eᵀ))·(E α̃ + e_α/m²)`, and that can be **strictly
  positive** — witness `E_f = (2, −1)`, `α̃_f = (−1/3, −5/3)`, `e_α = 0`, where
  the true value is `+1` and (4.58) predicts `−3`. So (4.57)+(4.58) do not
  establish the boundedness of `α̃_f` claimed on page 66. The qualitative
  conclusion of Section 4.3 survives via the reduced candidate
  `V = α̃ᵀα̃/2` (eq. (24) of Narendra–Wang–Chen), for which
  `V̇ = −γ(E α̃)² − γ(E α̃)(e_α/m²) ≤ 0`; the `N`-dependence of the convergence
  rate read off from (4.58) does not survive.
* **(4.69)** omits `v_f` from its residual term: it writes `−N α̃ᵀ M_f α*_f`
  where the correct residual is `M_f α*_f + v_f`. The text's own justification
  one line later is the value of `M_f α*_f + v_f`, so the intent is right and
  only the written expression is incomplete. The residual is proved to vanish
  identically once `θ*ᵖ` is in the convex hull.

**2. The design rule needs `N = 2n + 1`, not `N ≥ 2n + 1`.** The inequality
gives *existence* of a representation `θ*ᵖ = Σ αᵢ* θ̂ᵢ(0)` — which is exactly
what the dissertation's own justification argues — but the second level
*identifies* `α*_f`, so `α*_f` must be a single point, and uniqueness holds only
at `N = d + 1 = 2n + 1`. Appendix A already builds exactly `d+1` affinely
independent vertices, so nothing is lost. Full argument, a hexagon
counterexample and the affected pages: [`NOTE_convex_uniqueness.md`](NOTE_convex_uniqueness.md).

**3. Two places are more conservative than necessary.** The virtual model's
error equals the convex combination of the first-level errors *identically*, not
just asymptotically (no condition on initial values); and `Σ eᵢ α*ᵢ` is exactly
`0` for every `t ≥ 0`, not merely `→ 0`, because `θ*ᵖ` never leaves the convex
hull. Convex-hull invariance itself — stated in the dissertation without proof —
is proved here by a Lyapunov argument plus the mean value theorem.

## The four developments

| Directory | System | Contents |
|---|---|---|
| [`coq/`](coq/) | Coq 8.18.0 | the reference development; `coq/annotated/` is the same proofs with prose annotations |
| [`lean/`](lean/) | Lean 4.33.0 + Mathlib v4.33.0 | idiomatic port; slightly stronger in places (unused hypotheses dropped, unconditional counterexample witnesses) |
| [`isabelle/`](isabelle/) | Isabelle2025-2 (HOL) | locale-based port, plus `SLA_Check.thy`, an audit theory that restates the headline results and proves each by a single `rule` |
| [`keymaerax/`](keymaerax/) | KeYmaera X 5.1.2 + Z3 | the genuinely *dynamical* parts as differential dynamic logic: ODE invariants and Lyapunov arguments at fixed dimensions |

Each directory has its own README with an equation → theorem map, build
instructions, and an explicit list of what is *not* formalised.

The four are independent: the Lean, Isabelle and KeYmaera X versions were
written against the dissertation rather than transliterated, and they agree on
the two findings — including on the same explicit counterexample for (4.58),
which KeYmaera X produced by quantifier elimination.

## Verification status

All four toolchains were re-run from clean state; see
[`VERIFICATION.md`](VERIFICATION.md) for the full record.

| System | Result |
|---|---|
| Coq 8.18.0 | 4 files compile, no `admit`/`Admitted`; 23 headline theorems audited with `Print Assumptions` — only the axioms Coq's own `Reals` is built on |
| Lean 4.33.0 / Mathlib v4.33.0 | 5 modules build, no `sorry`; 21 headline theorems audited with `#print axioms` — only `propext`, `Classical.choice`, `Quot.sound` |
| Isabelle2025-2 | 5 theories build, no `sorry`/`oops`/`axiomatization` |
| KeYmaera X 5.1.2 | 33/33 intended entries proved; the 2 entries of `05_eq458_dI_fails.kyx` deliberately do not close |

## Building

Each subdirectory is self-contained:

```bash
cd coq       && source ./coqenv.sh && make     # or: sudo apt install coq && make
cd lean      && lake build                     # needs the .lake symlink, see lean/README.md
cd isabelle  && ./build.sh
cd keymaerax && ./build.sh                     # ~3.5 min fixed start-up per file
```

## What is deliberately not formalised

Consistently across all four: the asymptotic theory the dissertation itself
cites Ioannou & Sun (1996) for (Barbalat's lemma, `L²` membership of `ε m`,
persistency of excitation and the resulting parameter convergence); the
projection operator of (4.59); the state-space/transfer-function correspondence
of (4.1)–(4.7); and the *necessity* half of the design rule (an affine-dimension
argument asserted on page 64). Per-system limitations — in particular what
cannot be expressed in dL — are listed in each directory's README.

## Sources consulted

* Z. Han & K. S. Narendra, "New concepts in adaptive control using multiple
  models", *IEEE TAC* 57(1):78–89, 2012.
* K. S. Narendra, Y. Wang, W. Chen, "The Rationale for Second Level Adaptation",
  [arXiv:1510.04989](https://arxiv.org/abs/1510.04989).
* P. Ioannou & J. Sun, *Robust Adaptive Control*, 1996.
* G. Chowdhary, T. Yucelen, M. Mühlegg, E. N. Johnson, "Concurrent learning
  adaptive control of linear systems with exponentially convergent bounds",
  *IJACSP* 27(4):280–301, 2013.

## Licence

The formalisations and accompanying notes are [MIT](LICENSE) licensed.
`DISSERT.pdf` is the author's MSc dissertation (UFRN, 2018), included for
reference; the MIT licence does not extend to it.
