# Annotated copies

Same Coq code as `../`, with a block comment before every definition, lemma
and theorem explaining the **syntax**. The mathematics is assumed known; the
comments only decode the notation.

Verified: stripping all comments from these files and from `../` produces
byte-identical text, so nothing was silently changed. They also compile
independently:

```bash
source ../coqenv.sh
make
```

## Suggested reading order

| Order | File | Why |
|---|---|---|
| 1 | `SLA_Prelim.v` | The header explains how to read *any* Coq file. Read at minimum: `Sum`, `Sum_ext`, `dot`, `Deriv`, and above all **`D_ext`** — that one lemma is the idiom behind every derivative proof in the development. |
| 2 | `SLA_Chapter4.v` | Equations 4.1–4.69. Its header explains sections/hypotheses and the three-bullet shape of every derivative proof. |
| 3 | `SLA_AppendixA.v` | Appendix A. Self-contained, no sections, lighter reading. |
| 4 | `SLA_Instance.v` | Concrete numbers. Good for seeing how an abstract theorem gets applied. |

If Chapter 4 feels dense, the three landmarks worth reading first are
`e_eq_dot_tht` (4.15, the simplest complete proof), `E_alpha_star` (4.49/4.51,
the algebraic heart, commented with the goal after each tactic), and
`tht_law` (4.20/4.21, the smallest instance of the `D_ext` pattern).

## Two conventions that cause most of the confusion

**Application is juxtaposition, left-associative.** `th i t j` means
`((th i) t) j`. There are no commas. Partial application is therefore how
vectors appear: with `th : nat -> R -> nat -> R`, the term `th i t` is a
function `nat -> R`, i.e. the vector θ̂ᵢ(t). You will see `dot d (th i t) (phi t)`
constantly — that is θ̂ᵢ(t)ᵀφ(t).

**`ring` cannot divide.** An identity containing `x / 2` is rejected by `ring`
with *"not a valid ring equation"*; use `field` (which then asks you to prove
each denominator nonzero). For inequalities use `lra` (linear, reads
hypotheses) or `nra` (nonlinear, incomplete). That distinction explains most
of the tactic choices in these files.

## Where the design-rule amendment lives

- `SLA_AppendixA.v`, `theorem1_uniqueness` / `theorem2_uniqueness` — the
  Appendix A vertices give *unique* coefficients, not merely existing ones.
- `SLA_AppendixA.v`, `more_vertices_not_unique` — the counterexample: with
  `N > d+1` two different convex combinations reach the same point.
- `SLA_AppendixA.v`, `design_rule_exact` — existence **and** uniqueness at
  `N = d+1`.
- `SLA_Chapter4.v`, `H_N_exact` — the hypothesis, tightened from `≥` to `=`.
- `SLA_Instance.v`, `inst_astar_unique` — and the instance rebuilt at `N = 2`.

See `../../NOTE_convex_uniqueness.md` for the argument and the hexagon
counterexample.

## Where the two discrepancies live

- `SLA_Chapter4.v`, `Vb_dyn` and the two corollaries immediately after it —
  the factor `N` in (4.58).
- `SLA_Chapter4.v`, the comment block above `VrF_dyn` — the missing `v_f` in
  (4.69).

Both are stated as ordinary theorems, so they are checked by the compiler like
everything else. See `../README.md` for the mathematical discussion.
