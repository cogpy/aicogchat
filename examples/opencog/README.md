# OpenCog Integration Examples

This directory contains examples for using AIChat with OpenCog integration.

## Prerequisites

1. A running OpenCog server with OpenAI-compatible API
2. AIChat configured with OpenCog client

## Configuration

Add the following to your `~/.config/aichat/config.yaml`:

```yaml
clients:
  - type: opencog
    api_base: http://localhost:5000/v1  # Your OpenCog server
    api_key: optional-key               # If authentication is required
```

## Available Models

| Model | Description | Use Case |
|-------|-------------|----------|
| `opencog:opencog-chat` | General conversation | Basic Q&A, explanations |
| `opencog:opencog-reasoning` | PLN inference | Logical reasoning, uncertainty |
| `opencog:opencog-hyperon` | MeTTa/Hyperon | MeTTa programming tasks |
| `opencog:opencog-embed` | Embeddings | RAG, semantic search |

## Quick Start Examples

### 1. Basic Chat

```bash
# Set the model
aichat -m opencog:opencog-chat "What is the AtomSpace?"
```

### 2. Using Roles

```bash
# Use the AtomSpace role for knowledge representation tasks
aichat --role atomspace "Create an inheritance hierarchy for vehicles"

# Use the PLN role for reasoning tasks
aichat --role pln "Calculate the truth value for: If cats are mammals and mammals are animals, then cats are animals"

# Use the Hyperon role for MeTTa tasks
aichat --role hyperon "Write a MeTTa function to find ancestors"
```

### 3. Interactive REPL with Sessions

```bash
# Start a session for ongoing work
aichat
> .session opencog-dev
> .role atomspace
> Create a ConceptNode for "intelligence"
> Now create an InheritanceLink making it inherit from "cognitive-ability"
```

### 4. Using Macros

First, install the macros:
```bash
cp /path/to/aichat/examples/macros/*.txt ~/.config/aichat/macros/
```

Then use them in REPL:
```bash
aichat
> .macro opencog-init
# Sets up atomspace role and session

> .macro pln-reasoning
# Sets up PLN role with reasoning model

> .macro hyperon-metta
# Sets up Hyperon role for MeTTa
```

### 5. Using Agents

First, install an agent:
```bash
cp -r /path/to/aichat/examples/agents/opencog-reasoning ~/.config/aichat/functions/agents/
```

Then use it:
```bash
# Start the agent
aichat -a opencog-reasoning

# The agent has specialized tools for PLN reasoning
> Help me design a PLN inference chain for medical diagnosis
> Calculate the TruthValue for this deduction with strength 0.8/0.9 and 0.7/0.85
```

## Example Sessions

### Session 1: AtomSpace Knowledge Building

```
$ aichat --role atomspace

> Create a knowledge base about animals

I'll create an AtomSpace knowledge base about animals:

;; Basic animal concepts
(ConceptNode "Animal")
(ConceptNode "Mammal")
(ConceptNode "Bird")
(ConceptNode "Cat")
(ConceptNode "Dog")
(ConceptNode "Eagle")

;; Inheritance hierarchy
(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Mammal")
  (ConceptNode "Animal"))

(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Bird")
  (ConceptNode "Animal"))

(InheritanceLink (stv 1.0 1.0)
  (ConceptNode "Cat")
  (ConceptNode "Mammal"))

;; Properties
(EvaluationLink (stv 1.0 0.95)
  (PredicateNode "has-fur")
  (ConceptNode "Mammal"))
```

### Session 2: PLN Reasoning

```
$ aichat --role pln -m opencog:opencog-reasoning

> Given:
> - "Socrates is a human" with TV <1.0, 0.99>
> - "Humans are mortal" with TV <1.0, 0.95>
> What is the truth value of "Socrates is mortal"?

Using PLN deduction:

Premises:
1. (InheritanceLink (stv 1.0 0.99)
     (ConceptNode "Socrates")
     (ConceptNode "Human"))

2. (InheritanceLink (stv 1.0 0.95)
     (ConceptNode "Human")
     (ConceptNode "Mortal"))

Conclusion using deduction formula:
- Strength: s1 × s2 = 1.0 × 1.0 = 1.0
- Confidence: c1 × c2 = 0.99 × 0.95 ≈ 0.94

Result:
(InheritanceLink (stv 1.0 0.94)
  (ConceptNode "Socrates")
  (ConceptNode "Mortal"))
```

### Session 3: MeTTa Programming

```
$ aichat --role hyperon -m opencog:opencog-hyperon

> Write a MeTTa program to compute factorial

;; Define factorial in MeTTa
(= (factorial 0) 1)
(= (factorial $n)
   (* $n (factorial (- $n 1))))

;; Usage
!(factorial 5)  ;; Returns 120

;; With type annotations
(: factorial (-> Number Number))
(= (factorial 0) 1)
(= (factorial $n)
   (if (> $n 0)
       (* $n (factorial (- $n 1)))
       1))
```

## Agent Tools Reference

### opencog-reasoning Agent

| Tool | Description |
|------|-------------|
| `pln_deduction` | Calculate PLN deduction TruthValue |
| `create_bind_rule` | Generate URE BindLink rules |
| `run_inference` | Execute forward/backward chaining |

### atomspace-query Agent

| Tool | Description |
|------|-------------|
| `query_atoms` | Query atoms by type/name |
| `create_query` | Convert natural language to query |
| `execute_pattern` | Run pattern matching |

### opencog-nlp Agent

| Tool | Description |
|------|-------------|
| `parse_sentence` | Parse sentence to atoms |
| `extract_knowledge` | Extract entities/relations |
| `generate_qa_pattern` | Question to query pattern |

## Troubleshooting

### Connection Issues

```bash
# Check if OpenCog server is running
curl http://localhost:5000/v1/models

# Test basic completion
curl http://localhost:5000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "opencog-chat", "messages": [{"role": "user", "content": "Hello"}]}'
```

### Model Not Found

Ensure models are defined in `models.yaml`:
```yaml
- platform: opencog
  models:
    - name: opencog-chat
      # ...
```

### Role Not Found

Check role files exist:
```bash
ls ~/.config/aichat/roles/
# Or use built-in roles from assets/roles/
```
