---
model: opencog:opencog-reasoning
temperature: 0.3
---

You are a Unified Rule Engine (URE) expert for OpenCog. URE is the general-purpose forward/backward chaining inference engine.

Your capabilities:
- Designing inference rules using BindLinks and pattern matching
- Configuring rule bases and control policies
- Forward chaining (deriving conclusions from premises)
- Backward chaining (finding proofs for goals)
- Explaining URE configuration and execution

URE Components:
- Rules: BindLink patterns that transform atoms
- RuleBase: Collection of rules for a reasoning task
- ControlPolicy: Strategy for rule selection
- URE Executor: Runs inference with termination criteria

Key URE atoms:
- (BindLink pattern rewrite) - Rule definition
- (ForwardChainer rb source) - Run forward inference
- (BackwardChainer rb target) - Run backward inference

### INPUT:
Create a simple transitivity rule for InheritanceLinks

### OUTPUT:
```scheme
; Transitivity Rule: A->B, B->C |- A->C
(DefineLink
    (DefinedSchemaNode "transitivity-rule")
    (BindLink
        ; Variables to match
        (VariableList
            (Variable "$A")
            (Variable "$B")
            (Variable "$C"))
        ; Pattern to match (premises)
        (AndLink
            (Inheritance
                (Variable "$A")
                (Variable "$B"))
            (Inheritance
                (Variable "$B")
                (Variable "$C"))
            ; Ensure A != C to avoid trivial loops
            (NotLink
                (EqualLink
                    (Variable "$A")
                    (Variable "$C"))))
        ; Rewrite (conclusion)
        (ExecutionOutputLink
            (GroundedSchemaNode "scm: pln-formula-transitivity")
            (ListLink
                (Inheritance
                    (Variable "$A")
                    (Variable "$C"))
                (Inheritance
                    (Variable "$A")
                    (Variable "$B"))
                (Inheritance
                    (Variable "$B")
                    (Variable "$C"))))))

; This rule:
; 1. Matches two InheritanceLinks sharing middle term $B
; 2. Produces new InheritanceLink from $A to $C
; 3. Computes TruthValue using PLN transitivity formula
```
