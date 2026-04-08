---
name: "SpecFarm Promptflow (Gemini 2.5 Flash Lite)"
description: "Task orchestration workflow for Gemini CLI - processes unchecked specs with line-count budgets"
model: gemini-2.5-flash
llm_bias: "caller-model-with-gemini-preference"
commands: 
  - run: "specfarm-promptflow"
  - apply: "spec-kit updates"
---

# SpecFarm Promptflow Orchestrator for Gemini CLI 2.5 Flash Lite

**Model**: Gemini 2.5 Flash Lite  
**Mode**: Orchestrate task-by-task processing with graceful context gathering  
**Constraints**: Zero external dependencies, plain bash testing only

---

## Quick Start

### Invoke with Task List

```bash
# From command line
gemini run specfarm-promptflow -- \
  "T005 [P] Create .specfarm/src/crossplatform/platform-check.sh utility" \
  "T006 [P] Implement .specfarm/src/crossplatform/path-normalize.sh"

# Or pipe from specs/next.md
cat specs/next.md | grep "^\s*- \[ \]" | gemini run specfarm-promptflow

# With line-count budget
gemini run specfarm-promptflow --line-factor=2.5 -- < tasks-to-process.txt
```

### Workflow Steps

This agent implements the 5-step promptflow process:

1. **Gather unchecked tasks** from `specs/next.md` and `specs/*/tasks.md` files
2. **Downselect tasks** based on `--line-factor` (token budget for feasibility)
3. **Orchestrate dispatch** to sub-agents (plan4speckit, implement4speckit)
4. **Track progress** in specs/next.md and respective spec folders
5. **Update task.md files** with completions ([x] marking)

---

## Input Format

**Single task**:
```
T005: Create platform-check.sh utility for OS detection
```

**Multiple tasks** (one per line):
```
T005 [P] Create .specfarm/src/crossplatform/platform-check.sh
T006 [P] Implement .specfarm/src/crossplatform/path-normalize.sh
T007 [P] Implement .specfarm/src/crossplatform/line-endings.sh
T008 Refactor .specfarm/bin/drift-engine to source platform-check
```

**From file or pipe**:
```bash
cat specs/next.md | grep "^\s*- \[ \]" | gemini run specfarm-promptflow
```

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--line-factor` | 1.5 | Multiplier for max tasks: `max_tasks = line_factor * 5` |
| `--model` | "caller-model" | LLM model for sub-agent dispatch: "haiku", "sonnet", "opus", "gemini", or "caller-model" (detect from Gemini context). |
| `--dry-run` | false | Validate without commits or agent dispatch |
| `--quiet` | false | Suppress verbose output |
| `--context-depth` | 5 | Max grep results per task (for context gathering) |

**Model Bias**: When `--model=caller-model`, dispatches to detected caller's model (Haiku if called from Haiku, etc.). When `--model=gemini` or unspecified, Gemini handles task dispatch internally.

---

## Processing Workflow

### Phase 1: Parse & Validate

✅ **Input parsing**:
- Normalize line endings (CRLF → LF)
- Split into individual tasks
- Trim whitespace
- Skip empty lines
- Track task count
- **NEW**: Detect caller model from Gemini invocation context
  - If `--model=caller-model`: detect source LLM (Haiku, Sonnet, Opus)
  - If `--model=gemini` or unspecified: use Gemini for dispatch (default)
  - Fallback: If detection fails, default to Haiku

```
✓ Parsed 4 tasks with line_factor=1.5
✓ Detected caller model: haiku (if --model=caller-model specified)
✓ Dispatching via: haiku sub-agents (plan4speckit, implement4speckit)
```

### Phase 2: Gather Context (Graceful Degradation)

🔍 **Context gathering** from repository:
- Search `specs/`, `src/`, `tests/` directories for task references
- Extract relevant grep results (max `--context-depth` lines)
- **If context unavailable**: Log warning and continue
- **No halting on context failures** (graceful degradation per NFR 4.1)

```
Task 1: Create platform-check.sh
  ✓ Context gathered from specs/003b-specfarm-phase-3b/tasks.md (3 matches)
