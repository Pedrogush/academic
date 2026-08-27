# Soundness tests: what a green build does *not* prove

`coqc` exiting 0, `lake build` exiting 0, `isabelle build` exiting 0 and
KeYmaera X printing `PROVED` all mean the same modest thing: **the proof
scripts type-check against the statements as written.** None of them says the
statements are the intended ones, that they are about anything at all, or that
they are not vacuously true.

This directory attacks the development from that angle. The question it tries
to answer is not "does it compile?" but:

> If someone had wanted to produce a formalisation that compiles cleanly,
> passes an axiom audit, and still proves nothing about second level
> adaptation — what would they have done, and would we notice?

Five kinds of check, cheapest first:

| layer | what it is | cost |
|---|---|---|
| `static/` | syntactic anti-cheat scan, the axiom audit turned into a pass/fail test, and a statement-by-statement comparison of `coq/` with `coq/annotated/` | ~1 min |
| `coq/T01–T04`, `T06` | machine-checked tests that pin the *meaning*: the definitions discriminate, the hypotheses have a model, the statements match the equations, and the two findings are realised by actual trajectories | ~1 min |
| `lean/Check.lean`, `keymaerax/T05` | the same idea in the other two systems: restated statements closed by the library theorem, instance bundles shown inhabited, dL preconditions shown satisfiable | ~1 min / ~8 min |
| `numeric/` | an independent numerical integration of the two witness trajectories — no proof involved, so it catches modelling mistakes a proof cannot | seconds |
| `mutants/` | mutation testing: break the source on purpose, check that the build notices | ~1 h |

Run everything with `./run_all.sh` (add `--dl` for the KeYmaera X entries,
`--mutants` for the full mutation run).

---

## The threat model

Nine ways to make a proof assistant say yes while proving nothing. For each:
the attack, whether the repository as it stood caught it, and what catches it
now.

### G1 — `sorry` and friends

`Admitted`, `admit`, `Axiom`, `Parameter`, `sorry`, `oops`, `axiomatization`.
The classic. Also the *configuration* variants, which are easier to miss:
Isabelle's `quick_and_dirty = true` accepts `sorry` silently, and Lean's
`native_decide` closes goals through a trusted compiler path.

**Caught before:** yes (the original verification pass grepped for these).
**Now:** `static/scan.sh` re-checks them on every run, with comments stripped
first, and additionally asserts `quick_and_dirty = false` in `isabelle/ROOT`
and the absence of `native_decide`/`unsafe`/`implemented_by` in Lean.

### G2 — a private axiom

Not `Axiom cheat : False`, which a grep finds, but an innocuous-looking one
used in one place. `Print Assumptions` reveals it — but `Print Assumptions`
only *prints*; a build that runs it and ignores the output is theatre.

**Now:** `static/coq_axioms.sh` runs the audit over 19 library theorems *and*
the test theorems, and exits non-zero if anything appears outside the four
axioms Coq's `Reals` itself is built on. The detector was itself tested
against a file with a deliberate `Axiom cheat : forall P : Prop, P`.

### G3 — vacuous hypotheses  ← **the one that got through**

Every theorem in `SLA_Chapter4` lives under about fifteen section hypotheses.
If those are jointly unsatisfiable, all of them hold vacuously — with no
axiom, no `admit`, and a perfectly clean build.

`SLA_Instance.v` is the intended defence: it exhibits concrete signals that
satisfy every hypothesis. But it only ever *applies* first-level theorems
(`hull_invariance`). Nothing in the repository applied `Vr_dyn`, `Vb_dyn`,
`Mf_psd`, `qres_zero` or `VrF_dyn` to anything.

That gap is real, and mutant **C24** demonstrates it: inserting

```coq
Hypothesis H_absurd : (0 = 1)%R.
```

