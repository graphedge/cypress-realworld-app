---
date: 2026-04-06
author: Copilot CLI (Claude Haiku 4.5)
status: proposal
scope: agent-capability-expansion
llm_bias: claude-haiku-4.5
---

# Agent Update Proposal: LLM Model Bias & Execution Defaults

## Executive Summary

This proposal updates **5 key agents** to apply **caller-LLM-model bias** as the primary execution strategy. When an agent is invoked by a specific LLM model (Haiku, Sonnet, Opus, Gemini, GPT), dispatch defaults to that model for task execution unless explicitly overridden.

**Execution model**: Caller model → Dispatch preference. No breaking changes; all agents remain backward compatible.

---

## Agents for Update

### 1. **specfarm.promptflow4speckit** (Production)
**Location**: `.github/agents/specfarm.promptflow4speckit.agent.md`  
**Current state**: Deprecated prototype; promoted to production  
**Update**: Add model-bias parameter and dispatch override  
**Default model**: Haiku (fast execution for most tasks)  
**Override syntax**: `--model=sonnet` to force Sonnet  

**Changes**:
- [ ] Add `--model` parameter to parameter table (default: "caller-model")
- [ ] Implement caller-model detection in Phase 1 (parse user context)
- [ ] Update Phase 3 dispatch logic to prefer caller model
- [ ] Add override examples to Quick Start section

---

### 2. **specfarm.promptflow-gemini** (Production)
**Location**: `.github/agents/specfarm.promptflow-gemini.agent.md`  
**Current state**: Production Gemini orchestrator  
**Update**: Add multi-model dispatch capability  
**Primary model**: Gemini 2.5 Flash (current)  
**Secondary model**: Claude Haiku (fallback for non-Gemini callers)  

**Changes**:
- [ ] Add caller-model detection to Phase 1
- [ ] Extend Phase 3 Agent Selection table to include model selection criteria
- [ ] Add dispatcher override: `--delegate-to=haiku` for coding tasks from Haiku callers
- [ ] Update Constitution Compliance section (NFR 4.2 new)

---

### 3. **implement-update.md** (Prototype → Deployment Directive)
**Location**: `.github/agents/prototypes/implement-update.md`  
**Current state**: Commit policy guidance for implement4speckit  
**Update**: Formalize as binding deployment directive; add model-specific WIP cadence  
**Applies to**: All implement4speckit invocations  

**Changes**:
- [ ] Add model-specific WIP commit intervals:
  - Haiku: 10 min (fast, more frequent saves)
  - Sonnet: 15 min (balanced)
  - Opus: 20 min (thorough analysis, slower)
- [ ] Add auto-detection: "Detect caller model from agent context"
- [ ] Add circuit breaker for model fallback (if primary fails 3x, switch to next model)

---

### 4. **plan4sk-update.md** (Prototype → Deployment Directive)
**Location**: `.github/agents/prototypes/plan4sk-update.md`  
**Current state**: Commit policy guidance for plan4speckit  
**Update**: Formalize as binding deployment directive; add model-context awareness  
**Applies to**: All plan4speckit invocations  

**Changes**:
- [ ] Add model detection clause: "If called from Haiku, use Haiku model for task analysis"
- [ ] Adjust planning granularity by model:
  - Haiku: "task-by-task planning (simpler breakdown)"
  - Sonnet: "cross-task dependency analysis (full coverage)"
  - Opus: "strategic planning with alternatives (premium analysis)"
- [ ] Link to model-bias section of main promptflow agents

---

### 5. **specfarm.gatherrules-update** (Prototype → Enhancement)
**Location**: `.github/agents/prototypes/todo-specfarm.gatherrules-update.agent.md`  
**Current state**: Prototype for rules gathering enhancement  
**Update**: Add caller-model dispatch and graceful degradation  
**Primary use**: Extraction of rules from commit history  

**Changes**:
- [ ] Add `--preferred-model` parameter (default: caller model)
- [ ] Add fallback logic: "If Gemini gatherer unavailable, use Haiku parser"
- [ ] Add output format validation by model (Haiku → compact; Sonnet → detailed)

---

## Implementation Strategy

### Phase 1: Update Core Promptflow Agents (Haiku)
**Agents**: specfarm.promptflow4speckit, specfarm.promptflow-gemini  
**Tasks**:
- [ ] T101: Add model-bias parameter to promptflow4speckit.agent.md (Haiku dispatch)
- [ ] T102: Implement caller-model detection in Phase 1 (both agents)
- [ ] T103: Update Phase 3 dispatch heuristics (model-aware selection)
- [ ] T104: Add override syntax to Quick Start sections
- [ ] T105: Update Constitution sections (add NFR 4.2: "Caller model bias preferred")

**Acceptance Criteria**:
- ✅ `specfarm.promptflow4speckit --model=haiku` uses Haiku for tasks
- ✅ `specfarm.promptflow4speckit` (no `--model`) auto-detects caller model
- ✅ Backward compatible: existing invocations unaffected
- ✅ ShellCheck validates all YAML and heredocs
- ✅ Parameter table updated in both agents

---

