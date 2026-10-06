(** * SLA_Prelim.v — ANNOTATED COPY

    Identical Coq code to ../SLA_Prelim.v, with a block comment before every
    item explaining the *syntax*.  The mathematics is elementary; the comments
    assume you know it and are only here to decode the notation.

    ====================================================================
    HOW TO READ ANY COQ FILE
    ====================================================================

    (a) COMMENTS.  (* ... *) is a comment.  (** ... *) is a documentation
        comment (same thing to the compiler).  Comments nest.

    (b) THE THREE KINDS OF LINE.

          Definition / Fixpoint  ... := ...        an abbreviation
          Lemma / Theorem  name : statement.       something to be proved
          Proof.  tactic. tactic. ...  Qed.        the proof script

        Lemma, Theorem and Corollary are the *same* keyword to Coq.  The
        choice is documentation only.

    (c) APPLICATION IS JUXTAPOSITION, and it associates to the LEFT.
        There are no commas and no parentheses around argument lists:

          Sum n f          is    Sum(n, f)
          dot d u v        is    dot(d, u, v)
          th i t j         is    ((th i) t) j

        Consequently PARTIAL APPLICATION is available and used constantly:
        if th : nat -> R -> nat -> R then  th i t  is a function nat -> R,
        i.e. the vector theta-hat_i(t).

    (d) fun x => e   is the lambda abstraction  x |-> e.

    (e) TYPES.  x : T  reads  x has type T.
          R          the real numbers
          nat        the natural numbers 0, 1, 2, ...
          Prop       the type of statements (propositions)
          A -> B     functions from A to B; also, logical implication
          forall x, P    universal quantification

    (f) SCOPES.  This file does  Local Open Scope R_scope,  so a bare
        +  *  -  <  <=  =  means the REAL operation.  When a natural-number
        comparison is meant it must be written  (i < n)%nat.  The %nat is a
        scope annotation, not part of the mathematics.

    (g) IMPLICATION AND HYPOTHESES ARE THE SAME THING.  A lemma written

          Lemma L : forall n f, (forall i, P i) -> Sum n f = 0.

        has ONE hypothesis (the parenthesised forall) and one conclusion.
        To use L you must supply a proof of the hypothesis.

    ====================================================================
    WHAT THIS FILE PROVIDES
    ====================================================================

    Vectors of R^n are represented as functions nat -> R; only the first n
    indices are ever constrained.  Sums are Sum n f = f 0 + ... + f (n-1).

    Derivatives use the Coq standard library predicate derivable_pt_lim, so
    every 'derivative along the trajectories' step of the dissertation is a
    genuine analytic statement and not an axiom. *)

(* Require Import loads libraries.  Reals = the real numbers and real
   analysis.  Lra = the tactic 'lra' (linear real arithmetic).  Lia = the
   tactic 'lia' (linear integer arithmetic).                               *)
Require Import Reals Lra Lia.

(* From here on, unannotated arithmetic symbols mean real arithmetic.
   'Local' means: only inside this file.                                    *)
Local Open Scope R_scope.

(** ** Finite sums *)

(* ---------------------------------------------------------------------
   Sum n f  =  f 0 + f 1 + ... + f (n-1)

   'Fixpoint' = a recursive definition.  Coq requires that it obviously
   terminates; here it recurses on n, which shrinks.

   'match n with ... end' is case analysis on a natural number.  A natural
   number is either O (the constructor zero) or S k (the successor of k).
   So the two branches are  n = 0  and  n = k+1.

   Note the recursion peels off the LAST term:  Sum (k+1) f = Sum k f + f k.
   This matters later: splitting the N-th term off a sum is then a purely
   definitional step, requiring no arithmetic (see E_alpha_star in
   SLA_Chapter4.v, which is equation 4.48).
   --------------------------------------------------------------------- *)
Fixpoint Sum (n : nat) (f : nat -> R) : R :=
  match n with
  | O => 0
  | S k => Sum k f + f k
  end.

