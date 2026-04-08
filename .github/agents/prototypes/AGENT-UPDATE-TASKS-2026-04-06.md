# Agent Update Tasks: LLM Model Bias Implementation

**Proposal**: [AGENT-UPDATE-PROPOSAL-2026-04-06.md](./AGENT-UPDATE-PROPOSAL-2026-04-06.md)  
**Status**: Ready for Implementation  
**Model Bias**: claude-haiku-4.5 (caller preference)  
**Total Tasks**: 12  
**Estimated Effort**: 75–110 minutes  

---

## Phase 1: Core Promptflow Agents (Haiku Dispatch)

### T101: Add model-bias parameter to specfarm.promptflow4speckit.agent.md

**Description**: Update the production promptflow4speckit agent to accept a `--model` parameter and detect caller model context.

**Scope**:
- Add `--model` parameter to the Parameters section (default: "caller-model")
- Add caller-model detection logic to Quick Start examples
- Update Phase 1 (Parse & Validate) to document model detection
- Add override syntax examples

**Acceptance Criteria**:
- ✅ Parameter table includes `--model` with description and default value
- ✅ Quick Start includes 3 examples (no flag, `--model=haiku`, `--model=sonnet`)
- ✅ Phase 1 describes "Detect caller model from agent context"
- ✅ YAML metadata at top includes `llm_bias: "claude-haiku-4.5"` (default)
- ✅ File passes ShellCheck for embedded bash blocks

**Test**:
```bash
grep -c "model.*caller" .github/agents/specfarm.promptflow4speckit.agent.md  # Should be ≥3
grep -c "\-\-model" .github/agents/specfarm.promptflow4speckit.agent.md  # Should be ≥5
```

**Dependencies**: None  
**Risk**: LOW (additive only)

---

### T102: Implement caller-model detection in Phase 1 (both agents)

**Description**: Add logic to Phase 1 of both promptflow agents to detect which model invoked the agent.

**Scope**:
- Update specfarm.promptflow4speckit.agent.md Phase 1 section
- Update specfarm.promptflow-gemini.agent.md Phase 1 section
- Add pseudo-code for model detection (parse agent context, check env vars)
- Document detection heuristics (caller context, agent metadata, fallback)

**Acceptance Criteria**:
- ✅ Both agents describe model detection algorithm in Phase 1
- ✅ Detection heuristics documented (e.g., "From agent caller context, extract model name")
- ✅ Fallback behavior specified (if detection fails, default to Haiku)
- ✅ Examples show output: `Detected caller model: haiku` or `Detected caller model: gemini`

**Test**:
```bash
grep -A5 "Detect.*caller.*model" .github/agents/specfarm.promptflow4speckit.agent.md
grep -A5 "Detect.*caller.*model" .github/agents/specfarm.promptflow-gemini.agent.md
```

**Dependencies**: T101 (prepare promptflow4speckit structure)  
**Risk**: MEDIUM (model detection logic must be reliable)

---

### T103: Update Phase 3 dispatch heuristics (model-aware selection)

**Description**: Enhance the Phase 3 Agent Selection table in both agents to include model-selection criteria.

**Scope**:
- Extend dispatch heuristic table in specfarm.promptflow4speckit.agent.md
- Extend dispatch heuristic table in specfarm.promptflow-gemini.agent.md
- Add new column: "Recommended Model" (Haiku, Sonnet, Opus, Gemini)
- Add dispatch logic: "If caller is Haiku, prefer Haiku for dispatch"
- Document override syntax: `--model=sonnet` to force different model

**Acceptance Criteria**:
- ✅ Dispatch table includes 3+ rows (plan tasks, implement tasks, default)
- ✅ Each row includes "Recommended Model" based on task type
- ✅ Override syntax documented (example: `implement: --model=sonnet Update drift cache`)
- ✅ Phase 3 output example updated: `=== Task 1 done === Updated arch impl4speckit(haiku)`

**Test**:
```bash
grep -c "Recommended Model" .github/agents/specfarm.promptflow4speckit.agent.md  # Should be ≥2
grep "Haiku\|Sonnet\|Opus" .github/agents/specfarm.promptflow-gemini.agent.md | wc -l  # Should be ≥4
```

**Dependencies**: T102 (model detection in place)  
**Risk**: MEDIUM (dispatch logic must not break existing workflows)

---

### T104: Add override syntax to Quick Start sections

**Description**: Add clear examples of explicit model override to the Quick Start sections of both production agents.

**Scope**:
- Add 5+ examples to specfarm.promptflow4speckit.agent.md Quick Start
- Add 5+ examples to specfarm.promptflow-gemini.agent.md Quick Start
- Show: no flag (auto), `--model=haiku`, `--model=sonnet`, force override scenarios
- Include output showing detected vs overridden model

