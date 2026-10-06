(*  Title:      SLA_AppendixA.thy
    Author:     Isabelle/HOL port of the Coq development in ../coq

    Appendix A of the dissertation: convex combinations.

    These are the two theorems the dissertation invokes (Appendix A, used in
    Chapter 2 and again in Chapter 4 just above eq. 4.46) to justify the design
    rule

        N = 2n + 1 = d + 1   models,   d = 2n = dim(theta*_p),

    namely that the box of uncertainty in R^d -- the polytope with 2^d vertices
    given by all combinations of the known bounds -- is contained in a simplex
    with only d+1 vertices, so every point of the box, and in particular
    theta*_p, is a convex combination of d+1 chosen parameter vectors.

      Theorem 1 (A.1-A.10): the unit box [0,1]^p.
      Theorem 2 (A.11):     a general box [w_i^-, w_i^+].

    Vertices are indexed 0..p: index k < p is the k-th non-trivial vertex,
    index p is the base vertex (the origin in Theorem 1, w^- in Theorem 2).

    AMENDMENT (see ../NOTE_convex_uniqueness.md).  The dissertation writes the
    design rule as N >= 2n+1.  That inequality is correct for EXISTENCE of a
    representation, which is what the text's own justification argues for, but
    it is not sufficient for UNIQUENESS: with N unknowns and d+1 equations
    (d coordinates plus sum-to-one) the solution family has dimension
    N - (d+1), which is zero iff N = d+1.  Since the second level treats
    alpha*_f as the parameter it identifies, alpha*_f must be a single point.
    Nothing is lost, because the vertices Theorem 2 constructs are exactly d+1
    and are affinely independent: theorem1_uniqueness and theorem2_uniqueness
    below, and design_rule_exact, which gives existence AND uniqueness.
    more_vertices_not_unique shows the failure is real for N > d+1.
*)

theory SLA_AppendixA
  imports SLA_Prelim
begin

section \<open>The simplex coefficients (A.4) and (A.7)\<close>

definition alpha :: "nat \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> nat \<Rightarrow> real"
  where "alpha p u k =
           (if k < p then u k / real p else 1 - (\<Sum>i<p. u i / real p))"

lemma alpha_low: "k < p \<Longrightarrow> alpha p u k = u k / real p"
  by (simp add: alpha_def)

lemma alpha_top: "alpha p u p = 1 - (\<Sum>i<p. u i / real p)"
  by (simp add: alpha_def)

text \<open>(A.6)\<close>

lemma sum_u_bounds:
  assumes p: "0 < p" and u: "\<And>i. i < p \<Longrightarrow> 0 \<le> u i \<and> u i \<le> 1"
  shows "0 \<le> (\<Sum>i<p. u i / real p) \<and> (\<Sum>i<p. u i / real p) \<le> 1"
proof
  show "0 \<le> (\<Sum>i<p. u i / real p)"
    using p u by (intro sum_nonneg) auto
next
  have "(\<Sum>i<p. u i / real p) \<le> (\<Sum>i<p. 1 / real p)"
    using p u by (intro sum_mono divide_right_mono) auto
  also have "\<dots> = 1" using p by simp
  finally show "(\<Sum>i<p. u i / real p) \<le> 1" .
qed

text \<open>(A.5) + (A.8): the coefficients are legitimate convex weights.\<close>

theorem alpha_bounds:
  assumes p: "0 < p" and u: "\<And>i. i < p \<Longrightarrow> 0 \<le> u i \<and> u i \<le> 1" and k: "k \<le> p"
  shows "0 \<le> alpha p u k \<and> alpha p u k \<le> 1"
proof (cases "k < p")
  case True
  have p1: "1 \<le> real p" using p by simp
  have "0 \<le> u k / real p" using u[OF True] p by simp
  moreover have "u k / real p \<le> 1"
  proof -
    have "u k / real p \<le> 1 / real p"
      using u[OF True] p by (intro divide_right_mono) auto
    also have "\<dots> \<le> 1" using p1 by simp
    finally show ?thesis .
  qed
  ultimately show ?thesis by (simp add: alpha_low[OF True])
next
  case False
  with k have "k = p" by simp
  thus ?thesis using sum_u_bounds[OF p u] by (simp add: alpha_top)
qed

text \<open>(A.10)\<close>