(* ---------------------------------------------------------------------
   Sum_ext: two sums are equal if their summands agree on 0..n-1.

   STATEMENT.  forall n f g, (forall i, (i < n)%nat -> f i = g i)
                             -> Sum n f = Sum n g.
   Read: for all n, f, g, IF f and g agree at every index below n, THEN the
   sums agree.  Note f and g need NOT agree at indices >= n.

   This lemma is the workhorse of the whole development, because you cannot
   apply 'ring' underneath a Sum: the summand is a lambda, not an expression.
   Sum_ext is how you rewrite inside a summation sign.

   PROOF.
     induction n         -- proof by induction on n.  Generates two goals
                            (n = 0 and n = k+1) and, in the second, an
                            induction hypothesis named IHn.
     intros f g H        -- name the remaining universally quantified things
                            and call the hypothesis H.
     simpl               -- unfold Sum one step.
     [reflexivity|]      -- the square brackets dispatch the goals produced by
                            the previous tactic positionally.  Here: close the
                            base case with 'reflexivity' (both sides are 0),
                            leave the second goal untouched (empty slot).
     rewrite (IHn f g) by (...)
                         -- rewrite using the induction hypothesis, INSTANTIATED
                            at f and g.  IHn itself has a hypothesis, and the
                            'by (...)' clause discharges it.
     apply H; lia        -- 'apply H' reduces the goal to H's hypothesis, here
                            (i < n)%nat, which 'lia' proves from i < S n.
     rewrite (H n) by lia -- rewrite f n into g n; side condition n < S n by lia.
     reflexivity         -- both sides now identical.
   --------------------------------------------------------------------- *)
Lemma Sum_ext : forall n f g,
  (forall i, (i < n)%nat -> f i = g i) -> Sum n f = Sum n g.
Proof.
  induction n; intros f g H; simpl; [reflexivity|].
  rewrite (IHn f g) by (intros; apply H; lia).
  rewrite (H n) by lia. reflexivity.
Qed.

(* ---------------------------------------------------------------------
   The next six lemmas are the linearity of Sum.  They all have the same
   two-line proof, so read one and you have read them all:

     induction n; intros; simpl; [ring | rewrite IHn; ring].

     induction n      -- induct on n
     intros           -- name everything quantified
     simpl            -- unfold Sum one step in both goals
     [ring | ... ]    -- base case: 0 = 0 + 0 etc., closed by 'ring'
                         step case: use IHn, then 'ring'

   'ring' proves any identity valid in a commutative ring, treating the
   unknowns (here Sum n f, f n, c, ...) as opaque atoms.  IMPORTANT: 'ring'
   does NOT understand division.  An identity containing x / 2 will be
   rejected with 'not a valid ring equation'; use 'field' there instead.
   --------------------------------------------------------------------- *)

(* Sum of a pointwise sum splits. *)
Lemma Sum_plus : forall n f g,
  Sum n (fun i => f i + g i) = Sum n f + Sum n g.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* Sum of a pointwise difference splits. *)
Lemma Sum_minus : forall n f g,
  Sum n (fun i => f i - g i) = Sum n f - Sum n g.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* Sum commutes with negation. *)
Lemma Sum_opp : forall n f, Sum n (fun i => - f i) = - Sum n f.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* A constant factor on the LEFT of each summand comes out of the sum.
   This is the one used to extract sum(beta_i) in equation 4.35.          *)
Lemma Sum_scal_l : forall n c f, Sum n (fun i => c * f i) = c * Sum n f.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* Same, factor on the RIGHT.  Coq distinguishes  c * f i  from  f i * c
   syntactically, so both versions are needed in practice.                *)
Lemma Sum_scal_r : forall n c f, Sum n (fun i => f i * c) = Sum n f * c.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* Two-term linear combination in one step.  Written explicitly because
   chaining Sum_plus and Sum_scal_l leaves Coq guessing which subterm to
   match, which is fragile.  A and B are the summand functions, a and b the
   scalar coefficients.  The annotation (A B : nat -> R) is optional but
   documents the intent.                                                   *)
Lemma Sum_comb : forall n (A B : nat -> R) (a b : R),
  Sum n (fun i => a * A i + b * B i) = a * Sum n A + b * Sum n B.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* Three-term version; used once, in VrF_dyn (equation 4.69). *)
Lemma Sum_comb3 : forall n (A B C : nat -> R) (a b c : R),
  Sum n (fun i => a * A i + b * B i + c * C i)
  = a * Sum n A + b * Sum n B + c * Sum n C.