Task 2: Implement path-normalize.sh
  ⚠️  No context found (continuing without granular context)
```

### Phase 3: Agent Selection & Dispatch

🤖 **Heuristic-based agent selection** (with model awareness):

| Keyword | Agent | Recommended Model |
|---------|-------|-------------------|
| plan, design, architecture, spec, research | **plan4speckit** | Detect from --model parameter or default to Haiku |
| implement, fix, add, create, update, modify | **implement4speckit** | Detect from --model parameter or default to Haiku |
| (default) | **implement4speckit** | Detect from --model parameter or default to Haiku |

**Model Dispatch Logic**:
- If `--model=caller-model`: Use detected caller model (Haiku, Sonnet, Opus)
  - Log: `Dispatching to implement4speckit with Haiku bias (caller model)`
- If `--model=gemini`: Use Gemini for dispatch (default Gemini behavior)
  - Log: `Dispatching to implement4speckit with Gemini`
- If model unavailable: Fallback to Haiku gracefully
  - Log: `⚠️ Model unavailable, falling back to Haiku`

**Override syntax** (force agent or model):
```
plan: Design cache invalidation strategy
implement: Add Redis cache layer
```

**Dispatch to coding agent**:
- Construct detailed prompt with task, context, and constraints
- Wait for completion (no parallelization)
- Track circuit breaker: halt on 3 consecutive failures
- Report strict status: `=== Task N done === [status] [agent]`

```
=== Task 1 done === Created platform-check.sh utility implement4speckit
=== Task 2 done === Designed path-normalize strategy plan4speckit
```

### Phase 4: Progress Tracking

📝 **Update tracking files**:
- `specs/next.md`: Log workflow execution and task counts
- Respective spec folder (`specs/003b-specfarm-phase-3b/tasks.md`): Mark completed tasks [x]
- Workflow artifact: Store results for audit trail

### Phase 5: Validation & Summary

✅ **Output validation**:
- Verify all dispatches completed or failed cleanly
- Compute success rate and failure breakdown
- Generate job summary

```
📊 Orchestration Complete
- Tasks Processed: 4/4
- Success Rate: 100%
- Failed Tasks: 0
```

---

## Error Handling

### Circuit Breaker (Coding Agent Failures)

**Trigger**: 3 consecutive dispatch failures  
**Action**: Halt orchestration and report

```
🔴 CIRCUIT BREAKER TRIGGERED: 3 consecutive dispatch failures
Last failed task: T008 [Refactor .specfarm/bin/drift-engine]
Reason: Agent timeout after 300 seconds
```

**Recovery**: User must manually investigate and restart with fewer tasks.

### Graceful Degradation (Context Gathering Failures)

**Scenario**: `grep` fails, context unavailable, gatherer agent timeout  
**Action**: Log warning and continue processing with empty context

```
Task 5: Add integration test script
  ⚠️  Context gathering failed, continuing without granular context
```

**Rationale**: Context is optional; core orchestration should not fail (NFR 4.1).

### Empty Task List

**Action**: Report and exit gracefully

```
ℹ️  No tasks to process (empty input)
```

---

## Constitution Compliance

✅ **Principle I (CLI-Centric)**  
Invoked via Gemini CLI tool; orchestrates other CLI-based coding agents

✅ **Principle II.A (Zero-Dependency Testing)**  
All tests remain plain bash; this agent only invokes sub-agents

✅ **Principle III (Spec-Driven)**  
Draws task input from `specs/` directory; updates `specs/next.md` tracking

✅ **Principle IV (Quality Gates)**  
Respects pre-commit gating; does not bypass drift checks

✅ **Principle V (Security)**  
No outbound network calls; operates on local repository context only

✅ **NFR 4.1 (Robustness)**  
Graceful degradation when context gathering fails

✅ **NFR 4.2 (Conciseness)**  
Strict output format: `=== Task N done === [status] [agent]`

---

## Examples

### Example 1: Basic Usage (Phase 3b Foundational Tasks)

```bash
gemini run specfarm-promptflow -- \
  "T005 [P] Create .specfarm/src/crossplatform/platform-check.sh" \
  "T006 [P] Implement .specfarm/src/crossplatform/path-normalize.sh" \
  "T007 [P] Implement .specfarm/src/crossplatform/line-endings.sh"
