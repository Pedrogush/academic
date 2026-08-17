(*  Title:      SLA_Prelim.thy
    Author:     Isabelle/HOL port of the Coq development in ../coq

    Preliminaries for the formalisation of Chapter 4 (eqs. 4.1-4.69) of

      Pedro Yochinori Gushiken, "Adaptacao de Segundo Nivel como Tecnica de
      Estimacao de Parametros e sua Aplicacao ao Controle Adaptativo por
      Modelo de Referencia", MSc dissertation, UFRN, 2018.

    MODELLING CHOICES (where Isabelle offers something better than the Coq
    original, this port takes it):

      * Finite sums are the library's "sum" over "{..<n}".  The Coq
        development carried its own [Sum] fixpoint together with a dozen
        lemmas about it (Sum_plus, Sum_scal_l, Sum_swap, Sum_select, ...).
        All of those are library facts here (sum.distrib, sum_distrib_left,
        sum.swap, sum.delta, ...), so they simply disappear.  Crucially,
        sum.lessThan_Suc peels the LAST summand, exactly like the Coq [Sum],
        so eliminating alpha_N in (4.48) remains a one-step rewrite.

      * Derivatives are the library predicate has_real_derivative (HOL.Deriv,
        the same notion HOL-Analysis is built on), NOT a hand-rolled
        epsilon/delta predicate.  Every "derivando ao longo das trajetorias"
        step of the dissertation is therefore a genuine analytic statement.
        Since all signals of the chapter are scalar functions of time (vectors
        are handled componentwise), has_real_derivative is exactly the right
        library notion; the Frechet-style has_derivative of HOL-Analysis would
        add nothing here.

      * Monotonicity from the sign of the derivative is the library's mean
        value theorem (DERIV_nonpos_imp_nonincreasing), not a bespoke argument.

      * Because Isabelle/HOL has functional extensionality, the Coq idiom
        [D_ext] -- an eight-line hand unfolding of the epsilon/delta
        definition, needed there to stay axiom-free -- collapses to the
        one-line Deriv_cong below.
*)

theory SLA_Prelim
  imports Complex_Main
begin

section \<open>Derivatives on the whole real line\<close>

text \<open>@{term "Deriv f f'"} says that f' is the derivative of f at every
  point.  It is an abbreviation, so every goal and every fact below is
  literally a statement about the library predicate @{const has_real_derivative}.\<close>

abbreviation Deriv :: "(real \<Rightarrow> real) \<Rightarrow> (real \<Rightarrow> real) \<Rightarrow> bool"
  where "Deriv f f' \<equiv> (\<forall>t. (f has_real_derivative f' t) (at t))"

text \<open>The replacement for Coq's @{text D_ext}: rewriting under a derivative
  statement is just extensionality.\<close>

lemma Deriv_cong:
  assumes "Deriv f f'" and "\<And>t. f t = g t" and "\<And>t. f' t = g' t"
  shows "Deriv g g'"
proof -
  have "f = g" using assms(2) by (simp add: fun_eq_iff)
  moreover have "f' = g'" using assms(3) by (simp add: fun_eq_iff)
  ultimately show ?thesis using assms(1) by simp
qed

text \<open>The common special case: the function is unchanged and only the
  expression for its derivative is reshaped.  Using this instead of
  @{thm Deriv_cong} avoids a trivial reflexivity subgoal.\<close>

lemma Deriv_cong_deriv:
  assumes "Deriv f f'" and "\<And>t. f' t = g' t"
  shows "Deriv f g'"
proof -
  have "f' = g'" using assms(2) by (simp add: fun_eq_iff)
  thus ?thesis using assms(1) by simp
qed

subsection \<open>Differentiation rules in the @{term Deriv} form\<close>

lemma Deriv_const: "Deriv (\<lambda>_. c) (\<lambda>_. 0)"
  by (simp add: DERIV_const)

lemma Deriv_ident: "Deriv (\<lambda>t. t) (\<lambda>_. 1)"
  by (simp add: DERIV_ident)

lemma Deriv_add:
  assumes "Deriv f f'" and "Deriv g g'"
  shows "Deriv (\<lambda>t. f t + g t) (\<lambda>t. f' t + g' t)"
proof (intro allI)
  fix t :: real
  have 1: "(f has_real_derivative f' t) (at t)" using assms(1) by blast
  have 2: "(g has_real_derivative g' t) (at t)" using assms(2) by blast
  show "((\<lambda>t. f t + g t) has_real_derivative f' t + g' t) (at t)"
    by (rule DERIV_add[OF 1 2])