into `Section SLA_conventional` makes every second-level theorem vacuous, and
**the whole repository still builds** — Coq, all four files, exit 0, clean
axiom audit. The same attack in the plant section (C25) *is* caught, because
`SLA_Instance` instantiates first-level results.

**Now:** `coq/T02_nonvacuity.v` instantiates *every* headline theorem of the
chapter — SLA and SLAFF included — on the model in `SLA_Instance`. C24 is
killed by T02 and by nothing else.

Isabelle and Lean turn out to be structurally better off here: their
hypotheses are bundled in a locale / a `structure`, and `SLA_Instance.thy` /
`Instance.lean` must discharge every field of the bundle to interpret it, so
an absurd assumption cannot hide (mutants I06, L06).

### G4 — a model that exists but is degenerate

A trivial model satisfies everything: `d = 0`, `M = 0`, all signals zero,
`E_f ≡ 0`. The theorems are then true and empty.

The existing instance is already non-degenerate (`d = 1`, `N = 2`, `E_f`
nowhere zero — this was fixed in the `N = 2n+1` amendment, when an earlier
`N = 3` instance had a rank-deficient `E_f`).
**Now:** T02 states the non-degeneracy explicitly and proves it (`nondeg_*`),
including that the first-level Lyapunov function *strictly* decreases, so
`V1_nonincreasing` is not the trivial `c ≤ c`.

### G5 — definitions that make the theorems trivial

If `Deriv f f'` were `True`, if `dot` ignored an argument, if `Sum` were
constantly 0, every theorem above would still compile and mean nothing. This
is invisible to G1 and G2.

**Now:** `coq/T01_defs_discriminate.v` pins each notion from below —
`Deriv` refutes a wrong derivative (`¬ Deriv id 0`) and has teeth (a negative
derivative forces a decrease); `dot` uses both arguments; `Sum` sees every
index; `Wq` is strictly positive off zero; `msq > 1` for a nonzero regressor.

Note what mutation testing can and cannot do here. A *one-line* vacuous
redefinition is killed immediately — not by any statement, but by the proof
scripts that mention the underlying predicate. The residual risk is a
*coordinated* rewrite of definitions and proofs together, which no mutation
simulates. T01 is the guard against that.

### G6 — statement drift

The theorem labelled `(4.23)` says something else: a sign flipped, a factor
dropped, a conclusion weakened, an extra hypothesis added. The comment carries
the claim; nothing checks the comment.

**Caught before:** in Isabelle only — `SLA_Check.thy` restates the headline
results and closes each by a single `rule`.
**Now:** `coq/T04_statement_fidelity.v` does the same for Coq and
`lean/Check.lean` for Lean (run with `lake env lean ../tests/lean/Check.lean`,
so the audit file is not part of the shipped library), and writes out
the *claimed* right-hand sides of (4.58) and (4.69) as their own definitions
(`claimed_458`, `claimed_469_term`), so the two findings are comparisons of two
explicitly stated formulas rather than assertions in prose. Fifteen of the
mutants (C04–C15, C17–C19) are statement/definition drift of exactly this kind;
all are killed.

### G7 — a conditional theorem whose hypotheses cannot be met  ← **the second gap**

This one bites precisely where the dissertation's two findings live. The
refutation of (4.58) was stated as

```coq
Corollary Vb_deriv_can_be_positive : forall t,
  ea t = 0 -> Ealpt t = 1 -> Sb t = -2 -> SE t = 1 -> 0 < (exact derivative).
```

`Ealpt`, `Sb` and `SE` are *derived* quantities of the trajectory. If no
system satisfying (4.19), (4.41) and (4.52) ever reaches such a state, the
corollary is vacuous and refutes nothing. All three provers stopped at an
arithmetic witness — `E_f = (2,−1)`, `α̃_f = (−1/3,−5/3)` — which shows the
three scalar values are mutually consistent, **not** that they are reachable.

**Now:** `coq/T03_witness_458.v` closes it. It builds a complete model of
Chapter 4 at `d = 2`, `N = 3 = d+1` (the amended design rule), `M = 2`, with
closed-form solutions of *both* adaptive laws:

