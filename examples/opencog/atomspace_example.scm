;; AtomSpace Example Knowledge Base
;; This file demonstrates creating a knowledge base in OpenCog's AtomSpace
;; Use with: aichat --role atomspace

;; ============================================
;; Basic Concepts
;; ============================================

;; Define fundamental concepts
(ConceptNode "Animal")
(ConceptNode "Plant")
(ConceptNode "LivingThing")

;; Define animal subcategories
(ConceptNode "Mammal")
(ConceptNode "Bird")
(ConceptNode "Fish")
(ConceptNode "Reptile")

;; Define specific animals
(ConceptNode "Cat")
(ConceptNode "Dog")
(ConceptNode "Eagle")
(ConceptNode "Salmon")

;; ============================================
;; Inheritance Hierarchy
;; ============================================

;; Top-level inheritance (with TruthValues)
(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Animal")
  (ConceptNode "LivingThing"))

(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Plant")
  (ConceptNode "LivingThing"))

;; Animal categories
(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Mammal")
  (ConceptNode "Animal"))

(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Bird")
  (ConceptNode "Animal"))

(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Fish")
  (ConceptNode "Animal"))

;; Specific animals
(InheritanceLink (stv 1.0 0.99)
  (ConceptNode "Cat")
  (ConceptNode "Mammal"))

(InheritanceLink (stv 1.0 0.99)
  (ConceptNode "Dog")
  (ConceptNode "Mammal"))

(InheritanceLink (stv 1.0 0.99)
  (ConceptNode "Eagle")
  (ConceptNode "Bird"))

(InheritanceLink (stv 1.0 0.99)
  (ConceptNode "Salmon")
  (ConceptNode "Fish"))

;; ============================================
;; Properties and Attributes
;; ============================================

;; Define properties as predicates
(PredicateNode "has-fur")
(PredicateNode "has-feathers")
(PredicateNode "has-scales")
(PredicateNode "can-fly")
(PredicateNode "can-swim")
(PredicateNode "is-warm-blooded")

;; Assign properties to categories
(EvaluationLink (stv 1.0 0.95)
  (PredicateNode "has-fur")
  (ConceptNode "Mammal"))

(EvaluationLink (stv 1.0 0.95)
  (PredicateNode "has-feathers")
  (ConceptNode "Bird"))

(EvaluationLink (stv 1.0 0.95)
  (PredicateNode "has-scales")
  (ConceptNode "Fish"))

(EvaluationLink (stv 0.9 0.9)
  (PredicateNode "can-fly")
  (ConceptNode "Bird"))

(EvaluationLink (stv 1.0 0.95)
  (PredicateNode "can-swim")
  (ConceptNode "Fish"))

(EvaluationLink (stv 1.0 0.98)
  (PredicateNode "is-warm-blooded")
  (ConceptNode "Mammal"))

(EvaluationLink (stv 1.0 0.98)
  (PredicateNode "is-warm-blooded")
  (ConceptNode "Bird"))

;; ============================================
;; Relationships Between Entities
;; ============================================

;; Similarity relationships
(SimilarityLink (stv 0.8 0.9)
  (ConceptNode "Cat")
  (ConceptNode "Dog"))

;; Predator-prey relationships
(EvaluationLink (stv 0.7 0.8)
  (PredicateNode "eats")
  (ListLink
    (ConceptNode "Cat")
    (ConceptNode "Fish")))

(EvaluationLink (stv 0.9 0.85)
  (PredicateNode "eats")
  (ListLink
    (ConceptNode "Eagle")
    (ConceptNode "Fish")))

;; ============================================
;; Query Patterns
;; ============================================

;; Example: Find all mammals
;; (GetLink
;;   (TypedVariableLink
;;     (VariableNode "$X")
;;     (TypeNode "ConceptNode"))
;;   (InheritanceLink
;;     (VariableNode "$X")
;;     (ConceptNode "Mammal")))

;; Example: Find all animals that can fly
;; (GetLink
;;   (TypedVariableLink
;;     (VariableNode "$X")
;;     (TypeNode "ConceptNode"))
;;   (AndLink
;;     (InheritanceLink
;;       (VariableNode "$X")
;;       (ConceptNode "Animal"))
;;     (EvaluationLink
;;       (PredicateNode "can-fly")
;;       (VariableNode "$X"))))

;; ============================================
;; Inference Rules (for PLN)
;; ============================================

;; Transitive inheritance rule
;; If A inherits from B, and B inherits from C, then A inherits from C
(define transitive-inheritance-rule
  (BindLink
    (VariableList
      (TypedVariableLink (VariableNode "$A") (TypeNode "ConceptNode"))
      (TypedVariableLink (VariableNode "$B") (TypeNode "ConceptNode"))
      (TypedVariableLink (VariableNode "$C") (TypeNode "ConceptNode")))
    (AndLink
      (InheritanceLink (VariableNode "$A") (VariableNode "$B"))
      (InheritanceLink (VariableNode "$B") (VariableNode "$C")))
    (InheritanceLink (VariableNode "$A") (VariableNode "$C"))))
