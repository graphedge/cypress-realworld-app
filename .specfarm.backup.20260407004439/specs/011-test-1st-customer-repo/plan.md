# Implementation Plan: Spec-011 Real Customer Repo Testing

**Feature**: Testing SpecFarm gather-rules agent on real mid-dev repository  
**Status**: Planning Phase  
**Owner**: SpecFarm CI/Testing  
**Last Updated**: 2025 Q1  

---

## 1. Technical Context & Architecture

### 1.1 Feature Overview
This implementation validates the gather-rules agent (US1 / T005–T012) by running it against a real mid-development repository. The goal is to prove the agent can:
- Extract rules from real git history with confidence scoring
- Generate markdown output with evidence linkage
- Support task-context mode for bootstrapping SDD into existing codebases
- Work reliably on non-specfarm repositories

### 1.2 Tech Stack & Dependencies

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Core Agent** | Pure Bash + xmllint + git | Zero external dependencies; compliant with Constitution II.A |
| **Rules Storage** | XML (rules.xml) | Schema-based validation; easy curateability |
| **Output Format** | Markdown + confidence scores | Human-readable; easy to review and import |
| **Git Integration** | Native git CLI | Already available; no external tools needed |
| **Test Harness** | Bash TAP (tap.sh) | Self-contained; no pytest dependency |
| **Code Analysis** | Keyword extraction + XPath scoring | Custom confidence scorer; extensible keyword lists |

### 1.3 Key Dependencies & Prerequisites

1. **Gather-rules agent** (Status: ✅ Complete, 310/310 tests passing)
   - Location: `.specfarm-agents/gather-rules-agent.sh`
   - Must be copied to target repo root
   - Already on master branch
   
2. **Starter rules.xml** (Status: ✅ Available)
   - Can be copied or generated from skeleton
   - Used as baseline for comparison
   
3. **Test harness** (Status: ✅ Complete)
   - `tests/run_all_tests.sh` available for validation in target repo
   - Bash TAP-based; no external dependencies
   
4. **Target repository** (Status: 🔴 Not yet selected)
   - Must meet mid-dev criteria (20–100+ commits, 2+ authors, 10–80 source files)
   - Should have signal: tests, commit messages, patterns
   - Ideal: Python/bash-heavy for keyword confidence

5. **Documentation templates** (Status: ✅ Available)
   - Constitution governance guidelines
   - SDD bootstrap workflow
   - Rule confidence scoring methodology

### 1.4 Architecture Overview

```
Target Mid-Dev Repo (External)
├── .specfarm-agents/
│   └── gather-rules-agent.sh          [COPY FROM specfarm2]
├── rules.xml                           [COPY/BOOTSTRAP FROM specfarm2]
├── tests/
│   └── run_all_tests.sh               [OPTIONAL: COPY FOR VALIDATION]
├── .git/                               [EXISTING: Git history to analyze]
└── [Source code files]
     ├── Test files (*_test.py, test*.sh)  [SIGNAL FOR CONFIDENCE SCORER]
     └── Feature files                    [TO BE SCORED FOR PATTERNS]

specfarm2 Repository (Source)
├── .specfarm-agents/
│   └── gather-rules-agent.sh          [SOURCE TO COPY]
├── rules/ → rules.xml                 [SOURCE TO BOOTSTRAP FROM]
└── tests/ → run_all_tests.sh         [OPTIONAL TEST SOURCE]
```

### 1.5 Data Model & Contracts

#### Input: Git History
- **Source**: Target repo's `.git` directory
- **Format**: Git log entries (commit SHA, author, date, message, diff)
- **Range**: Last ~10 commits (configurable via `--depth` parameter)
- **Extraction**: `git log --oneline --all --format=...`

