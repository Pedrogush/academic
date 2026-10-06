/-
# Preliminaries: derivatives along trajectories and quadratic Lyapunov forms

Support library for the Lean 4 port of Chapter 4 (equations 4.1–4.69) of

> Pedro Yochinori Gushiken, *Adaptação de Segundo Nível como Técnica de Estimação
> de Parâmetros e sua Aplicação ao Controle Adaptativo por Modelo de Referência*,
> MSc dissertation, UFRN, 2018.

Modelling choices (ported from the Coq development, made idiomatic):

* vectors of `ℝ^d` are `Fin d → ℝ` and inner products are Mathlib's `dotProduct`
  (`⬝ᵥ`), so `Finset.sum` lemmas apply directly;
* a derivative "along the trajectories" is `HasDerivAt`, i.e. a genuine analytic
  statement, never an axiom;
* the monotonicity steps go through Mathlib's mean-value theorem corollaries
  `antitone_of_deriv_nonpos` / `monotone_of_deriv_nonneg`.
-/
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Data.Matrix.Mul
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.LinearCombination

open scoped Matrix

namespace SLA

variable {f f' g g' : ℝ → ℝ}

/-- `Deriv f f'` says that `f'` is the derivative of `f` at every real time.
This is the Lean counterpart of the Coq development's
`Deriv f f' := ∀ t, derivable_pt_lim f t (f' t)`. -/
def Deriv (f f' : ℝ → ℝ) : Prop := ∀ t, HasDerivAt f (f' t) t

namespace Deriv

