(*  Title:      SLA_Instance.thy
    Author:     Isabelle/HOL port of the Coq development in ../coq

    A concrete model of EVERY assumption of SLA_Chapter4.

    A formalisation whose theorems live under a long list of hypotheses is
    worthless if those hypotheses are contradictory: everything would then be
    provable vacuously.  This file rules that out by exhibiting concrete
    signals for which every assumption of the locale chain

        plant < first_level < hull_models < second_level < sla / slaff

    holds, and then instantiating the main theorem on them.

    The instance is the simplest non-degenerate one whose adaptive ODEs have
    closed-form solutions, and it obeys the AMENDED design rule N = d + 1
    exactly (see ../NOTE_convex_uniqueness.md):

      d = 1,  N = 2 models (M = 1),  phi(t) = 1,  theta*_p = 1,  z(t) = 1,
      Gamma = 2, so the gradient law (4.19) is  d/dt thetahat_i = -(thetahat_i - 1)
      and hence            thetahat_i(t) = 1 + (v_i - 1) e^{-t}
      with initial values  v = (0, 2).

    Since N = d + 1 = 2, the convex representation of theta*_p = 1 by the
    initial estimates (0, 2) is UNIQUE: alpha* = (1/2, 1/2), proved as
    inst_astar_unique.  (The N = 3 instance the Coq development used before the
    amendment admitted a whole one-parameter family of alpha*, and its
    second-level regressor was correspondingly rank deficient.)

    Note that here the LAST model is NOT initialised at theta*_p, so
    eps_M(t) = e^{-t}/2 is not identically zero and v_f is not identically
    zero either: the instance genuinely exercises the v_f term that (4.69)
    omits.  With sigma = 1 the forgetting-factor equations (4.66) still solve
    in closed form:
      M_f(t)_{ij} = (v_i-2)(v_j-2)/4 (e^{-t} - e^{-2t}),
      v_f(t)_i    = (v_i-2)/4 (e^{-t} - e^{-2t}),
    and the residual M_f alpha* + v_f vanishes identically (inst_MFalp).
*)

theory SLA_Instance
  imports SLA_Chapter4
begin

text \<open>The instance uses @{term "d = 1"} and @{term "M = 1"}, and those
  numerals occur as ARGUMENTS of the interpreted locale constants (e.g.
  @{text "first_level_sig.eps 1 PHI Z TH"}).  The default simplification
  @{thm One_nat_def} would rewrite them to @{term "Suc 0"} and so
  desynchronise every closed-form lemma below from the interpretation.
  Switching it off for this theory keeps the two in step.\<close>

declare One_nat_def [simp del]

section \<open>The instance\<close>

definition v :: "nat \<Rightarrow> real"
  where "v i = (if i = 0 then 0 else 2)"

definition PHI :: "real \<Rightarrow> nat \<Rightarrow> real"       where "PHI t j = 1"
definition PHID :: "real \<Rightarrow> nat \<Rightarrow> real"      where "PHID t j = 0"
definition THSTAR :: "nat \<Rightarrow> real"            where "THSTAR j = 1"
definition Z :: "real \<Rightarrow> real"                where "Z t = 1"
definition TH :: "nat \<Rightarrow> real \<Rightarrow> nat \<Rightarrow> real"
  where "TH i t j = 1 + (v i - 1) * exp (- t)"
definition GAM :: "nat \<Rightarrow> real"               where "GAM j = 2"
definition BETA :: "nat \<Rightarrow> real"              where "BETA i = 1/2"
definition ASTAR :: "nat \<Rightarrow> real"             where "ASTAR i = 1/2"
definition GN :: real                          where "GN = 1"
definition SIG :: real                         where "SIG = 1"
definition ALP :: "real \<Rightarrow> nat \<Rightarrow> real"       where "ALP t i = ASTAR i"
definition MF :: "real \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> real"
  where "MF t i j = (v i - 2) * (v j - 2) / 4 * (exp (- t) - exp (- 2 * t))"