Proof. induction n; intros; simpl; [ring | rewrite IHn; ring]. Qed.

(* ---------------------------------------------------------------------
   Sum of a constant.  INR : nat -> R is the injection of the naturals into
   the reals, so INR n is 'n as a real number'.

   'fun _ => c' is a lambda whose argument is ignored; the underscore is a
   name you promise not to use.

   PROOF.
     - base case: Sum 0 (fun _ => c) = INR 0 * c, i.e. 0 = 0 * c; 'ring'.
     - step: rewrite S_INR first.  S_INR : INR (S n) = INR n + 1.  This is
       done BEFORE simplifying because a bare 'simpl' would also try to
       compute INR (S n) into an ugly normal form and then the rewrite would
       no longer match.
     cbn [Sum]   -- like simpl, but ONLY unfolds the constant named in the
                    bracket list.  A precision instrument: it expands Sum and
                    leaves everything else alone.
   --------------------------------------------------------------------- *)
Lemma Sum_const : forall n c, Sum n (fun _ => c) = INR n * c.
Proof.
  induction n; intros c.
  - simpl. ring.
  - rewrite S_INR. cbn [Sum]. rewrite IHn. ring.
Qed.

(* ---------------------------------------------------------------------
   A sum whose summands all vanish is zero.

   PROOF.  Rewrite f into the constant function 0 using Sum_ext (the 'by
   assumption' discharges Sum_ext's hypothesis, which is literally the
   hypothesis H we were handed), then apply Sum_const: INR n * 0 = 0.

   'assumption' = the goal is exactly one of the hypotheses in context.
   The semicolon in 'rewrite Sum_const; ring' means: do the rewrite, then run
   'ring' on every goal it produces.
   --------------------------------------------------------------------- *)
Lemma Sum_zero : forall n f, (forall i, (i < n)%nat -> f i = 0) -> Sum n f = 0.
Proof.
  intros n f H. rewrite (Sum_ext n f (fun _ => 0)) by assumption.
  rewrite Sum_const; ring.
Qed.

(* ---------------------------------------------------------------------
   A sum of nonnegative terms is nonnegative.

   PROOF.  Induction.  In the step case we produce the two facts we need as
   named local results and then let 'lra' finish.

     assert (P) by tac   -- prove P on the side using tac, then add it to the
                            context.  Without a name, Coq calls it H, H0, ...
     lra                 -- decides LINEAR real arithmetic, using the
                            hypotheses in context.  Here: from 0 <= Sum n f
                            and 0 <= f n conclude 0 <= Sum n f + f n.
   --------------------------------------------------------------------- *)
Lemma Sum_nonneg : forall n f,
  (forall i, (i < n)%nat -> 0 <= f i) -> 0 <= Sum n f.
Proof.
  induction n; intros f H; simpl; [lra|].
  assert (0 <= Sum n f) by (apply IHn; intros; apply H; lia).
  assert (0 <= f n) by (apply H; lia). lra.
Qed.

(* ---------------------------------------------------------------------
   If a sum of nonnegative terms vanishes, EVERY term vanishes.

   This is the engine behind the convex-hull invariance theorem: it converts
   'the Lyapunov function is zero' into 'the parametric error vector is the
   zero vector'.

   PROOF.
     [lia|]             -- base case n = 0: the hypothesis i < 0 is absurd, and
                           'lia' closes any goal from contradictory arithmetic
                           hypotheses.
     simpl in Hsum      -- unfold Sum inside the HYPOTHESIS Hsum rather than in
                           the goal.  'in H' works for most tactics.
     Hz1, Hz2           -- both summands are >= 0 and add to 0, so both are 0.
     destruct (Nat.eq_dec i n) as [->|Hne]
                        -- decide whether i = n.  Nat.eq_dec is decidable
                           equality on nat; it returns one of two cases.
                           The pattern [->|Hne] means: in the first case,
                           immediately REWRITE with the equation (that is what
                           -> does inside a destruct pattern) instead of naming
                           it; in the second case name the disequality Hne.
     try assumption     -- 'try' runs a tactic and silently succeeds if it
                           fails.  Used here because 'apply IHn' leaves several
                           goals of which some are closed by assumption.
   --------------------------------------------------------------------- *)
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