theorem differentiable (h : Deriv f f') : Differentiable ℝ f := fun t => (h t).differentiableAt

theorem deriv_eq (h : Deriv f f') (t : ℝ) : deriv f t = f' t := (h t).deriv

/-- Derivatives are stable under pointwise reformulation of both the function
and the derivative.  Replaces the Coq development's `D_ext`, which is used to
massage every single dynamical computation into the shape wanted. -/
theorem congr (h : Deriv f f') (hfg : ∀ t, f t = g t) (hfg' : ∀ t, f' t = g' t) :
    Deriv g g' := by
  intro t
  have h₁ : HasDerivAt g (f' t) t :=
    (h t).congr_of_eventuallyEq (Filter.Eventually.of_forall fun x => (hfg x).symm)
  rwa [hfg' t] at h₁

theorem const (c : ℝ) : Deriv (fun _ => c) (fun _ => 0) := fun t => hasDerivAt_const t c

theorem add (hf : Deriv f f') (hg : Deriv g g') :
    Deriv (fun t => f t + g t) (fun t => f' t + g' t) := fun t => (hf t).add (hg t)

theorem sub (hf : Deriv f f') (hg : Deriv g g') :
    Deriv (fun t => f t - g t) (fun t => f' t - g' t) := fun t => (hf t).sub (hg t)

theorem neg (hf : Deriv f f') : Deriv (fun t => -f t) (fun t => -f' t) := fun t => (hf t).neg

theorem mul (hf : Deriv f f') (hg : Deriv g g') :
    Deriv (fun t => f t * g t) (fun t => f' t * g t + f t * g' t) := fun t => (hf t).mul (hg t)

theorem const_mul (c : ℝ) (hf : Deriv f f') : Deriv (fun t => c * f t) (fun t => c * f' t) :=
  fun t => (hf t).const_mul c

theorem mul_const (hf : Deriv f f') (c : ℝ) : Deriv (fun t => f t * c) (fun t => f' t * c) :=
  fun t => (hf t).mul_const c

theorem sub_const (hf : Deriv f f') (c : ℝ) : Deriv (fun t => f t - c) f' :=
  fun t => (hf t).sub_const c

theorem sum {ι : Type*} (s : Finset ι) (F F' : ι → ℝ → ℝ) (h : ∀ i ∈ s, Deriv (F i) (F' i)) :
    Deriv (fun t => ∑ i ∈ s, F i t) (fun t => ∑ i ∈ s, F' i t) := by
  intro t
  have hf : (fun t => ∑ i ∈ s, F i t) = ∑ i ∈ s, F i :=
    funext fun x => (Finset.sum_apply x s F).symm
  rw [hf]
  exact HasDerivAt.sum fun i hi => h i hi t

theorem exp_linear (a : ℝ) :
    Deriv (fun t => Real.exp (a * t)) (fun t => a * Real.exp (a * t)) := by
  intro t
  have h : HasDerivAt (fun x : ℝ => a * x) a t := by
    simpa using (hasDerivAt_id t).const_mul a
  simpa [mul_comm] using h.exp

/-- Mean value theorem: a nonpositive derivative gives an antitone function. -/
theorem antitone (h : Deriv f f') (hs : ∀ t, f' t ≤ 0) : Antitone f :=
  antitone_of_deriv_nonpos h.differentiable fun t => by rw [h.deriv_eq]; exact hs t

/-- Mean value theorem: a nonnegative derivative gives a monotone function. -/
theorem monotone (h : Deriv f f') (hs : ∀ t, 0 ≤ f' t) : Monotone f :=
  monotone_of_deriv_nonneg h.differentiable fun t => by rw [h.deriv_eq]; exact hs t

end Deriv

/-- `0 ≤ vᵀv`; used for the normalising signal `m² = 1 + φᵀφ`. -/
theorem dotProduct_self_nonneg {d : ℕ} (v : Fin d → ℝ) : 0 ≤ v ⬝ᵥ v := by
  unfold dotProduct
  exact Finset.sum_nonneg fun j _ => mul_self_nonneg _

/-! ## Generic quadratic Lyapunov forms

Every Lyapunov candidate of the chapter — (4.22), (4.57) and (4.68) — has the
shape `V = ½ ∑ⱼ Tⱼ²/cⱼ`.  The lemmas below are proved once and reused. -/

noncomputable section Quadratic

variable {n : ℕ} {c : Fin n → ℝ} {T T' : ℝ → Fin n → ℝ}

/-- The generic quadratic Lyapunov candidate `V = ½ ∑ⱼ Tⱼ²/cⱼ`. -/
def Wq (c : Fin n → ℝ) (T : ℝ → Fin n → ℝ) (t : ℝ) : ℝ :=
  2⁻¹ * ∑ j, (c j)⁻¹ * (T t j * T t j)

theorem Wq_nonneg (hc : ∀ j, 0 < c j) (t : ℝ) : 0 ≤ Wq c T t := by
  have h : 0 ≤ ∑ j, (c j)⁻¹ * (T t j * T t j) :=
    Finset.sum_nonneg fun j _ => mul_nonneg (inv_nonneg.2 (hc j).le) (mul_self_nonneg _)
  unfold Wq
  linarith

theorem Wq_init (h0 : ∀ j, T 0 j = 0) : Wq c T 0 = 0 := by simp [Wq, h0]

theorem Wq_hasDeriv (h : ∀ j, Deriv (fun t => T t j) (fun t => T' t j)) :
    Deriv (Wq c T) (fun t => ∑ j, (c j)⁻¹ * (T t j * T' t j)) := by
  have key : Deriv (fun t => ∑ j, (c j)⁻¹ * (T t j * T t j))
      (fun t => ∑ j, (c j)⁻¹ * (T' t j * T t j + T t j * T' t j)) :=
    Deriv.sum _ _ _ fun j _ => Deriv.const_mul _ ((h j).mul (h j))
  refine (Deriv.const_mul 2⁻¹ key).congr (fun _ => rfl) fun t => ?_
  rw [Finset.mul_sum]
  exact Finset.sum_congr rfl fun j _ => by ring

/-- If a quadratic form starts at zero and its derivative is never positive,
the underlying vector is identically zero for all `t ≥ 0`.

This is the rigorous replacement for the ODE-uniqueness handwave used in the
dissertation (and in Narendra–Wang–Chen, "point 3"): a Lyapunov argument plus
the mean value theorem. -/
theorem quad_zero {W' : ℝ → ℝ} (hc : ∀ j, 0 < c j) (hD : Deriv (Wq c T) W')
    (hW : ∀ t, W' t ≤ 0) (h0 : ∀ j, T 0 j = 0) :
    ∀ t, 0 ≤ t → ∀ j, T t j = 0 := by
  intro t ht j
  have h1 : Wq c T t ≤ Wq c T 0 := hD.antitone hW ht
  rw [Wq_init h0] at h1
  have h2 : (0 : ℝ) ≤ Wq c T t := Wq_nonneg hc t
  have h3 : ∑ k, (c k)⁻¹ * (T t k * T t k) = 0 := by
    unfold Wq at h1 h2; linarith
  have h4 : (c j)⁻¹ * (T t j * T t j) = 0 :=
    (Finset.sum_eq_zero_iff_of_nonneg fun k _ =>
      mul_nonneg (inv_nonneg.2 (hc k).le) (mul_self_nonneg _)).1 h3 j (Finset.mem_univ j)
  have h5 : T t j * T t j = 0 := by
    rcases mul_eq_zero.1 h4 with h | h
    · exact absurd h (inv_ne_zero (hc j).ne')
    · exact h
  exact mul_self_eq_zero.1 h5

end Quadratic

end SLA