**Acceptance Criteria**:
- ✅ Quick Start has "Model Selection" subsection with 5+ examples
- ✅ Each example shows command and expected output
- ✅ Examples include: default (auto), explicit Haiku, explicit Sonnet, Gemini special case
- ✅ Error case documented: "If model unavailable, fallback to Haiku"

**Test**:
```bash
grep -c "example\|Example" .github/agents/specfarm.promptflow4speckit.agent.md  # Should be ≥10
```

**Dependencies**: T103 (dispatch heuristics finalized)  
**Risk**: LOW (documentation only)

---

### T105: Update Constitution sections (add NFR 4.2)

**Description**: Add new Constitution Compliance NFR (4.2) to both production agents documenting model-bias principle.

**Scope**:
- Add to specfarm.promptflow4speckit.agent.md Constitution Compliance section
- Add to specfarm.promptflow-gemini.agent.md Constitution Compliance section
- Document NFR 4.2: "Caller model preference: If agent invoked by Haiku, dispatch tasks to Haiku by default"
- Add rationale: "Minimizes context switching; caller model is likely best fit for user's workflow"

**Acceptance Criteria**:
- ✅ Both agents have NFR 4.2 documented in Constitution section
- ✅ Rationale explains why caller model is preferred
- ✅ Exception documented: "User can override with --model=X"
- ✅ Links to this proposal document

**Test**:
```bash
grep -c "NFR 4.2\|caller model" .github/agents/specfarm.promptflow4speckit.agent.md  # Should be ≥2
grep -c "NFR 4.2\|caller model" .github/agents/specfarm.promptflow-gemini.agent.md  # Should be ≥2
```

**Dependencies**: T104 (examples in place)  
**Risk**: LOW (documentation; no logic changes)

---

## Phase 2: Commit Policy Directives (Formalization)

### T106: Formalize implement-update.md as binding directive

**Description**: Convert implement-update.md from advisory guidance to formal binding directive with model-specific WIP commit intervals.

**Scope**:
- Add YAML metadata header (name, scope, applies-to, model-specific-intervals)
- Add model-specific WIP commit rules:
  - Haiku: 10 min (fast iteration)
  - Sonnet: 15 min (balanced)
  - Opus: 20 min (thorough analysis)
- Add auto-detection: "Detect caller model and apply corresponding interval"
- Add circuit-breaker rule: "On 3 consecutive commit failures, fallback to parent model"
- Link to .specfarm/directives/ folder

**Acceptance Criteria**:
- ✅ YAML metadata added (name: "commit-policy-implement4speckit", scope: "implementation")
- ✅ Model-specific intervals documented (Haiku 10, Sonnet 15, Opus 20 minutes)
- ✅ Auto-detection clause present ("Detect from agent context")
- ✅ Circuit-breaker clause documented
- ✅ File passes YAML validation

**Test**:
```bash
head -10 .github/agents/prototypes/implement-update.md | grep "^---"  # YAML header present
grep -E "10 min|15 min|20 min" .github/agents/prototypes/implement-update.md | wc -l  # Should be ≥3
```

**Dependencies**: None  
**Risk**: LOW (formalizes existing guidance)

---

### T107: Formalize plan4sk-update.md as binding directive

**Description**: Convert plan4sk-update.md from advisory guidance to formal binding directive with model-context-aware planning granularity.

**Scope**:
- Add YAML metadata header (name, scope, applies-to)
- Add planning-granularity levels by model:
  - Haiku: "task-by-task (simpler breakdown, ~3–5 per task)"
  - Sonnet: "cross-task dependencies (full coverage, ~5–8 per task)"
  - Opus: "strategic alternatives (premium analysis, ~8–12 per task)"
- Add model detection clause: "If called from Haiku, use Haiku granularity"
- Link to .specfarm/directives/ folder

**Acceptance Criteria**:
- ✅ YAML metadata added (name: "planning-policy-plan4speckit", scope: "planning")
- ✅ Granularity levels documented for all 3 models
- ✅ Model detection clause present
- ✅ File passes YAML validation

**Test**:
```bash
head -10 .github/agents/prototypes/plan4sk-update.md | grep "^---"  # YAML header present
grep -E "task-by-task|cross-task|strategic" .github/agents/prototypes/plan4sk-update.md | wc -l  # Should be ≥3
```

**Dependencies**: None  
**Risk**: LOW (formalizes existing guidance)

---

### T108: Add circuit-breaker logic (both directives)

**Description**: Document circuit-breaker failure recovery for both implement and plan directives.

