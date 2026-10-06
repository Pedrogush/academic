(** * SLA_AppendixA.v — Appendix A of the dissertation: convex combinations

    These are the two theorems the dissertation invokes (Appendix A, used in
    Chapter 2 and again in Chapter 4 just above eq. 4.46) to justify the design
    rule

        N >= 2n + 1  =  d + 1     models,    d = 2n = dim(theta*_p),

    namely that the box of uncertainty in R^d — the polytope with 2^d vertices
    given by all combinations of the known bounds a_i^-, a_i^+, b_i^-, b_i^+ —
    is contained in a simplex with only d+1 vertices, so every point of the
    box, and in particular theta*_p, is a convex combination of d+1 chosen
    parameter vectors.

      Theorem 1 (A.1–A.10): the unit box [0,1]^p.
      Theorem 2 (A.11):     a general box [w_i^-, w_i^+].

    Vertices are indexed 0..p: index k < p is the k-th non-trivial vertex,
    index p is the base vertex (the origin in Theorem 1, w^- in Theorem 2).
    Everything is stated with explicit arguments so that the statements are
    directly usable. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Local Open Scope R_scope.

Lemma INRp_pos : forall p, (0 < p)%nat -> 0 < INR p.
Proof. intros p Hp. apply lt_0_INR. assumption. Qed.

Lemma INRp_neq0 : forall p, (0 < p)%nat -> INR p <> 0.
Proof. intros p Hp. pose proof (INRp_pos p Hp). lra. Qed.

Lemma INRp_ge1 : forall p, (0 < p)%nat -> 1 <= INR p.
Proof.
  intros p Hp. replace 1 with (INR 1) by (simpl; ring). apply le_INR. lia.
Qed.

(** ** The simplex coefficients  (A.4) and (A.7) *)

Definition alpha (p : nat) (u : nat -> R) (k : nat) : R :=
  if Nat.ltb k p then u k / INR p else 1 - Sum p (fun i => u i / INR p).

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

(** (A.6) *)
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

(** (A.5) + (A.8): the coefficients are legitimate convex weights. *)
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

(** (A.10) *)
Theorem alpha_sum : forall p u, Sum (S p) (alpha p u) = 1.
Proof.
  intros p u. cbn [Sum]. rewrite alpha_top.
  rewrite (Sum_ext p (alpha p u) (fun i => u i / INR p))
    by (intros; apply alpha_low; assumption).
  ring.
Qed.

(** ** Theorem 1 (A.1–A.10): the unit box [0,1]^p

    Containing simplex P_{u,2}: the origin (index p) and the p vectors p*e_k. *)

Definition V1 (p : nat) (k j : nat) : R := if Nat.eqb k j then INR p else 0.

(** (A.9) *)
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

Theorem theorem1_convexity : forall p w, (0 < p)%nat ->
  (forall i, (i < p)%nat -> 0 <= w i <= 1) ->
  Sum (S p) (alpha p w) = 1
  /\ forall k, (k <= p)%nat -> 0 <= alpha p w k <= 1.
Proof.
  intros p w Hp Hw. split; [apply alpha_sum | apply alpha_bounds; assumption].
Qed.

(** *** Uniqueness

    The p+1 vertices of P_{u,2} are affinely independent, so the convex
    coefficients representing a given point are not merely available but
    *unique*.  This is what fails as soon as one uses more than d+1 vertices,
    and it is what the second level needs in order for alpha*_f to be a
    well-defined target (see NOTE_convex_uniqueness.md). *)

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

(** ** Theorem 2 (A.11): a general box [w_i^-, w_i^+]

    Containing simplex W_{x,2}: w^- (index p) and w^- + p e_k (w_k^+ - w_k^-). *)

Definition u2 (wlo whi w : nat -> R) (i : nat) : R :=
  (w i - wlo i) / (whi i - wlo i).

Definition V2 (p : nat) (wlo whi : nat -> R) (k j : nat) : R :=
  wlo j + (if Nat.eqb k j then INR p * (whi j - wlo j) else 0).

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

(** (A.11) *)
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

(** *** Uniqueness for the general box

    Same statement for W_{x,2}.  Note that the box-membership hypothesis
    [wlo <= w <= whi] is not needed: uniqueness is an affine-independence
    fact and holds for every w, inside the box or not. *)

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

(** ** The design rule  N = 2n+1  (exactly)

    Instantiating Theorem 2 with p = d = 2n and the box of known bounds gives
    exactly the statement used in Chapter 4: d+1 initial parameter vectors can
    be chosen so that theta*_p is a convex combination of them — i.e.
    N = 2n+1 models, which is hypothesis [H_astar_init] of SLA_Chapter4.

    AMENDMENT (see NOTE_convex_uniqueness.md).  The dissertation writes the
    design rule as N >= 2n+1 (pp. 23, 28, 60, 64, 72, 83).  That inequality is
    correct for *existence* of a representation, which is what the text's own
    justification argues for.  It is not sufficient for *uniqueness*: with
    N unknowns and d+1 equations (d coordinates plus sum-to-one) the solution
    family has dimension N - (d+1), which is zero iff N = d+1.  Since the
    second level treats alpha*_f as the parameter it identifies, alpha*_f must
    be a point, so the rule is tightened here to

        N = 2n + 1 = d + 1   exactly.

    Nothing is lost: the vertices Theorem 2 constructs are exactly d+1 and are
    affinely independent, so [theorem2_uniqueness] applies to them.  The
    converse ("fewer than d+1 points cannot do it") is a statement about
    affine dimension; the dissertation asserts it on page 64 and it is not
    formalised here. *)

(** More than d+1 vertices really does destroy uniqueness.  The smallest
    instance is d = 1 with three points w3 = (0,2,1): the target 1 is a convex
    combination of them in at least two different ways.  This is the
    one-dimensional shadow of the hexagon example in the note — six points in
    R^2 carry a 3-parameter family of representations of any interior point. *)

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

(** The amended rule: with exactly d+1 = 2n+1 models the convex representation
    of theta*_p not only exists but is the *only* one.  This is the statement
    Chapter 4 needs in order for alpha*_f to be a well-defined identification
    target, and it is what [H_N_exact] of SLA_Chapter4 now assumes. *)

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