definition VF :: "real \<Rightarrow> nat \<Rightarrow> real"
  where "VF t i = (v i - 2) / 4 * (exp (- t) - exp (- 2 * t))"

subsection \<open>The two exponentials and their derivatives\<close>

lemma D_exp1: "Deriv (\<lambda>t. exp (- t)) (\<lambda>t. - exp (- t))"
  by (rule Deriv_cong[OF Deriv_exp_lin[of "- 1"]]) simp_all

lemma D_exp2: "Deriv (\<lambda>t. exp (- 2 * t)) (\<lambda>t. - 2 * exp (- 2 * t))"
  by (rule Deriv_exp_lin)

lemma v0: "v 0 = 0" by (simp add: v_def)
lemma v1: "v 1 = 2" by (simp add: v_def)

lemma exp_sq:
  fixes t :: real
  shows "exp (- t) * exp (- t) = exp (- 2 * t)"
proof -
  have "- 2 * t = (- t) + (- t)" by simp
  hence "exp (- 2 * t) = exp ((- t) + (- t))" by (rule arg_cong)
  also have "\<dots> = exp (- t) * exp (- t)" by (rule exp_add)
  finally show ?thesis by simp
qed

section \<open>Every assumption of the locale chain holds\<close>

subsection \<open>The plant (4.8) and the signature of the first level\<close>

interpretation Inst: first_level_sig 1 PHI PHID THSTAR Z 2 TH GAM
proof
  show "\<And>j. j < 1 \<Longrightarrow> Deriv (\<lambda>t. PHI t j) (\<lambda>t. PHID t j)"
    unfolding PHI_def PHID_def by (rule Deriv_const)
next
  show "\<And>t. Z t = dot 1 THSTAR (PHI t)"      \<comment> \<open>(4.8)\<close>
    by (simp add: dot_def lessThan_1 THSTAR_def PHI_def Z_def)
qed

subsection \<open>Closed forms of the derived signals\<close>

lemma inst_msq: "Inst.msq t = 2"                                  \<comment> \<open>(4.12)\<close>
  by (simp add: Inst.msq_def dot_def lessThan_1 PHI_def)

lemma inst_e: "Inst.e i t = (v i - 1) * exp (- t)"                \<comment> \<open>(4.11)\<close>
  by (simp add: Inst.e_def Inst.zh_def dot_def lessThan_1
                PHI_def Z_def TH_def)

lemma inst_eps: "Inst.eps i t = (v i - 1) * exp (- t) / 2"        \<comment> \<open>(4.13)\<close>
  by (simp add: Inst.eps_def inst_e inst_msq)

text \<open>The last model is NOT initialised at theta*_p, so its error does not
  vanish -- unlike in the pre-amendment N = 3 instance.\<close>

lemma inst_eps1: "Inst.eps 1 t = exp (- t) / 2"
  by (simp add: inst_eps v_def)

subsection \<open>The gradient law (4.19) and the design rule\<close>

interpretation Inst: first_level 1 PHI PHID THSTAR Z 2 TH GAM
proof
  show "(2::nat) = Suc 1" by simp                    \<comment> \<open>N = d + 1 exactly\<close>
next
  show "\<And>j. j < 1 \<Longrightarrow> 0 < GAM j" by (simp add: GAM_def)
next
  fix i j :: nat
  assume "i < 2" and "j < 1"
  show "Deriv (\<lambda>t. TH i t j) (\<lambda>t. - (GAM j * Inst.eps i t * PHI t j))"
  proof (rule Deriv_cong)
    show "Deriv (\<lambda>t. 1 + (v i - 1) * exp (- t))
                (\<lambda>t. 0 + (v i - 1) * (- exp (- t)))"
      by (rule Deriv_add[OF Deriv_const Deriv_scale[OF D_exp1]])
  next
    fix t show "1 + (v i - 1) * exp (- t) = TH i t j" by (simp add: TH_def)
  next
    fix t show "0 + (v i - 1) * (- exp (- t))
                = - (GAM j * Inst.eps i t * PHI t j)"
      by (simp add: inst_eps GAM_def PHI_def)
  qed