* first level: `φ ≡ (1,0)`, `Γ = 2I`, `θ̂ᵢ(t) = (sᵢe^{−t}, cᵢ)` with
  `s = (10/3, −8/3, −2/3)`, `c = (1,−1,0)`, `α* = (1/3,1/3,1/3)`;
  the three initial estimates are affinely independent, `E_f(t) = e^{−t}(2,−1)`
  is nowhere zero, and `e_α ≡ 0`;
* second level: with `e_α = 0`, (4.52) reduces to `α̃̇ = −EᵀE α̃`, and for a
  rank-one `EᵀE` this integrates: `α̃(t) = α̃(0) + u(t)·E_f(0)ᵀ` with
  `u = (w−1)/5`, `w(t) = exp(−5/2 + (5/2)e^{−2t})`, `α̃(0) = (−1/3,−5/3)`.

Every hypothesis of the chapter is discharged for this model, and then
`Vb_dyn` is applied to it. The consequences, all machine-checked:

| result | statement |
|---|---|
| `W_Vb_rate_at_0` | the exact derivative of (4.57) at `t = 0` is **+1** |
| `W_rate_458_at_0` | (4.58) predicts **−3** at the same instant |
| `W_458_is_wrong_here` | the two differ, on a trajectory, not merely as formulas |
| `W_Vb_strictly_increases` | `∃h > 0. Vb(0) < Vb(h)` — the dissertation's own Lyapunov function **strictly increases** along a genuine solution of (4.19)+(4.52) |

The last line is what the finding always wanted to say. It is no longer
conditional on anything.

A proof cannot catch a *modelling* mistake: if the Coq model were not the
system of Chapter 4, the proof would go through anyway. So
`numeric/simulate.py` integrates the ODEs numerically, written out as the
dissertation writes them and with no reference to the closed form, and finds

```
t        V(4.57)
0.00     3.444444        exact derivative of (4.57) at 0 = +1.000000
0.20     3.594550        value predicted by (4.58)       = -3.000000
0.60     3.691401        finite difference of V at 0     = +1.000000
1.00     3.715376        max |integrator - closed form| over [0,1] = 1.2e-13
```

(4.57) rises monotonically along the trajectory while (4.58) says it should be
falling at rate 3.

**The obvious objection, and `coq/T06_witness_simplex.v`.** In T03's witness
`α_f(0) = (0, −4/3)` lies outside the simplex, and a defender of (4.58) could
say the algorithm is not meant to visit such a state. That objection cannot be
met *at that witness*: `1⃗α̃ = −2` together with `Σα*_f ≤ 1` forces
`Σα_f ≤ −1 < 0`, so every state with those scalar values is outside the
simplex. T06 therefore builds a **second** complete model, again at
`d = 2, N = 3, M = 2`, in which

```
alpha_f(0) = (1, 0)        <- a VERTEX of the simplex
alpha*     = (1/3,1/3,1/3)
E_f(0)     = (1, 3)
exact derivative of (4.57) at t = 0  =  +1/3     (V increases)
value claimed by (4.58)              =  -1/3     (V decreases)
```

The two do not even agree in sign. So the failure of (4.58) is not an artefact
of an exotic initial condition: putting all the second-level weight on the
first model — the most natural initialisation there is — already does it.
`numeric/simulate.py B` confirms this trajectory independently.

The same gap exists for the *second* finding, and is closed the same way.
(4.69) omits `v_f` from the residual — an objection with no force if `v_f` were
identically zero or if the omitted term were negligible. On the instance, at
`t = 1`, `T02` proves all three of

```
M_f α*_f ≠ 0        v_f ≠ 0        M_f α*_f + v_f = 0
```

