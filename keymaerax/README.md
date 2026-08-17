# KeYmaera X (differential dynamic logic) port of Chapter 4

Companion to `../coq/`, which is the source of truth. This folder encodes the
parts of the Coq development that are genuinely *dynamical* — ODE invariants
and Lyapunov arguments — as differential dynamic logic (dL) models for
[KeYmaera X](https://github.com/LS-Lab/KeYmaeraX-release).

**Status: all 33 intended proof obligations were discharged by the KeYmaera X
command-line prover (8 files, 35 archive entries; the 2 entries of
`05_eq458_dI_fails.kyx` are deliberately not provable and did not close).
`verification-log.txt` contains the verbatim prover output of every run.
Nothing in this README is claimed as verified unless that log shows it.**

| File | Entries | Result |
|---|---|---|
| `01_first_level.kyx` | 3 | all proved |
| `02_hull_invariance.kyx` | 4 | all proved |
| `03_second_level.kyx` | 3 | all proved |
| `04_eq458_discrepancy.kyx` | 5 | all proved |
| `05_eq458_dI_fails.kyx` | 2 | **did not close — intended**, exit 255 |
| `06_slaff.kyx` | 4 | all proved |
| `07_instance.kyx` | 7 | all proved |
| `08_design_rule.kyx` | 7 | all proved |

Nothing timed out and nothing failed unexpectedly.

> **Amendment (design rule).** The dissertation's `N >= 2n+1` has been
> corrected to **`N = 2n+1 = d+1` exactly** — see
> [`../NOTE_convex_uniqueness.md`](../NOTE_convex_uniqueness.md). The
> inequality gives *existence* of a convex representation but not
> *uniqueness*, and the second level identifies `alpha*_f`, so `alpha*_f` must
> be a single point. This folder was updated accordingly; §7 below records
> exactly what changed in each file and why. The (4.58) and (4.69) findings
> are unaffected and still verify.

---

## 1. Toolchain, and how it was installed (rootless, no sudo)

| Component | Version | Where |
|---|---|---|
| KeYmaera X | 5.1.2 | `~/kyx-tools/keymaerax.jar` |
| Java | Eclipse Temurin JDK 21.0.12+8 | `~/kyx-tools/jdk-21.0.12+8` |
| Z3 (arithmetic backend) | 5.0.0 (x64, glibc 2.39) | `~/kyx-tools/z3-5.0.0-x64-glibc-2.39/bin/z3` |

```bash
mkdir -p ~/kyx-tools && cd ~/kyx-tools

# Java 21 (KeYmaera X 5.1.2 runs on a modern JDK; JavaFX is not needed for
# the command-line prover, only for the web UI)
curl -L -o jdk21.tar.gz \
  "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse"
tar xzf jdk21.tar.gz

# KeYmaera X
curl -L -o keymaerax.jar \
  "https://github.com/LS-Lab/KeYmaeraX-release/releases/download/5.1.2/keymaerax.jar"

# Z3 — the release jar does not bundle a Linux Z3 binary
curl -L -o z3.zip \
  "https://github.com/Z3Prover/z3/releases/download/z3-5.0.0/z3-5.0.0-x64-glibc-2.39.zip"
unzip -q z3.zip
```

Mathematica / Wolfram Engine is the other supported backend; it is licensed
and was deliberately not used.

### Two Z3-specific gotchas you must work around

**(a) Z3 hangs forever on some of KeYmaera X's own lemmas.** At start-up
KeYmaera X derives a ~450-lemma *derived axiom* base (cached in
`~/.keymaerax/cache/lemmadb`). Nineteen of those lemmas are rational-function
and real-exponent normalisation facts — the blocking one is literally

```
(assert (not (forall ((x Real) (i Real) (j Real)) (= (* (^ x i) (^ x j)) (^ x (+ i j))))))
```

Z3 cannot decide a power with a *variable real exponent* and never returns.
KeYmaera X's `QE_TIMEOUT_MAX` does not cap it, so `-setup` and `-prove` both
block indefinitely. **Fix: give Z3 its own hard limit with a wrapper**, and
point `-z3path` at the wrapper:

```bash
mkdir -p ~/kyx-tools/z3wrap
cat > ~/kyx-tools/z3wrap/z3 <<'EOF'
#!/bin/sh
exec ~/kyx-tools/z3-5.0.0-x64-glibc-2.39/bin/z3 -T:25 "$@"
EOF
chmod +x ~/kyx-tools/z3wrap/z3
```

`build.sh` creates this wrapper automatically if it is missing.

**(b) Those 19 lemmas can never be derived with Z3 at all** (Mathematica can
do them). KeYmaera X therefore prints, on *every* run,

```
WARNING: Encountered 19 errors when trying to populate DerivedAxioms database.
Unable to derive: timesDivInverse powNegOne powerLemma timesPowersBoth ...
Timed out while trying to derive lemmas. Continuing with restricted functionality!
DETAILS: QE with Z3 gives SAT. Cannot reduce the following formula to True:
\forall y \forall x 1/x*y=y/x
```

and carries on. This is harmless for the models here — none of them needs a
symbolic reciprocal or a variable exponent — but it costs about **3.5 minutes
of fixed start-up on every invocation**, which is why every wall-clock time in
`verification-log.txt` is ~3.5 min even though the proofs themselves take
between 51 ms and 3.4 s. Do **not** try to complete the cache with `-setup`;
it cannot finish with Z3 as the only backend.

`build.sh` filters this warning out of its output.

## 2. Running the proofs

```bash
./build.sh
```

It runs, for each `.kyx` file in sorted order, exactly the command that
produced `verification-log.txt`:

```bash
timeout 560 nice -n 15 ~/kyx-tools/jdk-21.0.12+8/bin/java -Xmx2g -Xss20M \
  -jar ~/kyx-tools/keymaerax.jar -launch -prove FILE.kyx \
  -tool z3 -z3path ~/kyx-tools/z3wrap/z3 -timeout 200
```

`-launch` makes KeYmaera X use the current JVM instead of forking a second
one, so `-Xmx2g -Xss20M` actually take effect (the 20 MB stack is required;
the default overflows in the parser). `nice` and the heap cap matter on a
small machine — this was developed on 4 cores / 7 GB.

`05_eq458_dI_fails.kyx` is expected to return a **non-zero** exit code (it
returned 255); every other file is expected to return 0. Override
`KYX_TOOLS`, `JAVA_HOME`, `KYX_JAR`, `Z3_REAL`, `TIMEOUT` or `PROOF_BUDGET`
in the environment if your layout differs.

The prover writes one `FILE.kyx-SLA/` directory of `.kyp` proof artifacts per
input file; only the `.kyx` sources are kept in this folder, so delete them
with `rm -rf *.kyx-SLA` after a run. (Incidentally, the directory produced for
`05_eq458_dI_fails.kyx` comes out empty — no proof was recorded, matching the
two `UNFINISHED` results.)

## 3. Concrete dimensions

dL has no dependent types and no induction over an abstract dimension, so
every dimension here is a fixed numeral:

* **d = 2** (parameter vector `theta*_p` in R^2, i.e. plant order n = 1) in
  `01_first_level.kyx`.
* **d = 1** (scalar parameter) in `02_hull_invariance.kyx`,
  `07_instance.kyx` and `08_design_rule.kyx`.
* **N = 2 models** (hence **M = 1**) wherever `d = 1` is fixed, because the
  amended design rule is `N = d+1`. This is `02` (entries 1–3) and `07`.
* **M = 2** in `03`, `04` and `06`. Those files never fix `d`; they fix only
  `M = 2`, hence `N = 3`, with `E_1, E_2` free symbols. Read at **d = 2**
  (plant order `n = 1`) the configuration is `N = 3 = d+1`, which satisfies
  the amended rule.
* `07_instance.kyx` pins `phi = 1`, `Gamma = 2`, `theta* = 1`, `sigma = 1`,
  `alpha* = (1/2, 1/2)`, `thetahat(0) = (0, 2)` — exactly the amended
  instance of `coq/SLA_Instance.v`.

Two modelling devices recur:

* **The normalisation `m^2 = 1 + phi^T phi`.** dL terms admit division, but
  differential induction over rational functions is fragile, so instead of
  writing `eps = e/m^2` a state variable `r` stands for `1/m^2`, carrying the
  derivative that `1/(1+phi^T phi)` really has
  (`r' = -2 (phi . phi') r^2`), with `r > 0` in the evolution domain. The
  regressor itself is time varying, `phi' = q` with `q` a constant symbol.
* **Positive diagonal `Gamma`.** `theta~^T Gamma^-1 theta~ / 2` is multiplied
  through by `det(Gamma) > 0` where that keeps every term polynomial. Scaling
  a Lyapunov function by a positive constant does not change its sublevel
  sets, so the statement proved is equivalent to (4.22)/(4.23).

## 4. What each file contains

| File | Dissertation eqs. | Coq counterpart | Statement |
|---|---|---|---|
| `01_first_level.kyx` | 4.19, 4.22, 4.23 | `V1`, `V1_dyn`, `V1_nonincreasing` | `V = theta~^T Gamma^-1 theta~/2` is nonincreasing along `thetahat' = -Gamma eps phi`; plus the exact identity `Vdot = -eps^2 m^2` |
| `02_hull_invariance.kyx` | 4.41, 4.44, 4.45 | **`hull_invariance`**, `theta_star_in_hull`, `ea_zero` | **the main theorem**: if `sum_i alpha*_i thetahat_i(0) = theta*` then that holds for all `t >= 0`; also the Lyapunov-function route (`W = tha^2/2Gamma`), and `e_alpha == 0`. Entries 1–3 at `N = 2 = d+1`; entry 4 retains `N = 3` on purpose (see §7) |
| `03_second_level.kyx` | 4.49–4.52, 4.56–4.58 | `E_alpha_star`, `alpt_dyn`, `Vr_dyn`, `Vr_nonincreasing` | elimination of `alpha*_N`; the *reduced* Lyapunov function `alpha~^T alpha~/2` is a differential invariant of (4.56) |
| `04_eq458_discrepancy.kyx` | **4.57, 4.58** | `Vb_dyn`, **`Vb_deriv_differs_from_4_58`**, **`Vb_deriv_can_be_positive`** | **the refutation of (4.58)** — see §5 |
| `05_eq458_dI_fails.kyx` | 4.57 | — | the corresponding *negative* observation in the prover: `dI` does not close on the dissertation's candidate. **Expected not to prove.** |
| `06_slaff.kyx` | 4.66, 4.68, 4.69 | `Mf_psd`, `qres_zero`, `VrF_nonpos` | `M_f >= 0` along `M_f' = -sigma M_f + E^T E`; the residual `M_f alpha* + v_f` vanishes when `e_alpha = 0`; the SLAFF Lyapunov function is nonincreasing |
| `07_instance.kyx` | 4.51, 4.66, 4.69 | `inst_hull_invariance`, `inst_astar_unique`, `inst_models_are_distinct`, `inst_E_nonzero`, `qres_zero` | the concrete non-vacuous instance, at the amended `d = 1, N = 2, M = 1` |
| `08_design_rule.kyx` | design rule (pp. 23, 28, 60, 64, 72, 83) | `design_rule_exact`, `more_vertices_not_unique`, `inst_astar_unique` | **the amendment**: at `N = d+1` the convex coefficients are unique; at `N > d+1` they are a continuum, and `E_f` degenerates |

## 5. The (4.58) discrepancy — what is and is not established here

The Coq development's first "result that does not hold as stated" is that the
dissertation's Lyapunov candidate

```
V = ( alpha~^T alpha~ + (1.alpha~)^2 ) / (2 gamma)                     (4.57)
```

does not have the derivative claimed in (4.58). The exact derivative along
the second-level error dynamics (4.56) is

```
Vdot = -( E alpha~ + (1.alpha~)(1.E) ) * ( E alpha~ + e_alpha/m^2 )
```

and **it can be strictly positive**, so (4.57) is not a Lyapunov function.

This folder separates two very different kinds of evidence, and the reader
should keep them apart:

1. **A genuine, machine-checked refutation** lives in
   `04_eq458_discrepancy.kyx`. Its entries are pure real-arithmetic formulas
   discharged by KeYmaera X's `QE`:
   * the exact Lie derivative of (4.57) along (4.56) equals
     `-(E alpha~ + (1.alpha~)(1.E)) (E alpha~ + e_alpha/m^2)`;
   * there exist `E_f` and `alpha~_f` (explicitly `E = (2,-1)`,
     `alpha~ = (-1/3,-5/3)`, giving `E alpha~ = 1`, `1.alpha~ = -2`,
     `1.E = 1`, `e_alpha = 0`) at which that derivative is `+1 > 0`;
   * at that same state (4.58) would give `-3`, so the two disagree;
   * by contrast the *reduced* candidate `alpha~^T alpha~ / 2` has a
     derivative that is `<= 0` for **every** state when `e_alpha = 0`.

   Together these refute (4.58) as stated: it asserts a quantity that is
   `<= 0` whenever `e_alpha = 0`, and there is a reachable state where the
   true value is positive.

   All five were discharged by `QE` in well under a second each; see
   `verification-log.txt`.

2. **A failed proof attempt**, in `05_eq458_dI_fails.kyx`, is *not* a
   refutation. Both of its entries came back `UNFINISHED` (exit 255), which
   means only that `dI` and `ODE` did not close those goals — a stronger
   tactic, or a cleverer invariant, is not ruled out by that outcome alone.
   It is included because the contrast with `03_second_level.kyx` is
   informative: there the *same* `implyR(1); dI(1)` closes the *same*
   statement in 527 ms once the Lyapunov function is the reduced one. The
   contrast was observed, but the weight of the claim rests entirely on
   point 1.

The corrected statement, `Vdot = -gamma (E alpha~)^2 - gamma (E alpha~)
(e_alpha/m^2)`, is eq. (24) of Narendra–Wang–Chen and is what
`03_second_level.kyx` proves.

## 6. The amended design rule, and what each file did about it

`../NOTE_convex_uniqueness.md` corrects the dissertation's design rule from
`N >= 2n+1` to **`N = 2n+1 = d+1` exactly**. The counting is: `N` unknown
coefficients against `d+1` equations (`d` coordinates plus sum-to-one), so the
family of valid `alpha*` has dimension `N - (d+1)`, zero **iff** `N = d+1`.
The inequality delivers existence — which is all the dissertation's own
justification claims — but the second level *identifies* `alpha*_f`, and that
needs `alpha*_f` to be a point.

`08_design_rule.kyx` is the dL rendering of this, and it is a good fit: the
whole argument is first-order real arithmetic, which `QE` settles outright.
It proves, all at `d = 1`:

* at `N = d+1 = 2`, any two vertices `v0 != v1` force the coefficients — the
  general statement, not just the instance (`design_rule_exact`);
* the amended instance's `alpha* = (1/2, 1/2)` is therefore forced
  (`inst_astar_unique`);
* at `N = 3 > d+1` with vertices `(0, 2, 1)`, the coefficients `(s, s, 1-2s)`
  are convex and reproduce `theta* = 1` for **every** `s` in `[0, 1/2]`, and
  two distinct members are exhibited both explicitly and existentially
  (`more_vertices_not_unique`);
* the same degeneracy seen through the regressor: at `N = 3`,
  `E_f = (-x/2, +x/2)` with `x = e^{-t}`, so `E_f . (1,1) = 0` for every `t` —
  `E_f` is rank 1 in `R^2` forever, and its null direction is exactly the
  direction in which the `alpha*` family runs. At `N = 2` the single
  component of `E_f` is nonzero, i.e. full rank.

Per-file decisions, and the reasoning:

| File | Decision | Why |
|---|---|---|
| `01_first_level.kyx` | **unchanged, not re-run** | `d = 2`, single model; `N` never appears. The first level is per-model and the design rule plays no role. |
| `02_hull_invariance.kyx` | **moved to `N = 2`**, plus one `N = 3` entry retained | It is the one file that fixes `d = 1` *and* a model count, so at `N = 3` it was outside the rule. Entries 1–3 are now at `N = 2 = d+1`. Entry 4 keeps `N = 3` deliberately: note §7 lists hull invariance among the results the amendment does not affect, and entry 4 is the machine-checked form of that — the proof consumes only the *existence* of `alpha*`, so it still closes in the degenerate configuration. |
| `03_second_level.kyx` | **comment only**, re-run | Fixes only `M = 2`, hence `N = 3`, with `E_1, E_2` free symbols and free rates; `d` never appears. Read at `d = 2` this is `N = 3 = d+1`, i.e. compliant. |
| `04_eq458_discrepancy.kyx` | **comment only**, re-run | Same reading at `d = 2`. Additionally, the content is pure arithmetic in `Ea`, `Sb`, `SE`, `ra`, and the counterexample is exhibited directly in the `(E, alphatilde)` coordinates that (4.56) acts on — nothing depends on the hull being non-degenerate. Note §7 lists this finding as unaffected. |
| `05_eq458_dI_fails.kyx` | **unchanged, not re-run** | Companion to `04`; same reading, and its content is the *absence* of a proof. |
| `06_slaff.kyx` | **comment only**, re-run | Same reading at `d = 2`. |
| `07_instance.kyx` | **rebuilt at `d = 1, N = 2, M = 1`** | It fixed `d = 1` with three vertices `(0, 2, 1)` — precisely the degenerate case, where `(1/2,1/2,0)` and `(0,0,1)` both work. Now `v = (0, 2)`, `alpha* = (1/2, 1/2)`, provably unique. |
| `08_design_rule.kyx` | **new** | The amendment itself. |

The rebuild of `07` is a strict improvement in test strength, not just a
change of numbers. In the old `N = 3` instance the last model was initialised
exactly at `theta*`, so `eps_M`, `E_f alpha*` and `v_f` were all identically
zero and several entries were vacuously `0 = 0`. At `N = 2` with `v = (0,2)`
the pivot model is at `2`, so

```
eps_M(t) = e^{-t}/2 ,   E_f(t) = -e^{-t} ,
M_f(t)   = e^{-t} - e^{-2t} ,   v_f(t) = -(e^{-t} - e^{-2t})/2
```

are all nonzero, and the last entry of `07` proves that the residual
`M_f alpha*_f + v_f` *still* vanishes identically. That is exactly the
configuration in which (4.69)'s omission of the `v_f` term would matter, so
the amended instance tests the second reported finding much harder than the
original one did.

## 7. What could not be encoded in dL, and why

KeYmaera X is a theorem prover for dL formulas about hybrid programs. It is
not a general-purpose proof assistant: there are no higher-order functions,
no user-defined inductive types, no dependent types, no induction over an
abstract natural number, and no quantification over functions. The following
parts of `coq/` therefore have **no** counterpart here.

* **Everything stated for an arbitrary dimension.** `coq/SLA_Prelim.v`'s
  `Sum n f` and `dot n u v`, and with them eqs. **4.15, 4.28, 4.35, 4.49** in
  their general `forall n` / `forall N` form, cannot be written: a dL term
  has no `sum_{j<n}`. Every statement here is a fixed-arity instance
  (d = 1 or 2; N = 2 or 3). The Coq proofs are by induction on `n`; that
  induction has no dL analogue.
* **Quantification over an abstract number of models.** `hull_invariance` in
  Coq is proved for every `N` and every `alpha*` with `sum alpha* = 1`. Here
  it is proved for N = 2 with symbolic `alpha*_0, alpha*_1` constrained by
  `a0+a1 = 1` (and, separately, for N = 3), which are those instances only.
* **Appendix A, as a general theorem** (`coq/SLA_AppendixA.v`, Theorems 1 and
  2, `theorem1_uniqueness`, `theorem2_uniqueness`, `design_rule_exact`,
  `more_vertices_not_unique`). These are affine-dimension and convexity
  arguments about `R^n` with `n` abstract; they are pure algebra with no ODE
  content, and they need induction over `n`. `08_design_rule.kyx` proves the
  **`d = 1` instances** of `design_rule_exact` and `more_vertices_not_unique`
  by QE — which the amendment note itself identifies as "the smallest
  instance of the same failure" — but the `forall n` statements, and the
  simplex construction of Theorem 2, remain outside dL.
* **`Mf_psd` in full generality.** Coq proves `x^T M_f x >= 0` for every
  vector `x` in `R^M`. Here `x` is a pair of *constant symbols* `x1, x2`, so
  the M = 2 statement is faithful; but there is no way to say "for all
  vectors of length M" for symbolic M.
* **The integrating-factor identities (4.64/4.65 ↔ 4.66)**
  (`Mf_integrating_factor`, `vf_integrating_factor`). These equate a
  convolution integral with an ODE. dL has no integral operator, and the
  proof needs `exp`. The ODE form (4.66) is what is modelled here; the
  equivalence with the integral form is not.
* **Anything involving `exp` in closed form.** `coq/SLA_Instance.v` computes
  `thetahat_i(t) = 1 + (v_i - 1) e^{-t}` and `M_f(t) = c_ij(e^{-t} -
  e^{-2t})`. dL terms are polynomial/rational; there is no `exp`. In
  `07_instance.kyx` the same instance is given by its *ODE* and every
  property is proved by differential induction instead of by solving.
* **The mean-value-theorem plumbing** (`nonincr_of_nonpos_deriv`,
  `quad_zero`). In dL this is not a lemma one states but the built-in meaning
  of differential induction, so it is absorbed into the `dI`/`dbx` rules
  rather than encoded.
* **The asymptotic theory** the Coq development also omits: Barbalat's lemma,
  `L^2` membership of `eps m`, persistency of excitation and parameter
  convergence, and the projection operator of (4.59).
* **The dissertation's `V` being non-invariant, as a dL theorem.** Refuting a
  box formula `[ODE] P` requires proving the diamond formula `<ODE> !P`,
  which for this non-solvable ODE would need a liveness (differential
  variant) argument. That was not attempted; the refutation is carried by
  the arithmetic facts of `04_eq458_discrepancy.kyx` instead (§5).

Finally, a modelling caveat rather than a limitation: in `01`, `02` and `06`
some facts are supplied as **evolution domain constraints** (`r > 0`, and the
positive-semidefiniteness of `M_f` in the last entry of `06`) rather than
proved simultaneously. Each is separately justified — `r > 0` because
`r = 1/(1+phi^T phi)`, and `M_f >= 0` by the first entry of `06` — but the
reader should note that a dL box formula with an evolution domain constraint
quantifies only over trajectories that stay inside it.