qed

subsection \<open>The convex combination (4.31) and the hull assumption (4.41)\<close>

interpretation Inst: virtual_model 1 PHI PHID THSTAR Z 2 TH GAM BETA
proof
  show "(\<Sum>i<2. BETA i) = 1" by (simp add: lessThan_2 BETA_def)
next
  show "\<And>i. i < 2 \<Longrightarrow> 0 \<le> BETA i \<and> BETA i \<le> 1" by (simp add: BETA_def)
qed

interpretation Inst: hull_models 1 PHI PHID THSTAR Z 2 TH GAM ASTAR
proof
  show "(\<Sum>i<2. ASTAR i) = 1" by (simp add: lessThan_2 ASTAR_def)
next
  show "\<And>i. i < 2 \<Longrightarrow> 0 \<le> ASTAR i \<and> ASTAR i \<le> 1" by (simp add: ASTAR_def)
next
  text \<open>(4.41) at t = 0: theta*_p = 1 is the convex combination
    (1/2)*0 + (1/2)*2 of the initial estimates.\<close>
  show "\<And>j. j < 1 \<Longrightarrow> (\<Sum>i<2. TH i 0 j * ASTAR i) = THSTAR j"
    by (simp add: lessThan_2 TH_def ASTAR_def v_def THSTAR_def)
qed

text \<open>Because @{text "N = d + 1 = 2"} exactly, that alpha* is the ONLY one:
  the two initial estimates 0 and 2 are affinely independent on the line.
  This is what the second level needs in order for alpha*_f to be a
  well-defined identification target -- see ../NOTE_convex_uniqueness.md and
  @{text SLA_AppendixA.theorem2_uniqueness}.  Note no nonnegativity of a is
  assumed: even as an AFFINE combination the representation is unique.\<close>

lemma inst_astar_unique:
  assumes asum: "(\<Sum>i<2. a i) = 1"
      and arep: "\<And>j. j < 1 \<Longrightarrow> (\<Sum>i<2. TH i 0 j * a i) = THSTAR j"
      and i: "i < 2"
  shows "a i = ASTAR i"
proof -
  have "(\<Sum>i<2. TH i 0 0 * a i) = THSTAR 0" by (rule arep) simp
  hence r: "2 * a 1 = 1" by (simp add: lessThan_2 TH_def v_def THSTAR_def)
  have s: "a 0 + a 1 = 1" using asum by (simp add: lessThan_2)
  from r have "a 1 = 1/2" by simp
  moreover with s have "a 0 = 1/2" by simp
  ultimately show ?thesis using i
    by (auto simp: ASTAR_def less_2_cases_iff One_nat_def)
qed

subsection \<open>The second-level regressor (4.50)\<close>

interpretation Inst: second_level 1 PHI PHID THSTAR Z 2 TH GAM ASTAR 1 GN
proof
  show "(2::nat) = Suc 1" by simp
next
  show "0 < GN" by (simp add: GN_def)
qed

lemma inst_Ev: "Inst.Ev t i = (v i - 2) * exp (- t) / 2"
  by (simp add: Inst.Ev_def inst_eps v1 field_simps)

text \<open>The instance is not degenerate: the second-level regressor is nonzero.\<close>

lemma inst_Ev0: "Inst.Ev t 0 = - exp (- t)"
  by (simp add: inst_Ev v_def)

subsection \<open>Conventional second level adaptation (4.52)\<close>

interpretation Inst: sla_sig 1 PHI PHID THSTAR Z 2 TH GAM ASTAR 1 GN ALP
  by unfold_locales

lemma inst_Ealp: "Inst.Ealp t = - (exp (- t) / 2)"
  by (simp add: Inst.Ealp_def lessThan_1 inst_Ev0 ALP_def ASTAR_def)

