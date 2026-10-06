# Amendment note: the design rule must read `N = 2n + 1`, not `N ≥ 2n + 1`

**Status:** the mathematics of Chapter 4 is unaffected. What changes is one
inequality in the design rule, and one sentence about what the second level
converges *to*. Appendix A already proves the corrected version; nothing in it
needs to be redone.

---

## 1. The issue in one line

`N ≥ 2n + 1` guarantees that a representation `θ*ₚ = Σ αᵢ* θ̂ᵢ(0)` **exists**.
It does not guarantee that it is **unique**. The claim that `α_f → α*_f`
needs uniqueness, and uniqueness holds only at `N = 2n + 1` exactly.

## 2. Where the dissertation states it

| Doc page | Passage |
|---|---|
| p. 23 | *"i = 1, ..., N, com N ≥ 2n + 1, modelos de identificação por regressão linear"* (Ch. 2 setup) |
| p. 28 | *"necessitamos de um número de modelos N ≥ 2n + 1, sendo necessários pelo menos N = 2n + 1 modelos pois uma combinação linear de 2n + 1 vetores pertencentes ao R²ⁿ tem dimensionalidade máxima igual a 2n"* |
| p. 60 | *"i = 1, ..., N, com N ≥ 2n + 1"* (Ch. 4 setup, just above (4.9)) |
| p. 64 | *"são necessários pelo menos N = 2n + 1 modelos de identificação ... precisamos de um número mínimo de modelos a partir do qual seja possível a existência de pelo menos uma representação"* |
| p. 72 | *"escolher os vértices de um fecho convexo de 2n + 1 vértices que contém a região"* |
| p. 83 | *"a partir de um conjunto de N ≥ 2n + 1"* (conclusions) |

Two things are worth noticing in these passages.

First, **the justification given is explicitly an existence argument** — *"seja
possível a existência de pelo menos uma representação"*. That argument is
correct. It establishes a lower bound `N ≥ 2n + 1` and nothing more, and it was
never advertised as doing more.

Second, **the text already contains the right number.** Pages 28 and 64 both
say `N = 2n + 1` when explaining *why* the bound is what it is; only the
formal hypothesis is written with `≥`. So the amendment aligns the hypothesis
with the reasoning that is already in the text.

Page 64 additionally requires *"garantir que, inicialmente, a dimensionalidade
do fecho seja a mesma da região de incerteza"* — the hull must be
full-dimensional. That condition is exactly what makes the amendment free: see
§6.

## 3. Why existence is not uniqueness

Let the vertices be `v₁, …, v_N ∈ R^d` (here `d = 2n`). The coefficients solve

```
Σ αᵢ vᵢ = θ*ₚ        (d equations)
Σ αᵢ   = 1           (1 equation)
```

That is `N` unknowns against `d + 1` equations. Generically the solution set is
an affine set of dimension

```
N − (d + 1)
```

intersected with the nonnegativity constraints `αᵢ ≥ 0`. It is a single point
**iff `N = d + 1`**. For an interior `θ*ₚ` and `N > d + 1` the nonnegativity
constraints are slack, so the solution set stays positive-dimensional: a
continuum of valid `α*`.

Note this counting does not involve `d` on its own — only `N` against `d + 1`.
**Passing to higher dimension does not remove the problem.**

## 4. The hexagon counterexample

A hexagon in `R²` is the natural test of the "higher dimensions are fine"
intuition, and it fails. Take an **irregular** convex hexagon in general
position (verified: all cross products same sign, no three vertices collinear —
so this is not an artefact of symmetry or degeneracy):

```
v₀ = (0,0)   v₁ = (4,0)   v₂ = (6,3)   v₃ = (5,6)   v₄ = (2,7)   v₅ = (−1,4)
```

and the interior point `p = (8/3, 10/3)`. Here `N = 6`, `d = 2`, so the
solution family has dimension `6 − 3 = 3`. Three members of it, each with
nonnegative entries summing to 1 and each reproducing `p` exactly:

```
α = ( 1/6,    1/6,   1/6,    1/6,  1/6, 1/6  )
α = ( 79/720, 21/80, 19/360, 1/4,  1/8, 1/5  )
α = ( 19/80,  9/80,  13/60,  1/10, 1/4, 1/12 )
```

