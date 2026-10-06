(** * SLA_Prelim.v — finite sums, vectors and derivative plumbing

    Support library for the formalisation of Chapter 4 (equations 4.1–4.69) of

      Pedro Yochinori Gushiken, "Adaptação de Segundo Nível como Técnica de
      Estimação de Parâmetros e sua Aplicação ao Controle Adaptativo por
      Modelo de Referência", MSc dissertation, UFRN, 2018.

    Vectors of R^n are represented as functions [nat -> R]; only the first
    [n] indices are ever constrained.  Sums are the finite sums
    [Sum n f = f 0 + ... + f (n-1)].

    Derivatives use the Coq standard library's [derivable_pt_lim], so every
    "derivative along the trajectories" step of the dissertation is a genuine
    analytic statement, not an axiom. *)

Require Import Reals Lra Lia.
Local Open Scope R_scope.

(** ** Finite sums *)

Fixpoint Sum (n : nat) (f : nat -> R) : R :=
  match n with
  | O => 0
  | S k => Sum k f + f k
  end.

Lemma Sum_ext : forall n f g,
  (forall i, (i < n)%nat -> f i = g i) -> Sum n f = Sum n g.
Proof.
  induction n; intros f g H; simpl; [reflexivity|].
  rewrite (IHn f g) by (intros; apply H; lia).
  rewrite (H n) by lia. reflexivity.
Qed.

Lemma Sum_plus : forall n f g,
  Sum n (fun i => f i + g i) = Sum n f + Sum n g.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_minus : forall n f g,
  Sum n (fun i => f i - g i) = Sum n f - Sum n g.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_opp : forall n f, Sum n (fun i => - f i) = - Sum n f.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_scal_l : forall n c f, Sum n (fun i => c * f i) = c * Sum n f.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_scal_r : forall n c f, Sum n (fun i => f i * c) = Sum n f * c.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_comb : forall n (A B : nat -> R) (a b : R),
  Sum n (fun i => a * A i + b * B i) = a * Sum n A + b * Sum n B.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_comb3 : forall n (A B C : nat -> R) (a b c : R),
  Sum n (fun i => a * A i + b * B i + c * C i)
  = a * Sum n A + b * Sum n B + c * Sum n C.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

Lemma Sum_const : forall n c, Sum n (fun _ => c) = INR n * c.
Proof.
  induction n; intros c.
  - simpl. ring.
  - rewrite S_INR. cbn [Sum]. rewrite IHn. ring.
Qed.

Lemma Sum_zero : forall n f, (forall i, (i < n)%nat -> f i = 0) -> Sum n f = 0.
Proof.
  intros n f H. rewrite (Sum_ext n f (fun _ => 0)) by assumption.
  rewrite Sum_const; ring.
Qed.

Lemma Sum_nonneg : forall n f,
  (forall i, (i < n)%nat -> 0 <= f i) -> 0 <= Sum n f.
Proof.
  induction n; intros f H; simpl; [lra|].
  assert (0 <= Sum n f) by (apply IHn; intros; apply H; lia).
  assert (0 <= f n) by (apply H; lia). lra.
Qed.

(** If a sum of nonnegative terms vanishes, every term vanishes. *)
Lemma Sum_eq0_all : forall n f,
  (forall i, (i < n)%nat -> 0 <= f i) -> Sum n f = 0 ->
  forall i, (i < n)%nat -> f i = 0.
Proof.
  induction n; intros f Hpos Hsum i Hi; [lia|].
  simpl in Hsum.
  assert (Hs : 0 <= Sum n f) by (apply Sum_nonneg; intros; apply Hpos; lia).
  assert (Hn : 0 <= f n) by (apply Hpos; lia).
  assert (Hz1 : Sum n f = 0) by lra.
  assert (Hz2 : f n = 0) by lra.
  destruct (Nat.eq_dec i n) as [->|Hne]; [assumption|].
  apply IHn; try assumption. intros; apply Hpos; lia. lia.
Qed.

Lemma Sum_le : forall n f g,
  (forall i, (i < n)%nat -> f i <= g i) -> Sum n f <= Sum n g.
Proof.
  induction n; intros f g H; simpl; [lra|].
  assert (Sum n f <= Sum n g) by (apply IHn; intros; apply H; lia).
  assert (f n <= g n) by (apply H; lia). lra.
Qed.

(** Selection: a sum whose summands vanish off a single index. *)
Lemma Sum_select : forall n (g : nat -> R) j, (j < n)%nat ->
  Sum n (fun i => if Nat.eqb i j then g i else 0) = g j.
Proof.
  induction n; intros g j Hj; [lia|].
  cbn [Sum]. destruct (Nat.eq_dec j n) as [He|Hne].
  - subst j.
    rewrite (Sum_zero n (fun i => if Nat.eqb i n then g i else 0))
      by (intros i Hi; destruct (Nat.eqb_spec i n); [exfalso; lia | reflexivity]).
    destruct (Nat.eqb_spec n n); [ring | exfalso; lia].
  - rewrite (IHn g j) by lia.
    destruct (Nat.eqb_spec n j); [exfalso; lia | ring].
Qed.

(** Exchange of two finite sums (discrete Fubini). *)
Lemma Sum_swap : forall n m (f : nat -> nat -> R),
  Sum n (fun i => Sum m (fun j => f i j)) =
  Sum m (fun j => Sum n (fun i => f i j)).
Proof.
  induction n; intros m f; cbn [Sum].
  - rewrite (Sum_zero m (fun _ => 0)) by (intros; reflexivity). reflexivity.
  - rewrite IHn. rewrite <- Sum_plus. reflexivity.
Qed.