interpretation Inst: sla 1 PHI PHID THSTAR Z 2 TH GAM ASTAR 1 GN ALP
proof
  fix i :: nat assume i: "i < 1"
  have i0: "i = 0" using i by simp
  show "Deriv (\<lambda>t. ALP t i)
              (\<lambda>t. - GN * (Inst.Ev t i * Inst.Ealp t)
                   - GN * (Inst.Ev t i * Inst.eps 1 t))"
  proof (rule Deriv_cong[OF Deriv_const[of "ASTAR i"]])
    fix t show "ASTAR i = ALP t i" by (simp add: ALP_def)
  next
    fix t show "(0::real) = - GN * (Inst.Ev t i * Inst.Ealp t)
                             - GN * (Inst.Ev t i * Inst.eps 1 t)"
      by (simp add: i0 inst_Ev0 inst_Ealp inst_eps1 GN_def exp_sq field_simps)
  qed
qed

subsection \<open>Forgetting factor: closed-form solutions of (4.66) with sigma = 1\<close>

interpretation Inst: slaff_sig
    1 PHI PHID THSTAR Z 2 TH GAM ASTAR 1 GN SIG MF VF ALP
  by unfold_locales

lemma inst_EalpF: "Inst.EalpF t = - (exp (- t) / 2)"
  by (simp add: Inst.EalpF_def lessThan_1 inst_Ev0 ALP_def ASTAR_def)

text \<open>The residual @{text "M_f alpha* + v_f"} vanishes identically -- this is
  (4.69) WITH the @{text v_f} term that the dissertation omits, and the two
  parts cancel exactly.\<close>

lemma inst_MFalp: "i < 1 \<Longrightarrow> (\<Sum>j<1. MF t i j * ALP t j) = - VF t i"
  by (simp add: lessThan_1 MF_def VF_def ALP_def ASTAR_def v_def)

interpretation Inst: slaff
    1 PHI PHID THSTAR Z 2 TH GAM ASTAR 1 GN SIG MF VF ALP
proof
  show "0 < SIG" by (simp add: SIG_def)
next
  show "\<And>i j. MF 0 i j = 0" by (simp add: MF_def)
next
  show "\<And>i. VF 0 i = 0" by (simp add: VF_def)
next
  fix i j :: nat
  assume i: "i < 1" and j: "j < 1"
  have i0: "i = 0" using i by simp
  have j0: "j = 0" using j by simp
  show "Deriv (\<lambda>t. MF t i j)
              (\<lambda>t. - SIG * MF t i j + Inst.Ev t i * Inst.Ev t j)"
  proof (rule Deriv_cong)
    show "Deriv (\<lambda>t. (v i - 2) * (v j - 2) / 4 * (exp (- t) - exp (- 2 * t)))
                (\<lambda>t. (v i - 2) * (v j - 2) / 4
                     * (- exp (- t) - - 2 * exp (- 2 * t)))"
      by (rule Deriv_scale[OF Deriv_diff[OF D_exp1 D_exp2]])
  next
    fix t show "(v i - 2) * (v j - 2) / 4 * (exp (- t) - exp (- 2 * t))
                = MF t i j" by (simp add: MF_def)
  next
    fix t
    show "(v i - 2) * (v j - 2) / 4 * (- exp (- t) - - 2 * exp (- 2 * t))
          = - SIG * MF t i j + Inst.Ev t i * Inst.Ev t j"
      by (simp add: i0 j0 inst_Ev0 SIG_def MF_def v_def exp_sq field_simps)
  qed
next
  fix i :: nat assume i: "i < 1"
  have i0: "i = 0" using i by simp
  show "Deriv (\<lambda>t. VF t i)
              (\<lambda>t. - SIG * VF t i + Inst.Ev t i * Inst.eps 1 t)"
  proof (rule Deriv_cong)
    show "Deriv (\<lambda>t. (v i - 2) / 4 * (exp (- t) - exp (- 2 * t)))
                (\<lambda>t. (v i - 2) / 4 * (- exp (- t) - - 2 * exp (- 2 * t)))"
      by (rule Deriv_scale[OF Deriv_diff[OF D_exp1 D_exp2]])
  next
    fix t show "(v i - 2) / 4 * (exp (- t) - exp (- 2 * t)) = VF t i"
      by (simp add: VF_def)
  next
    fix t
    show "(v i - 2) / 4 * (- exp (- t) - - 2 * exp (- 2 * t))
          = - SIG * VF t i + Inst.Ev t i * Inst.eps 1 t"
      by (simp add: i0 inst_Ev0 inst_eps1 SIG_def VF_def v_def
                    exp_sq field_simps)
  qed
