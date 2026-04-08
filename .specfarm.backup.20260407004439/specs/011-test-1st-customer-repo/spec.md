# Feature Specification: First Customer Repository Testing

**Feature ID**: 011  
**Title**: Test SpecFarm on First Mid-Dev Customer Repository with Gather-Rules Agent  
**Status**: Ready for Planning  
**Last Updated**: 2024-03-31  

---

## Executive Summary

Validate SpecFarm's core bootstrapping capability by deploying the gather-rules agent on a real mid-development customer repository. This real-world test demonstrates the "extract rules from git history" workflow, validates auto-confidence scoring on non-specfarm codebases, and surfaces any gaps before scaling to additional customers.

---

## User Scenarios

### US1: DevOps Engineer Adopts SpecFarm for Existing Project
**Actor**: Mid-sized development team lead  
**Goal**: Bootstrap Spec-Driven Development into an existing project with established git history  

**Flow**:
1. Team identifies their mid-dev repository (20–100+ commits, multiple branches, 10–80 source files)
2. DevOps engineer clones gather-rules agent and minimal starter rules from SpecFarm
3. Runs agent in discovery mode (`--mode discover` or default) to extract ranked rule candidates
4. Reviews confidence-scored rules extracted from git history
5. Manually curates top 6–8 high-confidence rules into `rules.xml`
6. Runs test harness to validate agent works in new environment
7. Begins task-context mode testing to validate end-to-end SDD loop

**Success Criteria**:
- Agent generates 5–10+ rules with confidence scores >70
- Evidence correctly traces back to real commits/tests
- Rules reflect actual coding patterns already present in repo
- No agent crashes on real git history
- Agent runs with zero external dependencies (bash, xmllint, git only)

### US2: SpecFarm Team Validates Agent Portability
**Actor**: SpecFarm development team  
**Goal**: Identify agent tweaks needed for non-specfarm repositories  

**Flow**:
1. Observe agent running on customer repo
2. Note keyword extraction differences (Python vs. JS vs. Go patterns)
3. Document any XPath query mismatches or scoring anomalies
4. Update keyword lists and scoring heuristics based on findings
5. Test improvements on same customer repo to validate

**Success Criteria**:
- Agent produces meaningful results on customer codebase
- Minimal (0–3) keyword/scoring adjustments needed for language parity
- Adjustments documented and mergeable back to main gather-rules agent

---

## Functional Requirements

### FR1: Repository Selection & Readiness
- **Description**: Establish clear criteria for choosing target mid-dev repository
- **Acceptance Criteria**:
  - Repository has 20–100+ commits in git history
  - At least 2–3 distinct development branches or recent feature work
  - Total of 10–80 source files
  - Contains some test artifacts (unit tests, shell scripts, CI configs)
  - Authored by 2+ contributors to demonstrate pattern diversity

### FR2: Minimal Bootstrap Setup
- **Description**: Copy agent and starter rules to target repository with zero environment changes
- **Acceptance Criteria**:
  - Single copy operation: `.specfarm-agents/gather-rules-agent.sh` copied to target repo
  - Single copy operation: Starter `rules.xml` (or skeleton) copied to target repo
  - No environment variables, external services, or system packages required
  - Bootstrap takes ≤5 minutes start to finish
  - Target repo remains functional after bootstrap (no test failures introduced)

### FR3: Discovery Mode Execution
- **Description**: Run gather-rules agent in default discovery mode on customer repository
- **Acceptance Criteria**:
  - Agent scans git log (default: last ~10 commits)
  - Agent generates candidate rules with confidence scores (30–100 scale)
  - Agent outputs markdown report with ranked rules + evidence links
  - Evidence correctly references commit SHAs, file paths, and patterns found
  - Output is immediately reviewable without additional tooling

### FR4: Confidence Scoring Accuracy
- **Description**: Validate that auto-scored rules reflect actual project patterns
- **Acceptance Criteria**:
  - Rules scoring >70 are manually verified to align with observed project patterns
  - Rules scoring 30–70 are edge-case patterns or project-specific tools
  - Evidence citations in output trace back to correct commits
  - Scoring heuristics handle language-specific patterns (Python `test_*`, shell `*.sh`, commit message keywords)
  - No false positives with confidence >80