(* Monotonicity of Sum.  Same induction pattern as Sum_nonneg.  Used only in
   the appendix, to bound sum(u_i / p) by sum(1 / p) = 1.                  *)
Lemma Sum_le : forall n f g,
  (forall i, (i < n)%nat -> f i <= g i) -> Sum n f <= Sum n g.
Proof.
  induction n; intros f g H; simpl; [lra|].
  assert (Sum n f <= Sum n g) by (apply IHn; intros; apply H; lia).
  assert (f n <= g n) by (apply H; lia). lra.
Qed.

(* ---------------------------------------------------------------------
   Selection: a sum whose summands vanish off one index collapses to that
   term.  Used in the appendix to evaluate sum_k alpha_k * (p e_k)_j.

   NOTATION.  Nat.eqb i j is the BOOLEAN equality test on naturals (it
   returns true or false, not a proposition).  'if b then x else y' is the
   usual conditional on a boolean.

   PROOF.
     destruct (Nat.eq_dec j n) as [He|Hne]  -- is the selected index the last
                                               one, or an earlier one?
     subst j            -- He : j = n is in context; substitute n for j
                           everywhere and discard He.
     destruct (Nat.eqb_spec i n)
                        -- Nat.eqb_spec is a REFLECTION lemma: it says the
                           boolean Nat.eqb i n is true exactly when i = n.
                           Destructing it splits into two cases AND replaces
                           the boolean test in the goal by true / false, so
                           the 'if' reduces automatically.
     exfalso; lia       -- 'exfalso' changes the goal to False; 'lia' then
                           derives the contradiction from the arithmetic
                           hypotheses.  Needed because the goal here is an
                           equation between reals, which lia cannot parse on
                           its own.
   --------------------------------------------------------------------- *)
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

(* ---------------------------------------------------------------------
   Exchange of two finite sums (discrete Fubini).  f : nat -> nat -> R is a
   doubly indexed family, i.e. a matrix.

   Needed exactly once, in dot_lincomb (SLA_Chapter4.v), to show that a
   linear combination of the model estimates produces the same linear
   combination of the model outputs: sum_j (sum_i th_ij c_i) phi_j
                                   = sum_i c_i (sum_j th_ij phi_j).

   PROOF.
     - base case n = 0: the left side is 0 and the right side is
       Sum m (fun _ => 0); Sum_zero turns the latter into 0.
     - step: apply IHn, then read Sum_plus BACKWARDS.  'rewrite <- L' uses
       the equation L from right to left, i.e. it re-assembles
       Sum m A + Sum m B  into  Sum m (fun j => A j + B j).
   --------------------------------------------------------------------- *)
Lemma Sum_swap : forall n m (f : nat -> nat -> R),
  Sum n (fun i => Sum m (fun j => f i j)) =
  Sum m (fun j => Sum n (fun i => f i j)).
Proof.
  induction n; intros m f; cbn [Sum].
  - rewrite (Sum_zero m (fun _ => 0)) by (intros; reflexivity). reflexivity.
  - rewrite IHn. rewrite <- Sum_plus. reflexivity.
Qed.

(** ** Vectors and inner products *)

(* ---------------------------------------------------------------------
   The inner product of two vectors of R^d.

   There is no vector TYPE: a vector is a function nat -> R and the dimension
   d is carried as a separate argument.  So

       dot d u v   is   sum_{j=0}^{d-1} u_j v_j.

   In the main file you will constantly see things like
       dot d (tht i t) (phi t)
   where 'tht i t' and 'phi t' are partial applications, i.e. the vectors
   theta-tilde_i(t) and phi(t).
   --------------------------------------------------------------------- *)
Definition dot (d : nat) (u v : nat -> R) : R := Sum d (fun j => u j * v j).

(* ---------------------------------------------------------------------
   Bilinearity in the first slot, difference form: (u - v) . w = u.w - v.w.
   This single lemma is what turns equation 4.11 into equation 4.15.

   PROOF.
     unfold dot          -- replace the name 'dot' by its body everywhere.
     rewrite <- Sum_minus -- re-assemble the right-hand side into a single Sum.
     apply Sum_ext        -- reduce 'the two sums are equal' to 'the summands
                             agree pointwise'.
     intros; ring         -- the pointwise goal (u j - v j) * w j
                             = u j * w j - v j * w j is ring algebra.
   --------------------------------------------------------------------- *)