#### Output: Discovered Rules (Markdown)
```markdown
## Discovered Rules (Confidence Rank)

### 1. Rule Name (Confidence: 85%)
- **Pattern**: Brief description of what the rule enforces
- **Evidence**: 
  - Commit abc123d: "Fix: enforce ...", test file updated
  - Commit def456g: "Test: added validation for ..."
- **Type**: Code pattern | Workflow | Governance | Testing
- **Related Keywords**: [keyword1, keyword2, ...]

### 2. Rule Name (Confidence: 72%)
...
```

#### Output: Task-Context Rules (JSON/Markdown)
```markdown
## Task: "Implement user authentication flow"
### Applicable Rules (ranked by relevance):
1. "Use bcrypt for password hashing" (Confidence: 90%)
2. "Write unit tests for auth endpoints" (Confidence: 82%)
3. "Follow OAuth2 grant flow structure" (Confidence: 71%)
```

#### Schema: rules.xml (Bootstrap Template)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rules>
  <rule id="rule-001">
    <name>Use bcrypt for password hashing</name>
    <type>code-pattern</type>
    <applies_to>security,authentication</applies_to>
    <confidence>high</confidence>
    <evidence>
      <commit sha="abc123d">Fix: enforce bcrypt for PWD hashing</commit>
    </evidence>
  </rule>
</rules>
```

---

## 2. Implementation Phases

### Phase 0: Setup & Target Repo Selection (T001–T003)

**Deliverables**:
- [ ] Target repo identified and criteria met
- [ ] Initial bootstrap script written
- [ ] Repository access verified
- [ ] Constitution compliance checklist created

**Tasks**:

| Task ID | Title | Description | Effort |
|---------|-------|-------------|--------|
| T001 | Select target mid-dev repo | Choose a real repo meeting criteria (20–100+ commits, 10–80 files, has tests). Examples: personal CLI tool, data pipeline, small internal service. | 2h |
| T002 | Clone & analyze target repo | Run `git log --all --format=...` to extract commit history. Ensure >20 commits, multiple authors, and test files exist. | 1h |
| T003 | Set up bootstrap script | Create `/path/to/target-repo/bootstrap.sh` that copies agent + rules.xml and validates pre-reqs. | 1h |

**Gate Criteria**:
- ✅ Target repo meets all mid-dev criteria
- ✅ Git history is accessible and has sufficient signal
- ✅ Bootstrap script runs without errors

---

### Phase 1: First Agent Run & Validation (T004–T008)

**Deliverables**:
- [ ] Agent runs successfully on target repo
- [ ] Markdown output generated with 5–10+ rules (confidence >70)
- [ ] Evidence correctly links to real commits
- [ ] No crashes on real git history
- [ ] Test harness validates agent in new environment

**Tasks**:

| Task ID | Title | Description | Effort |
|---------|-------|-------------|--------|
| T004 | Copy agent to target repo | Execute bootstrap: `cp gather-rules-agent.sh .specfarm-agents/` + validate permissions. | 0.5h |
| T005 | Copy starter rules.xml | Bootstrap rules with confirmed patterns from specfarm2. If repo is Python, add Python-specific keywords; if bash, add bash keywords. | 1h |
| T006 | Run agent in discovery mode | From target repo root: `./.specfarm-agents/gather-rules-agent.sh > discovered-rules.md`. Capture stdout/stderr. | 1h |
| T007 | Review discovered rules output | Check that top 10 rules (confidence >70) match real repo patterns. Validate evidence links to actual commits. | 2h |
| T008 | Run test harness in target repo | Execute `tests/run_all_tests.sh` (if copied). Confirm no environment-specific failures. | 1.5h |

**Gate Criteria**:
- ✅ Agent runs without crashes
- ✅ Output contains 5–10+ rules with confidence ≥70%
- ✅ Evidence is traceable to real commits/tests
- ✅ Test harness passes (or documents environment skips)

**Test Cases**:
```bash
# TC001: Agent runs without errors
./.specfarm-agents/gather-rules-agent.sh
echo "Exit code: $?"  # Expected: 0

