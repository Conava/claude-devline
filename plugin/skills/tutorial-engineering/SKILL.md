---
name: tutorial-engineering
description: "Create pedagogical learning experiences from code — tutorials, workshops, and guides with progressive difficulty, hands-on exercises, and fail-forward teaching. Use only when explicitly requested."
argument-hint: "<topic or codebase area to create tutorial for>"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Tutorial Engineering

Transform code and concepts into effective learning experiences. Not documentation (that explains) — tutorials that teach by doing.

**Invoked only on explicit request.**

## Pedagogical Design

### Progressive Skill Building

Structure every tutorial in this order:

1. **Concept Introduction**: What are we learning and why does it matter? (2-3 sentences, no jargon)
2. **Minimal Working Example**: Smallest possible code that demonstrates the concept
3. **Guided Practice**: Step-by-step walkthrough with explanations at each step
4. **Variations**: "Now try changing X and see what happens"
5. **Challenge**: An exercise that requires applying the concept in a slightly different context
6. **Common Mistakes**: What goes wrong and how to debug it (fail-forward teaching)

### Fail-Forward Teaching

Intentionally include common mistakes so learners practice debugging:

```
# This looks correct but has a subtle bug — can you spot it?
def calculate_average(numbers):
    return sum(numbers) / len(numbers)  # What if numbers is empty?
```

Show the error message, explain why it happens, then show the fix.

### Tutorial Formats

| Format | Length | Best For |
|--------|--------|----------|
| **Quick Start** | 5-10 min | Getting started, first success |
| **Deep Dive** | 30-60 min | Understanding a complex topic |
| **Workshop** | 2-4 hours | Building something real end-to-end |
| **Cookbook** | Varies | Recipe-style solutions to common tasks |

## Process

1. **Identify the audience**: What do they already know? What's their goal?
2. **Define learning objectives**: "After this tutorial, you will be able to..."
3. **Extract teachable concepts** from the codebase
4. **Order by dependency**: Concept A must be understood before Concept B
5. **Create progressive exercises**: Each builds on the previous
6. **Add debugging exercises**: Intentional errors for learners to find and fix
7. **Write verification steps**: How learners confirm they got it right

## Output

Write tutorials to `docs/tutorials/` with clear naming. Each tutorial includes:
- Prerequisites and setup
- Learning objectives
- Estimated time
- Step-by-step content with runnable code
- Exercises with solutions (collapsed/hidden)
- "Next steps" linking to related tutorials
