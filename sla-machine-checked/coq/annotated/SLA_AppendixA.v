(** * SLA_AppendixA.v — ANNOTATED COPY

    Identical Coq code to ../SLA_AppendixA.v, with a block comment before
    every item explaining the syntax.

    ====================================================================
    WHAT IS BEING PROVED
    ====================================================================

    Appendix A of the dissertation, invoked in Chapter 2 and again in
    Chapter 4 just above (4.46), to justify the design rule

        N >= 2n + 1  =  d + 1     models,    d = 2n = dim(theta*_p):

    the box of uncertainty in R^d — the polytope with 2^d vertices given by
    all combinations of the known bounds a_i^-, a_i^+, b_i^-, b_i^+ — is
    contained in a SIMPLEX with only d+1 vertices, so every point of the box,
    in particular theta*_p, is a convex combination of d+1 chosen parameter
    vectors.

      Theorem 1 (A.1-A.10): the unit box [0,1]^p.
      Theorem 2 (A.11):     a general box [w_i^-, w_i^+].

    ====================================================================
    THE INDEXING CONVENTION
    ====================================================================

    Vertices are numbered 0..p, i.e. p+1 of them:

        index k < p   the k-th non-trivial vertex
        index p       the base vertex (the origin in Thm 1, w^- in Thm 2)

    This ordering is chosen because Sum peels off the LAST index, so the base
    vertex is the one that separates cleanly from the sum.

    Two representation tricks make the proofs short:

    (i)  A vertex matrix is just a doubly indexed family.  V1 p k j is the
         j-th coordinate of the k-th vertex.  Writing

             V1 p k j = if Nat.eqb k j then INR p else 0

         makes indices k < p the scaled unit vectors p*e_k AND simultaneously
         makes index p the ZERO vector, because for j < p we always have
         p <> j so the test is false.  No case distinction is needed.

    (ii) The coefficient vector uses one 'if' on k < p:

             alpha p u k = if k < p then u_k / p else 1 - sum_i u_i / p

         so alpha_0..alpha_{p-1} are the scaled coordinates and alpha_p is
         the slack that makes them sum to one.

    ====================================================================
    NEW SYNTAX APPEARING IN THIS FILE
    ====================================================================

    Nat.eqb i j        BOOLEAN equality test on naturals (true / false),
                       as opposed to the PROPOSITION i = j.
    Nat.ltb k p        boolean less-than.
    if b then x else y conditional on a boolean.
    destruct B eqn:E   case-split on the boolean expression B, and record
                       which branch you are in as the equation E.
    Nat.ltb_lt         (n <? m) = true  <->  n < m
    Nat.ltb_ge         (n <? m) = false <->  m <= n
    Nat.eqb_eq         (n =? m) = true  <->  n = m
    proj2 (L a b) H    'proj2' takes the right half of a conjunction or
                       of an iff; used to turn an iff into the implication
                       you need.
    INR : nat -> R     the injection of naturals into reals.
    split              splits a conjunction goal A /\ B into two goals.
    Rle_trans          transitivity of <= : you supply the middle term.

    Everything here is stated with EXPLICIT arguments (no Section variables),
    so the statements can be used directly without worrying about which
    hypotheses Coq chose to abstract over. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Local Open Scope R_scope.

(* ---------------------------------------------------------------------
   Three facts about INR p that every proof below needs.

   lt_0_INR : (0 < n)%nat -> 0 < INR n     (standard library)
   le_INR   : (n <= m)%nat -> INR n <= INR m

   In INRp_ge1, 'replace 1 with (INR 1) by (simpl; ring)' turns the real
   literal 1 into INR 1 so that le_INR applies; the side proof simplifies
   INR 1 to 1 and closes by ring.
   --------------------------------------------------------------------- *)
Lemma INRp_pos : forall p, (0 < p)%nat -> 0 < INR p.
Proof. intros p Hp. apply lt_0_INR. assumption. Qed.

Lemma INRp_neq0 : forall p, (0 < p)%nat -> INR p <> 0.
Proof. intros p Hp. pose proof (INRp_pos p Hp). lra. Qed.

Lemma INRp_ge1 : forall p, (0 < p)%nat -> 1 <= INR p.
Proof.
  intros p Hp. replace 1 with (INR 1) by (simpl; ring). apply le_INR. lia.
Qed.

(** ** The simplex coefficients  (A.4) and (A.7) *)

(* ---------------------------------------------------------------------
   (A.4) alpha_k = u_k / p   for k < p
   (A.7) alpha_p = 1 - sum_{i<p} u_i / p

   One definition covers both, via the boolean test Nat.ltb k p (written
   'k <? p' in Coq's notation).
   --------------------------------------------------------------------- *)
Definition alpha (p : nat) (u : nat -> R) (k : nat) : R :=
  if Nat.ltb k p then u k / INR p else 1 - Sum p (fun i => u i / INR p).

(* ---------------------------------------------------------------------
   The two computation rules for alpha, so that later proofs never have to
   reason about the 'if' directly.

   PROOF of alpha_low.
     unfold alpha                     expose the conditional
     destruct (Nat.ltb k p) eqn:E     split on the test, recording it as E
     [reflexivity | ...]              true branch: the two sides coincide
                                      false branch: E : (k <? p) = false,
                                      so Nat.ltb_ge turns it into p <= k,
                                      contradicting Hk : k < p; lia closes.
   alpha_top is the mirror image at k = p, where the test is false.
   --------------------------------------------------------------------- *)
Lemma alpha_low : forall p u k, (k < p)%nat -> alpha p u k = u k / INR p.
Proof.
  intros p u k Hk. unfold alpha.
  destruct (Nat.ltb k p) eqn:E; [reflexivity | apply Nat.ltb_ge in E; lia].
Qed.

Lemma alpha_top : forall p u, alpha p u p = 1 - Sum p (fun i => u i / INR p).
Proof.
  intros p u. unfold alpha.
  destruct (Nat.ltb p p) eqn:E; [apply Nat.ltb_lt in E; lia | reflexivity].
Qed.

(* =====================================================================
   (A.6): 0 <= sum_{i<p} u_i / p <= 1  when every u_i is in [0,1].

   PROOF.  'split' turns the conjunction into two goals.

   LOWER BOUND: each summand is a product of two nonnegative reals
   (u_i >= 0 and 1/p > 0), so Sum_nonneg applies.
     unfold Rdiv           turn u i / INR p into u i * / INR p, so that
                           Rmult_le_pos (0<=a -> 0<=b -> 0<=a*b) matches.
     'left'                the goal 0 <= x is a disjunction 0 < x \/ 0 = x;
                           'left' selects the strict case.

   UPPER BOUND: compare termwise with the constant 1/p and sum.
     Rle_trans with (Sum p (fun _ => 1 / INR p))
                           chain through the intermediate quantity.
     Sum_le                termwise comparison; the summand bound is
                           u_i * (1/p) <= 1 * (1/p) by Rmult_le_compat_r.
     Sum_const             sum of a constant = INR p * that constant.
     replace ... by (field; apply INRp_neq0; assumption)
                           INR p * (1 / INR p) = 1; this needs 'field'
                           because it cancels a division, and field then
                           asks for INR p <> 0.
     lra                   1 <= 1.
   ===================================================================== *)
Lemma sum_u_bounds : forall p u, (0 < p)%nat ->
  (forall i, (i < p)%nat -> 0 <= u i <= 1) ->
  0 <= Sum p (fun i => u i / INR p) <= 1.
Proof.
  intros p u Hp Hu. pose proof (INRp_pos p Hp) as Hpos.
  split.
  - apply Sum_nonneg. intros i Hi. unfold Rdiv.
    apply Rmult_le_pos; [apply Hu; assumption |].
    left. apply Rinv_0_lt_compat. assumption.
  - apply Rle_trans with (Sum p (fun _ => 1 / INR p)).
    + apply Sum_le. intros i Hi. unfold Rdiv.
      apply Rmult_le_compat_r; [left; apply Rinv_0_lt_compat; assumption |].
      apply Hu; assumption.
    + rewrite Sum_const.
      replace (INR p * (1 / INR p)) with 1
        by (field; apply INRp_neq0; assumption).
      lra.
Qed.

(* =====================================================================
   (A.5) + (A.8): every alpha_k lies in [0,1], for k = 0..p.

   Two cases.
     k = p:  alpha_p = 1 - S with 0 <= S <= 1 by (A.6); lra.
     k < p:  alpha_k = u_k / p with 0 <= u_k <= 1 and p >= 1.
             Lower bound: product of nonnegatives.
             Upper bound: u_k/p <= 1/p <= 1.  The last inequality is
             1/p <= 1/1, i.e. Rinv_le_contravar applied to 1 <= p; the
             'rewrite Rmult_1_l, <- Rinv_1' first puts the goal in the shape
             / INR p <= / 1 that Rinv_le_contravar expects.

   'destruct (Hu k Hlt) as [H0 H1]' takes the CONJUNCTION 0 <= u k <= 1
   apart into its two halves.  (In Coq, a <= b <= c is notation for
   a <= b /\ b <= c.)
   ===================================================================== *)
Theorem alpha_bounds : forall p u, (0 < p)%nat ->
  (forall i, (i < p)%nat -> 0 <= u i <= 1) ->
  forall k, (k <= p)%nat -> 0 <= alpha p u k <= 1.
Proof.
  intros p u Hp Hu k Hk.
  pose proof (INRp_pos p Hp) as Hpos. pose proof (INRp_ge1 p Hp) as Hge1.
  destruct (Nat.eq_dec k p) as [->|Hne].
  - rewrite alpha_top. pose proof (sum_u_bounds p u Hp Hu). lra.
  - assert (Hlt : (k < p)%nat) by lia.
    rewrite alpha_low by assumption.
    destruct (Hu k Hlt) as [H0 H1]. unfold Rdiv. split.
    + apply Rmult_le_pos; [assumption | left; apply Rinv_0_lt_compat; assumption].
    + apply Rle_trans with (1 * / INR p).
      * apply Rmult_le_compat_r;
          [left; apply Rinv_0_lt_compat; assumption | assumption].
      * rewrite Rmult_1_l, <- Rinv_1.
        apply Rinv_le_contravar; lra.
Qed.

(* =====================================================================
   (A.10): the p+1 coefficients sum to one.

   Note this needs NO hypothesis at all — not even u_i in [0,1] — because
   alpha_p is DEFINED as the slack.  Convexity (A.5)/(A.8) is what needs the
   bounds; the affine condition is free.

   PROOF.
     cbn [Sum]                Sum (S p) f = Sum p f + f p; only Sum unfolds.
     rewrite alpha_top        evaluate the last coefficient.
     rewrite (Sum_ext p ...)  replace alpha p u by u i / INR p inside the
                              remaining sum, which is legitimate for i < p
                              by alpha_low.
     ring                     S + (1 - S) = 1.
   ===================================================================== *)
Theorem alpha_sum : forall p u, Sum (S p) (alpha p u) = 1.
Proof.
  intros p u. cbn [Sum]. rewrite alpha_top.
  rewrite (Sum_ext p (alpha p u) (fun i => u i / INR p))
    by (intros; apply alpha_low; assumption).
  ring.
Qed.

(** ** Theorem 1 (A.1–A.10): the unit box [0,1]^p *)

(* ---------------------------------------------------------------------
   The vertices of the containing simplex P_{u,2}.

   V1 p k j = the j-th coordinate of the k-th vertex
            = INR p  if k = j,  else 0.

   For k < p this is the vector p*e_k.  For k = p and any coordinate j < p
   the test p =? j is false, so the vertex is the ORIGIN — exactly the base
   vertex of (A.9), obtained for free from the same formula.
   --------------------------------------------------------------------- *)
Definition V1 (p : nat) (k j : nat) : R := if Nat.eqb k j then INR p else 0.

(* =====================================================================
   (A.9): w = alpha_0 * 0 + sum_{k<p} alpha_k (p e_k), coordinatewise.

   PROOF.
     cbn [Sum]                        split off the k = p term.
     assert (Hvp : V1 p p j = 0)      the base vertex has j-th coordinate 0:
                                      Nat.eqb p j must be false since j < p.
                                      ('apply Nat.eqb_eq in E' converts the
                                      boolean equation into p = j, then lia
                                      contradicts Hj.)
     rewrite Hvp                      kill that term.
     rewrite (Sum_ext p A B)          rewrite the remaining summand into
                                      selection form:
                                        if k =? j then w_k/p * p else 0
                                      The obligation is discharged in the
                                      SECOND bullet below, by unfolding V1
                                      and doing a case split; 'destruct
                                      (Nat.eqb k j); ring' handles both
                                      branches with the same tactic.
     Sum_select                       collapses the selection sum to the
                                      j-th term, w_j/p * p.
     field                            cancels: (w_j / p) * p = w_j; side
                                      condition INR p <> 0.

   Note the bullets here are attached to the goals produced by the Sum_ext
   REWRITE (main goal first, side condition second), not to a case split.
   ===================================================================== *)
Theorem theorem1_representation : forall p w, (0 < p)%nat ->
  (forall i, (i < p)%nat -> 0 <= w i <= 1) ->
  forall j, (j < p)%nat -> Sum (S p) (fun k => alpha p w k * V1 p k j) = w j.
Proof.
  intros p w Hp Hw j Hj. cbn [Sum].
  assert (Hvp : V1 p p j = 0).
  { unfold V1. destruct (Nat.eqb p j) eqn:E;
      [apply Nat.eqb_eq in E; lia | reflexivity]. }
  rewrite Hvp.
  rewrite (Sum_ext p (fun k => alpha p w k * V1 p k j)
                     (fun k => if Nat.eqb k j then w k / INR p * INR p else 0)).
  - rewrite (Sum_select p (fun i => w i / INR p * INR p) j Hj).
    field. apply INRp_neq0; assumption.
  - intros k Hk. rewrite (alpha_low p w k Hk). unfold V1.
    destruct (Nat.eqb k j); ring.
Qed.

(* The coefficients really are convex weights.  '/\' is logical conjunction;
   'split' proves the two halves separately.                               *)
Theorem theorem1_convexity : forall p w, (0 < p)%nat ->
  (forall i, (i < p)%nat -> 0 <= w i <= 1) ->
  Sum (S p) (alpha p w) = 1
  /\ forall k, (k <= p)%nat -> 0 <= alpha p w k <= 1.
Proof.
  intros p w Hp Hw. split; [apply alpha_sum | apply alpha_bounds; assumption].
Qed.

(* =====================================================================
   UNIQUENESS.  This is the part the amendment turns on.

   Theorem 1 says a representation EXISTS.  The lemma below says it is the
   ONLY one, which is a different claim and needs the vertices to be
   affinely independent — true here because there are exactly p+1 of them.
   ===================================================================== *)

(* Helper: collapse the sum of 'a k * V1 p k j' down to a single term.

   Read the statement as: for a coordinate j below p, summing the j-th
   coordinate of every vertex weighted by a gives a j * p.  That is because
   V1 p k j is INR p when k = j and 0 otherwise, so all but one term die.

   'cbn [Sum]' unfolds ONE layer of Sum, turning Sum (S p) f into
   Sum p f + f p — that peels off the last (base) vertex, whose j-th
   coordinate is 0 because j < p means p <> j.                            *)
Lemma sum_a_V1 : forall p a j, (j < p)%nat ->
  Sum (S p) (fun k => a k * V1 p k j) = a j * INR p.
Proof.
  intros p a j Hj. cbn [Sum].
  assert (Hvp : V1 p p j = 0).
  { unfold V1. destruct (Nat.eqb p j) eqn:E;
      [apply Nat.eqb_eq in E; lia | reflexivity]. }
  rewrite Hvp.
  rewrite (Sum_ext p (fun k => a k * V1 p k j)
                     (fun k => if Nat.eqb k j then a k * INR p else 0)).
  - rewrite (Sum_select p (fun i => a i * INR p) j Hj). ring.
  - intros k Hk. unfold V1. destruct (Nat.eqb k j); ring.
Qed.

(* THEOREM 1, UNIQUENESS HALF.

   In words: if ANY vector 'a' sums to 1 and reproduces w through the same
   vertices, then a IS the alpha we constructed — coefficient by coefficient.

   Note what is NOT assumed: no bounds on w, and no nonnegativity of a.
   Uniqueness is pure linear algebra; the convexity constraints play no part.

   The proof splits on whether k is the base index p or not:
     - for k < p, the helper gives a k * INR p = w k, so a k = w k / INR p,
       which is exactly what alpha_low says alpha is;
     - for k = p, sum-to-one pins the remaining coefficient.
   'destruct (Nat.eq_dec k p) as [->|Hne]' does the case split; the '->' in
   the first branch means "substitute k := p everywhere" rather than naming
   a hypothesis.                                                           *)
Theorem theorem1_uniqueness : forall p w a, (0 < p)%nat ->
  Sum (S p) a = 1 ->
  (forall j, (j < p)%nat -> Sum (S p) (fun k => a k * V1 p k j) = w j) ->
  forall k, (k <= p)%nat -> a k = alpha p w k.
Proof.
  intros p w a Hp Hsum Hrep k Hk.
  pose proof (INRp_neq0 p Hp) as Hp0.
  assert (Hlow : forall i, (i < p)%nat -> a i = w i / INR p).
  { intros i Hi. pose proof (Hrep i Hi) as H.
    rewrite (sum_a_V1 p a i Hi) in H. rewrite <- H. field. assumption. }
  destruct (Nat.eq_dec k p) as [->|Hne].
  - rewrite alpha_top. cbn [Sum] in Hsum.
    rewrite (Sum_ext p a (fun i => w i / INR p)) in Hsum by assumption. lra.
  - assert (Hlt : (k < p)%nat) by lia.
    rewrite alpha_low by assumption. apply Hlow; assumption.
Qed.

(** ** Theorem 2 (A.11): a general box [w_i^-, w_i^+] *)

(* ---------------------------------------------------------------------
   The normalised coordinates that reduce Theorem 2 to Theorem 1:

       u2_i = (w_i - w_i^-) / (w_i^+ - w_i^-)   in [0,1].

   'wlo' and 'whi' are w^- and w^+.  Note u2 does not depend on p.
   --------------------------------------------------------------------- *)
Definition u2 (wlo whi w : nat -> R) (i : nat) : R :=
  (w i - wlo i) / (whi i - wlo i).

(* ---------------------------------------------------------------------
   The vertices of W_{x,2}: the base vertex w^- (index p) and, for k < p,

       w^- + p e_k (w_k^+ - w_k^-).

   Same trick as V1: for j < p the test p =? j is false, so index p gives
   exactly wlo j, the base vertex.
   --------------------------------------------------------------------- *)
Definition V2 (p : nat) (wlo whi : nat -> R) (k j : nat) : R :=
  wlo j + (if Nat.eqb k j then INR p * (whi j - wlo j) else 0).

(* ---------------------------------------------------------------------
   u2 lands in [0,1] when w is in the box.

   Hnd is the nondegeneracy assumption w_i^- < w_i^+ (needed so the division
   makes sense).

   PROOF of the upper bound.
     Rmult_le_reg_r X          to prove a <= b it suffices to prove
                               a * X <= b * X for some X > 0; here
                               X = whi i - wlo i.
     unfold Rdiv               turn the quotient into a product with an
                               inverse, so that
     Rmult_assoc, Rinv_l       can cancel  / X * X  into 1.  Rinv_l requires
                               X <> 0, discharged by 'by lra' from Hnd.
     lra                       what remains is linear.
   --------------------------------------------------------------------- *)
Lemma u2_bounds : forall p wlo whi w,
  (forall i, (i < p)%nat -> wlo i < whi i) ->
  (forall i, (i < p)%nat -> wlo i <= w i <= whi i) ->
  forall i, (i < p)%nat -> 0 <= u2 wlo whi w i <= 1.
Proof.
  intros p wlo whi w Hnd Hbox i Hi.
  destruct (Hbox i Hi) as [H1 H2]. pose proof (Hnd i Hi) as H3.
  unfold u2. split.
  - apply Rmult_le_pos; [lra | left; apply Rinv_0_lt_compat; lra].
  - apply Rmult_le_reg_r with (whi i - wlo i); [lra|].
    unfold Rdiv. rewrite Rmult_assoc, Rinv_l by lra. lra.
Qed.

(* =====================================================================
   (A.11): every point of the box is a convex combination of the p+1
   vertices of W_{x,2}.

   PROOF.  The summand alpha_k * V2_k j splits into a part proportional to
   wlo j (present for every k) and a selection part (present only at k = j):

       alpha_k * V2 p wlo whi k j
     = wlo j * alpha_k  +  1 * (if k =? j then alpha_k * (p (whi_j - wlo_j)) else 0)

   That rewriting is the Sum_ext, whose obligation is the last bullet
   ('destruct (Nat.eqb k j); ring' — both branches are ring identities).

   Then
     Sum_comb        splits the sum into the two pieces, pulling out the
                     scalars wlo j and 1.
     alpha_sum       the first piece is wlo j * 1.
     Sum_select      the second collapses to alpha_j * (p (whi_j - wlo_j)).
     alpha_low       alpha_j = u2_j / p.
     unfold u2; field
                     (u2_j / p) * p * (whi_j - wlo_j) = w_j - wlo_j, so the
                     total is wlo j + (w_j - wlo_j) = w_j.  'field' needs the
                     two denominators nonzero: INR p (from Hp0) and
                     whi_j - wlo_j (from Hnz), which is why 'lra' is supplied
                     at the end.

   'by lia' after Sum_select discharges the index condition j < S p.
   ===================================================================== *)
Theorem theorem2_representation : forall p wlo whi w, (0 < p)%nat ->
  (forall i, (i < p)%nat -> wlo i < whi i) ->
  (forall i, (i < p)%nat -> wlo i <= w i <= whi i) ->
  forall j, (j < p)%nat ->
    Sum (S p) (fun k => alpha p (u2 wlo whi w) k * V2 p wlo whi k j) = w j.
Proof.
  intros p wlo whi w Hp Hnd Hbox j Hj.
  pose proof (Hnd j Hj) as Hnz. pose proof (INRp_neq0 p Hp) as Hp0.
  rewrite (Sum_ext (S p)
    (fun k => alpha p (u2 wlo whi w) k * V2 p wlo whi k j)
    (fun k => wlo j * alpha p (u2 wlo whi w) k
              + 1 * (if Nat.eqb k j
                     then alpha p (u2 wlo whi w) k * (INR p * (whi j - wlo j))
                     else 0))).
  - rewrite Sum_comb, alpha_sum.
    rewrite (Sum_select (S p)
               (fun k => alpha p (u2 wlo whi w) k * (INR p * (whi j - wlo j))) j)
      by lia.
    rewrite (alpha_low p (u2 wlo whi w) j Hj). unfold u2. field. lra.
  - intros k Hk. unfold V2. destruct (Nat.eqb k j); ring.
Qed.

(* The convexity half of Theorem 2, reduced to the general lemmas via
   u2_bounds.                                                              *)
Theorem theorem2_convexity : forall p wlo whi w, (0 < p)%nat ->
  (forall i, (i < p)%nat -> wlo i < whi i) ->
  (forall i, (i < p)%nat -> wlo i <= w i <= whi i) ->
  Sum (S p) (alpha p (u2 wlo whi w)) = 1
  /\ forall k, (k <= p)%nat -> 0 <= alpha p (u2 wlo whi w) k <= 1.
Proof.
  intros p wlo whi w Hp Hnd Hbox.
  split.
  - apply alpha_sum.
  - apply alpha_bounds; [assumption | apply (u2_bounds p wlo whi w Hnd Hbox)].
Qed.

(* Helper for the general box, same role as sum_a_V1.

   V2 p wlo whi k j = wlo j + (INR p * (whi j - wlo j) if k = j else 0), so
   the weighted sum splits into a common part 'wlo j' (which is why the
   sum-to-one hypothesis is needed) plus one surviving term.

   'Sum_comb' is the two-scalar linearity lemma
       Sum n (fun i => a * f i + b * g i) = a * Sum n f + b * Sum n g,
   used here with a := wlo j and b := 1.                                   *)
Lemma sum_a_V2 : forall p wlo whi a j, (j < p)%nat ->
  Sum (S p) a = 1 ->
  Sum (S p) (fun k => a k * V2 p wlo whi k j)
  = wlo j + a j * (INR p * (whi j - wlo j)).
Proof.
  intros p wlo whi a j Hj Hsum.
  rewrite (Sum_ext (S p)
    (fun k => a k * V2 p wlo whi k j)
    (fun k => wlo j * a k
              + 1 * (if Nat.eqb k j
                     then a k * (INR p * (whi j - wlo j))
                     else 0))).
  - rewrite Sum_comb, Hsum.
    rewrite (Sum_select (S p)
               (fun k => a k * (INR p * (whi j - wlo j))) j) by lia.
    ring.
  - intros k Hk. unfold V2. destruct (Nat.eqb k j); ring.
Qed.

(* THEOREM 2, UNIQUENESS HALF — the statement the amended design rule rests on.

   Same shape as theorem1_uniqueness.  The only extra hypothesis is
   'wlo i < whi i' (the box is non-degenerate), needed so that the edge
   length whi i - wlo i can be divided by.

   Observe again that box membership of w is NOT required: the coefficients
   are determined whether or not w lies inside the box.

   'field. split; assumption.' — 'field' clears the two denominators and
   leaves the side conditions 'whi i - wlo i <> 0' and 'INR p <> 0' as a
   conjunction; both are already in context, so 'split; assumption' closes
   them without caring which order field produced them in.                 *)
Theorem theorem2_uniqueness : forall p wlo whi w a, (0 < p)%nat ->
  (forall i, (i < p)%nat -> wlo i < whi i) ->
  Sum (S p) a = 1 ->
  (forall j, (j < p)%nat -> Sum (S p) (fun k => a k * V2 p wlo whi k j) = w j) ->
  forall k, (k <= p)%nat -> a k = alpha p (u2 wlo whi w) k.
Proof.
  intros p wlo whi w a Hp Hnd Hsum Hrep k Hk.
  pose proof (INRp_neq0 p Hp) as Hp0.
  assert (Hlow : forall i, (i < p)%nat -> a i = u2 wlo whi w i / INR p).
  { intros i Hi. pose proof (Hnd i Hi) as Hi2.
    assert (Hne : whi i - wlo i <> 0) by lra.
    pose proof (Hrep i Hi) as H.
    rewrite (sum_a_V2 p wlo whi a i Hi Hsum) in H.
    unfold u2. rewrite <- H. field. split; assumption. }
  destruct (Nat.eq_dec k p) as [->|Hne].
  - rewrite alpha_top. cbn [Sum] in Hsum.
    rewrite (Sum_ext p a (fun i => u2 wlo whi w i / INR p)) in Hsum
      by assumption.
    lra.
  - assert (Hlt : (k < p)%nat) by lia.
    rewrite alpha_low by assumption. apply Hlow; assumption.
Qed.

(* =====================================================================
   MORE THAN d+1 VERTICES DESTROYS UNIQUENESS.

   Concrete counterexample, and the reason for the amendment.  In dimension
   d = 1, take the three points w3 = (0, 2, 1) and the target 1.  Both
     aA = (1/2, 1/2, 0)   and   aB = (0, 0, 1)
   are legitimate convex combinations reaching it, and they differ.  So with
   N = 3 > d+1 = 2 the coefficient vector is NOT determined by the data.

   This is the one-dimensional shadow of the hexagon example in
   ../../NOTE_convex_uniqueness.md: six points in R^2 carry a 3-parameter
   family of representations of any interior point, so higher dimension does
   not rescue the situation — what matters is N against d+1.

   NEW SYNTAX.
     'split; [ tac | ]'  proves the FIRST conjunct with tac and leaves the
                         rest as the single remaining goal.  Chaining these
                         walks down a nested conjunction one step at a time.
                         (Plain 'repeat split' is avoided here: it dives
                         under the 'forall i' binders and introduces i for
                         you, which then clashes with 'intros i'.)
     'destruct i as [|[|k]]'
                         case-splits a natural number into 0, 1, or S (S k),
                         which is enough to evaluate the three-branch
                         'match' definitions below.
   ===================================================================== *)

Definition w3 (i : nat) : R := match i with O => 0 | S O => 2 | _ => 1 end.
Definition aA (i : nat) : R := match i with O => 1/2 | S O => 1/2 | _ => 0 end.
Definition aB (i : nat) : R := match i with O => 0 | S O => 0 | _ => 1 end.

Theorem more_vertices_not_unique :
  Sum 3 aA = 1
  /\ Sum 3 aB = 1
  /\ (forall i, (i < 3)%nat -> 0 <= aA i <= 1)
  /\ (forall i, (i < 3)%nat -> 0 <= aB i <= 1)
  /\ Sum 3 (fun k => aA k * w3 k) = 1
  /\ Sum 3 (fun k => aB k * w3 k) = 1
  /\ aA 0 <> aB 0.
Proof.
  split; [ cbn [Sum]; unfold aA; lra | ].
  split; [ cbn [Sum]; unfold aB; lra | ].
  split; [ intros i Hi; unfold aA; destruct i as [|[|k]]; lra | ].
  split; [ intros i Hi; unfold aB; destruct i as [|[|k]]; lra | ].
  split; [ cbn [Sum]; unfold aA, w3; lra | ].
  split; [ cbn [Sum]; unfold aB, w3; lra | ].
  unfold aA, aB; lra.
Qed.

(* =====================================================================
   THE DESIGN RULE — amended to N = 2n+1 exactly.

   Instantiating Theorem 2 at p = d = 2n and the box of known bounds gives
   exactly the statement Chapter 4 needs: d+1 initial parameter vectors can
   be chosen so that theta*_p is a convex combination of them.  That is
   precisely hypothesis H_astar_init of SLA_Chapter4.v, so this corollary is
   the guarantee that the hypothesis can be met.

   AMENDMENT.  The dissertation writes N >= 2n+1 (pp. 23, 28, 60, 64, 72,
   83).  The corollary below, design_rule_suffices, is the honest content of
   that inequality: EXISTENCE.  But the second level identifies alpha*_f, so
   alpha*_f has to be a single point, and by more_vertices_not_unique that
   fails as soon as N > d+1.  design_rule_exact, further down, is the
   amended statement: at N = d+1 exactly you get existence AND uniqueness.
   Nothing had to be reproved — Theorem 2 always built exactly d+1 vertices.

   NEW SYNTAX.
     'exists A B'   supplies the witnesses for an existential goal
                    'exists (vertex : ...) (a : ...), P'.  Here the witnesses
                    are the vertex family V2 and the coefficient vector alpha
                    built from the normalised coordinates.
     'repeat split' breaks a nested conjunction A /\ B /\ C into three goals.
                    (It produces four here because the third component is
                    itself a 'forall ... /\ ...' pattern being destructed.)
     'destruct ... as [Hs Hb]'
                    takes the conjunction returned by theorem2_convexity apart.

   The CONVERSE — that fewer than d+1 points cannot work — is a statement
   about affine dimension.  The dissertation asserts it on page 64; it is NOT
   formalised here.
   ===================================================================== *)
Corollary design_rule_suffices :
  forall (d : nat) (alo ahi theta : nat -> R),
    (0 < d)%nat ->
    (forall i, (i < d)%nat -> alo i < ahi i) ->
    (forall i, (i < d)%nat -> alo i <= theta i <= ahi i) ->
    exists (vertex : nat -> nat -> R) (a : nat -> R),
      Sum (S d) a = 1
      /\ (forall k, (k <= d)%nat -> 0 <= a k <= 1)
      /\ (forall j, (j < d)%nat -> Sum (S d) (fun k => a k * vertex k j) = theta j).
Proof.
  intros d alo ahi theta Hd Hnd Hbox.
  exists (V2 d alo ahi), (alpha d (u2 alo ahi theta)).
  destruct (theorem2_convexity d alo ahi theta Hd Hnd Hbox) as [Hs Hb].
  repeat split.
  - exact Hs.
  - apply Hb; assumption.
  - apply Hb; assumption.
  - intros j Hj. apply (theorem2_representation d alo ahi theta Hd Hnd Hbox j Hj).
Qed.

(* THE AMENDED RULE.

   Identical to design_rule_suffices except for the fourth conjunct, which
   is the uniqueness clause: ANY other b that sums to one and reproduces
   theta through the same vertices equals a coefficient-for-coefficient.

   Read the fourth conjunct as: "and if b is another such representation,
   then b = a".  That is what makes alpha*_f a well-defined identification
   target for the second level, and it is what H_N_exact of SLA_Chapter4.v
   now assumes is available.

   The proof is the previous one plus a single extra bullet handing the new
   goal to theorem2_uniqueness.                                            *)
Corollary design_rule_exact :
  forall (d : nat) (alo ahi theta : nat -> R),
    (0 < d)%nat ->
    (forall i, (i < d)%nat -> alo i < ahi i) ->
    (forall i, (i < d)%nat -> alo i <= theta i <= ahi i) ->
    exists (vertex : nat -> nat -> R) (a : nat -> R),
      Sum (S d) a = 1
      /\ (forall k, (k <= d)%nat -> 0 <= a k <= 1)
      /\ (forall j, (j < d)%nat -> Sum (S d) (fun k => a k * vertex k j) = theta j)
      /\ (forall b, Sum (S d) b = 1 ->
            (forall j, (j < d)%nat ->
               Sum (S d) (fun k => b k * vertex k j) = theta j) ->
            forall k, (k <= d)%nat -> b k = a k).
Proof.
  intros d alo ahi theta Hd Hnd Hbox.
  exists (V2 d alo ahi), (alpha d (u2 alo ahi theta)).
  destruct (theorem2_convexity d alo ahi theta Hd Hnd Hbox) as [Hs Hb].
  repeat split.
  - exact Hs.
  - apply Hb; assumption.
  - apply Hb; assumption.
  - intros j Hj. apply (theorem2_representation d alo ahi theta Hd Hnd Hbox j Hj).
  - intros b Hbsum Hbrep k Hk.
    apply (theorem2_uniqueness d alo ahi theta b Hd Hnd Hbsum Hbrep k Hk).
Qed.