# TC002: Output is valid markdown
[[ -f discovered-rules.md ]] && grep -q "^##" discovered-rules.md
echo "Markdown valid: $?"  # Expected: 0

# TC003: Confidence scores are in range
grep "Confidence:" discovered-rules.md | grep -oP '\d+(?=%)'
# Expected: All values between 30–100

# TC004: Evidence references real commits
grep "Commit [a-f0-9]" discovered-rules.md | head -1
# Expected: Valid commit SHA from `git log --format=%h`
```

---

### Phase 2: Task-Context Mode Validation (T009–T012)

**Deliverables**:
- [ ] Task-context mode runs successfully with sample tasks
- [ ] Agent returns relevant rules ranked by task relevance
- [ ] Confidence scores adjust based on task keywords
- [ ] Output format is consistent with discovery mode
- [ ] Evidence filtering works correctly

**Tasks**:

| Task ID | Title | Description | Effort |
|---------|-------|-------------|--------|
| T009 | Prepare task-context test cases | Create 3–5 realistic tasks: "Implement API auth", "Add logging", "Fix SQL injection", "Optimize DB queries", "Write integration tests". | 1h |
| T010 | Run agent in task-context mode | For each task: `./.specfarm-agents/gather-rules-agent.sh --task-context "Task description"`. Collect outputs. | 1h |
| T011 | Validate task-context filtering | Confirm that returned rules are relevant to each task. Check that confidence adjusts (e.g., auth task boosts "bcrypt" rule). | 2h |
| T012 | Document task→rule mappings | Curate top 3 rules per task into a simple JSON mapping. Validate with code review. | 1.5h |

**Gate Criteria**:
- ✅ Task-context mode returns rules, not errors
- ✅ Returned rules are topically relevant (manual validation)
- ✅ Confidence scores reflect task alignment
- ✅ No duplicate or contradictory rules in output

**Test Cases**:
```bash
# TC005: Task-context returns rules
./.specfarm-agents/gather-rules-agent.sh --task-context "Add logging to codebase"
echo "Exit code: $?"  # Expected: 0

# TC006: Output contains task-relevant rules
OUTPUT=$(./.specfarm-agents/gather-rules-agent.sh --task-context "Implement auth")
[[ $OUTPUT == *"password"* ]] || [[ $OUTPUT == *"auth"* ]] || [[ $OUTPUT == *"bcrypt"* ]]
echo "Topically relevant: $?"  # Expected: 0 (true)