### FR5: Task-Context Mode Validation
- **Description**: Validate agent's task-context mode works with curated customer rules
- **Acceptance Criteria**:
  - Agent accepts `--task-context "<task description>"` parameter
  - Agent filters extracted rules based on task context
  - Agent outputs prioritized rules applicable to given task
  - Example: `--task-context "Implement user authentication flow"` returns relevant auth-related rules from rules.xml
  - Output is traceable to source rules in rules.xml

### FR6: Zero-Dependency Verification
- **Description**: Confirm agent runs with only bash, xmllint, and git
- **Acceptance Criteria**:
  - No external npm, pip, or other package manager dependencies
  - Agent runs successfully on minimal Linux environment (bash shell only)
  - All XML parsing done via xmllint (included in most Linux distros)
  - Git operations use standard `git` CLI (no custom wrappers)
  - Dependencies document in agent clearly lists: bash, xmllint, git

### FR7: Test Harness Portability
- **Description**: Run existing test harness on customer repository to validate environment compatibility
- **Acceptance Criteria**:
  - `tests/run_all_tests.sh` copied to customer repo executes without modification
  - All 310+ existing tests pass in customer repo environment
  - No test failures due to environment differences (path, shell, permissions)
  - Test harness output is identical to specfarm2 baseline

### FR8: Documentation & Handoff Package
- **Description**: Produce runbook and findings report for customer team
- **Acceptance Criteria**:
  - Runbook includes 5-minute setup steps (copy, chmod, run)
  - Runbook includes task-context example and rule curation workflow
  - Findings report documents discovered rules, confidence scores, and evidence
  - Findings report identifies any language-specific tweaks or keyword gaps
  - Both documents are markdown format and suitable for non-technical handoff

---

## Success Criteria

1. **Agent Execution**: Agent runs on customer repository without crashes or errors
2. **Rule Quality**: At least 5 rules with confidence >70 are discovered and verified against actual project patterns
3. **Evidence Traceability**: 100% of top-10 rules have evidence that correctly links to real commits
4. **Zero Blocking Issues**: No environment or dependency issues preventing agent deployment
5. **Test Coverage**: All 310+ existing tests pass in customer environment
6. **Task-Context Validation**: Agent filters rules contextually for at least 2 example tasks
7. **Documentation**: Complete runbook and findings report delivered to customer team

---

## Key Entities & Data Structures

### Repository Metadata
- **repo_name**: String, customer project identifier
- **commit_count**: Integer, total commits in analysis window
- **branch_count**: Integer, distinct branches in repository
- **source_file_count**: Integer, total `.py`, `.sh`, `.js`, etc. files
- **test_file_count**: Integer, total test-related files
- **contributor_count**: Integer, unique committers

### Extracted Rule
- **rule_id**: String, unique identifier from rules.xml
- **rule_name**: String, human-readable rule title
- **confidence_score**: Integer (30–100), auto-calculated confidence
- **evidence_commits**: Array of commit SHAs with matching patterns
- **evidence_description**: String, text explaining why confidence is this value
- **applicable_languages**: Array of language tags (python, bash, javascript, etc.)

### Test Results
- **test_name**: String, test identifier
- **status**: Enum (pass, fail, skip)
- **environment**: Object with (os, shell, bash_version, xmllint_version, git_version)
- **duration_ms**: Integer, execution time

---

## Technical Assumptions

1. **Git History Availability**: Customer repository has accessible `.git` directory with full history (not shallow clone)
2. **Language Composition**: Primary languages are Python, Bash, or JavaScript (agent keyword extractor optimized for these)
3. **Standard Git Workflow**: Repository uses standard `git commit`, branch, and merge operations (not GitHub Actions-specific)
4. **Rule Curation**: Customer team has 1–2 engineers available for 30-min manual rule review before full deployment
5. **Test Environment**: Customer repo can run bash scripts in CI or local environment with xmllint installed
6. **Starter Rules Quality**: Provided `rules.xml` skeleton matches gathered-rules agent output schema exactly
7. **No Breaking Changes**: Customer repo codebase remains unchanged by agent (agent is read-only for git operations)

---

## Constraints & Dependencies

### Constraints
- Agent must complete discovery on 10 commits in <5 seconds (performance)
- Confidence scores must be reproducible and deterministic across multiple runs
- All output must be human-reviewable without custom parsers
- Customer team should not need to modify agent code