### Phase 2: Deploy Commit Policies (Directive Formalization)
**Prototypes**: implement-update.md, plan4sk-update.md  
**Tasks**:
- [ ] T106: Formalize implement-update.md as binding directive (add model-specific WIP intervals)
- [ ] T107: Formalize plan4sk-update.md as binding directive (add granularity levels)
- [ ] T108: Add circuit-breaker logic for both (3-strike model fallback rule)
- [ ] T109: Create deployment checklist (copy to `.specfarm/directives/` for CI/CD enforcement)

**Acceptance Criteria**:
- ✅ Directives enforceable via pre-commit hook
- ✅ Model detection logic works (Haiku → 10 min, Sonnet → 15 min, etc.)
- ✅ Circuit breaker halts safely (no infinite retries)
- ✅ Backward compatible with existing agents

---

### Phase 3: Enhance Rules Gatherer (Optional Enhancement)
**Prototype**: specfarm.gatherrules-update.agent.md  
**Tasks**:
- [ ] T110: Add `--preferred-model` parameter with fallback logic
- [ ] T111: Implement model-specific output formatting
- [ ] T112: Add graceful degradation (Gemini unavailable → Haiku parser)

**Acceptance Criteria**:
- ✅ Gatherer respects caller model preference
- ✅ Falls back gracefully if primary unavailable
- ✅ Output consistent across models (YAML/JSON validated)

---

## Model Bias Decision Tree

```
┌─ User invokes agent (Haiku context)
│
├─ Agent detects caller: Haiku
│
├─ Check for explicit override:
│  ├─ if --model=X → use X
│  └─ if no override → use Haiku
│
└─ Dispatch to Haiku model
   (Fast execution, minimal overhead)
```

**Precedence**:
1. Explicit `--model=X` flag (user override)
2. Caller model (auto-detected context)
3. Default fallback (Haiku for most tasks; Gemini for integration tasks)

---

## LLM Model Selection Rationale

| Model | Best For | Reasoning |
|-------|----------|-----------|
| **Haiku** | Coding tasks, tests, simple planning | Fast, low latency, ideal for iterative development |
| **Sonnet** | Complex planning, architecture, multi-task | Balanced cost/capability; good for dependency analysis |
| **Opus** | High-stakes code review, security, final validation | Premium analysis; slower but more thorough |
| **Gemini** | Large-context orchestration, multi-spec processing | Specialized for context-aware task selection |

**For this proposal**: Default to **Haiku** (caller model bias) unless Gemini or Opus explicitly selected.

---

## Backward Compatibility

✅ **All changes are additive**:
- Existing agent invocations work unchanged
- New `--model` parameter is optional
- Caller-model detection is transparent
- Default behavior preserved

✅ **No breaking changes**:
- Old prompts still work
- Existing tasks not re-routed
- Integration tests unaffected

---

## Estimated Effort

| Phase | Tasks | Est. Lines | Model | Est. Time |
|-------|-------|-----------|-------|-----------|
| 1: Core Agents | T101–T105 | 100–150 | Haiku | 30–45 min |
| 2: Directives | T106–T109 | 80–120 | Haiku | 25–35 min |
| 3: Enhancement | T110–T112 | 60–90 | Haiku | 20–30 min |
| **Total** | **12 tasks** | **240–360** | **Haiku** | **75–110 min** |

---

## Next Steps

### If Approved:
1. ✅ Create tasks.md with 12 tasks (T101–T112) in this proposal folder
2. ✅ Deploy Phase 1 (core agents) using `specfarm.promptflow4speckit --model=haiku T101 T102 T103 T104 T105`
3. ✅ Deploy Phase 2 (directives) using `specfarm.promptflow4speckit --model=haiku T106 T107 T108 T109`
4. ✅ Deploy Phase 3 (enhancement) using same orchestrator for T110–T112
5. ✅ Validate with full test suite
6. ✅ Commit all changes with `FEAT: Add LLM model-bias to agents (T101–T112)` message

### For Implementation:
- Coordinate with `.github/agents/specfarm.promptflow4speckit.agent.md` to dispatch tasks
- Use `--model=haiku` to ensure fast execution (since I'm Haiku)
- Mark WIP commits every 10 min per implement-update.md guidance
- Fallback to Sonnet only if Haiku dispatch fails 3x

---

## Questions for User

1. **Model preference confirmation**: Should default dispatch always prefer caller model (Haiku if called from Haiku)?
2. **Fallback strategy**: On 3 consecutive failures, escalate to Sonnet (slower but more thorough) or halt?
3. **Scope**: Include Phase 3 (rules gatherer) or defer as "nice-to-have"?
4. **Validation**: Should ShellCheck all YAML/bash artifacts before commit, or skip for speed?

---

## Constitution Alignment

✅ **Principle I (CLI-Centric)**: All updates via CLI agents (not manual edits)  
✅ **Principle II.A (Bash-only testing)**: No new test frameworks; ShellCheck validation only  
✅ **Principle IV (Version bumping)**: Bump agent versions in metadata if deployed  
✅ **Principle V (Zero external deps)**: All model dispatch via built-in agent wiring  

---

**Generated**: 2026-04-06T05:47:19Z  
**Caller Model**: Claude Haiku 4.5  
**Ready for**: Review → Approval → Implementation