# TC007: Confidence scores are confidence scores are adjusted
OUTPUT=$(./.specfarm-agents/gather-rules-agent.sh --task-context "Implement logging")
# Manually verify that "Add logging" rules rank higher than unrelated rules
```

---

### Phase 3: Curation & Real-World Feedback (T013–T016)

**Deliverables**:
- [ ] Final rules.xml curated from top 6–8 discovered rules
- [ ] Validation report generated (discovery accuracy, false positives)
- [ ] Recommendations for keyword extensions documented
- [ ] Feedback loop captured (what changed in target repo, what didn't)

**Tasks**:

| Task ID | Title | Description | Effort |
|---------|-------|-------------|--------|
| T013 | Manually curate top rules | Select 6–8 highest-confidence rules from discovery output. Filter for actionable, repo-specific patterns. Update rules.xml accordingly. | 2h |
| T014 | Generate validation report | Document: rules discovered, confidence accuracy (manual spot-check), false positives, keyword suggestions. | 1.5h |
| T015 | Identify keyword gaps | Analyze false negatives: real patterns not discovered. Suggest new keywords or XPath tweaks for the agent. | 1.5h |
| T016 | Document lessons learned | Summarize: repo-specific insights, toolkit tweaks needed, recommendations for other repos. | 1h |

**Gate Criteria**:
- ✅ 6–8 rules curated and validated as accurate
- ✅ Validation report identifies ≥3 keyword suggestions
- ✅ False positive rate <20%
- ✅ Feedback actionable and linked to specific commits

---

## 3. Constitution Check

### 3.1 Alignment with SpecFarm Constitution II

| Principle | Requirement | Status | Notes |
|-----------|-------------|--------|-------|
| **II.A Zero External Deps** | No pkg managers, only bash + git + standard tools | ✅ Compliant | Agent uses xmllint (pre-installed), git (ubiquitous), bash |
| **II.B No Breaking Changes** | Must work on existing repos without enforcing new constraints | ✅ Compliant | Agent is non-invasive; copy-only bootstrap |
| **II.C Rules-First Governance** | Rules extracted from git history, not imposed top-down | ✅ Compliant | Discover mode extracts patterns; task-context aligns to existing rules |
| **II.D Confidence Scoring** | All recommendations must have confidence scores and evidence | ✅ Compliant | Every rule has score (30–100) and commit links |
| **II.E Extensibility** | Design must support keyword lists, custom XPath, future scoring models | ✅ Compliant | Keywords in `gather-rules-agent.sh` are modular; easy to extend |

### 3.2 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| **Target repo has minimal signal** (few tests, generic commits) | Medium | Low | Pre-screen repo selection; require 2+ authors, 20+ commits, tests |
| **Agent performance degrades on large repos** (1000+ commits) | Low | Medium | Implement `--depth N` flag; default to last 10 commits; document performance curve |
| **False positive rules confuse users** | High | Medium | Curation phase (T013) filters low-confidence rules; manual review required before rules.xml |
| **Keyword list mismatch for target language** | Medium | Low | Extend keywords per repo language; phase T015 identifies gaps |
| **Git history not accessible or corrupt** | Very Low | High | Validate git repo early (T002); error handling in agent |

---

## 4. Integration Points & Dependencies

### 4.1 External Dependencies

1. **Target Repository**
   - Location: External (not in specfarm2)
   - Access: SSH or HTTPS clone required
   - Size: 20–100+ commits, 10–80 source files
   - Required content: Test files, descriptive commit messages

2. **specfarm2 Source Materials**
   - Agent source: `.specfarm-agents/gather-rules-agent.sh`
   - Starter rules: `rules/rules.xml`
   - Test harness: `tests/run_all_tests.sh`

3. **CI/CD Integration** (Future)
   - GitHub Actions workflow to run gather-rules on new repos
   - Integration with phase 3b validation (`--size tiny`)
   - Automated rules.xml export → main repo

### 4.2 Sequence & Ordering

```
T001 (Select Repo)
  ↓
T002 (Clone & Analyze)
  ↓
T003 (Bootstrap Script)
  ↓
T004 (Copy Agent) ← Parallel: T005 (Copy rules.xml)
  ↓
T006 (Run Discovery)
  ↓
T007 (Review Rules) ← Gate: Rules quality check
  ↓
T008 (Run Tests)
  ↓
T009 (Prepare Task-Context Tests) ← Parallel: T013–T016 can start if T007 passes
  ↓
T010 (Run Task-Context)
  ↓
T011 (Validate Task-Context)
  ↓
T012 (Document Mappings)
  ↓
T014 (Generate Report)
  ↓
T015 (Identify Keywords)
  ↓
T016 (Document Lessons)
  ↓