For a regular hexagon the same point can be read off the picture without
algebra: the centre is `½v₀ + ½v₃`, and `½v₁ + ½v₄`, and `⅙Σvᵢ`.

Nonzero volume and unique coefficients pull in opposite directions:

| | requires |
|---|---|
| hull has nonzero `d`-volume | `N ≥ d + 1` |
| coefficients are unique | `N ≤ d + 1` (with affine independence) |
| **both** | **`N = d + 1 = 2n + 1`** |

## 5. What actually depends on uniqueness

The second-level estimator treats `α*_f` as the true parameter to be
identified. The claim

> *"a convergência de α_f para α\*_f"*

presupposes that `α*_f` **is a point**. When `N > 2n + 1` it is a
positive-dimensional set and there is no such target.

The degeneracy also shows up analytically. In the `N = 3`, `d = 1` instance
formerly used in `coq/SLA_Instance.v`, the second-level regressor is

```
E_f(t) = (e^{−t}/2) · (−1, 1)
```

which is **rank 1 in R² for every t** — always parallel to `(−1,1)`. Its null
direction `(1,1)` is exactly the direction along which the family of valid
`α*` runs. The non-uniqueness of `α*` and the rank deficiency of `E_f` are the
same fact seen twice, so the second-level regression is structurally
under-determined there.

## 6. The amendment

**Replace `N ≥ 2n + 1` by `N = 2n + 1` at pages 23, 28, 60, 64, 72 and 83.**

This costs nothing, for three reasons.

1. **Appendix A already proves the corrected statement.** Theorem 2 builds
   exactly `p + 1 = d + 1` vertices — the base vertex `w⁻` together with
   `w⁻ + p·e_k·(w_k⁺ − w_k⁻)` for `k = 1..p`. These are affinely independent,
   i.e. a genuine simplex, so barycentric coordinates are unique. Appendix A
   needs no change; it was always the `N = d + 1` construction.

2. **The non-degeneracy condition on p. 64 then delivers uniqueness for free.**
   At `N = d + 1` exactly, "the hull has the same dimensionality as the
   uncertainty region" is *equivalent* to affine independence of the vertices,
   which is *equivalent* to uniqueness of `α*`. The condition you already
   require is precisely the one needed.

3. **No theorem of Chapter 4 is weakened.** Every identity in (4.9)–(4.69) is
   conditioned on *"let `α*` be some vector with `Σα* = 1`, `α* ≥ 0`,
   `θ*ₚ = Σα*ᵢθ̂ᵢ(0)`"*. Existence is all they consume. Restricting `N` to
   `d + 1` only shrinks the set of admissible configurations, so every theorem
   continues to hold.

### Alternative repair, if `N > 2n + 1` is wanted

Keep `N ≥ 2n + 1` and weaken the convergence claim: state that the *combination*
`Σα̂ᵢθ̂ᵢ → θ*ₚ` converges, not that `α̂ → α*`. The identification objective
only needs the former. Then `α̂` wandering on a positive-dimensional set is
harmless and no claim is overstated. This is a legitimate option; it just has
to be chosen deliberately.

## 7. What is **not** affected

- Convex-hull invariance (4.41)–(4.45), including `hull_invariance`.
- `E_f α*_f = −ε_N + e_α/m²` (4.49)/(4.51).
- Everything about the first level (4.9)–(4.30).
- The SLA and SLAFF Lyapunov analyses (4.52)–(4.69), including the two
  previously reported findings about (4.58) and (4.69).
- Appendix A, in full.

## 8. Machine-checked companions

| Fact | Where |
|---|---|
| Appendix A vertices give **unique** coefficients | `coq/SLA_AppendixA.v`, `theorem1_uniqueness`, `theorem2_uniqueness` |
| `N = d + 1` gives existence **and** uniqueness | `coq/SLA_AppendixA.v`, `design_rule_exact` |
| `N > d + 1` admits two distinct representations | `coq/SLA_AppendixA.v`, `more_vertices_not_unique` |
| Chapter 4 now assumes `N = d + 1` | `coq/SLA_Chapter4.v`, `H_N_exact` |
| The instance satisfies it, with `α*` provably unique | `coq/SLA_Instance.v`, `inst_astar_unique` |

The hexagon computation of §4 is arithmetic over `Q` and is reproduced in
`coq/SLA_AppendixA.v` in its 1-dimensional form (three points on a line), which
is the smallest instance of the same failure.
