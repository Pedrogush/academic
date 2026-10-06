/-
# A concrete model of every hypothesis of Chapter 4

Lean 4 port of `coq/SLA_Instance.v`.

A formalisation whose theorems live under a long list of hypotheses is worthless
if those hypotheses are contradictory: everything would then be provable
vacuously.  This file rules that out by exhibiting concrete signals for which
*every* field of `SLA.Model`, `SLA.Hull`, `SLA.SecondLevel` and
`SLA.Forgetting` is satisfied, and then instantiating the main theorems on them.

Since the amendment of the design rule to `N = 2n + 1 = d + 1` exactly (see
`../NOTE_convex_uniqueness.md`), the instance is built at

    d = 1,  N = 2 models (M = 1),  φ(t) = 1,  θ*ᵖ = 1,  z(t) = 1,  Γ = 2,

so the gradient law (4.19) is `θ̂̇ᵢ = −(θ̂ᵢ − 1)` and hence
`θ̂ᵢ(t) = 1 + (vᵢ − 1)e^{−t}` with initial values `v = (0, 2)`.
The convex coefficients `α* = (1/2, 1/2)` reproduce `θ*ᵖ = 1` from `v`, and
`Instance.astar_unique` shows they are the **only** ones — which is exactly what
`N = d + 1` buys and what the old `N = 3` instance did not have.

Consequences of dropping to two models, relative to the earlier `N = 3` version:
the last model no longer sits on `θ*ᵖ`, so `ε_{N,f}(t) = e^{−t}/2 ≠ 0`
(`eps_last_ne_zero`) and `v_f ≢ 0` (`vf_ne_zero`).  The SLAFF accumulators still
solve in closed form with `σ = 1`,

    M_f(t)ᵢⱼ = (vᵢ−2)(vⱼ−2)/4 · (e^{−t} − e^{−2t}),
    v_f(t)ᵢ  = (vᵢ−2)/4     · (e^{−t} − e^{−2t}),

and the residual `M_f α* + v_f` still vanishes identically (`qres_direct`), so
`α_f ≡ α*` satisfies both the SLA law (4.52) and the SLAFF law (4.67).
-/
import SLA.Chapter4

open scoped Matrix

noncomputable section

namespace SLA
namespace Instance

/-- the initial values of the two estimates -/
def v : Fin 2 → ℝ := ![0, 2]

/-- the convex coefficients `α*` -/
def astar : Fin 2 → ℝ := ![1 / 2, 1 / 2]

@[simp] theorem v_zero : v 0 = 0 := rfl
@[simp] theorem v_one : v 1 = 2 := rfl
@[simp] theorem v_last : v (Fin.last 1) = 2 := rfl
@[simp] theorem astar_zero : astar 0 = 1 / 2 := rfl
@[simp] theorem astar_one : astar 1 = 1 / 2 := rfl
@[simp] theorem astar_last : astar (Fin.last 1) = 1 / 2 := rfl
@[simp] theorem castSucc_zero' : (0 : Fin 1).castSucc = (0 : Fin 2) := rfl

theorem exp_sq (t : ℝ) : Real.exp (-1 * t) * Real.exp (-1 * t) = Real.exp (-2 * t) := by
  rw [← Real.exp_add]
  ring_nf

/-! ## The instance of `Model` (hypotheses 4.8, 4.17, 4.19/4.29, and `N = d+1`) -/

/-- `d = 1`, `N = 2 = d + 1`, `φ ≡ 1`, `θ*ᵖ = 1`, `z ≡ 1`, `Γ = 2`,
`θ̂ᵢ(t) = 1 + (vᵢ − 1)e^{−t}`. -/
def M0 : Model 1 1 where
  φ := fun _ _ => 1
  φ' := fun _ _ => 0
  θstar := fun _ => 1
  z := fun _ => 1
  θ := fun i t _ => 1 + (v i - 1) * Real.exp (-1 * t)
  γ := fun _ => 2
  hφ := fun _ => Deriv.const 1
  hparam := fun _ => by simp [dotProduct]
  hγ := fun _ => by norm_num
  hlaw := by
    intro i _
    have hD : Deriv (fun t : ℝ => 1 + (v i - 1) * Real.exp (-1 * t))
        (fun t => 0 + (v i - 1) * (-1 * Real.exp (-1 * t))) :=
      (Deriv.const 1).add (Deriv.const_mul (v i - 1) (Deriv.exp_linear (-1)))
    refine hD.congr (fun _ => rfl) fun t => ?_
    simp only [dotProduct, Fin.sum_univ_one, mul_one]
    ring
  -- `N = M + 1 = 2 = d + 1 = 1 + 1`: the amended design rule holds exactly.
  hN_exact := rfl