DONE: Validation + Feedback
```

---

## 5. Success Criteria & Measurement

### 5.1 Primary Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| **Agent Stability** | 0 crashes on real repo | Run agent, capture exit code and stderr |
| **Rules Discovery Rate** | ≥6–8 rules with confidence >70% | Count rules in markdown output; manually review |
| **Evidence Traceability** | 100% of rules link to valid commits | `git rev-parse <sha>` validation |
| **Task-Context Relevance** | 100% of returned rules match task topic | Manual code review of 5 sample tasks |
| **Confidence Accuracy** | ≥80% of high-confidence rules are true positives | Curation phase feedback |

### 5.2 Learning Outcomes

- **What worked**: Patterns the agent reliably extracted
- **What didn't**: False positives, missed patterns
- **Keyword suggestions**: New keywords to add for better recall
- **Repo-type guidelines**: What repo characteristics drive good results

---

## 6. Risk & Contingency Plan

### 6.1 High-Risk Scenarios

1. **Target repo has no tests or minimal commit history**
   - **Mitigation**: Screen earlier; use fallback repo (e.g., public project like a small CLI tool)
   - **Contingency**: Reduce confidence threshold; focus on code-pattern rules rather than test-based

2. **Agent crashes on real git history**
   - **Mitigation**: Run on smaller `--depth 5` first; test with synthetic repo
   - **Contingency**: Patch agent, re-run, document failure mode

3. **High false positive rate (>30%)**
   - **Mitigation**: Curation phase filters low-confidence rules
   - **Contingency**: Re-tune confidence thresholds; adjust keyword weighting

### 6.2 Rollback Plan

If validation fails catastrophically:
1. Revert target repo to clean state (no modifications to codebase)
2. Select alternate target repo
3. Re-run phases 0–1
4. Document failure analysis in validation report

---

## 7. Documentation & Outputs

### 7.1 Deliverables Checklist

- [ ] **discovered-rules.md** — Markdown output from agent run (Phase 1)
- [ ] **task-context-results.json** — Task→rules mappings (Phase 2)
- [ ] **rules-curated.xml** — Final rules.xml after curation (Phase 3)
- [ ] **validation-report.md** — Accuracy, false positives, keyword gaps (Phase 3)
- [ ] **lessons-learned.md** — Recommendations for future repos (Phase 3)
- [ ] **test-results.log** — Test harness output (Phase 1)
- [ ] **bootstrap-script.sh** — Reproducible setup (Phase 0)

### 7.2 Documentation Standards

- All markdown must follow SpecFarm style guide (headings, code blocks, links)
- All test results must include exit code + stderr
- All evidence must be traceable to commits (SHA + commit message)
- All keyword suggestions must include false-positive examples

---

## 8. Timeline & Estimates

| Phase | Duration | Effort | Start Date | End Date |
|-------|----------|--------|-----------|----------|
| **Phase 0** (Setup) | 4h | 4 task-hours | Week 1 | Week 1 |
| **Phase 1** (First Run) | 6.5h | 6.5 task-hours | Week 1 | Week 2 |
| **Phase 2** (Task-Context) | 5.5h | 5.5 task-hours | Week 2 | Week 2 |
| **Phase 3** (Curation) | 6h | 6 task-hours | Week 2–3 | Week 3 |
| **Total** | **~22h** | **22 task-hours** | | |

**Staffing**: 1 engineer (full-time on this feature) + code review from SpecFarm lead (10% time).

---

## 9. Open Questions & Clarifications

1. **Target Repository**: Which specific mid-dev repo should be used? (Personal project, internal service, public OSS?)
2. **Keyword Customization**: Should keyword lists be repo-language-specific from day 1, or use a generic base?
3. **Confidence Threshold**: Should rules <70% confidence be filtered out or shown with caveats?
4. **CI Integration**: Should this validation run automatically on each commit to specfarm2, or only on-demand?
5. **Rules Export**: After curation, should rules.xml be committed to the target repo or kept in specfarm2?

---

## 10. References & Related Docs

- **Feature Spec**: `specs/011-test-1st-customer-repo.md`
- **Gather-Rules Agent**: `.specfarm-agents/gather-rules-agent.sh` (source)
- **Constitution II**: `.specify/memory/constitution.md`
- **Related Task**: US1 (T005–T012)
- **Phase 3b Context**: `--size tiny` validation (related, not blocking)

---

**Next Steps**:
1. ✅ Finalize this plan with stakeholder review
2. ⏳ Select and validate target repository (T001–T002)
3. ⏳ Execute bootstrap and first agent run (T003–T008)
4. ⏳ Run task-context validation (T009–T012)
5. ⏳ Curate rules and generate feedback (T013–T016)