qed

lemma Deriv_diff:
  assumes "Deriv f f'" and "Deriv g g'"
  shows "Deriv (\<lambda>t. f t - g t) (\<lambda>t. f' t - g' t)"
proof (intro allI)
  fix t :: real
  have 1: "(f has_real_derivative f' t) (at t)" using assms(1) by blast
  have 2: "(g has_real_derivative g' t) (at t)" using assms(2) by blast
  show "((\<lambda>t. f t - g t) has_real_derivative f' t - g' t) (at t)"
    by (rule DERIV_diff[OF 1 2])
qed

lemma Deriv_minus:
  assumes "Deriv f f'"
  shows "Deriv (\<lambda>t. - f t) (\<lambda>t. - f' t)"
proof (intro allI)
  fix t :: real
  have 1: "(f has_real_derivative f' t) (at t)" using assms by blast
  show "((\<lambda>t. - f t) has_real_derivative - f' t) (at t)"
    by (rule DERIV_minus[OF 1])
qed

lemma Deriv_mult:
  assumes "Deriv f f'" and "Deriv g g'"
  shows "Deriv (\<lambda>t. f t * g t) (\<lambda>t. f' t * g t + f t * g' t)"
proof (intro allI)
  fix t :: real
  have 1: "(f has_real_derivative f' t) (at t)" using assms(1) by blast
  have 2: "(g has_real_derivative g' t) (at t)" using assms(2) by blast
  have "((\<lambda>t. f t * g t) has_real_derivative f t * g' t + f' t * g t) (at t)"
    by (rule DERIV_mult'[OF 1 2])
  thus "((\<lambda>t. f t * g t) has_real_derivative f' t * g t + f t * g' t) (at t)"
    by (simp add: add.commute)
qed

text \<open>Multiplication by a constant.  Kept separate from @{thm Deriv_mult}
  because it gives a much shorter derivative expression, which keeps the later
  algebra small -- exactly the reason the Coq development has @{text D_scal}.\<close>

lemma Deriv_scale:
  assumes "Deriv f f'"
  shows "Deriv (\<lambda>t. c * f t) (\<lambda>t. c * f' t)"
proof (intro allI)
  fix t :: real
  have 1: "(f has_real_derivative f' t) (at t)" using assms by blast
  show "((\<lambda>t. c * f t) has_real_derivative c * f' t) (at t)"
    by (rule DERIV_cmult[OF 1])
qed

lemma Deriv_divide_const:
  assumes "Deriv f f'"
  shows "Deriv (\<lambda>t. f t / c) (\<lambda>t. f' t / c)"
proof (intro allI)
  fix t :: real
  have 1: "(f has_real_derivative f' t) (at t)" using assms by blast
  show "((\<lambda>t. f t / c) has_real_derivative f' t / c) (at t)"
    by (rule DERIV_cdivide[OF 1])
qed

text \<open>Termwise differentiation of a finite sum.\<close>

lemma Deriv_sum:
  fixes n :: nat
  shows "(\<And>i. i < n \<Longrightarrow> Deriv (F i) (F' i)) \<Longrightarrow>
         Deriv (\<lambda>t. \<Sum>i<n. F i t) (\<lambda>t. \<Sum>i<n. F' i t)"
proof (induction n)
  case 0
  show ?case using Deriv_const[of 0] by simp
next
  case (Suc n)
  have 1: "Deriv (\<lambda>t. \<Sum>i<n. F i t) (\<lambda>t. \<Sum>i<n. F' i t)"
  proof (rule Suc.IH)
    fix i assume "i < n"
    thus "Deriv (F i) (F' i)" using Suc.prems by simp
  qed
  have 2: "Deriv (F n) (F' n)" using Suc.prems by simp
  from Deriv_add[OF 1 2] show ?case by simp
qed

text \<open>The only nontrivial rule needed: @{term "exp (a * t)"}.  It drives the
  integrating factors of (4.65)/(4.66) and the closed forms of the instance.\<close>

lemma Deriv_exp_lin: "Deriv (\<lambda>t. exp (a * t)) (\<lambda>t. a * exp (a * t))"
proof (intro allI)
  fix t :: real
  show "((\<lambda>t. exp (a * t)) has_real_derivative a * exp (a * t)) (at t)"
    by (auto intro!: derivative_eq_intros)
qed

subsection \<open>Monotonicity from the sign of the derivative (mean value theorem)\<close>

text \<open>This is the rigorous replacement for the informal step "Vdot is negative
  semidefinite, hence V cannot grow" that appears after (4.23), (4.58) and
  (4.69).  Combined with @{text quad_zero} below it also replaces the implicit
  ODE-uniqueness argument behind the convex-hull invariance claim.\<close>

lemma nonincr_of_nonpos_deriv:
  assumes D: "Deriv f f'" and neg: "\<And>t. f' t \<le> 0" and ab: "a \<le> b"
  shows "f b \<le> f a"
proof (rule DERIV_nonpos_imp_nonincreasing[OF ab])
  fix x :: real
  show "\<exists>y. (f has_real_derivative y) (at x) \<and> y \<le> 0"
    using D neg by blast
qed

lemma nondecr_of_nonneg_deriv:
  assumes D: "Deriv f f'" and pos: "\<And>t. 0 \<le> f' t" and ab: "a \<le> b"
  shows "f a \<le> f b"
proof (rule DERIV_nonneg_imp_nondecreasing[OF ab])
  fix x :: real
  show "\<exists>y. (f has_real_derivative y) (at x) \<and> 0 \<le> y"
    using D pos by blast
qed

section \<open>Vectors and inner products\<close>

text \<open>A vector of @{text "R^d"} is a function @{typ "nat \<Rightarrow> real"}; only the
  first d indices are ever constrained.\<close>

definition dot :: "nat \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> real"
  where "dot d u v = (\<Sum>j<d. u j * v j)"

lemma dot_diff_left: "dot d (\<lambda>j. u j - v j) w = dot d u w - dot d v w"
  by (simp add: dot_def sum_subtractf algebra_simps)

lemma dot_nonneg: "0 \<le> dot d u u"
  by (simp add: dot_def sum_nonneg)

lemma dot_zero_left: "(\<And>j. j < d \<Longrightarrow> u j = 0) \<Longrightarrow> dot d u v = 0"
  by (simp add: dot_def)

section \<open>Generic quadratic Lyapunov forms\<close>

text \<open>Every Lyapunov function of the chapter has the shape
  @{term "Wq n c T t"}, i.e. (4.22), (4.57) and (4.68).\<close>

definition Wq :: "nat \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> (real \<Rightarrow> nat \<Rightarrow> real) \<Rightarrow> real \<Rightarrow> real"
  where "Wq n c T t = 1/2 * (\<Sum>j<n. inverse (c j) * (T t j * T t j))"

lemma Wq_deriv:
  assumes HT: "\<And>j. j < n \<Longrightarrow> Deriv (\<lambda>t. T t j) (\<lambda>t. T' t j)"
  shows "Deriv (Wq n c T) (\<lambda>t. \<Sum>j<n. inverse (c j) * (T t j * T' t j))"
proof (rule Deriv_cong)
  have D: "Deriv (\<lambda>t. inverse (c j) * (T t j * T t j))
                 (\<lambda>t. inverse (c j) * (T' t j * T t j + T t j * T' t j))"
    if "j < n" for j
    by (rule Deriv_scale[OF Deriv_mult[OF HT[OF that] HT[OF that]]])
  show "Deriv (\<lambda>t. 1/2 * (\<Sum>j<n. inverse (c j) * (T t j * T t j)))
              (\<lambda>t. 1/2 * (\<Sum>j<n. inverse (c j)
                                 * (T' t j * T t j + T t j * T' t j)))"
    by (rule Deriv_scale[OF Deriv_sum[OF D]])
next
  fix t show "1/2 * (\<Sum>j<n. inverse (c j) * (T t j * T t j)) = Wq n c T t"
    by (simp add: Wq_def)
next
  fix t
  have "(\<Sum>j<n. inverse (c j) * (T' t j * T t j + T t j * T' t j))
        = (\<Sum>j<n. 2 * (inverse (c j) * (T t j * T' t j)))"
    by (rule sum.cong) (auto simp: algebra_simps)
  also have "\<dots> = 2 * (\<Sum>j<n. inverse (c j) * (T t j * T' t j))"
    by (simp add: sum_distrib_left)
  finally show "1/2 * (\<Sum>j<n. inverse (c j)
                              * (T' t j * T t j + T t j * T' t j))
                = (\<Sum>j<n. inverse (c j) * (T t j * T' t j))"
    by simp
qed

lemma inv_sq_nonneg:
  fixes c x :: real
  assumes "0 < c" shows "0 \<le> inverse c * (x * x)"
proof (rule mult_nonneg_nonneg)
  show "0 \<le> inverse c" using assms by simp
next
  show "0 \<le> x * x" by (rule zero_le_square)
qed

lemma Wq_nonneg:
  assumes "\<And>j. j < n \<Longrightarrow> 0 < c j"
  shows "0 \<le> Wq n c T t"
proof -
  have "0 \<le> (\<Sum>j<n. inverse (c j) * (T t j * T t j))"
  proof (rule sum_nonneg)
    fix j assume "j \<in> {..<n}"
    hence "0 < c j" using assms by simp
    thus "0 \<le> inverse (c j) * (T t j * T t j)" by (rule inv_sq_nonneg)
  qed
  thus ?thesis by (simp add: Wq_def)
qed

lemma Wq_init0:
  assumes "\<And>j. j < n \<Longrightarrow> T 0 j = 0"
  shows "Wq n c T 0 = 0"
  using assms by (simp add: Wq_def)

text \<open>If a quadratic form starts at zero and its derivative is never positive,
  the underlying vector is identically zero for all @{term "0 \<le> t"}.  This is
  the rigorous replacement for the ODE-uniqueness argument used implicitly in
  the dissertation (and in Narendra et al., "point 3").\<close>

lemma quad_zero:
  assumes c: "\<And>j. j < n \<Longrightarrow> 0 < c j"
      and D: "Deriv (Wq n c T) W'"
      and neg: "\<And>t. W' t \<le> 0"
      and init: "\<And>j. j < n \<Longrightarrow> T 0 j = 0"
      and t: "0 \<le> t" and j: "j < n"
  shows "T t j = 0"
proof -
  have Z0: "Wq n c T 0 = 0" by (rule Wq_init0) (rule init)
  have "Wq n c T t \<le> Wq n c T 0" by (rule nonincr_of_nonpos_deriv[OF D neg t])
  hence le: "Wq n c T t \<le> 0" by (simp add: Z0)
  have "0 \<le> Wq n c T t" by (rule Wq_nonneg) (rule c)
  with le have "Wq n c T t = 0" by simp
  hence Z: "(\<Sum>k<n. inverse (c k) * (T t k * T t k)) = 0"
    by (simp add: Wq_def)
  have fin: "finite {..<n}" by simp
  have nn: "0 \<le> inverse (c k) * (T t k * T t k)" if "k \<in> {..<n}" for k
  proof -
    have "0 < c k" using c that by simp
    thus ?thesis by (rule inv_sq_nonneg)
  qed
  from sum_nonneg_eq_0_iff[OF fin nn] Z
  have "\<forall>k\<in>{..<n}. inverse (c k) * (T t k * T t k) = 0" by simp
  hence "inverse (c j) * (T t j * T t j) = 0" using j by simp
  with c[OF j] show ?thesis by simp
qed

section \<open>Linear combinations of finite sums\<close>

text \<open>The counterparts of the Coq development's @{text Sum_comb} and
  @{text Sum_comb3}.  Written out explicitly, rather than left to
  @{thm sum.distrib} and @{thm sum_distrib_left}, because the simplifier
  reassociates the summand before those rules can match.\<close>

lemma sum_comb:
  fixes n :: nat and a b :: real
  shows "(\<Sum>i<n. a * A i + b * B i)
         = a * (\<Sum>i<n. A i) + b * (\<Sum>i<n. B i)"
  by (induct n) (simp_all add: algebra_simps)

lemma sum_comb3:
  fixes n :: nat and a b c :: real
  shows "(\<Sum>i<n. a * A i + (b * B i + c * C i))
         = a * (\<Sum>i<n. A i) + (b * (\<Sum>i<n. B i) + c * (\<Sum>i<n. C i))"
  by (induct n) (simp_all add: algebra_simps)

section \<open>Small explicit index sets\<close>

text \<open>@{thm sum.lessThan_Suc} splits a sum over @{term "{..<Suc n}"}, but a
  numeral is not syntactically a successor.  These three equations let
  @{method simp} evaluate the small concrete sums of the counterexamples of
  Chapter 4 and of the instance.\<close>

lemma lessThan_1: "{..<1::nat} = {0}" by auto
lemma lessThan_2: "{..<2::nat} = {0,1}" by auto
lemma lessThan_3: "{..<3::nat} = {0,1,2}" by auto

end
