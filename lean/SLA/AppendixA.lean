/-
# Appendix A: convex combinations, and the design rule `N ≥ 2n + 1`

Lean 4 port of `coq/SLA_AppendixA.v`.

These are the two theorems the dissertation invokes (Appendix A, used in
Chapter 2 and again in Chapter 4 just above eq. 4.46) to justify

    N ≥ 2n + 1 = d + 1   models,      d = 2n = dim θ*ᵖ,

namely that the box of uncertainty in `ℝ^d` — the polytope with `2^d` vertices
given by all combinations of the known bounds `aᵢ⁻, aᵢ⁺, bᵢ⁻, bᵢ⁺` — is contained
in a simplex with only `d+1` vertices, so every point of the box, and in
particular `θ*ᵖ`, is a convex combination of `d+1` chosen parameter vectors.

* Theorem 1 (A.1–A.10): the unit box `[0,1]^p`.
* Theorem 2 (A.11): a general box `[wᵢ⁻, wᵢ⁺]`.

Vertices are indexed by `Fin (p+1)`: `Fin.castSucc k` is the `k`-th non-trivial
vertex and `Fin.last p` is the base vertex (the origin in Theorem 1, `w⁻` in
Theorem 2).
-/
import SLA.Prelim

noncomputable section

namespace SLA
namespace AppendixA

variable {p : ℕ}

/-- (A.4)/(A.7): the simplex coefficients. -/
def alph (p : ℕ) (u : Fin p → ℝ) : Fin (p + 1) → ℝ :=
  Fin.lastCases (1 - ∑ i, u i / p) fun k => u k / p

@[simp] theorem alph_castSucc (u : Fin p → ℝ) (k : Fin p) :
    alph p u k.castSucc = u k / p := by
  simp [alph]

@[simp] theorem alph_last (u : Fin p → ℝ) :
    alph p u (Fin.last p) = 1 - ∑ i, u i / p := by
  simp [alph]

/-- (A.6) -/
theorem sum_u_bounds (hp : 0 < p) (u : Fin p → ℝ) (hu : ∀ i, u i ∈ Set.Icc (0 : ℝ) 1) :
    0 ≤ ∑ i, u i / (p : ℝ) ∧ ∑ i, u i / (p : ℝ) ≤ 1 := by
  have hpR : (0 : ℝ) < p := Nat.cast_pos.2 hp
  refine ⟨Finset.sum_nonneg fun i _ => div_nonneg (hu i).1 hpR.le, ?_⟩
  rw [← Finset.sum_div, div_le_one hpR]
  calc ∑ i, u i ≤ ∑ _i : Fin p, (1 : ℝ) := Finset.sum_le_sum fun i _ => (hu i).2
    _ = (p : ℝ) := by simp

/-- (A.5)+(A.8): the coefficients are legitimate convex weights. -/
theorem alph_bounds (hp : 0 < p) (u : Fin p → ℝ) (hu : ∀ i, u i ∈ Set.Icc (0 : ℝ) 1)
    (k : Fin (p + 1)) : alph p u k ∈ Set.Icc (0 : ℝ) 1 := by
  have hpR : (0 : ℝ) < p := Nat.cast_pos.2 hp
  have hp1 : (1 : ℝ) ≤ p := by exact_mod_cast hp
  refine Fin.lastCases ?_ ?_ k
  · rw [alph_last]
    obtain ⟨h0, h1⟩ := sum_u_bounds hp u hu
    exact ⟨by linarith, by linarith⟩
  · intro i
    rw [alph_castSucc]
    refine ⟨div_nonneg (hu i).1 hpR.le, ?_⟩
    rw [div_le_one hpR]
    exact le_trans (hu i).2 hp1

/-- (A.10) -/
theorem alph_sum (u : Fin p → ℝ) : ∑ k, alph p u k = 1 := by
  rw [Fin.sum_univ_castSucc]
  simp

/-! ## Theorem 1 (A.1–A.10): the unit box `[0,1]^p`