theorem alpha_sum: "(\<Sum>k<Suc p. alpha p u k) = 1"
proof -
  have "(\<Sum>k<Suc p. alpha p u k) = (\<Sum>k<p. alpha p u k) + alpha p u p"
    by simp
  also have "(\<Sum>k<p. alpha p u k) = (\<Sum>k<p. u k / real p)"
    by (rule sum.cong) (auto simp: alpha_low)
  finally show ?thesis by (simp add: alpha_top)
qed

section \<open>Theorem 1 (A.1-A.10): the unit box [0,1]^p\<close>

text \<open>Containing simplex P: the origin (index p) and the p vectors p*e_k.\<close>

definition vtx1 :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> real"
  where "vtx1 p k j = (if k = j then real p else 0)"

text \<open>The value of an arbitrary affine combination of the Theorem 1 vertices.
  This is what makes the coefficients recoverable, i.e. unique.\<close>

lemma sum_a_vtx1:
  assumes j: "j < p"
  shows "(\<Sum>k<Suc p. a k * vtx1 p k j) = a j * real p"
proof -
  have top: "vtx1 p p j = 0" using j by (simp add: vtx1_def)
  have "(\<Sum>k<Suc p. a k * vtx1 p k j) = (\<Sum>k<p. a k * vtx1 p k j)"
    by (simp add: top)
  also have "\<dots> = (\<Sum>k<p. if k = j then a j * real p else 0)"
    by (rule sum.cong) (auto simp: vtx1_def)
  also have "\<dots> = a j * real p" using j by simp
  finally show ?thesis .
qed

text \<open>(A.9)\<close>

theorem theorem1_representation:
  assumes p: "0 < p" and w: "\<And>i. i < p \<Longrightarrow> 0 \<le> w i \<and> w i \<le> 1" and j: "j < p"
  shows "(\<Sum>k<Suc p. alpha p w k * vtx1 p k j) = w j"
proof -
  have "(\<Sum>k<Suc p. alpha p w k * vtx1 p k j) = alpha p w j * real p"
    by (rule sum_a_vtx1[OF j])
  also have "\<dots> = w j" using p by (simp add: alpha_low[OF j])
  finally show ?thesis .
qed

theorem theorem1_convexity:
  assumes p: "0 < p" and w: "\<And>i. i < p \<Longrightarrow> 0 \<le> w i \<and> w i \<le> 1"
  shows "(\<Sum>k<Suc p. alpha p w k) = 1
         \<and> (\<forall>k \<le> p. 0 \<le> alpha p w k \<and> alpha p w k \<le> 1)"
proof (intro conjI)
  show "(\<Sum>k<Suc p. alpha p w k) = 1" by (rule alpha_sum)
next
  show "\<forall>k \<le> p. 0 \<le> alpha p w k \<and> alpha p w k \<le> 1"
  proof (intro allI impI)
    fix k assume k: "k \<le> p"
    show "0 \<le> alpha p w k \<and> alpha p w k \<le> 1"
    proof (rule alpha_bounds)
      show "0 < p" by (rule p)
      show "\<And>i. i < p \<Longrightarrow> 0 \<le> w i \<and> w i \<le> 1" by (rule w)
      show "k \<le> p" by (rule k)
    qed
  qed
qed

text \<open>UNIQUENESS for Theorem 1.  Any coefficient vector that sums to one and
  reproduces w from the same vertices IS the vector of (A.4).  Note that no
  box-membership and no nonnegativity hypothesis on a is needed: this is an
  affine-independence fact, not a convexity fact.\<close>

theorem theorem1_uniqueness:
  assumes p: "0 < p"
      and asum: "(\<Sum>k<Suc p. a k) = 1"
      and arep: "\<And>j. j < p \<Longrightarrow> (\<Sum>k<Suc p. a k * vtx1 p k j) = w j"
      and k: "k \<le> p"
  shows "a k = alpha p w k"
proof -
  have pz: "real p \<noteq> 0" using p by simp
  have low: "a i = w i / real p" if "i < p" for i
  proof -
    have "a i * real p = w i" using arep[OF that] sum_a_vtx1[OF that] by simp
    thus ?thesis using pz by (simp add: field_simps)
  qed
  show ?thesis
  proof (cases "k < p")
    case True
    thus ?thesis by (simp add: alpha_low low)
  next
    case False
    with k have keq: "k = p" by simp
    have "(\<Sum>i<p. a i) = (\<Sum>i<p. w i / real p)"
      by (rule sum.cong) (auto simp: low)
    moreover have "(\<Sum>k<Suc p. a k) = (\<Sum>i<p. a i) + a p" by simp
    ultimately have "a p = 1 - (\<Sum>i<p. w i / real p)" using asum by simp
    thus ?thesis by (simp add: keq alpha_top)
  qed
