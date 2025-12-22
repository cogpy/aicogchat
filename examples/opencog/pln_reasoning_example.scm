;; PLN Reasoning Example
;; This file demonstrates Probabilistic Logic Networks reasoning
;; Use with: aichat --role pln -m opencog:opencog-reasoning

;; ============================================
;; Knowledge Base Setup
;; ============================================

;; Basic facts with TruthValues (strength, confidence)
(InheritanceLink (stv 1.0 0.99)
  (ConceptNode "Socrates")
  (ConceptNode "Human"))

(InheritanceLink (stv 1.0 0.95)
  (ConceptNode "Human")
  (ConceptNode "Mortal"))

(InheritanceLink (stv 0.85 0.9)
  (ConceptNode "Human")
  (ConceptNode "Rational"))

;; ============================================
;; PLN Deduction
;; ============================================

;; Deduction: A→B ∧ B→C ⊢ A→C
;;
;; Given:
;;   P(B|A) = sAB with confidence cAB
;;   P(C|B) = sBC with confidence cBC
;;
;; Conclusion:
;;   P(C|A) ≈ sAB × sBC
;;   Confidence decreases through the chain

;; Example deduction:
;; From "Socrates is Human" and "Humans are Mortal"
;; Conclude "Socrates is Mortal"
;;
;; sAB = 1.0, cAB = 0.99 (Socrates → Human)
;; sBC = 1.0, cBC = 0.95 (Human → Mortal)
;;
;; Conclusion strength: 1.0 × 1.0 = 1.0
;; Conclusion confidence: 0.99 × 0.95 ≈ 0.94

(InheritanceLink (stv 1.0 0.94)  ;; Derived by PLN
  (ConceptNode "Socrates")
  (ConceptNode "Mortal"))

;; ============================================
;; PLN Induction
;; ============================================

;; Induction: A→B ∧ A→C ⊢ B→C (with lower confidence)
;;
;; Observing that multiple A's have both B and C properties
;; suggests B and C might be related

;; Example:
(InheritanceLink (stv 1.0 0.95)
  (ConceptNode "Tweety")
  (ConceptNode "Bird"))

(InheritanceLink (stv 1.0 0.9)
  (ConceptNode "Tweety")
  (ConceptNode "CanFly"))

(InheritanceLink (stv 1.0 0.95)
  (ConceptNode "Robin")
  (ConceptNode "Bird"))

(InheritanceLink (stv 1.0 0.9)
  (ConceptNode "Robin")
  (ConceptNode "CanFly"))

;; Induced conclusion (with lower confidence due to limited evidence):
(InheritanceLink (stv 0.9 0.7)  ;; Induced
  (ConceptNode "Bird")
  (ConceptNode "CanFly"))

;; ============================================
;; PLN Abduction
;; ============================================

;; Abduction: B→C ∧ A→C ⊢ A→B (hypothesis formation)
;;
;; If we observe that A leads to C, and we know B leads to C,
;; we might hypothesize that A is related to B

;; Example:
;; We observe symptoms (C) and know diseases (B) cause symptoms
;; We hypothesize patient (A) might have the disease

(InheritanceLink (stv 0.95 0.9)
  (ConceptNode "Flu")
  (ConceptNode "Fever"))

(EvaluationLink (stv 1.0 0.95)
  (PredicateNode "has-symptom")
  (ListLink
    (ConceptNode "Patient1")
    (ConceptNode "Fever")))

;; Abduced hypothesis (lower confidence - it's a guess):
(InheritanceLink (stv 0.7 0.5)  ;; Abduced
  (ConceptNode "Patient1")
  (ConceptNode "HasFlu"))

;; ============================================
;; PLN Revision
;; ============================================

;; When we have multiple pieces of evidence for the same conclusion,
;; we can combine them using the revision rule:
;;
;; TV1 = <s1, c1>, TV2 = <s2, c2>
;;
;; Revised strength: (s1×c1 + s2×c2) / (c1 + c2)
;; Revised confidence: (c1 + c2) / (c1 + c2 + c1×c2)

;; Example: Two observations about birds flying
;; Observation 1: <0.9, 0.7>
;; Observation 2: <0.85, 0.6>
;;
;; Revised: s = (0.9×0.7 + 0.85×0.6)/(0.7+0.6) = 0.877
;;          c = (0.7+0.6)/(0.7+0.6+0.42) = 0.756

;; ============================================
;; URE Rules for PLN
;; ============================================

;; Deduction rule for URE
(define pln-deduction-rule
  (BindLink
    (VariableList
      (TypedVariableLink (VariableNode "$A") (TypeNode "ConceptNode"))
      (TypedVariableLink (VariableNode "$B") (TypeNode "ConceptNode"))
      (TypedVariableLink (VariableNode "$C") (TypeNode "ConceptNode")))
    (AndLink
      (InheritanceLink (VariableNode "$A") (VariableNode "$B"))
      (InheritanceLink (VariableNode "$B") (VariableNode "$C"))
      ;; Ensure A≠B, B≠C, A≠C
      (NotLink (EqualLink (VariableNode "$A") (VariableNode "$B")))
      (NotLink (EqualLink (VariableNode "$B") (VariableNode "$C")))
      (NotLink (EqualLink (VariableNode "$A") (VariableNode "$C"))))
    (ExecutionOutputLink
      (GroundedSchemaNode "scm: pln-deduction-formula")
      (ListLink
        (InheritanceLink (VariableNode "$A") (VariableNode "$B"))
        (InheritanceLink (VariableNode "$B") (VariableNode "$C"))
        (InheritanceLink (VariableNode "$A") (VariableNode "$C"))))))

;; Modus Ponens rule
(define pln-modus-ponens-rule
  (BindLink
    (VariableList
      (TypedVariableLink (VariableNode "$P") (TypeNode "PredicateNode"))
      (TypedVariableLink (VariableNode "$Q") (TypeNode "PredicateNode")))
    (AndLink
      (ImplicationLink (VariableNode "$P") (VariableNode "$Q"))
      (VariableNode "$P"))  ;; P is true
    (VariableNode "$Q")))   ;; Conclude Q

;; ============================================
;; Running Inference
;; ============================================

;; Forward chaining: derive new facts from existing ones
;; (cog-fc rule-base (SetLink) #:maximum-iterations 100)

;; Backward chaining: try to prove a target
;; (cog-bc rule-base target #:maximum-iterations 100)

;; Example: Prove Socrates is Mortal
;; (define target
;;   (InheritanceLink
;;     (ConceptNode "Socrates")
;;     (ConceptNode "Mortal")))
;;
;; (cog-bc pln-rule-base target)