The containing simplex `P_{u,2}` has the origin (index `Fin.last p`) and the `p`
vectors `p·e_k` as vertices. -/

/-- the vertices of `P_{u,2}` -/
def V1 (p : ℕ) (k : Fin (p + 1)) (j : Fin p) : ℝ := if k = j.castSucc then (p : ℝ) else 0

/-- (A.9): every point of the unit box is the corresponding convex combination
of the `p+1` vertices.

Note that the box bounds `0 ≤ wᵢ ≤ 1` are *not* needed for the representation —
only for the convexity of the coefficients (`theorem1_convexity`).  The Coq
version carries them as an unused hypothesis. -/
theorem theorem1_representation (hp : 0 < p) (w : Fin p → ℝ) (j : Fin p) :
    ∑ k, alph p w k * V1 p k j = w j := by
  have hpR : (p : ℝ) ≠ 0 := (Nat.cast_pos.2 hp).ne'
  have hlast : V1 p (Fin.last p) j = 0 := if_neg (Fin.castSucc_lt_last j).ne'
  rw [Fin.sum_univ_castSucc, hlast, mul_zero, add_zero]
  have hterm : ∀ k : Fin p, alph p w k.castSucc * V1 p k.castSucc j
      = if k = j then w k / (p : ℝ) * (p : ℝ) else 0 := by
    intro k
    rw [alph_castSucc, V1]
    by_cases h : k = j
    · subst h; simp
    · rw [if_neg fun hc => h (Fin.castSucc_inj.mp hc), if_neg h, mul_zero]
  rw [Finset.sum_congr rfl fun k _ => hterm k, Finset.sum_ite_eq' Finset.univ j]
  simp [hpR]

theorem theorem1_convexity (hp : 0 < p) (w : Fin p → ℝ) (hw : ∀ i, w i ∈ Set.Icc (0 : ℝ) 1) :
    (∑ k, alph p w k = 1) ∧ ∀ k, alph p w k ∈ Set.Icc (0 : ℝ) 1 :=
  ⟨alph_sum w, alph_bounds hp w hw⟩

/-! ## Theorem 2 (A.11): a general box `[wᵢ⁻, wᵢ⁺]`

The containing simplex `W_{x,2}` has `w⁻` (index `Fin.last p`) and
`w⁻ + p·e_k·(w_k⁺ − w_k⁻)` as vertices. -/

/-- the normalised coordinates of `w` inside the box -/
def u2 (wlo whi w : Fin p → ℝ) (i : Fin p) : ℝ := (w i - wlo i) / (whi i - wlo i)

/-- the vertices of `W_{x,2}` -/
def V2 (p : ℕ) (wlo whi : Fin p → ℝ) (k : Fin (p + 1)) (j : Fin p) : ℝ :=
  wlo j + (if k = j.castSucc then (p : ℝ) * (whi j - wlo j) else 0)

theorem u2_bounds (wlo whi w : Fin p → ℝ) (hnd : ∀ i, wlo i < whi i)
    (hbox : ∀ i, w i ∈ Set.Icc (wlo i) (whi i)) (i : Fin p) :
    u2 wlo whi w i ∈ Set.Icc (0 : ℝ) 1 := by
  obtain ⟨h1, h2⟩ := hbox i
  have h3 : 0 < whi i - wlo i := sub_pos.2 (hnd i)
  refine ⟨div_nonneg (by linarith) h3.le, ?_⟩
  rw [u2, div_le_one h3]
  linarith

/-- (A.11) -/
theorem theorem2_representation (hp : 0 < p) (wlo whi w : Fin p → ℝ)
    (hnd : ∀ i, wlo i < whi i) (j : Fin p) :
    ∑ k, alph p (u2 wlo whi w) k * V2 p wlo whi k j = w j := by
  have hpR : (p : ℝ) ≠ 0 := (Nat.cast_pos.2 hp).ne'
  have hj : whi j - wlo j ≠ 0 := (sub_pos.2 (hnd j)).ne'
  have hstep : ∀ k : Fin (p + 1), alph p (u2 wlo whi w) k * V2 p wlo whi k j
      = wlo j * alph p (u2 wlo whi w) k
        + (if k = j.castSucc then
            alph p (u2 wlo whi w) k * ((p : ℝ) * (whi j - wlo j)) else 0) := by
    intro k
    by_cases h : k = j.castSucc <;> simp [V2, h] <;> ring
  rw [Finset.sum_congr rfl fun k _ => hstep k, Finset.sum_add_distrib, ← Finset.mul_sum,
    alph_sum, Finset.sum_ite_eq' Finset.univ j.castSucc]
  simp only [Finset.mem_univ, if_true, alph_castSucc, u2]
  field_simp
  ring

theorem theorem2_convexity (hp : 0 < p) (wlo whi w : Fin p → ℝ)
    (hnd : ∀ i, wlo i < whi i) (hbox : ∀ i, w i ∈ Set.Icc (wlo i) (whi i)) :
    (∑ k, alph p (u2 wlo whi w) k = 1)
      ∧ ∀ k, alph p (u2 wlo whi w) k ∈ Set.Icc (0 : ℝ) 1 :=
  ⟨alph_sum _, alph_bounds hp _ (u2_bounds wlo whi w hnd hbox)⟩

/-! ## Uniqueness of the barycentric coefficients

Both containing simplices have exactly `p + 1` affinely independent vertices, so
the convex representation of a point is not merely *possible* but *unique*.  This
is the half of the design rule that the dissertation's own justification does not
supply, and it is what forces `N = 2n+1` rather than `N ≥ 2n+1`; see
`../NOTE_convex_uniqueness.md`.

Neither uniqueness theorem needs the box-membership bounds — only `Σ a = 1` and
the representation identity.  (The representation theorems above do not need them
either.) -/

/-- At coordinate `i` only the `i`-th vertex of `P_{u,2}` contributes. -/
theorem sum_a_V1 (a : Fin (p + 1) → ℝ) (i : Fin p) :
    ∑ k, a k * V1 p k i = a i.castSucc * (p : ℝ) := by
  have h : ∀ k : Fin (p + 1), a k * V1 p k i
      = if k = i.castSucc then a k * (p : ℝ) else 0 := by
    intro k
    rw [V1]
    by_cases hk : k = i.castSucc <;> simp [hk]
  rw [Finset.sum_congr rfl fun k _ => h k, Finset.sum_ite_eq' Finset.univ i.castSucc]
  simp

/-- The same for the general box: every vertex contributes `wlo i`, and only the
`i`-th one contributes anything more. -/
theorem sum_a_V2 (wlo whi : Fin p → ℝ) (a : Fin (p + 1) → ℝ) (hsum : ∑ k, a k = 1)
    (j : Fin p) :
    ∑ k, a k * V2 p wlo whi k j
      = wlo j + a j.castSucc * ((p : ℝ) * (whi j - wlo j)) := by
  have h : ∀ k : Fin (p + 1), a k * V2 p wlo whi k j
      = wlo j * a k
        + (if k = j.castSucc then a k * ((p : ℝ) * (whi j - wlo j)) else 0) := by
    intro k
    rw [V2]
    by_cases hk : k = j.castSucc <;> simp [hk] <;> ring
  rw [Finset.sum_congr rfl fun k _ => h k, Finset.sum_add_distrib, ← Finset.mul_sum, hsum,
    Finset.sum_ite_eq' Finset.univ j.castSucc]
  simp

/-- **Uniqueness for Theorem 1**: the coefficients of a convex (indeed, of any
affine) representation over the `p+1` vertices of `P_{u,2}` are forced. -/
theorem theorem1_uniqueness (hp : 0 < p) (w : Fin p → ℝ) (a : Fin (p + 1) → ℝ)
    (hsum : ∑ k, a k = 1) (hrep : ∀ j, ∑ k, a k * V1 p k j = w j) :
    ∀ k, a k = alph p w k := by
  have hpR : (p : ℝ) ≠ 0 := (Nat.cast_pos.2 hp).ne'
  have hlow : ∀ i : Fin p, a i.castSucc = w i / (p : ℝ) := by
    intro i
    have h := hrep i
    rw [sum_a_V1] at h
    rw [eq_div_iff hpR]
    exact h
  intro k
  refine Fin.lastCases ?_ ?_ k
  · rw [alph_last]
    have h := Fin.sum_univ_castSucc a
    rw [hsum] at h
    rw [Finset.sum_congr rfl fun i _ => hlow i] at h
    linarith
  · intro i
    rw [alph_castSucc]
    exact hlow i

/-- **Uniqueness for Theorem 2** (A.11): the vertices `w⁻`, `w⁻ + p·e_k(w_k⁺−w_k⁻)`
are affinely independent, so barycentric coordinates over them are unique. -/
theorem theorem2_uniqueness (hp : 0 < p) (wlo whi w : Fin p → ℝ)
    (hnd : ∀ i, wlo i < whi i) (a : Fin (p + 1) → ℝ) (hsum : ∑ k, a k = 1)
    (hrep : ∀ j, ∑ k, a k * V2 p wlo whi k j = w j) :
    ∀ k, a k = alph p (u2 wlo whi w) k := by
  have hpR : (p : ℝ) ≠ 0 := (Nat.cast_pos.2 hp).ne'
  have hlow : ∀ i : Fin p, a i.castSucc = u2 wlo whi w i / (p : ℝ) := by
    intro i
    have hne : whi i - wlo i ≠ 0 := (sub_pos.2 (hnd i)).ne'
    have h := hrep i
    rw [sum_a_V2 wlo whi a hsum i] at h
    rw [u2, div_div, eq_div_iff (mul_ne_zero hne hpR)]
    linear_combination h
  intro k
  refine Fin.lastCases ?_ ?_ k
  · rw [alph_last]
    have h := Fin.sum_univ_castSucc a
    rw [hsum] at h
    rw [Finset.sum_congr rfl fun i _ => hlow i] at h
    linarith
  · intro i
    rw [alph_castSucc]
    exact hlow i

/-! ## The design rule `N = 2n + 1`

Instantiating Theorem 2 with `p = d = 2n` and the box of known bounds gives
exactly the statement used in Chapter 4: `d+1` initial parameter vectors can be
chosen so that `θ*ᵖ` is a convex combination of them, **and the coefficients are
unique** — i.e. `N = 2n+1` models are exactly right, which is the field
`Hull.init` of `SLA.Hull` together with `Model.hN_exact`.

The dissertation writes `N ≥ 2n+1`, and its justification (page 64, *"seja
possível a existência de pelo menos uma representação"*) is an existence
argument, which only supports the lower bound.  But the second level identifies
`α*_f`, so `α*_f` must be a single point, and that needs `N ≤ d+1` as well;
`more_vertices_not_unique` below shows the failure at `N = d+2`.  See
`../NOTE_convex_uniqueness.md`.

The converse ("fewer than `d+1` points cannot span the box") is a statement about
affine dimension; the dissertation asserts it on page 64 and it is not formalised
here. -/

/-- Existence only — the statement supported by the dissertation's own argument. -/
theorem design_rule_suffices (d : ℕ) (hd : 0 < d) (alo ahi θ : Fin d → ℝ)
    (hnd : ∀ i, alo i < ahi i) (hbox : ∀ i, θ i ∈ Set.Icc (alo i) (ahi i)) :
    ∃ (vertex : Fin (d + 1) → Fin d → ℝ) (a : Fin (d + 1) → ℝ),
      (∑ k, a k = 1) ∧ (∀ k, a k ∈ Set.Icc (0 : ℝ) 1)
        ∧ ∀ j, ∑ k, a k * vertex k j = θ j := by
  refine ⟨V2 d alo ahi, alph d (u2 alo ahi θ), ?_, ?_, ?_⟩
  · exact alph_sum _
  · exact alph_bounds hd _ (u2_bounds alo ahi θ hnd hbox)
  · exact fun j => theorem2_representation hd alo ahi θ hnd j

/-- **The amended design rule**: with exactly `N = d + 1 = 2n + 1` vertices one
gets existence *and* uniqueness of the convex coefficients, which is what the
second level needs in order to have a well-defined target `α*_f`. -/
theorem design_rule_exact (d : ℕ) (hd : 0 < d) (alo ahi θ : Fin d → ℝ)
    (hnd : ∀ i, alo i < ahi i) (hbox : ∀ i, θ i ∈ Set.Icc (alo i) (ahi i)) :
    ∃ (vertex : Fin (d + 1) → Fin d → ℝ) (a : Fin (d + 1) → ℝ),
      (∑ k, a k = 1) ∧ (∀ k, a k ∈ Set.Icc (0 : ℝ) 1)
        ∧ (∀ j, ∑ k, a k * vertex k j = θ j)
        ∧ ∀ b : Fin (d + 1) → ℝ, (∑ k, b k = 1) →
            (∀ j, ∑ k, b k * vertex k j = θ j) → ∀ k, b k = a k := by
  refine ⟨V2 d alo ahi, alph d (u2 alo ahi θ), alph_sum _,
    alph_bounds hd _ (u2_bounds alo ahi θ hnd hbox),
    fun j => theorem2_representation hd alo ahi θ hnd j, ?_⟩
  intro b hbsum hbrep
  exact theorem2_uniqueness hd alo ahi θ hnd b hbsum hbrep

/-! ### More than `d+1` vertices really does destroy uniqueness

The smallest instance is `d = 1` with the three points `(0, 2, 1)`: the target
`1` is a convex combination of them in at least two different ways.  This is the
one-dimensional shadow of the hexagon example of `../NOTE_convex_uniqueness.md`
(six points in `ℝ²` carrying a 3-parameter family of representations of any
interior point).  Note the two witnesses below are the coefficient vectors of the
*old* `N = 3` instance of this development and of the degenerate alternative. -/

/-- three points on a line, `d = 1`, `N = 3 = d + 2` -/
def w3 : Fin 3 → ℝ := ![0, 2, 1]

def aA : Fin 3 → ℝ := ![1 / 2, 1 / 2, 0]

def aB : Fin 3 → ℝ := ![0, 0, 1]

@[simp] theorem w3_zero : w3 0 = 0 := rfl
@[simp] theorem w3_one : w3 1 = 2 := rfl
@[simp] theorem w3_two : w3 2 = 1 := rfl
@[simp] theorem aA_zero : aA 0 = 1 / 2 := rfl
@[simp] theorem aA_one : aA 1 = 1 / 2 := rfl
@[simp] theorem aA_two : aA 2 = 0 := rfl
@[simp] theorem aB_zero : aB 0 = 0 := rfl
@[simp] theorem aB_one : aB 1 = 0 := rfl
@[simp] theorem aB_two : aB 2 = 1 := rfl

theorem more_vertices_not_unique :
    (∑ k, aA k = 1) ∧ (∑ k, aB k = 1)
      ∧ (∀ i, aA i ∈ Set.Icc (0 : ℝ) 1) ∧ (∀ i, aB i ∈ Set.Icc (0 : ℝ) 1)
      ∧ (∑ k, aA k * w3 k = 1) ∧ (∑ k, aB k * w3 k = 1)
      ∧ aA 0 ≠ aB 0 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [Fin.sum_univ_three]; norm_num
  · rw [Fin.sum_univ_three]; norm_num
  · intro i; fin_cases i <;> norm_num [aA]
  · intro i; fin_cases i <;> norm_num [aB]
  · rw [Fin.sum_univ_three]; norm_num
  · rw [Fin.sum_univ_three]; norm_num
  · norm_num

end AppendixA
end SLA