so the dropped term is not small: it is one half of a pair that cancels
exactly. (In the pre-amendment `N = 3` instance `v_f` *was* identically zero,
which is precisely why the amendment rebuilt the instance at `N = d+1`.)

One residue: `Vb_deriv_differs_from_4_58` is stated at the scalar values
`(E α̃, 1⃗α̃, 1⃗Eᵀ) = (1, 1, 1)`, and no trajectory is exhibited *at those
particular values*. Its conclusion — the exact derivative differs from the
value (4.58) claims — is proved on trajectories in T03 and T06 instead, at
`(1, −2, 1)` and `(−1/3, 1/3, 4)`.

### G8 — dL-specific vacuity (KeYmaera X)

`pre → [ODE]post` is trivially valid if `pre` is unsatisfiable, if the
evolution domain is false at the initial state, if `post` is a tautology, or
if the vector field is zero. KeYmaera X prints `PROVED` for all four.

**Now:** `keymaerax/T05_dl_vacuity.kyx` rules each out for the four
box-modality models (`01_first_level`, `02_hull_invariance`,
`03_second_level`, `06_slaff`), by QE only: a non-degenerate witness for the
precondition (in which *neither* estimate equals `θ*`), a state refuting the
postcondition, a state where the adaptive vector field is `−1 ≠ 0`, the domain
`r > 0` inhabited at `r = 1/(1+φ²) = 1/2`, a Lyapunov level strictly between 0
and `c`, a strictly positive `M_f` quadratic form together with a state where
that form is negative, and the (4.58) witness state. `07_instance` and
`08_design_rule` need no such check — their entries are either fully concrete
or universally quantified arithmetic.

`keymaerax/run.sh` additionally re-runs `05_eq458_dI_fails.kyx`, the one file
whose *failure* is the intended outcome, and requires the failure to be an
`UNFINISHED` proof rather than a parse error or a missing file — otherwise a
typo in that file would be silently counted as the expected result.

### G9 — the readable copy is not the checked copy

`coq/annotated/` exists so a reader who does not know Coq can follow the
development. If it drifted from `coq/`, the reader would be reading one thing
while the machine checks another — the most comfortable way to be wrong, and
invisible to every check above (both trees compile).

`static/annotated_equiv.sh` compiles the two trees separately and prints the
type of every declaration of `coq/*.v` in both worlds, fully qualified, then
diffs. **193 declarations, identical.** A changed statement, a reordered or
extra section hypothesis, or a missing declaration would show as a diff. This
replaces the hand comparison recorded in `VERIFICATION.md`.

---

## Mutation testing

`mutants/catalogue.tsv` lists 43 mutations across the four systems, each with
the expectation `kill` (the build must fail) or `survive`.
`mutants/run_mutants.py` applies each one to a scratch copy, rebuilds, and
compares. `mutants/results.tsv` is the log.

Two things to keep in mind when reading the results:

* **A kill does not mean the mutated statement is false.** It means the *proof*
  depends on the text that changed. C10 is the instructive case: with the sign
  of the gradient law flipped, hull invariance remains *true* — `θ̃_α` still
  satisfies a linear ODE with `θ̃_α(0) = 0`, so uniqueness pins it at zero
  either way — but the Coq proof runs through a Lyapunov function that has to
  be nonincreasing, and that step dies. The mutant reports what the proof
  depends on, not what reality does.
* **A survivor is not automatically a bug.** It maps out what the machine is
  *not* checking. Of the survivors here, C22 is the control and C16 is a
  documented fact about the chapter rather than a defect.
* **A prediction can be wrong, and that is data too.** K02 was catalogued as an
  expected survivor and was killed; the reasoning behind the expectation was
  faulty, not the development. The catalogue records the correction.

For Coq the runner builds the library *and* the tests in this directory, and
reports the two verdicts separately — that is how C24 is visible as
"survives the repository, killed by T02".

### Results

All 25 Coq mutants behaved exactly as catalogued (`results.tsv`).

