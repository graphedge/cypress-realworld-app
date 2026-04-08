# SpecFarm Binding Directives

**Status**: Mandatory policies for agent execution  
**Scope**: All `speckit.plan`, `plan4speckit`, `speckit.implement`, `implement4speckit` agent invocations  
**Applies to**: Both GitHub Actions and local CLI execution  

---

## Active Directives

### 1. Commit Policy: implement4speckit
**File**: `commit-policy-implement4speckit.md`  
**Applies to**: `speckit.implement`, `implement4speckit` agents  
**Binding**: YES (mandatory, overrides previous guidance)  

**Key Rules**:
- ✅ Model-specific WIP commit intervals:
  - Haiku: 10 min
  - Sonnet: 15 min
  - Opus: 20 min
- ✅ Max 5 WIP commits per task
- ✅ Circuit breaker: On 3 consecutive failures, escalate from Haiku to Sonnet
- ✅ Syntax check before every WIP (`bash -n` required)
- ✅ Mandatory Co-authored-by trailer

**Enforcement**: Pre-commit hook validates WIP message format and syntax checks have passed.

---

### 2. Planning Policy: plan4speckit
**File**: `planning-policy-plan4speckit.md`  
**Applies to**: `speckit.plan`, `plan4speckit` agents  
**Binding**: YES (mandatory, overrides previous guidance)  

**Key Rules**:
- ✅ Model-specific planning granularity:
  - Haiku: Task-by-task (3–5 tasks per run)
  - Sonnet: Cross-task dependencies (5–8 tasks per run)
  - Opus: Strategic alternatives (8–12 tasks per run)
- ✅ Max 3 WIP commits per planning run
- ✅ Circuit breaker: On 3 consecutive failures, escalate from Haiku to Sonnet
- ✅ YAML validation before every WIP commit
- ✅ Mandatory Co-authored-by trailer

**Enforcement**: Pre-commit hook validates YAML syntax for plan.md and tasks.md.

---

## Directive Lifecycle

### Creation
1. Directive written as prototype in `.github/agents/prototypes/`
2. Formatted with YAML metadata header (name, scope, applies-to, binding)
3. Documented with concrete examples and use cases

### Formalization
1. Binding status set to `true`
2. Copied to `.specfarm/directives/` (source of truth)
3. Pre-commit hook updated to enforce directive compliance
4. Agents updated with links to directive file

### Enforcement
1. **Pre-commit hook**: Validates syntax and WIP message format
2. **Agent startup**: Agents log loaded directives to stderr
3. **Audit trail**: All WIP/final commits recorded with directive compliance status
4. **Escalation**: Circuit breaker triggers when directive violations exceed threshold

---

## Pre-Commit Hook Validation

The following checks run before every commit to enforce directive compliance:

### For implement-update commits (WIP or final)
```bash
# Check 1: WIP message format
if git show --name-only | grep -E "WIP:|DRAFT:"; then
  # Must include task ID
  if ! git log -1 --format=%s | grep -E "task-[0-9]+"; then
    exit 1 "ERROR: WIP commit missing task-XXX ID"
  fi
fi

# Check 2: Syntax check passed
# (Agent must have already run bash -n before staging)

# Check 3: Co-authored-by trailer present
if ! git log -1 --format=%b | grep "Co-authored-by:"; then
  exit 1 "ERROR: Missing Co-authored-by trailer"
fi
```

### For plan4speckit commits (WIP or final)
```bash
# Check 1: YAML validation
if git show --name-only | grep -E "plan\.md|tasks\.md"; then
  yamllint $file || exit 1
fi

# Check 2: Max WIP limit check
if git log --oneline --grep="WIP: plan4speckit" | wc -l | grep -E "[4-9]|[0-9]{2,}"; then
  exit 1 "ERROR: Exceeded max 3 WIP commits for planning run"
fi

# Check 3: Co-authored-by trailer present
if ! git log -1 --format=%b | grep "Co-authored-by:"; then
  exit 1 "ERROR: Missing Co-authored-by trailer"
fi
```

---

## Circuit Breaker: Failure Escalation

**Trigger**: 3 consecutive commit failures (for either directive)

**Current Model**: Haiku  
**Escalation Target**: Sonnet  
**Action Taken**:
```
🔴 CIRCUIT BREAKER TRIGGERED: 3 consecutive commit failures
Rule: Commit policy (implement-update or planning-policy)
Reason: [error message from failed commit]
Escalating model: Haiku → Sonnet
Recovery: User must investigate and manually retry or continue
```

**Recovery Procedure**:
1. Review `.specfarm/error-memory.md` for last 3 commit failures
2. Determine root cause (syntax error, permission issue, network fault, etc.)
3. Fix the issue or adjust task scope
4. Manually retry the failed task or ask user for guidance

---

## Directive Compliance Checklist (Pre-Deployment)

Before deploying these directives to production agents, verify:

### Syntax & Format
- [ ] `commit-policy-implement4speckit.md` has valid YAML header
- [ ] `planning-policy-plan4speckit.md` has valid YAML header
- [ ] Both files have complete sections (Principles, Workflow, Examples, Constitution)
- [ ] All markdown formatting is valid (no broken links, syntax errors)

### Model-Specific Logic
- [ ] Haiku intervals correctly specified: implement=10 min, planning=task-by-task
- [ ] Sonnet intervals correctly specified: implement=15 min, planning=cross-task
- [ ] Opus intervals correctly specified: implement=20 min, planning=strategic
- [ ] Fallback model logic works (circuit breaker to Sonnet on 3 failures)

### Enforcement
- [ ] Pre-commit hook template includes all validation rules
- [ ] WIP message format validation works (must include task-XXX or agent name)
- [ ] Syntax check validation works (bash -n for shell, yamllint for YAML)
- [ ] Co-authored-by trailer validation works

### Backward Compatibility
- [ ] Agents still accept tasks without `--model` flag (auto-detect fallback)
- [ ] Existing WIP/final commits not broken by new policy
- [ ] Previous task histories remain valid (no retroactive enforcement)

### Documentation
- [ ] Both directives referenced in `.github/agents/README.md`
- [ ] Both directives linked from agent metadata
- [ ] Constitution updated to reference NFR 4.2 (Model Bias)
- [ ] Error memory includes directive compliance logs

---

## Related Documentation

- **Agent Registry**: `.github/agents/README.md`
- **Promptflow Agents**: `.github/agents/specfarm.promptflow4speckit.agent.md`, `.github/agents/specfarm.promptflow-gemini.agent.md`
- **Constitution**: `.specify/memory/constitution.md`
- **Error Memory**: `.specfarm/error-memory.md` (for directive compliance audit trail)
- **Pre-Commit Hooks**: `.git/hooks/pre-commit` (deployment target for hook validation)

---

## Versioning & Updates

- **Created**: 2026-04-06
- **Last Updated**: 2026-04-06
- **Next Review**: 2026-05-06 (assess circuit breaker triggers, WIP patterns)
- **Breaking Changes**: None planned (additive rules only)

All directive updates require:
1. Updated here (`.specfarm/directives/`)
2. Updated in prototype (`.github/agents/prototypes/`)
3. Documented in Constitution if principle-affecting
4. Pre-commit hook updated if enforcement rules change
5. Git commit with message: `chore: Update directive - [name] (reason for change)`
