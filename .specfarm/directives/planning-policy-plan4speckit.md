---
name: "planning-policy-plan4speckit"
scope: "planning"
applies-to: ["speckit.plan", "plan4speckit"]
binding: true
model-specific-granularity:
  haiku: "task-by-task (3–5 tasks per run)"
  sonnet: "cross-task dependencies (5–8 tasks per run)"
  opus: "strategic alternatives (8–12 tasks per run)"
fallback-model: "sonnet"
max-wips-per-run: 3
---

# Binding Planning Policy: plan4speckit

**Status**: Mandatory directive (overrides previous guidance)  
**Applies to**: All `speckit.plan` and `plan4speckit` invocations  
**Scope**: Planning & specification generation in unstable environments  

---

## Core Principles

1. **Frequent saves** — Prioritize saving progress frequently to avoid losing work.

2. **Model-Specific Planning Granularity** (MANDATORY):
   - **Haiku**: Task-by-task planning (simpler breakdown, ~3–5 tasks per planning run)
     - Focus: Linear task decomposition, minimal cross-task dependencies
     - Plan depth: Shallow (straightforward sequencing)
   - **Sonnet**: Cross-task dependency analysis (full coverage, ~5–8 tasks per run)
     - Focus: Dependency graphs, parallel opportunities, risk assessment
     - Plan depth: Medium (comprehensive but efficient)
   - **Opus**: Strategic alternatives with premium analysis (~8–12 tasks per run)
     - Focus: Multiple implementation paths, trade-off analysis, contingency planning
     - Plan depth: Deep (exhaustive analysis for high-stakes decisions)
   - **Auto-detect**: Detect caller model from agent context and apply corresponding granularity

3. **Planning Artifact Requirements**:
   - Generate `plan.md` (strategy, rationale, high-level approach)
   - Generate `tasks.md` (detailed task breakdown with dependencies)
   - Include risk assessment (LOW/MEDIUM/HIGH for each task)
   - Include acceptance criteria (testable, measurable outcomes)

---

## Workflow

### Phase 1: Gather Context
- Collect feature requirements, existing implementations, related specs
- Detect caller model for granularity selection

### Phase 2: Plan Generation (Model-Dependent)
- **Haiku path**: Simple linear breakdown (fast, task-by-task sequencing)
- **Sonnet path**: Full dependency analysis (balanced approach)
- **Opus path**: Strategic analysis with alternatives (thorough, multiple paths)

### Phase 3: Task Breakdown
- Generate tasks.md with dependencies, risk levels, acceptance criteria
- Number tasks sequentially (T001, T002, etc.)
- Include test coverage plans for each task

### Phase 4: Commit & Validate
- Commit WIP every 10–15 min (model-dependent via implement-directive)
- When complete: Amend final WIP → `docs: plan4speckit - completed plan.md + tasks.md`

---

## WIP Commit Limits

- **Max WIP commits per planning run**: 3
- **If 4th WIP needed**: Commit as final (even if imperfect) and ask user for guidance
- **Circuit breaker**: On 3 consecutive commit failures, escalate from Haiku to Sonnet

---

## Planning Granularity Examples

### Haiku Path (Simple Breakdown)
```
Feature: Create platform-check.sh utility
Tasks:
- T001: Implement OS detection function
- T002: Add shell compatibility checks
- T003: Write unit tests
- T004: Validate with ShellCheck
- T005: Final testing & documentation

Total: 5 tasks (simple sequencing, minimal dependencies)
```

### Sonnet Path (Dependency Analysis)
```
Feature: Refactor drift-engine with platform support
Tasks:
- T001: Create platform-check.sh utility (foundation)
- T002: Create path-normalize.sh utility (foundation)
  └─ Depends on: T001 (both need platform detection)
- T003: Refactor bin/drift-engine to use utilities
  └─ Depends on: T001, T002
- T004: Add integration tests
  └─ Depends on: T003
- T005: Validate cross-platform execution
  └─ Depends on: T004
- T006: Performance benchmarking (parallel option)
- T007: Documentation & deployment guide

Total: 7 tasks (full dependency graph, parallel opportunities identified)
```

### Opus Path (Strategic Analysis)
```
Feature: Multi-agent orchestration framework
Tasks:
- T001–T003: Foundation layer (platform detection, path normalization, etc.)
- T004–T008: Core orchestration (dispatcher, model selection, fallback logic)
- T009–T012: Validation & testing (unit, integration, E2E, performance)

Alternative approaches considered:
- Approach A: Monolithic agent with all logic (rejected: hard to test, scale)
- Approach B: Plugin architecture (selected: modular, extensible)
- Approach C: Distributed agents (deferred: more complex, less immediate value)

Risk assessment:
- HIGH: Model availability (fallback to Haiku needed)
- MEDIUM: Dependency graph complexity (well-scoped, manageable)
- LOW: Testing coverage (complete suite planned)

Total: 12 tasks (strategic path with trade-offs documented)
```

---

## All WIP Commits Must Include

- [ ] Agent name (plan4speckit) and context (feature name, spec ID)
- [ ] Brief description of what was generated
- [ ] Syntax check passed (YAML validation for plan/tasks.md)
- [ ] Log entry in `.specfarm/error-memory.md`
- [ ] Co-authored-by trailer: `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`

---

## Constitution Alignment

✅ **Principle IV (Quality Gates)**: Pre-commit YAML validation required  
✅ **Principle V (Stability)**: Frequent saves prevent data loss  
✅ **Model Bias (NFR 4.2)**: Model-specific granularity supports caller-model-preference principle  
✅ **Zero External Dependencies**: Planning uses only built-in agent capabilities