| id | mutation | repo build | tests | reading |
|---|---|---|---|---|
| C01–C09 | `dot` ignores an argument; `Sum` drops a term; MVT direction reversed; `m²`, `e`, `ε`, `θ̃`, `E_f` sign/shape; the ½ of the quadratic form | KILLED | — | the definitions are load-bearing |
| C10 | (4.19): drop the minus in the gradient law | KILLED | — | the descent direction is load-bearing |
| C11–C15, C17–C19 | claimed derivative signs in (4.23), (4.49)/(4.51), (4.57), the cross term of the exact derivative, the SLAFF residual's `v_f`, (A.4)'s `1/p` | KILLED | — | statement drift is caught |
| C16 | `H_N_exact : N = S d` → `N = d` | **SURVIVED** | SURVIVED | **expected**: the design rule is stated in Chapter 4 but never used there; its content lives in `AppendixA.design_rule_exact`. Consistent with the source comment, now machine-confirmed |
| C20 | the instance's initial estimates no longer straddle `θ*` | KILLED | — | the model is not decorative |
| C21, C23 | `Σα* = 1` → `= 2`; `Γ > 0` → `Γ ≥ 0` | KILLED | — | the convexity and positivity hypotheses are used |
| C22 | comment-only (control) | SURVIVED | SURVIVED | the harness is not reporting noise |
| C24 | absurd hypothesis in the SLA section | **SURVIVED** | **KILLED** | the gap of G3, and the reason T02 exists |
| C25 | absurd hypothesis in the plant section | KILLED | — | `SLA_Instance` covers the first level |

All 7 Isabelle mutants behaved as catalogued.

| id | mutation | result | reading |
|---|---|---|---|
| I01–I05 | the same definition/law/statement mutations as C04, C05, C08, C10, C14 | KILLED | the Isabelle port depends on the same things the Coq one does |
| I06 | absurd assumption added to the `sla` locale | KILLED | **the vacuity attack that survives in Coq does not survive here**: `SLA_Instance.thy` *interprets* the locale, and an interpretation must discharge every assumption. Locales force what Coq sections leave optional |
| I07 | comment-only (control) | SURVIVED | control behaves |

### KeYmaera X

| id | mutation | result | reading |
|---|---|---|---|
| K01 | postcondition of the hull-invariance entry changed to `… = ts + 1` | KILLED | the box formula is not proved by the postcondition being trivially true |
| K02 | sign of the `t̂₀` equation flipped (only that one) | KILLED | **catalogued as an expected survivor; it was not.** The prediction was wrong: flipping *one* of the two equations destroys the Darboux structure (`S′` is no longer proportional to `S − θ*`), and the invariant genuinely fails — at `α* = (½,½)`, `θ* = 0`, `θ̂ = (1,−1)` the state satisfies the invariant but leaves it immediately. So this is a correct kill, and the catalogue entry has been fixed |
| K03 | sign of the cross term in the algebraic identity behind the (4.58) finding | KILLED | the identity Z3 checks is the intended one |
| K04 | sign of the gradient law in the (4.23) dL entry | KILLED | here the sign *is* load-bearing: the Lyapunov level set is not invariant for the ascending law |
| K05 | sign of **both** adaptation equations (the experiment K02 was meant to be) | **SURVIVED** | **expected, and it is a real observation about the port**: with both equations flipped the invariant is still Darboux, and the entry still proves. So `02_hull_invariance.kyx` pins the *relative* sign of the two adaptive laws but not the sign of `Γ` itself. Nothing is wrong — the entry proves invariance, which holds either way — but a reader should not read it as also certifying the descent direction. `01_first_level.kyx` (K04) and the Coq Lyapunov proof (C10) are what pin that |

All five KeYmaera X mutants are now consistent with the catalogue (K02 after
its correction).