### Dependencies
- **gather-rules agent (merged)**: T005–T012 complete, 310/310 tests passing, on master branch
- **Test harness**: `tests/run_all_tests.sh` must be portable and runnable on customer environment
- **Customer repo criteria**: Must meet mid-dev selection criteria (20–100+ commits, 10–80 files, test artifacts present)
- **XPath rule schema**: Rules in `rules.xml` must follow existing schema (no new fields required for customer validation)

---

## Risks & Mitigation

### Risk 1: Language-Specific Keyword Gaps
**Impact**: Low confidence scores due to agent not recognizing customer's language patterns  
**Mitigation**:
- Pre-analyze customer repo for primary languages before running agent
- Document discovered keywords for post-agent curation
- Plan keyword extension for T013+ based on findings

### Risk 2: Performance on Large Commits
**Impact**: Agent slow on repos with >1000-line commits or large binary files  
**Mitigation**:
- Default to last 10 commits (configurable via flag)
- Skip binary files automatically
- Document any performance issues for post-test optimization

### Risk 3: Unmet Environment Dependencies
**Impact**: Customer environment lacks xmllint or bash 4.x+  
**Mitigation**:
- Pre-flight check script (`check-env.sh`) provided to customer
- Clear fallback instructions if xmllint unavailable
- Plan vendored xmllint or alternative XPath parser for T014+

---

## Out of Scope

- **Windows support** (Phase 3b optimization deferred to separate feature)
- **`--size tiny` flag** (end-to-end scope control deferred to T014)
- **Evidence depth configuration** (fine-grained git blame/diffs deferred to T015)
- **Real-time dashboard updates** (customer feedback collection happens post-test)
- **Multi-repo aggregation** (single repo validation only)
- **Custom rule formats** (XML schema unchanged)

---

## Acceptance Scenarios

### Scenario 1: Successful Discovery on Python/Bash Project
**Given**: Customer repo with 40 commits, 30 Python test files, 5 shell scripts, 25 Python source files  
**When**: Agent runs in discovery mode  
**Then**:
- Agent outputs 8 rules with confidence >70
- Top 3 rules are test patterns (`test_*.py`, `assert` usage)
- Evidence correctly traces to test commits
- Agent completes in <3 seconds

### Scenario 2: Task-Context Filtering
**Given**: Customer rules.xml populated with 10 curated rules  
**When**: Agent runs with `--task-context "Add logging to payment flow"`  
**Then**:
- Agent returns 2–4 rules related to logging, payments, or error handling
- Returned rules have evidence from commits touching payment code
- Output is ranked by relevance to task

### Scenario 3: Test Harness Portability
**Given**: Customer repo with standard Linux environment (bash, git, xmllint)  
**When**: Test harness is copied and executed  
**Then**:
- All 310+ tests pass
- No environment-specific failures
- Execution time is within expected range (same as specfarm2)

### Scenario 4: Zero-Dependency Validation
**Given**: Fresh Linux container with only bash, git, xmllint  
**When**: Agent and tests are run  
**Then**:
- No external package manager invocations (no `npm install`, `pip install`, etc.)
- All operations use only built-in tools
- Any new language runtimes are explicitly documented

---

## Definition of Done

- [ ] Customer repository identified and meets selection criteria
- [ ] Agent runs successfully in discovery mode and task-context mode
- [ ] At least 5 rules with >70 confidence are discovered and verified
- [ ] Evidence correctly traces to real commits (100% accuracy)
- [ ] Test harness runs and all tests pass in customer environment
- [ ] Zero-dependency constraint validated (bash, xmllint, git only)
- [ ] Runbook and findings report completed and handed off to customer
- [ ] Post-test retro identifies 0–3 keyword/scoring tweaks for agent improvement
- [ ] All findings documented in PR for PR14 or separate follow-up PR

---

## Related Features & Future Work

- **T013**: Extend `--size tiny` flag for scope-controlled feature bootstrapping
- **T014**: Evidence depth configuration and git blame integration
- **T015**: Multi-repo rule aggregation and cross-codebase validation
- **Phase 3b**: Windows bash compatibility for customer repos
- **Feature 020**: Scale SpecFarm adoption to 2–3 more customer repos (based on 011 learnings)

---

## Sign-Off

**Feature Owner**: SpecFarm Core Team  
**Reviewed By**: [Pending Review]  
**Approved By**: [Pending Approval]  

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-03-31 | SpecFarm Team | Initial specification from feature brief |