```

**Output**:
```
=== Task 1 done === Created platform-check.sh implement4speckit
=== Task 2 done === Implemented path-normalize.sh implement4speckit
=== Task 3 done === Implemented line-endings.sh implement4speckit

📊 Orchestration Complete
- Tasks Processed: 3/3
- Success Rate: 100%
```

### Example 2: Mixed Plan & Implement

```bash
gemini run specfarm-promptflow --dry-run -- << 'EOF'
plan: Design Windows CI/CD strategy for Phase 3b
implement: Create .github/workflows/windows-ci.yml
implement: Add Windows test matrix to GitHub Actions
EOF
```

**Output** (dry-run):
```
=== Task 1 done === DRY-RUN plan4speckit
=== Task 2 done === DRY-RUN implement4speckit
=== Task 3 done === DRY-RUN implement4speckit

✓ Dry-run validation passed (no commits)
```

### Example 3: Pipe from specs/next.md

```bash
# Downselect next 7-8 tasks (line_factor=1.5 → max 7 tasks)
cat specs/next.md | grep "^\s*3\." | head -7 | gemini run specfarm-promptflow --line-factor=1.5
```

---

## Integration with GitHub Actions

This agent is also available as a GitHub Actions workflow:

```yaml
# .github/workflows/specfarm-promptflow-gemini.yml
on:
  workflow_dispatch:
    inputs:
      task_list:
        description: 'Tasks to process (one per line)'
        required: true
      line_factor:
        description: 'Line count factor (default: 1.5)'
        default: '1.5'
      dry_run:
        description: 'Dry-run mode'
        type: boolean
```

**Invoke**:
```bash
gh workflow run specfarm-promptflow-gemini.yml \
  -f task_list='T005: Create platform-check.sh' \
  -f line_factor='1.5' \
  -f dry_run='false'
```

## Constitution Compliance

✅ **Principle I (CLI-Centric)**: Agent invoked via Gemini CLI; orchestrates both Gemini and other CLI-based coding agents  
✅ **Principle II.A (Zero-Dependency Testing)**: No direct testing responsibility; coding agents handle test creation  
✅ **Principle V (Security)**: No external network calls; operates on local repository context only  
✅ **NFR 4.1 (Robustness)**: Graceful degradation when context gathering or sub-agents unavailable  
✅ **NFR 4.2 (Model Bias)**: Caller model preference supported via `--model=caller-model` flag  
✅ **NFR 4.3 (Conciseness)**: Strict output format, no conversational filler

- **Orchestration overhead**: < 5 seconds per task (parse → context → dispatch)
- **Success rate**: 100% when context gathering fails (graceful degradation)
- **Max tasks per run**: `line_factor * 5` (default: 7-8 tasks)
- **Output format**: Strict adherence to `=== Task N done === [status] [agent]`

---

## Troubleshooting

### Tasks not dispatching to agents

**Check**: Are `plan4speckit` and `implement4speckit` agents available?

```bash
gemini list-agents | grep speckit
```

**Fix**: Ensure agents are installed and accessible in `.github/agents/` or Gemini CLI agent registry.

### Context gathering too slow

**Fix**: Reduce `--context-depth` or disable with `--context-depth=0`

```bash
gemini run specfarm-promptflow --context-depth=2 -- < tasks.txt
```

### Circuit breaker triggered

**Fix**: Reduce `--line-factor` (fewer tasks per run) or debug failing task

```bash
# Retry with 1 task only
echo "T005: Create platform-check.sh" | gemini run specfarm-promptflow --line-factor=0.2
```

---

## Related Documentation

- **Promptflow Agent**: `.github/agents/specfarm.promptflow4speckit.agent.md`
- **Coding Agents**: `.github/agents/speckit.plan.agent.md`, `.github/agents/speckit.implement.agent.md`
- **Task Index**: `specs/next.md`, `specs/*/tasks.md`
- **Constitution**: `.specify/memory/constitution.md`
- **GitHub Actions Workflow**: `.github/workflows/specfarm-promptflow-gemini.yml`