next
  fix i :: nat assume i: "i < 1"
  have i0: "i = 0" using i by simp
  show "Deriv (\<lambda>t. ALP t i)
              (\<lambda>t. GN * (- (\<Sum>j<1. MF t i j * ALP t j)
                         - Inst.Ev t i * Inst.EalpF t - VF t i
                         - Inst.Ev t i * Inst.eps 1 t))"
  proof (rule Deriv_cong[OF Deriv_const[of "ASTAR i"]])
    fix t show "ASTAR i = ALP t i" by (simp add: ALP_def)
  next
    fix t
    show "(0::real) = GN * (- (\<Sum>j<1. MF t i j * ALP t j)
                           - Inst.Ev t i * Inst.EalpF t - VF t i
                           - Inst.Ev t i * Inst.eps 1 t)"
      by (simp add: i0 lessThan_1 inst_Ev0 inst_EalpF inst_eps1
                    GN_def MF_def VF_def ALP_def ASTAR_def v_def
                    exp_sq field_simps)
  qed
qed

section \<open>The main theorem, instantiated\<close>

text \<open>Convex-hull invariance holds for this instance, and it is not vacuous:
  the individual estimates both differ from theta*_p = 1 at every finite t,
  yet their fixed convex combination is exactly 1.\<close>

corollary inst_hull_invariance:
  "0 \<le> t \<Longrightarrow> j < 1 \<Longrightarrow> Inst.tha t j = 0"
  by (rule Inst.hull_invariance)

corollary inst_theta_star_in_hull:
  "0 \<le> t \<Longrightarrow> j < 1 \<Longrightarrow> (\<Sum>i<2. TH i t j * ASTAR i) = THSTAR j"
  by (rule Inst.theta_star_in_hull)

corollary inst_ea_zero: "0 \<le> t \<Longrightarrow> Inst.ea t = 0"
  by (rule Inst.ea_zero)

text \<open>Independent check by direct computation: the same identity obtained
  WITHOUT the theorem.  Agreement confirms the instance really is a model of
  the assumptions rather than an artefact of the encoding.  Note that, unlike
  @{thm inst_theta_star_in_hull}, this holds for every real t.\<close>

lemma inst_hull_direct: "(\<Sum>i<2. TH i t 0 * ASTAR i) = 1"
  by (simp add: lessThan_2 TH_def ASTAR_def v_def field_simps)

text \<open>The estimates are genuinely distinct: model 0 never equals theta*_p.\<close>

lemma inst_models_are_distinct: "TH 0 t 0 \<noteq> THSTAR 0"
  using exp_gt_zero[of "- t"] by (simp add: TH_def THSTAR_def v_def)

text \<open>... and the second-level regressor E_f is not identically zero either,
  so the instance does not satisfy the assumptions by collapsing them.\<close>

lemma inst_E_nonzero: "Inst.Ev t 0 \<noteq> 0"
  using exp_gt_zero[of "- t"] by (simp add: inst_Ev0)

lemma inst_e_nonzero: "Inst.e 0 t \<noteq> 0"
  using exp_gt_zero[of "- t"] by (simp add: inst_e v_def)

text \<open>... and, unlike the pre-amendment instance, @{text v_f} is genuinely
  nonzero, so the residual term that (4.69) omits is actually exercised.\<close>

lemma inst_vf_nonzero: "0 < t \<Longrightarrow> VF t 0 \<noteq> 0"
proof -
  assume t: "0 < t"
  have "exp (- 2 * t) < exp (- t)" using t by simp
  thus ?thesis by (simp add: VF_def v_def)
qed

end