**Scope**:
- Add to implement-update.md: "On 3 consecutive WIP commits fail, escalate to Sonnet model"
- Add to plan4sk-update.md: "On 3 consecutive task generation fails, escalate to Sonnet model"
- Document recovery procedure: "User must manually investigate before restart"
- Add example output: "🔴 CIRCUIT BREAKER: 3 consecutive failures. Escalating from Haiku to Sonnet."

**Acceptance Criteria**:
- ✅ Both directives have circuit-breaker section
- ✅ Failure count (3) documented
- ✅ Escalation target (Sonnet) specified
- ✅ Recovery procedure clear (manual investigation required)
- ✅ Example output provided

**Test**:
```bash
grep -c "CIRCUIT BREAKER\|3 consecutive" .github/agents/prototypes/implement-update.md  # Should be ≥2
grep -c "CIRCUIT BREAKER\|3 consecutive" .github/agents/prototypes/plan4sk-update.md  # Should be ≥2
```

**Dependencies**: T106, T107 (directives formalized)  
**Risk**: MEDIUM (failure escalation logic must be safe)

---

### T109: Create deployment checklist and copy to .specfarm/directives/

**Description**: Create formal checklist for deploying these directives to agents and place binding copies in .specfarm/directives/.

**Scope**:
- Create checklist: Pre-deployment validation steps (YAML parsing, model-detection tests, backward compat)
- Copy implement-update.md to .specfarm/directives/commit-policy-implement4speckit.md
- Copy plan4sk-update.md to .specfarm/directives/planning-policy-plan4speckit.md
- Create .specfarm/directives/README.md listing all active directives
- Add pre-commit hook check: Verify directive compliance before commits

**Acceptance Criteria**:
- ✅ Checklist document created (5–10 steps)
- ✅ Copies placed in .specfarm/directives/ folder
- ✅ .specfarm/directives/README.md lists both directives
- ✅ Pre-commit hook checks for directive files (if present, validate syntax)
- ✅ All YAML files pass validation

**Test**:
```bash
ls -la .specfarm/directives/  # Should include 2 directive files + README.md
grep -c "binding\|mandatory" .specfarm/directives/README.md  # Should be ≥2
```

**Dependencies**: T108 (circuit-breaker logic complete)  
**Risk**: LOW (deployment logistics only)

---

## Phase 3: Enhancement (Optional)

### T110: Add --preferred-model parameter to gatherrules agent

**Description**: Enhance specfarm.gatherrules-update.agent.md to accept `--preferred-model` parameter with fallback logic.

**Scope**:
- Add `--preferred-model` parameter (default: caller model)
- Add fallback chain: "Gemini → Haiku → Manual"
- Document: "If Gemini gatherer unavailable, fall back to Haiku parser"
- Add examples showing preferred model and fallback behavior

**Acceptance Criteria**:
- ✅ Parameter table includes `--preferred-model` (optional, default: "caller-model")
- ✅ Fallback chain documented (Gemini primary, Haiku secondary)
- ✅ Examples show both successful gather and fallback scenario
- ✅ Error handling clear: "If all models unavailable, skip rules gathering"

**Test**:
```bash
grep -c "\-\-preferred-model" .github/agents/prototypes/todo-specfarm.gatherrules-update.agent.md  # Should be ≥2
grep -c "fallback\|Fallback" .github/agents/prototypes/todo-specfarm.gatherrules-update.agent.md  # Should be ≥3
```

**Dependencies**: None (independent enhancement)  
**Risk**: LOW (optional feature)

---

### T111: Implement model-specific output formatting

**Description**: Update gatherrules agent to format output differently based on model (compact for Haiku, detailed for Sonnet).

**Scope**:
- Add output format specification: Haiku → "compact YAML (key rules only)", Sonnet → "detailed YAML (full descriptions)"
- Document schema differences (compact: name+type only, detailed: name+type+description+examples)
- Add examples showing both formats
- Validate output against format schema

**Acceptance Criteria**:
- ✅ Output formats documented (compact vs detailed)
- ✅ Schema examples provided (compact and detailed)
- ✅ Model-to-format mapping clear (Haiku → compact, Sonnet/Opus → detailed)
- ✅ Validation logic described (schema validation required before output)

**Test**:
```bash
grep -c "compact\|detailed\|YAML" .github/agents/prototypes/todo-specfarm.gatherrules-update.agent.md | wc -l  # Should be ≥5
```

**Dependencies**: T110 (preferred-model parameter in place)  
**Risk**: LOW (output formatting only)

---

### T112: Add graceful degradation (Gemini unavailable → Haiku parser)

**Description**: Implement graceful fallback for gatherrules agent when Gemini is unavailable.