qed

section \<open>Theorem 2 (A.11): a general box\<close>

text \<open>Containing simplex W: w^- (index p) and w^- + p e_k (w_k^+ - w_k^-).\<close>

definition u2 :: "(nat \<Rightarrow> real) \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> nat \<Rightarrow> real"
  where "u2 wlo whi w i = (w i - wlo i) / (whi i - wlo i)"

definition vtx2 :: "nat \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> (nat \<Rightarrow> real) \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> real"
  where "vtx2 p wlo whi k j =
           wlo j + (if k = j then real p * (whi j - wlo j) else 0)"

lemma u2_bounds:
  assumes nd: "\<And>i. i < p \<Longrightarrow> wlo i < whi i"
      and box: "\<And>i. i < p \<Longrightarrow> wlo i \<le> w i \<and> w i \<le> whi i"
      and i: "i < p"
  shows "0 \<le> u2 wlo whi w i \<and> u2 wlo whi w i \<le> 1"
proof
  show "0 \<le> u2 wlo whi w i" using nd[OF i] box[OF i] by (simp add: u2_def)
next
  have "(w i - wlo i) / (whi i - wlo i) \<le> 1"
    using nd[OF i] box[OF i] by simp
  thus "u2 wlo whi w i \<le> 1" by (simp add: u2_def)
qed

text \<open>The value of an arbitrary AFFINE combination of the Theorem 2 vertices.
  Unlike Theorem 1 this needs the sum-to-one hypothesis, because every vertex
  carries the base point w^-.\<close>

lemma sum_a_vtx2:
  assumes j: "j < p" and asum: "(\<Sum>k<Suc p. a k) = 1"
  shows "(\<Sum>k<Suc p. a k * vtx2 p wlo whi k j)
         = wlo j + a j * (real p * (whi j - wlo j))"
proof -
  have SP: "(\<Sum>k<Suc p. a k * vtx2 p wlo whi k j)
        = wlo j * (\<Sum>k<Suc p. a k)
          + (\<Sum>k<Suc p. if k = j
                        then a k * (real p * (whi j - wlo j)) else 0)"
  proof -
    have E1: "(\<Sum>k<Suc p. a k * vtx2 p wlo whi k j)
          = (\<Sum>k<Suc p. wlo j * a k
                        + (if k = j
                           then a k * (real p * (whi j - wlo j)) else 0))"
      by (rule sum.cong) (auto simp: vtx2_def algebra_simps)
    have E2: "(\<Sum>k<Suc p. wlo j * a k
                        + (if k = j
                           then a k * (real p * (whi j - wlo j)) else 0))
          = (\<Sum>k<Suc p. wlo j * a k)
            + (\<Sum>k<Suc p. if k = j
                          then a k * (real p * (whi j - wlo j)) else 0)"
      by (rule sum.distrib)
    have E3: "(\<Sum>k<Suc p. wlo j * a k) = wlo j * (\<Sum>k<Suc p. a k)"
      by (rule sum_distrib_left[symmetric])
    show ?thesis unfolding E1 E2 E3 by (rule refl)
  qed
  have SL: "(\<Sum>k<Suc p. if k = j
                        then a k * (real p * (whi j - wlo j)) else 0)
            = a j * (real p * (whi j - wlo j))"
    using j by simp
  show ?thesis unfolding SP SL asum by simp
qed

text \<open>(A.11)\<close>

theorem theorem2_representation:
  assumes p: "0 < p"
      and nd: "\<And>i. i < p \<Longrightarrow> wlo i < whi i"
      and box: "\<And>i. i < p \<Longrightarrow> wlo i \<le> w i \<and> w i \<le> whi i"
      and j: "j < p"
  shows "(\<Sum>k<Suc p. alpha p (u2 wlo whi w) k * vtx2 p wlo whi k j) = w j"
proof -
  have nz: "whi j - wlo j \<noteq> 0" using nd[OF j] by simp
  have pz: "real p \<noteq> 0" using p by simp
  have "(\<Sum>k<Suc p. alpha p (u2 wlo whi w) k * vtx2 p wlo whi k j)
        = wlo j + alpha p (u2 wlo whi w) j * (real p * (whi j - wlo j))"
    by (rule sum_a_vtx2[OF j alpha_sum])
  also have "alpha p (u2 wlo whi w) j * (real p * (whi j - wlo j))
             = w j - wlo j"
    using nz pz by (simp add: alpha_low[OF j] u2_def)
  finally show ?thesis by simp
