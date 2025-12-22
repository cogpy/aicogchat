;; MeTTa Programming Examples for Hyperon
;; Use with: aichat --role hyperon -m opencog:opencog-hyperon

;; ============================================
;; Basic MeTTa Syntax
;; ============================================

;; Atoms (the fundamental unit)
Cat
Dog
Animal

;; Expressions (nested structures)
(Inheritance Cat Animal)
(Inheritance Dog Animal)

;; Variables (start with $)
$x
$animal

;; ============================================
;; Type Definitions
;; ============================================

;; Declare types
(: Cat Type)
(: Dog Type)
(: Animal Type)

;; Function type signatures
(: is-mammal (-> Animal Bool))
(: parent-of (-> Animal Animal Bool))

;; ============================================
;; Equality and Pattern Matching
;; ============================================

;; Define equality (like functions)
(= (is-mammal Cat) True)
(= (is-mammal Dog) True)

;; Pattern matching with variables
(= (category $x)
   (if (is-mammal $x)
       Mammal
       Unknown))

;; ============================================
;; Knowledge Base Queries
;; ============================================

;; Add facts to space
(Inheritance Cat Mammal)
(Inheritance Dog Mammal)
(Inheritance Mammal Animal)
(Inheritance Bird Animal)
(Inheritance Eagle Bird)

;; Query: Find all mammals
;; !(match &self (Inheritance $x Mammal) $x)
;; Returns: Cat, Dog

;; Query: Find what Cat inherits from
;; !(match &self (Inheritance Cat $y) $y)
;; Returns: Mammal

;; ============================================
;; Recursive Functions
;; ============================================

;; Factorial
(= (factorial 0) 1)
(= (factorial $n)
   (* $n (factorial (- $n 1))))

;; Fibonacci
(= (fib 0) 0)
(= (fib 1) 1)
(= (fib $n)
   (+ (fib (- $n 1))
      (fib (- $n 2))))

;; ============================================
;; List Operations
;; ============================================

;; List construction
(Cons 1 (Cons 2 (Cons 3 Nil)))

;; List length
(= (length Nil) 0)
(= (length (Cons $head $tail))
   (+ 1 (length $tail)))

;; Map function over list
(= (map $f Nil) Nil)
(= (map $f (Cons $head $tail))
   (Cons ($f $head) (map $f $tail)))

;; Filter list
(= (filter $pred Nil) Nil)
(= (filter $pred (Cons $head $tail))
   (if ($pred $head)
       (Cons $head (filter $pred $tail))
       (filter $pred $tail)))

;; ============================================
;; Family Relationships Example
;; ============================================

;; Define parent relationships
(parent-of Tom Mary)
(parent-of Tom John)
(parent-of Mary Alice)
(parent-of Mary Bob)
(parent-of John Carol)

;; Grandparent rule
(= (grandparent-of $gp $gc)
   (let $p (match &self (parent-of $gp $p) $p)
     (match &self (parent-of $p $gc) $gc)))

;; Ancestor rule (recursive)
(= (ancestor-of $a $d)
   (match &self (parent-of $a $d) True))
(= (ancestor-of $a $d)
   (let $m (match &self (parent-of $a $m) $m)
     (ancestor-of $m $d)))

;; Sibling rule
(= (sibling-of $x $y)
   (let $p (match &self (parent-of $p $x) $p)
     (let* (($s (match &self (parent-of $p $y) $y))
            (_ (if (== $x $s) (empty) ())))
       $s)))

;; ============================================
;; Type Inference
;; ============================================

;; Typed expressions
(: add (-> Number Number Number))
(= (add $x $y) (+ $x $y))

;; Generic types
(: identity (-> $t $t))
(= (identity $x) $x)

;; Dependent types
(: Vector (-> Type Nat Type))
(: VNil (Vector $a Z))
(: VCons (-> $a (Vector $a $n) (Vector $a (S $n))))

;; ============================================
;; Reasoning Patterns
;; ============================================

;; Modus Ponens
(= (modus-ponens $p (Implies $p $q)) $q)

;; Transitive reasoning
(= (transitive (Inherits $a $b) (Inherits $b $c))
   (Inherits $a $c))

;; Apply transitivity to our knowledge
;; !(transitive (Inheritance Cat Mammal) (Inheritance Mammal Animal))
;; Returns: (Inheritance Cat Animal)

;; ============================================
;; PLN-style TruthValues in MeTTa
;; ============================================

;; TruthValue type
(: TV Type)
(: stv (-> Number Number TV))

;; Fact with TruthValue
(WithTV (Inheritance Cat Mammal) (stv 1.0 0.99))
(WithTV (Inheritance Mammal Animal) (stv 1.0 0.95))

;; Deduction formula
(= (tv-deduction (stv $s1 $c1) (stv $s2 $c2))
   (stv (* $s1 $s2) (* $c1 $c2)))

;; ============================================
;; Execution Examples
;; ============================================

;; Run these with !(...) in MeTTa REPL:

;; !(factorial 5)
;; -> 120

;; !(fib 10)
;; -> 55

;; !(match &self (Inheritance $x Animal) $x)
;; -> Cat, Dog, Bird, Eagle, Mammal

;; !(grandparent-of Tom $gc)
;; -> Alice, Bob, Carol