Lemma dot_minus_l : forall d u v w,
  dot d (fun j => u j - v j) w = dot d u w - dot d v w.
Proof.
  intros. unfold dot.
  rewrite <- Sum_minus. apply Sum_ext; intros; ring.
Qed.

(* u . u >= 0.  Rle_0_sqr is the standard-library fact 0 <= r * r.
   Used only to show m^2 = 1 + phi.phi > 0, i.e. that the normalising signal
   never vanishes (equation 4.12).                                         *)
Lemma dot_nonneg : forall d u, 0 <= dot d u u.
Proof.
  intros. unfold dot. apply Sum_nonneg. intros. apply Rle_0_sqr.
Qed.

(** ** Derivatives *)

(* ---------------------------------------------------------------------
   THE CENTRAL DEFINITION OF THE WHOLE DEVELOPMENT.

       Deriv f f'   means   for every t, f' t is the derivative of f at t.

   derivable_pt_lim is Coq's standard-library derivative, defined by the
   usual epsilon/delta limit of the difference quotient.  Nothing is
   postulated: every 'derivando ao longo das trajetorias' step in the
   dissertation becomes a real analytic obligation.

   ': Prop' says that Deriv f f' is a STATEMENT, not a number.

   Note the shape: Deriv takes the function and its derivative as two
   separate arguments.  So you always write down the derivative you claim,
   and then prove the claim.  There is no operator that COMPUTES a
   derivative for you.  That design is the reason D_ext below exists.
   --------------------------------------------------------------------- *)