qed

theorem theorem2_convexity:
  assumes p: "0 < p"
      and nd: "\<And>i. i < p \<Longrightarrow> wlo i < whi i"
      and box: "\<And>i. i < p \<Longrightarrow> wlo i \<le> w i \<and> w i \<le> whi i"
  shows "(\<Sum>k<Suc p. alpha p (u2 wlo whi w) k) = 1
         \<and> (\<forall>k \<le> p. 0 \<le> alpha p (u2 wlo whi w) k
                    \<and> alpha p (u2 wlo whi w) k \<le> 1)"
proof (intro conjI)
  show "(\<Sum>k<Suc p. alpha p (u2 wlo whi w) k) = 1" by (rule alpha_sum)
next
  show "\<forall>k \<le> p. 0 \<le> alpha p (u2 wlo whi w) k
                 \<and> alpha p (u2 wlo whi w) k \<le> 1"
  proof (intro allI impI)
    fix k assume k: "k \<le> p"
    show "0 \<le> alpha p (u2 wlo whi w) k
          \<and> alpha p (u2 wlo whi w) k \<le> 1"
    proof (rule alpha_bounds)
      show "0 < p" by (rule p)
      show "\<And>i. i < p \<Longrightarrow>
              0 \<le> u2 wlo whi w i \<and> u2 wlo whi w i \<le> 1"
        by (rule u2_bounds[OF nd box])
      show "k \<le> p" by (rule k)
    qed
  qed
qed

text \<open>UNIQUENESS for Theorem 2.  Note that the box-membership hypothesis
  @{text "wlo \<le> w \<le> whi"} is NOT needed: uniqueness is an affine-independence
  fact and holds for every w, inside the box or not.  Neither is any
  nonnegativity hypothesis on a.\<close>

theorem theorem2_uniqueness:
  assumes p: "0 < p"
      and nd: "\<And>i. i < p \<Longrightarrow> wlo i < whi i"
      and asum: "(\<Sum>k<Suc p. a k) = 1"
      and arep: "\<And>j. j < p \<Longrightarrow>
                   (\<Sum>k<Suc p. a k * vtx2 p wlo whi k j) = w j"
      and k: "k \<le> p"
  shows "a k = alpha p (u2 wlo whi w) k"
proof -
  have pz: "real p \<noteq> 0" using p by simp
  have low: "a i = u2 wlo whi w i / real p" if "i < p" for i
  proof -
    have nz: "whi i - wlo i \<noteq> 0" using nd[OF that] by simp
    have "wlo i + a i * (real p * (whi i - wlo i)) = w i"
      using arep[OF that] sum_a_vtx2[OF that asum] by simp
    hence "a i * (real p * (whi i - wlo i)) = w i - wlo i" by simp
    thus ?thesis using nz pz by (simp add: u2_def field_simps)
  qed
  show ?thesis
  proof (cases "k < p")
    case True
    thus ?thesis by (simp add: alpha_low low)
  next
    case False
    with k have keq: "k = p" by simp
    have "(\<Sum>i<p. a i) = (\<Sum>i<p. u2 wlo whi w i / real p)"
      by (rule sum.cong) (auto simp: low)
    moreover have "(\<Sum>k<Suc p. a k) = (\<Sum>i<p. a i) + a p" by simp
    ultimately have "a p = 1 - (\<Sum>i<p. u2 wlo whi w i / real p)"
      using asum by simp
    thus ?thesis by (simp add: keq alpha_top)
  qed
qed

section \<open>More than d+1 vertices really does destroy uniqueness\<close>

text \<open>The smallest instance is @{text "d = 1"} with three points
  @{text "w3 = (0,2,1)"}: the target 1 is a convex combination of them in at
  least two genuinely different ways.  This is the one-dimensional shadow of
  the hexagon example of ../NOTE_convex_uniqueness.md -- six points in R^2
  carry a 3-parameter family of representations of any interior point.

  Note that both witnesses are honest CONVEX combinations (nonnegative,
  summing to one), so the degeneracy is not an artefact of allowing negative
  coefficients.\<close>

definition w3 :: "nat \<Rightarrow> real"
  where "w3 i = (if i = 0 then 0 else if i = 1 then 2 else 1)"

