(* Temporary audit theory: restates the headline results verbatim and proves
   each one by a single `rule` from the theorem it claims to be.  If any
   statement below differed from what the development actually proves, this
   theory would not compile. *)
theory SLA_Check
  imports SLA_Instance SLA_AppendixA
begin

context first_level begin
lemma chk_4_15: "i < N \<Longrightarrow> e i t = dot d (tht i t) (phi t)"
  by (rule e_eq_dot_tht)
lemma chk_4_23: "i < N \<Longrightarrow>
  Deriv (V1 i) (\<lambda>t. - (eps i t * eps i t * msq t))" by (rule V1_dyn)
end

context hull_models begin
lemma chk_hull: "0 \<le> t \<Longrightarrow> j < d \<Longrightarrow>
  (\<Sum>i<N. th i t j * astar i) = thstar j" by (rule theta_star_in_hull)
lemma chk_4_45: "0 \<le> t \<Longrightarrow> ea t = 0" by (rule ea_zero)
end

context second_level begin
lemma chk_4_49: "(\<Sum>i<M. Ev t i * astar i) = - eps M t + ea t / msq t"
  by (rule E_alpha_star)
lemma chk_4_51: "0 \<le> t \<Longrightarrow> (\<Sum>i<M. Ev t i * astar i) = - eps M t"
  by (rule E_alpha_star_exact)
lemma chk_N_is_d1: "M = d" by (rule M_eq_d)
end

context sla begin
text \<open>(4.58) as the dissertation writes it vs. the exact derivative.\<close>
lemma chk_4_58_exact:
  "Deriv Vb (\<lambda>t. - ((Ealpt t + Sb t * SE t) * (Ealpt t + ea t / msq t)))"
  by (rule Vb_dyn)
lemma chk_4_58_positive:
  "ea t = 0 \<Longrightarrow> Ealpt t = 1 \<Longrightarrow> Sb t = - 2 \<Longrightarrow> SE t = 1 \<Longrightarrow>
   0 < - ((Ealpt t + Sb t * SE t) * (Ealpt t + ea t / msq t))"
  by (rule Vb_deriv_can_be_positive)
lemma chk_4_58_witness:
  "M = 2 \<Longrightarrow> ea t = 0 \<Longrightarrow> Ev t 0 = 2 \<Longrightarrow> Ev t 1 = - 1 \<Longrightarrow>
   alpt t 0 = - 1/3 \<Longrightarrow> alpt t 1 = - 5/3 \<Longrightarrow>
   Ealpt t = 1 \<and> Sb t = - 2 \<and> SE t = 1
   \<and> - ((Ealpt t + Sb t * SE t) * (Ealpt t + ea t / msq t)) = 1
   \<and> - (real (Suc M) * (Ealpt t * Ealpt t)) = - 3"
  by (rule Vb_deriv_positive_witness)
end

context slaff begin
lemma chk_Mf_psd: "0 \<le> t \<Longrightarrow> 0 \<le> MQ x t" by (rule Mf_psd)
lemma chk_qres: "(\<And>t. ea t = 0) \<Longrightarrow> 0 \<le> t \<Longrightarrow> i < M \<Longrightarrow> qres t i = 0"
  by (rule qres_zero)
end

lemma chk_uniq:
  "0 < p \<Longrightarrow> (\<And>i. i < p \<Longrightarrow> wlo i < whi i) \<Longrightarrow> (\<Sum>k<Suc p. a k) = 1 \<Longrightarrow>
   (\<And>j. j < p \<Longrightarrow> (\<Sum>k<Suc p. a k * vtx2 p wlo whi k j) = w j) \<Longrightarrow>
   k \<le> p \<Longrightarrow> a k = alpha p (u2 wlo whi w) k"
  by (rule theorem2_uniqueness)

lemma chk_inst_unique:
  "(\<Sum>i<2. a i) = 1 \<Longrightarrow>
   (\<And>j. j < 1 \<Longrightarrow> (\<Sum>i<2. TH i 0 j * a i) = THSTAR j) \<Longrightarrow>
   i < 2 \<Longrightarrow> a i = ASTAR i"
  by (rule inst_astar_unique)

lemma chk_inst_hull: "0 \<le> t \<Longrightarrow> j < 1 \<Longrightarrow> Inst.tha t j = 0"
  by (rule inst_hull_invariance)

end