Definition Deriv (f f' : R -> R) : Prop :=
  forall t, derivable_pt_lim f t (f' t).

(* ---------------------------------------------------------------------
   The next eight lemmas are the differentiation rules, restated in terms of
   Deriv.  They are all one-liners that unpack Deriv (by introducing the
   point t) and hand the goal to the corresponding standard-library rule.

   The pattern is always:
       intros ... t.                  -- fix an arbitrary time t
       apply (derivable_pt_lim_XXX ...).  -- invoke the stdlib rule
   The explicit argument lists like (f g t (f' t) (g' t)) are there because
   Coq cannot always guess them; supplying them makes the proofs robust.
   --------------------------------------------------------------------- *)

(* The derivative of a constant is 0.  '(fun _ => c)' is the constant
   function.  Used everywhere that theta* or alpha* appears, since those are
   time invariant - this is exactly equations 4.20 and 4.55.               *)
Lemma D_const : forall c, Deriv (fun _ => c) (fun _ => 0).
Proof. intros c t. apply derivable_pt_lim_const. Qed.

(* The derivative of the identity is 1. *)
Lemma D_id : Deriv (fun t => t) (fun _ => 1).
Proof. intros t. apply derivable_pt_lim_id. Qed.

(* Sum rule.  Note the four function arguments are given as f g f' g', so
   the reading is: if f' is the derivative of f and g' of g, then f' + g' is
   the derivative of f + g.
   '[apply Hf | apply Hg]' dispatches the two subgoals positionally.       *)
Lemma D_plus : forall f g f' g',
  Deriv f f' -> Deriv g g' -> Deriv (fun t => f t + g t) (fun t => f' t + g' t).
Proof.
  intros f g f' g' Hf Hg t.
  apply (derivable_pt_lim_plus f g t (f' t) (g' t)); [apply Hf | apply Hg].
Qed.

(* Negation rule. *)
Lemma D_opp : forall f f', Deriv f f' -> Deriv (fun t => - f t) (fun t => - f' t).
Proof.
  intros f f' Hf t. apply (derivable_pt_lim_opp f t (f' t)). apply Hf.
Qed.

(* Difference rule.  This is the one used for theta-tilde = theta-hat -
   theta*, equations 4.20/4.21 and 4.54/4.55.                              *)
Lemma D_minus : forall f g f' g',
  Deriv f f' -> Deriv g g' -> Deriv (fun t => f t - g t) (fun t => f' t - g' t).
Proof.
  intros f g f' g' Hf Hg t.
  apply (derivable_pt_lim_minus f g t (f' t) (g' t)); [apply Hf | apply Hg].
Qed.

(* Product rule.  Used for every quadratic Lyapunov term and for the
   integrating factor exp(sigma t) * M_f(t).                               *)
Lemma D_mult : forall f g f' g',
  Deriv f f' -> Deriv g g' ->
  Deriv (fun t => f t * g t) (fun t => f' t * g t + f t * g' t).
Proof.
  intros f g f' g' Hf Hg t.
  apply (derivable_pt_lim_mult f g t (f' t) (g' t)); [apply Hf | apply Hg].
Qed.

(* Multiplication by a constant.  Kept separate from D_mult because it gives
   a much shorter derivative expression (c * f' rather than 0 * f + c * f'),
   which keeps later 'ring' goals small.                                   *)
Lemma D_scal : forall c f f', Deriv f f' -> Deriv (fun t => c * f t) (fun t => c * f' t).
Proof.
  intros c f f' Hf t.
  apply (derivable_pt_lim_scal f c t (f' t)). apply Hf.
Qed.

(* d/dt (a t) = a.  Needed as the inner step of the chain rule below.

   PROOF.
     pose proof (L args) as Hs  -- instantiate an existing lemma at concrete
                                   arguments and put the RESULT in the context
                                   under the name Hs.  (Unlike 'apply', this
                                   does not touch the goal.)
     replace X with Y in Hs by ring
                                -- rewrite inside Hs; the stdlib rule produces
                                   the limit a * 1, and we want a.
     exact Hs                   -- the goal is now literally Hs.
   --------------------------------------------------------------------- *)
Lemma D_lin : forall a, Deriv (fun t => a * t) (fun _ => a).
Proof.
  intros a t.
  pose proof (derivable_pt_lim_scal (fun x => x) a t 1 (derivable_pt_lim_id t)) as Hs.
  replace (a * 1) with a in Hs by ring. exact Hs.
Qed.

(* ---------------------------------------------------------------------
   d/dt exp(a t) = a exp(a t).  The only nontrivial differentiation rule we
   need; it is used for the forgetting-factor solutions M_f, v_f (equations
   4.65/4.66) and in the concrete instance file.

   PROOF.
     assert (H : ...) . { ... }  -- state an intermediate result and prove it
                                    in the braces.  Braces { } focus a goal,
                                    exactly like the bullets - and +.
     derivable_pt_lim_comp        -- the chain rule.  Its arguments are the
                                    inner function, the outer function, the
                                    point, and the two derivatives; it
                                    concludes with the limit in the order
                                    (outer' * inner'), which is why the final
                                    'replace ... by ring' is needed to flip
                                    exp(a t) * a into a * exp(a t).
   --------------------------------------------------------------------- *)
Lemma D_exp_lin : forall a, Deriv (fun t => exp (a * t)) (fun t => a * exp (a * t)).
Proof.
  intros a t.
  assert (H : derivable_pt_lim (fun x => exp (a * x)) t (exp (a * t) * a)).
  { apply (derivable_pt_lim_comp (fun x => a * x) exp t a (exp (a*t))).
    - apply D_lin.
    - apply derivable_pt_lim_exp. }
  replace (a * exp (a * t)) with (exp (a * t) * a) by ring. exact H.
Qed.

(* =====================================================================
   D_ext — THE MOST IMPORTANT LEMMA IN THIS FILE.  Read this carefully;
   it is the idiom used by every derivative theorem in SLA_Chapter4.v.

   THE PROBLEM.  The rules above hand you a derivative in a FIXED syntactic
   shape.  For instance applying D_minus to theta-hat - theta* yields the
   derivative written as  ( -Gamma eps phi ) - 0 , with a dangling '- 0'.
   But equation 4.21 is stated as  -Gamma eps phi .  Coq will not silently
   identify the two, because Deriv f f' mentions f' as a syntactic object.

   THE SOLUTION.  D_ext says: if you can prove Deriv for one pair of
   functions, and the pair you actually WANT agrees with it pointwise, you
   are done.

   STATEMENT.  forall f f' g g',
       (forall t, f t = g t)      -- the functions agree pointwise
    -> (forall t, f' t = g' t)    -- the derivative expressions agree
    -> Deriv f f'                 -- the calculus, in the convenient shape
    -> Deriv g g'.                -- the calculus, in the shape you want

   HOW IT IS USED.  The goal is always Deriv g g' (g, g' fixed by the
   statement you are proving), so you write

       apply (D_ext <convenient f> <convenient f'>).

   and get back exactly three subgoals, in this order:
       1.  forall t, f t = g t          usually closed by reflexivity
       2.  forall t, f' t = g' t        THIS IS WHERE THE ALGEBRA LIVES
       3.  Deriv f f'                   the actual differentiation rules

   Subgoal 2 is the mathematical content; subgoals 1 and 3 are bookkeeping.

   PROOF.  Rather than assume functional extensionality, we unfold the
   epsilon/delta definition by hand, so the development stays free of extra
   axioms.
     intros ... t eps Heps    -- 'Deriv g g'' unfolds to a forall over t, and
                                 derivable_pt_lim unfolds to a forall over
                                 eps > 0, so we can just keep introducing.
     destruct (H t eps Heps) as [delta Hd]
                              -- H gives us EXISTENCE of a delta; destruct
                                 takes it apart into the witness 'delta' and
                                 its property 'Hd'.
     exists delta             -- supply the same delta for g.
     rewrite <- !Hf, <- Hf'   -- rewrite g back into f throughout the goal.
                                 The '!' means: repeat as many times as
                                 possible.  '<-' means right-to-left.
   ===================================================================== *)
Lemma D_ext : forall f f' g g',
  (forall t, f t = g t) -> (forall t, f' t = g' t) -> Deriv f f' -> Deriv g g'.
Proof.
  intros f f' g g' Hf Hf' H t eps Heps.
  destruct (H t eps Heps) as [delta Hd].
  exists delta. intros h Hh Hlt.
  rewrite <- !Hf, <- Hf'. apply Hd; assumption.
Qed.

(* ---------------------------------------------------------------------
   Termwise differentiation of a finite sum.

   F and F' have type nat -> R -> R: F i is the i-th summand as a function of
   time, F' i its derivative.  So the statement is
       d/dt sum_{i<n} F_i(t) = sum_{i<n} F'_i(t),
   under the assumption that each F_i is differentiable with derivative F'_i.

   PROOF.  Induction on n.  Base case: the empty sum is the constant 0.
   Step: Sum (S n) is Sum n + F n, so apply the sum rule and recurse.
   The '+' bullets nest inside the '-' bullets; Coq requires that you use a
   different bullet symbol at each nesting level.
   --------------------------------------------------------------------- *)
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

(* ---------------------------------------------------------------------
   If V' <= 0 everywhere then V is nonincreasing.

   This is the rigorous replacement for the informal step 'V-dot is negative
   semidefinite, therefore V cannot grow' that appears after equations 4.23,
   4.58 and 4.69.  Combined with Sum_eq0_all it also replaces the implicit
   ODE-uniqueness argument behind the convex-hull invariance claim.

   PROOF.
     destruct (Rle_lt_or_eq_dec a b Hab) as [Hlt|Heq]
                     -- a <= b splits into a < b or a = b.
     MVT_cor2        -- the standard-library mean value theorem:
                          a < b, and f differentiable on [a,b] with derivative
                          f', imply there is c in (a,b) with
                          f b - f a = f' c * (b - a).
                        The argument (fun c _ => Hd c) is an anonymous proof
                        that the differentiability hypothesis holds at every
                        c; the underscore ignores the unused a <= c <= b.
     as [c [Hc _]]   -- take the witness c and its first property Hc; discard
                        the second with the underscore.
     specialize (Hs c) -- instantiate the hypothesis 'forall t, f' t <= 0' at
                        the particular point c.
     nra             -- NONLINEAR real arithmetic.  Needed instead of lra
                        because the conclusion requires multiplying
                        f' c <= 0 by b - a > 0, which is a product of two
                        unknown quantities.
     subst; lra      -- in the case a = b, substitute and finish.
   --------------------------------------------------------------------- *)
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

(* Mirror image: V' >= 0 everywhere implies V is nondecreasing.  Used once,
   to prove that M_f is positive semidefinite: the integrating factor
   exp(sigma t) * (x^T M_f x) has a nonnegative derivative and starts at 0.  *)
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