definition aA :: "nat \<Rightarrow> real"
  where "aA i = (if i = 0 then 1/2 else if i = 1 then 1/2 else 0)"

definition aB :: "nat \<Rightarrow> real"
  where "aB i = (if i = 0 then 0 else if i = 1 then 0 else 1)"

theorem more_vertices_not_unique:
  "(\<Sum>i<3. aA i) = 1
   \<and> (\<Sum>i<3. aB i) = 1
   \<and> (\<forall>i<3. 0 \<le> aA i \<and> aA i \<le> 1)
   \<and> (\<forall>i<3. 0 \<le> aB i \<and> aB i \<le> 1)
   \<and> (\<Sum>k<3. aA k * w3 k) = 1
   \<and> (\<Sum>k<3. aB k * w3 k) = 1
   \<and> aA 0 \<noteq> aB 0"
proof (intro conjI)
  show "(\<Sum>i<3. aA i) = 1" by (simp add: lessThan_3 aA_def)
  show "(\<Sum>i<3. aB i) = 1" by (simp add: lessThan_3 aB_def)
  show "\<forall>i<3. 0 \<le> aA i \<and> aA i \<le> 1" by (simp add: aA_def)
  show "\<forall>i<3. 0 \<le> aB i \<and> aB i \<le> 1" by (simp add: aB_def)
  show "(\<Sum>k<3. aA k * w3 k) = 1" by (simp add: lessThan_3 aA_def w3_def)
  show "(\<Sum>k<3. aB k * w3 k) = 1" by (simp add: lessThan_3 aB_def w3_def)
  show "aA 0 \<noteq> aB 0" by (simp add: aA_def aB_def)
qed

section \<open>The design rule N = 2n+1\<close>

text \<open>Instantiating Theorem 2 with @{text "p = d = 2n"} and the box of known
  bounds gives exactly the statement used in Chapter 4: @{text "d+1"} initial
  parameter vectors can be chosen so that theta*_p is a convex combination of
  them -- i.e. @{text "N = 2n+1"} models suffice, which is the assumption
  @{text H_astar_init} of @{text SLA_Chapter4}.

  The converse ("fewer than d+1 points cannot do it") is a statement about
  affine dimension; the dissertation asserts it on page 64 and it is NOT
  formalised here.\<close>

corollary design_rule_suffices:
  fixes d :: nat and alo ahi theta :: "nat \<Rightarrow> real"
  assumes d: "0 < d"
      and nd: "\<And>i. i < d \<Longrightarrow> alo i < ahi i"
      and box: "\<And>i. i < d \<Longrightarrow> alo i \<le> theta i \<and> theta i \<le> ahi i"
  shows "\<exists>vertex a. (\<Sum>k<Suc d. a k) = 1
                    \<and> (\<forall>k \<le> d. 0 \<le> a k \<and> a k \<le> 1)
                    \<and> (\<forall>j < d. (\<Sum>k<Suc d. a k * vertex k j) = theta j)"
proof (intro exI conjI)
  show "(\<Sum>k<Suc d. alpha d (u2 alo ahi theta) k) = 1" by (rule alpha_sum)
next
  show "\<forall>k \<le> d. 0 \<le> alpha d (u2 alo ahi theta) k
                \<and> alpha d (u2 alo ahi theta) k \<le> 1"
  proof (intro allI impI)
    fix k assume k: "k \<le> d"
    show "0 \<le> alpha d (u2 alo ahi theta) k
          \<and> alpha d (u2 alo ahi theta) k \<le> 1"
    proof (rule alpha_bounds)
      show "0 < d" by (rule d)
      show "\<And>i. i < d \<Longrightarrow>
              0 \<le> u2 alo ahi theta i \<and> u2 alo ahi theta i \<le> 1"
        by (rule u2_bounds[OF nd box])
      show "k \<le> d" by (rule k)
    qed
  qed
next
  show "\<forall>j < d. (\<Sum>k<Suc d. alpha d (u2 alo ahi theta) k
                            * vtx2 d alo ahi k j) = theta j"
  proof (intro allI impI)
    fix j assume j: "j < d"
    show "(\<Sum>k<Suc d. alpha d (u2 alo ahi theta) k * vtx2 d alo ahi k j)
          = theta j"
    proof (rule theorem2_representation)
      show "0 < d" by (rule d)
      show "\<And>i. i < d \<Longrightarrow> alo i < ahi i" by (rule nd)
      show "\<And>i. i < d \<Longrightarrow> alo i \<le> theta i \<and> theta i \<le> ahi i"
        by (rule box)
      show "j < d" by (rule j)
    qed
  qed
