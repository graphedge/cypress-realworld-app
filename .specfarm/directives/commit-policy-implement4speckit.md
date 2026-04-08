---
name: "commit-policy-implement4speckit"
scope: "implementation"
applies-to: ["speckit.implement", "implement4speckit"]
binding: true
model-specific-intervals:
  haiku: "10 minutes"
  sonnet: "15 minutes"
  opus: "20 minutes"
fallback-model: "sonnet"
circuit-breaker-threshold: 3
---

# Binding Commit Policy: implement4speckit

**Status**: Mandatory directive (overrides previous guidance)  
**Applies to**: All `speckit.implement` and `implement4speckit` invocations  
**Scope**: Implementation task execution in unstable environments  

---

## Core Principles

1. **Frequent saves** — Prioritize saving progress frequently to avoid losing work in unstable environments.

2. **Model-Specific WIP Intervals** (MANDATORY):
   - **Haiku**: Commit every **10 minutes** (fast iteration, more frequent saves)
   - **Sonnet**: Commit every **15 minutes** (balanced approach)
   - **Opus**: Commit every **20 minutes** (thorough analysis, less frequent saves)
   - **Auto-detect**: Detect caller model from agent context and apply corresponding interval

3. **WIP Commit Requirements**:
   - Format: `WIP: task-XXX - short description` or `DRAFT: filename - partial work`
   - Allowed state: Tests incomplete, constitution checks partial, validation not passed
   - Syntax check: Always run at least `bash -n` or `pwsh -NoProfile` before committing WIP
   - Task ID: Always include task identifier in commit message

---

## Workflow

### Before Starting Task
- Optional: `git commit --allow-empty -m "START: task-XXX"`

### During Implementation (Every ~10–20 min, model-dependent)
- Track elapsed time since last commit
- When interval reached (or meaningful progress made):
  1. Run quick syntax check (`bash -n` for shell, etc.)
  2. Commit immediately with WIP message
  3. Log summary to `.specfarm/error-memory.md` or task log
  4. **DO NOT WAIT** for tests to pass or constitution to fully validate

### After Task Complete (All Gates Pass)
- Tests passing (exit code 0)
- Constitution compliance verified
- ShellCheck clean
- Scope ±15%
- **Then**: Amend most recent WIP with final message: `feat: task-XXX - complete implementation + full validation`
- Or create clean final commit if preferred

---

## WIP Limits & Escalation

- **Max WIP commits per task**: 5
- **If 6th WIP needed**: Stop, commit 5th as final (even if imperfect), ask user for guidance
- **Circuit breaker**: On 3 consecutive commit failures, escalate from Haiku to Sonnet model

---

## Example Workflow

```
T042: Implement platform-check.sh (detected caller: Haiku)
├─ 00:00 START: task-042
├─ 08:00 WIP: task-042 - bash skeleton + main logic (syntax OK)
├─ 10:00 WIP: task-042 - add OS detection cases (syntax OK)
├─ 18:00 WIP: task-042 - add unit test helper (syntax OK)
├─ 10:00 WIP: task-042 - fix case statement guard
├─ 08:00 WIP: task-042 - add ShellCheck directives
├─ 20:00 ✅ AMEND: feat: task-042 - complete implementation + tests 8/8 passing
```

**Total elapsed**: ~74 minutes (7 commits, last one as final)

---

## Circuit Breaker: Failure Escalation

**Trigger**: 3 consecutive WIP commit failures (git push failure, permission error, etc.)

**Action**:
```
🔴 CIRCUIT BREAKER TRIGGERED: 3 consecutive commit failures
Reason: [error message from git]
Escalating: Haiku → Sonnet model
```

**Recovery**: User must investigate and decide whether to retry or halt.

---

## All WIP Commits Must Include

- [ ] Task ID in message (e.g., "task-042")
- [ ] Brief description of what was done
- [ ] Syntax check passed (bash -n or equivalent)
- [ ] Log entry in `.specfarm/error-memory.md`
- [ ] Co-authored-by trailer: `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`

---

## Constitution Alignment

✅ **Principle IV (Quality Gates)**: Pre-commit syntax checks required (bash -n, ShellCheck)  
✅ **Principle V (Stability)**: Frequent saves prevent data loss in unstable environments  
✅ **Model Bias (NFR 4.2)**: Model-specific intervals support caller-model-preference principle