/-! ### Closed forms of the derived signals -/

@[simp] theorem M0_msq (t : ℝ) : M0.msq t = 2 := by
  norm_num [Model.msq, M0, dotProduct]

theorem M0_e (i : Fin 2) (t : ℝ) : M0.e i t = (v i - 1) * Real.exp (-1 * t) := by
  simp only [Model.e, Model.zh, M0, dotProduct, Fin.sum_univ_one, mul_one]
  ring

theorem M0_eps (i : Fin 2) (t : ℝ) : M0.eps i t = (v i - 1) * Real.exp (-1 * t) / 2 := by
  rw [Model.eps, M0_e, M0_msq]

/-- With only two models the last one is **not** initialised at `θ*ᵖ`, so unlike
the old `N = 3` instance its normalised error does not vanish. -/
@[simp] theorem M0_eps_last (t : ℝ) :
    M0.eps (Fin.last 1) t = Real.exp (-1 * t) / 2 := by
  rw [M0_eps, v_last]
  ring

theorem eps_last_ne_zero (t : ℝ) : M0.eps (Fin.last 1) t ≠ 0 := by
  have h : 0 < Real.exp (-1 * t) := Real.exp_pos _
  rw [M0_eps_last]
  positivity

theorem M0_Ev (i : Fin 1) (t : ℝ) :
    M0.Ev t i = (v i.castSucc - 2) * Real.exp (-1 * t) / 2 := by
  rw [Model.Ev, M0_eps, M0_eps_last]
  ring

/-! ## The instance of `Hull` (hypothesis 4.41), with `α*` unique -/

/-- `θ*ᵖ = 1` is the convex combination `(1/2)·0 + (1/2)·2` of the initial
estimates `v = (0, 2)`. -/
def H0 : Hull M0 where
  α := astar
  sum_eq_one := by
    show (∑ i : Fin 2, astar i) = 1
    rw [Fin.sum_univ_two]
    norm_num
  mem_Icc := by
    intro i
    fin_cases i <;> norm_num [astar]
  init := by
    intro _
    simp only [M0, mul_zero, Real.exp_zero]
    show (∑ i : Fin 2, (1 + (v i - 1) * 1) * astar i) = 1
    rw [Fin.sum_univ_two]
    norm_num

/-- **`α*` is the only convex representation of `θ*ᵖ`** by the initial estimates.

This is what `N = d + 1` buys and what the earlier `N = 3` instance of this
development lacked: there, `(1/2, 1/2, 0)` and `(0, 0, 1)` were both valid
(`AppendixA.more_vertices_not_unique`).  Note nonnegativity is not even needed —
`Σ b = 1` plus the representation identity already forces `b = α*`. -/
theorem astar_unique (b : Fin 2 → ℝ) (hsum : ∑ i, b i = 1)
    (hrep : ∀ j, ∑ i, M0.θ i 0 j * b i = M0.θstar j) :
    ∀ i, b i = astar i := by
  have h : (∑ i : Fin 2, M0.θ i 0 0 * b i) = 1 := hrep 0
  rw [Fin.sum_univ_two] at h
  rw [Fin.sum_univ_two] at hsum
  simp only [M0, mul_zero, Real.exp_zero, v_zero, v_one] at h
  norm_num at h
  have hb1 : b 1 = 1 / 2 := by linarith
  have hb0 : b 0 = 1 / 2 := by linarith
  intro i
  fin_cases i
  · show b 0 = astar 0
    rw [astar_zero]; exact hb0
  · show b 1 = astar 1
    rw [astar_one]; exact hb1

/-- `e_{α,f} ≡ 0` for this instance — at *every* time, not only for `t ≥ 0`. -/
theorem H0_ea (t : ℝ) : H0.ea t = 0 := by
  simp only [Hull.ea, H0, M0_e]
  show (∑ i : Fin 2, (v i - 1) * Real.exp (-1 * t) * astar i) = 0
  rw [Fin.sum_univ_two]
  norm_num