qed

text \<open>The AMENDED rule: with exactly @{text "d+1 = 2n+1"} models the convex
  representation of theta*_p not only exists but is the ONLY one.  This is the
  statement Chapter 4 needs in order for alpha*_f to be a well-defined
  identification target, and it is what @{text H_N_exact} of
  @{text SLA_Chapter4} assumes.\<close>

corollary design_rule_exact:
  fixes d :: nat and alo ahi theta :: "nat \<Rightarrow> real"
  assumes d: "0 < d"
      and nd: "\<And>i. i < d \<Longrightarrow> alo i < ahi i"
      and box: "\<And>i. i < d \<Longrightarrow> alo i \<le> theta i \<and> theta i \<le> ahi i"
  shows "\<exists>vertex a.
           (\<Sum>k<Suc d. a k) = 1
           \<and> (\<forall>k \<le> d. 0 \<le> a k \<and> a k \<le> 1)
           \<and> (\<forall>j < d. (\<Sum>k<Suc d. a k * vertex k j) = theta j)
           \<and> (\<forall>b. (\<Sum>k<Suc d. b k) = 1
                  \<longrightarrow> (\<forall>j < d. (\<Sum>k<Suc d. b k * vertex k j) = theta j)
                  \<longrightarrow> (\<forall>k \<le> d. b k = a k))"
proof (intro exI conjI)
  show "(\<Sum>k<Suc d. alpha d (u2 alo ahi theta) k) = 1" by (rule alpha_sum)
next
  show "\<forall>k \<le> d. 0 \<le> alpha d (u2 alo ahi theta) k
                \<and> alpha d (u2 alo ahi theta) k \<le> 1"
  proof (intro allI impI)
    fix k assume k: "k \<le> d"
    show "0 \<le> alpha d (u2 alo ahi theta) k
          \<and> alpha d (u2 alo ahi theta) k \<le> 1"
    proof (rule alpha_bounds)
      show "0 < d" by (rule d)
      show "\<And>i. i < d \<Longrightarrow>
              0 \<le> u2 alo ahi theta i \<and> u2 alo ahi theta i \<le> 1"
        by (rule u2_bounds[OF nd box])
      show "k \<le> d" by (rule k)
    qed
  qed
next
  show "\<forall>j < d. (\<Sum>k<Suc d. alpha d (u2 alo ahi theta) k
                            * vtx2 d alo ahi k j) = theta j"
  proof (intro allI impI)
    fix j assume j: "j < d"
    show "(\<Sum>k<Suc d. alpha d (u2 alo ahi theta) k * vtx2 d alo ahi k j)
          = theta j"
    proof (rule theorem2_representation)
      show "0 < d" by (rule d)
      show "\<And>i. i < d \<Longrightarrow> alo i < ahi i" by (rule nd)
      show "\<And>i. i < d \<Longrightarrow> alo i \<le> theta i \<and> theta i \<le> ahi i"
        by (rule box)
      show "j < d" by (rule j)
    qed
  qed
next
  show "\<forall>b. (\<Sum>k<Suc d. b k) = 1
            \<longrightarrow> (\<forall>j < d. (\<Sum>k<Suc d. b k * vtx2 d alo ahi k j) = theta j)
            \<longrightarrow> (\<forall>k \<le> d. b k = alpha d (u2 alo ahi theta) k)"
  proof (intro allI impI)
    fix b :: "nat \<Rightarrow> real" and k :: nat
    assume bsum: "(\<Sum>k<Suc d. b k) = 1"
    assume brep: "\<forall>j < d. (\<Sum>k<Suc d. b k * vtx2 d alo ahi k j)
                            = theta j"
    assume k: "k \<le> d"
    show "b k = alpha d (u2 alo ahi theta) k"
    proof (rule theorem2_uniqueness)
      show "0 < d" by (rule d)
      show "\<And>i. i < d \<Longrightarrow> alo i < ahi i" by (rule nd)
      show "(\<Sum>k<Suc d. b k) = 1" by (rule bsum)
      show "\<And>j. j < d \<Longrightarrow>
              (\<Sum>k<Suc d. b k * vtx2 d alo ahi k j) = theta j"
        using brep by blast
      show "k \<le> d" by (rule k)
    qed
  qed
qed

end