(** ** Vectors and inner products *)

Definition dot (d : nat) (u v : nat -> R) : R := Sum d (fun j => u j * v j).

Lemma dot_minus_l : forall d u v w,
  dot d (fun j => u j - v j) w = dot d u w - dot d v w.
Proof.
  intros. unfold dot.
  rewrite <- Sum_minus. apply Sum_ext; intros; ring.
Qed.

Lemma dot_nonneg : forall d u, 0 <= dot d u u.
Proof.
  intros. unfold dot. apply Sum_nonneg. intros. apply Rle_0_sqr.
Qed.

(** ** Derivatives *)

Definition Deriv (f f' : R -> R) : Prop :=
  forall t, derivable_pt_lim f t (f' t).

Lemma D_const : forall c, Deriv (fun _ => c) (fun _ => 0).
Proof. intros c t. apply derivable_pt_lim_const. Qed.

Lemma D_id : Deriv (fun t => t) (fun _ => 1).
Proof. intros t. apply derivable_pt_lim_id. Qed.

Lemma D_plus : forall f g f' g',
  Deriv f f' -> Deriv g g' -> Deriv (fun t => f t + g t) (fun t => f' t + g' t).
Proof.
  intros f g f' g' Hf Hg t.
  apply (derivable_pt_lim_plus f g t (f' t) (g' t)); [apply Hf | apply Hg].
Qed.

Lemma D_opp : forall f f', Deriv f f' -> Deriv (fun t => - f t) (fun t => - f' t).
Proof.
  intros f f' Hf t. apply (derivable_pt_lim_opp f t (f' t)). apply Hf.
Qed.

Lemma D_minus : forall f g f' g',
  Deriv f f' -> Deriv g g' -> Deriv (fun t => f t - g t) (fun t => f' t - g' t).
Proof.
  intros f g f' g' Hf Hg t.
  apply (derivable_pt_lim_minus f g t (f' t) (g' t)); [apply Hf | apply Hg].
Qed.

Lemma D_mult : forall f g f' g',
  Deriv f f' -> Deriv g g' ->
  Deriv (fun t => f t * g t) (fun t => f' t * g t + f t * g' t).
Proof.
  intros f g f' g' Hf Hg t.
  apply (derivable_pt_lim_mult f g t (f' t) (g' t)); [apply Hf | apply Hg].
Qed.

Lemma D_scal : forall c f f', Deriv f f' -> Deriv (fun t => c * f t) (fun t => c * f' t).
Proof.
  intros c f f' Hf t.
  apply (derivable_pt_lim_scal f c t (f' t)). apply Hf.
Qed.

Lemma D_lin : forall a, Deriv (fun t => a * t) (fun _ => a).
Proof.
  intros a t.
  pose proof (derivable_pt_lim_scal (fun x => x) a t 1 (derivable_pt_lim_id t)) as Hs.
  replace (a * 1) with a in Hs by ring. exact Hs.
Qed.

Lemma D_exp_lin : forall a, Deriv (fun t => exp (a * t)) (fun t => a * exp (a * t)).
Proof.
  intros a t.
  assert (H : derivable_pt_lim (fun x => exp (a * x)) t (exp (a * t) * a)).
  { apply (derivable_pt_lim_comp (fun x => a * x) exp t a (exp (a*t))).
    - apply D_lin.
    - apply derivable_pt_lim_exp. }
  replace (a * exp (a * t)) with (exp (a * t) * a) by ring. exact H.
Qed.

(** Congruence: derivatives are stable under pointwise-equal reformulation.
    Proved directly from the epsilon/delta definition, so no axiom
    (in particular no functional extensionality) is used. *)
Lemma D_ext : forall f f' g g',
  (forall t, f t = g t) -> (forall t, f' t = g' t) -> Deriv f f' -> Deriv g g'.
Proof.
  intros f f' g g' Hf Hf' H t eps Heps.
  destruct (H t eps Heps) as [delta Hd].
  exists delta. intros h Hh Hlt.
  rewrite <- !Hf, <- Hf'. apply Hd; assumption.
Qed.

(** Derivative of a finite sum. *)
Lemma D_Sum : forall n (F F' : nat -> R -> R),
  (forall i, (i < n)%nat -> Deriv (F i) (F' i)) ->
  Deriv (fun t => Sum n (fun i => F i t)) (fun t => Sum n (fun i => F' i t)).
Proof.
  induction n; intros F F' H; simpl.
  - apply D_const.
  - apply D_plus.
    + apply IHn. intros; apply H; lia.
    + apply H; lia.
Qed.

(** ** Monotonicity from the sign of the derivative (via the MVT) *)

Lemma nonincr_of_nonpos_deriv : forall f f',
  Deriv f f' -> (forall t, f' t <= 0) ->
  forall a b, a <= b -> f b <= f a.
Proof.
  intros f f' Hd Hs a b Hab.
  destruct (Rle_lt_or_eq_dec a b Hab) as [Hlt|Heq].
  - destruct (MVT_cor2 f f' a b Hlt (fun c _ => Hd c)) as [c [Hc _]].
    specialize (Hs c). nra.
  - subst. lra.
Qed.

Lemma nondecr_of_nonneg_deriv : forall f f',
  Deriv f f' -> (forall t, 0 <= f' t) ->
  forall a b, a <= b -> f a <= f b.
Proof.
  intros f f' Hd Hs a b Hab.
  destruct (Rle_lt_or_eq_dec a b Hab) as [Hlt|Heq].
  - destruct (MVT_cor2 f f' a b Hlt (fun c _ => Hd c)) as [c [Hc _]].
    specialize (Hs c). nra.
  - subst. lra.
Qed.