**Scope**:
- Add fallback logic: "Detect Gemini availability; if unavailable, use Haiku parser"
- Document degraded-mode behavior: "Haiku parser produces compact output, no full descriptions"
- Add health check: "Verify at least one parser (Gemini or Haiku) available"
- Add example output showing degradation and retry strategy

**Acceptance Criteria**:
- ✅ Fallback condition documented (Gemini unavailable → use Haiku)
- ✅ Health check described (connectivity test or capability check)
- ✅ Degraded-mode output example provided
- ✅ Retry strategy documented (e.g., "retry up to 3x before giving up")
- ✅ User notification clear (log message: "Gemini unavailable, using Haiku parser")

**Test**:
```bash
grep -c "graceful\|degrade\|fallback" .github/agents/prototypes/todo-specfarm.gatherrules-update.agent.md  # Should be ≥4
```

**Dependencies**: T111 (output formatting finalized)  
**Risk**: MEDIUM (fallback logic must be robust)

---

## Implementation Checklist

### Pre-Implementation
- [ ] Proposal reviewed and approved
- [ ] This tasks.md generated and saved
- [ ] Verify agent files exist and are readable

### Phase 1 Execution
- [ ] T101: promptflow4speckit updated with --model parameter
- [ ] T102: Model detection logic added to Phase 1 (both agents)
- [ ] T103: Phase 3 dispatch heuristics updated (model-aware)
- [ ] T104: Override syntax examples added to Quick Start
- [ ] T105: NFR 4.2 documented in Constitution sections
- [ ] Phase 1 validation: All agents pass ShellCheck; YAML valid
- [ ] Phase 1 commit: `feat: Add LLM model-bias to promptflow agents (T101–T105)`

### Phase 2 Execution
- [ ] T106: implement-update.md formalized with model-specific intervals
- [ ] T107: plan4sk-update.md formalized with planning-granularity levels
- [ ] T108: Circuit-breaker logic added (both directives)
- [ ] T109: Deployment checklist created; copies placed in .specfarm/directives/
- [ ] Phase 2 validation: Directives pass YAML validation; pre-commit hook functional
- [ ] Phase 2 commit: `feat: Formalize commit & planning policies as binding directives (T106–T109)`

### Phase 3 Execution (Optional)
- [ ] T110: --preferred-model parameter added to gatherrules agent
- [ ] T111: Model-specific output formatting implemented
- [ ] T112: Graceful degradation (Gemini→Haiku fallback) added
- [ ] Phase 3 validation: gatherrules agent handles fallback scenarios
- [ ] Phase 3 commit: `feat: Add model-bias to gatherrules agent (T110–T112)` (if approved)

### Final Validation
- [ ] All agents pass ShellCheck
- [ ] All YAML files validated (schema compliance)
- [ ] Backward compatibility verified (existing tasks unaffected)
- [ ] Documentation links updated (.github/agents/README.md, if exists)
- [ ] Tests pass (unit + integration)
- [ ] Final commit: `docs: Update agent metadata and references for model-bias feature`

---

## Execution Command (Haiku Dispatch)

```bash
# Phase 1 (Recommended immediate execution)
specfarm.promptflow4speckit --model=haiku --line-factor=1.5 -- \
  "T101 [FEAT] Add model-bias parameter to specfarm.promptflow4speckit.agent.md" \
  "T102 [FEAT] Implement caller-model detection in Phase 1 (both agents)" \
  "T103 [FEAT] Update Phase 3 dispatch heuristics (model-aware selection)" \
  "T104 [FEAT] Add override syntax to Quick Start sections" \
  "T105 [FEAT] Update Constitution sections (add NFR 4.2)"

# Phase 2 (After Phase 1 validation)
specfarm.promptflow4speckit --model=haiku --line-factor=1.5 -- \
  "T106 [FEAT] Formalize implement-update.md as binding directive" \
  "T107 [FEAT] Formalize plan4sk-update.md as binding directive" \
  "T108 [FEAT] Add circuit-breaker logic (both directives)" \
  "T109 [FEAT] Create deployment checklist and copy to .specfarm/directives/"

# Phase 3 (If approved separately)
specfarm.promptflow4speckit --model=haiku --line-factor=1.0 -- \
  "T110 [FEAT] Add --preferred-model parameter to gatherrules agent" \
  "T111 [FEAT] Implement model-specific output formatting" \
  "T112 [FEAT] Add graceful degradation (Gemini→Haiku fallback)"
```

---

**Generated**: 2026-04-06T05:47:19Z  
**Model Bias**: Claude Haiku 4.5  
**Status**: Ready for Approval & Execution  
**Total Estimated Time**: 75–110 minutes (Phase 1: 30–45 min, Phase 2: 25–35 min, Phase 3: 20–30 min)