The dL non-vacuity file was run separately: **all 8 entries of
`keymaerax/T05_dl_vacuity.kyx` PROVED**, and `05_eq458_dI_fails.kyx` was
confirmed to fail as an `UNFINISHED` proof — a proof attempt that ran and did
not close — rather than as a parse error.

### Lean 4 / Mathlib

All 6 Lean mutants behaved as catalogued.

| id | mutation | result | reading |
|---|---|---|---|
| L01–L05 | the same definition/law/statement mutations as C04, C05, C08, C10, C14 | KILLED | the Lean port depends on the same things |
| L06 | an absurd field `absurd : (0 : ℝ) = 1` added to `structure SecondLevel` | KILLED — `Instance.lean:176: Fields missing: 'absurd'` | like Isabelle and unlike Coq, the vacuity attack cannot hide: a `structure` must be *constructed*, and `Instance.L0` fails to do so |

**The cross-system lesson.** The same attack (C24 / I06 / L06) is invisible in
Coq and fatal in Isabelle and Lean, and the reason is a design choice rather
than diligence: a locale `interpretation` and a `structure` instance must
discharge *every* assumption in the bundle, whereas a Coq `Section` hypothesis
imposes no obligation on anyone unless a file chooses to apply the theorem.
`tests/coq/T02_nonvacuity.v` supplies that obligation for the Coq port.

### Summary

**42 of 43 mutants behaved exactly as catalogued** (41/42 on the first pass,
plus K05 afterwards). The single deviation was K02, where the prediction — not
the development — was wrong; the catalogue records the corrected reasoning, and
K05 ran the experiment that was intended and survived, as predicted.

Five mutants survive their build; none is a defect, and each says something:

* **C22, I07** — the comment-only controls, proving the harness is not
  reporting noise.
* **C24** — survives the repository build and is killed by
  `tests/coq/T02_nonvacuity.v`. That split is the whole point of running the
  tests as a second stage.
* **C16** — the design rule `N = 2n+1` is stated in `SLA_Chapter4` and never
  used there. That matches the source comment; it is now machine-confirmed
  rather than asserted. (The rule does real work in `SLA_AppendixA`, where
  `design_rule_exact` and `more_vertices_not_unique` live.)
* **K05** — the dL hull-invariance entry does not pin the sign of `Γ`.

---

## What is still not covered

Stated plainly, because a test suite that oversells itself is worse than none.

1. **The trusted computing base.** Coq's kernel, Mathlib, HOL, KeYmaera X's
   core and Z3 are all trusted here. Nothing in this directory would notice a
   soundness bug in them. (The KeYmaera X runs do depend on Z3 answers; the
   Coq/Lean/Isabelle ones do not depend on any external solver.)
2. **Modelling fidelity.** Whether `Deriv`, `Sum`-over-`nat` vectors and the
   ODE-free treatment of the adaptive laws are a faithful rendering of the
   dissertation's continuous-time system is a mathematical judgement, not a
   machine-checkable one. T04 checks the equations against the *text*; it
   cannot check the text against reality.
3. **What is deliberately not formalised.** Barbalat's lemma, persistency of
   excitation and the asymptotic arguments are outside all four ports, as the
   subdirectory READMEs already say. No test here changes that.
4. **The non-vacuity witnesses are Coq-only.** T03/T06's trajectory-level refutation
   of (4.58) has no Lean or Isabelle counterpart yet; those ports still stop at
   the arithmetic witness (`rateExact_witness`, `Vb_deriv_positive_witness`).
   The mathematical content is identical and the Coq proof is complete, but a
   sceptic who trusts only Lean has not been served.
5. **Coordinated rewrites.** Mutation testing perturbs one place at a time. A
   development whose definitions *and* proofs were rewritten together to be
   self-consistently wrong would survive every mutant; only T01 and T04 speak
   to that, and only for the notions they name.
6. **Mutant coverage is a sample, not a proof.** 42 mutations over ~7 500 lines
   is a spot check chosen to hit the load-bearing places, not exhaustive
   coverage.