/-! ## The instance of `SecondLevel` (hypothesis 4.52)

With two models `E_f α*_f = −ε_{N,f}` is no longer `0 = 0`: both sides are
`−e^{−t}/2`.  This is `Hull.E_alpha_star_exact` verified by hand. -/

theorem M0_Ealp (t : ℝ) :
    ∑ k : Fin 1, M0.Ev t k * astar k.castSucc = -(Real.exp (-1 * t) / 2) := by
  simp only [Fin.sum_univ_one, M0_Ev, castSucc_zero', v_zero, astar_zero]
  ring

/-- `α_f ≡ α*` solves the second-level law (4.52), because `E_f α*_f + ε_{N,f} = 0`. -/
def L0 : SecondLevel H0 where
  γ₂ := 1
  hγ₂ := one_pos
  α := fun _ i => astar i.castSucc
  law := by
    intro i
    refine (Deriv.const (astar i.castSucc)).congr (fun _ => rfl) fun t => ?_
    rw [M0_Ealp t, M0_eps_last]
    ring

/-! ## The instance of `Forgetting` (hypotheses 4.66, 4.67)

`v_f` is genuinely nonzero now, so this instance exercises the `v_f` term that
(4.69) omits. -/

theorem M0_Mf_astar (i : Fin 1) (t : ℝ) :
    ∑ j : Fin 1, (v i.castSucc - 2) * (v j.castSucc - 2) / 4
        * (Real.exp (-1 * t) - Real.exp (-2 * t)) * astar j.castSucc
      = -((v i.castSucc - 2) / 4 * (Real.exp (-1 * t) - Real.exp (-2 * t))) := by
  simp only [Fin.sum_univ_one, castSucc_zero', v_zero, astar_zero]
  ring

/-- With `σ = 1`, `M_f(t)ᵢⱼ = (vᵢ−2)(vⱼ−2)/4·(e^{−t}−e^{−2t})` and
`v_f(t)ᵢ = (vᵢ−2)/4·(e^{−t}−e^{−2t})` solve (4.66) in closed form, and
`α_f ≡ α*` solves the SLAFF law (4.67). -/
def F0 : Forgetting H0 where
  γ₂ := 1
  hγ₂ := one_pos
  σ := 1
  hσ := one_pos
  Mf := fun t i j =>
    (v i.castSucc - 2) * (v j.castSucc - 2) / 4 * (Real.exp (-1 * t) - Real.exp (-2 * t))
  vf := fun t i => (v i.castSucc - 2) / 4 * (Real.exp (-1 * t) - Real.exp (-2 * t))
  α := fun _ i => astar i.castSucc
  Mf_init := by intro _ _; norm_num
  vf_init := by intro _; norm_num
  Mf_law := by
    intro i j
    have hD : Deriv
        (fun t : ℝ => (v i.castSucc - 2) * (v j.castSucc - 2) / 4
          * (Real.exp (-1 * t) - Real.exp (-2 * t)))
        (fun t => (v i.castSucc - 2) * (v j.castSucc - 2) / 4
          * (-1 * Real.exp (-1 * t) - -2 * Real.exp (-2 * t))) :=
      Deriv.const_mul _ ((Deriv.exp_linear (-1)).sub (Deriv.exp_linear (-2)))
    refine hD.congr (fun _ => rfl) fun t => ?_
    rw [M0_Ev, M0_Ev, ← exp_sq t]
    ring
  vf_law := by
    intro i
    have hD : Deriv
        (fun t : ℝ => (v i.castSucc - 2) / 4 * (Real.exp (-1 * t) - Real.exp (-2 * t)))
        (fun t => (v i.castSucc - 2) / 4
          * (-1 * Real.exp (-1 * t) - -2 * Real.exp (-2 * t))) :=
      Deriv.const_mul _ ((Deriv.exp_linear (-1)).sub (Deriv.exp_linear (-2)))
    refine hD.congr (fun _ => rfl) fun t => ?_
    rw [M0_Ev, M0_eps_last, ← exp_sq t]
    ring
  law := by
    intro i
    refine (Deriv.const (astar i.castSucc)).congr (fun _ => rfl) fun t => ?_
    rw [M0_Mf_astar i t, M0_Ealp t, M0_eps_last]
    ring

/-! ## The main theorems, instantiated

Convex-hull invariance holds for this instance, and it is not vacuous: both
estimates differ from `θ*ᵖ = 1` at every finite `t`, yet their fixed convex
combination is exactly `1`. -/

theorem hull_invariance_inst (t : ℝ) (ht : 0 ≤ t) (j : Fin 1) : H0.tha t j = 0 :=
  H0.hull_invariance t ht j

theorem theta_star_in_hull_inst (t : ℝ) (ht : 0 ≤ t) (j : Fin 1) :
    ∑ i, M0.θ i t j * astar i = M0.θstar j :=
  H0.theta_star_in_hull t ht j

theorem ea_zero_inst (t : ℝ) (ht : 0 ≤ t) : H0.ea t = 0 := H0.ea_zero t ht

/-- (4.51) instantiated: `E_f α*_f = −ε_{N,f}`, here `−e^{−t}/2`. -/
theorem E_alpha_star_inst (t : ℝ) (ht : 0 ≤ t) :
    ∑ i : Fin 1, M0.Ev t i * astar i.castSucc = -M0.eps (Fin.last 1) t :=
  H0.E_alpha_star_exact t ht

/-- Independent check by direct computation: the same identity obtained without
the theorem.  Agreement confirms the instance really is a model of the
hypotheses rather than an artefact of the encoding. -/
theorem hull_direct (t : ℝ) : ∑ i, M0.θ i t 0 * astar i = 1 := by
  show (∑ i : Fin 2, (1 + (v i - 1) * Real.exp (-1 * t)) * astar i) = 1
  rw [Fin.sum_univ_two]
  simp only [v_zero, v_one, astar_zero, astar_one]
  ring

/-- The estimates are genuinely distinct: model 0 never equals `θ*ᵖ`. -/
theorem models_are_distinct (t : ℝ) : M0.θ 0 t 0 ≠ M0.θstar 0 := by
  have h : 0 < Real.exp (-1 * t) := Real.exp_pos _
  show 1 + (v 0 - 1) * Real.exp (-1 * t) ≠ 1
  rw [v_zero]
  intro hc
  nlinarith

/-- … and the second-level regressor `E_f` is not identically zero either. -/
theorem E_nonzero (t : ℝ) : M0.Ev t 0 ≠ 0 := by
  have h : 0 < Real.exp (-1 * t) := Real.exp_pos _
  rw [M0_Ev, castSucc_zero', v_zero]
  intro hc
  nlinarith

/-- `v_f` really is nonzero here, so the term that (4.69) omits is not vacuous
in this instance. -/
theorem vf_ne_zero (t : ℝ) (ht : 0 < t) : F0.vf t 0 ≠ 0 := by
  have h : Real.exp (-2 * t) < Real.exp (-1 * t) := by
    apply Real.exp_lt_exp.2
    linarith
  show (v (0 : Fin 1).castSucc - 2) / 4 * (Real.exp (-1 * t) - Real.exp (-2 * t)) ≠ 0
  rw [castSucc_zero', v_zero]
  intro hc
  nlinarith

/-- The residual `M_f α*_f + v_f` of (4.69) vanishes identically here, by direct
computation as well as by the general theorem `Forgetting.qres_zero`. -/
theorem qres_direct (t : ℝ) (i : Fin 1) : F0.qres t i = 0 := by
  show (∑ j : Fin 1, (v i.castSucc - 2) * (v j.castSucc - 2) / 4
          * (Real.exp (-1 * t) - Real.exp (-2 * t)) * astar j.castSucc)
        + (v i.castSucc - 2) / 4 * (Real.exp (-1 * t) - Real.exp (-2 * t)) = 0
  rw [M0_Mf_astar i t]
  ring

/-- The second-level Lyapunov function of Narendra–Wang–Chen is nonincreasing
for this instance. -/
theorem Vr_antitone_inst : Antitone L0.Vr := L0.Vr_antitone H0_ea

theorem qres_zero_inst (t : ℝ) (ht : 0 ≤ t) (i : Fin 1) : F0.qres t i = 0 :=
  F0.qres_zero H0_ea t ht i

end Instance
end SLA
