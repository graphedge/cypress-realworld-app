# Spec 011: Test SpecFarm gather-rules on Real Mid-Dev Repo

## Specification Overview
Test SpecFarm's gather-rules agent on a real, production mid-development repository to validate the bootstrap SDD workflow and rule auto-extraction capabilities.

## Project Structure
```
Target Repository (external, mid-dev)
├── .specfarm-agents/
│   └── gather-rules-agent.sh
├── rules.xml (curated from agent output)
├── git history (20-100+ commits, multiple authors, signal for confidence scoring)
└── tests/ (any test framework with discoverable patterns)
```

## Implementation Strategy
- **Phase 1**: Preparation - Identify and setup target repository
- **Phase 2**: Agent Deployment - Copy and validate gather-rules agent
- **Phase 3**: Discovery Run - Execute agent in full discovery mode
- **Phase 4**: Validation - Verify output quality and evidence mapping
- **Phase 5**: Curation & Task Integration - Manually curate rules, test task-context mode
- **Phase 6**: Polish - Documentation and lessons learned capture

---

## Phase 1: Repository Selection & Preparation

### Story Goal
Identify and prepare a suitable mid-development repository for testing SpecFarm's gather-rules agent capabilities.

### Independent Test Criteria
- [ ] Selected repository meets size and complexity criteria (20-100+ commits, 10-80 source files)
- [ ] Repository has signal for confidence scoring (tests present, meaningful commit messages, 2+ authors)
- [ ] Repository is cloned and accessible locally
- [ ] Repository history is clean (no merge conflicts, all commits intact)

---

### Setup Tasks

- [ ] T001 Identify candidate mid-dev repository matching criteria
  - Repository must have 20-100+ commits (real development history)
  - Must have 10-80 source files (mid-sized, not monorepo)
  - Should have multiple authors and branches
  - Should be Python/bash-heavy or have discoverable test patterns
  - Document selection rationale in `repo-selection-notes.md`

- [ ] T002 Clone target repository to local development environment
  - Clone repository to `/tmp/target-repo` or equivalent workspace location
  - Verify all commits are present: `git log --oneline | wc -l`
  - List all branches: `git branch -a`
  - Document repository metadata: URL, branch count, file count, language mix

- [ ] T003 Analyze target repository structure and test patterns
  - List all test files: `find . -name "test_*.py" -o -name "*_test.py" -o -name "*.bats"` etc.
  - Identify test framework (pytest, unittest, bash bats, etc.)
  - Count commits by author: `git shortlog -sn | head -10`
  - Extract recent commit messages: `git log --oneline -20`
  - Document findings in `repository-analysis.md`

- [ ] T004 Verify git history contains sufficient signal
  - Confirm presence of test-related commits
  - Check for action verbs in commit messages (add, fix, implement, refactor, test)
  - Verify multiple commits per author (indicates collaborative development)
  - Document signal score in `repository-analysis.md`

---

## Phase 2: Agent Deployment & Validation

### Story Goal
Deploy the gather-rules agent into the target repository and validate it runs without errors on real git history.

### Independent Test Criteria
- [ ] gather-rules-agent.sh is copied to target repository
- [ ] Agent executes successfully without crashes on target repo history
- [ ] Agent outputs valid markdown with rule candidates
- [ ] Agent's dependencies (bash, xmllint, git) are available in target environment

---

### Deployment Tasks

- [ ] T005 [P] Copy gather-rules-agent.sh from specfarm2
  - Source: `/path/to/specfarm2/.specfarm-agents/gather-rules-agent.sh`
  - Destination: `target-repo/.specfarm-agents/gather-rules-agent.sh`
  - Create `.specfarm-agents/` directory if it doesn't exist
  - Verify file is executable: `chmod +x .specfarm-agents/gather-rules-agent.sh`

- [ ] T006 [P] Copy starter rules.xml from specfarm2 (or create minimal skeleton)
  - Option A: Copy `/path/to/specfarm2/rules.xml` to target repo root
  - Option B: Create minimal `rules.xml` skeleton if starter doesn't exist
  - Skeleton should be valid XML: `<?xml version="1.0"?>` with empty `<rules/>` root
  - Test XML validity: `xmllint --noout rules.xml`

- [ ] T007 Verify gather-rules agent dependencies
  - Test bash: `bash --version` (must be bash, not sh)
  - Test xmllint: `xmllint --version`
  - Test git: `git --version`
  - Test availability of common test keywords: `grep -r "test_\|\.sh\|describe(" . | head -5` or similar
  - Document any missing dependencies in `deployment-status.md`

- [ ] T008 Perform pre-run validation
  - Navigate to target repo root: `cd /tmp/target-repo`
  - Verify git history is intact: `git log --oneline | wc -l` (should match T003)
  - Verify rules.xml is present and valid: `xmllint --noout rules.xml`
  - Verify agent is executable: `ls -la .specfarm-agents/gather-rules-agent.sh`
  - Create `pre-run-checklist.md` documenting all validations

---

## Phase 3: Discovery Run - Full Mode

### Story Goal
Execute gather-rules agent in full discovery mode to extract and rank rule candidates from the target repository's git history and codebase.

### Independent Test Criteria
- [ ] Agent completes without crashing or errors
- [ ] Output contains ranked list of rule candidates (confidence scores visible)
- [ ] Confidence scores fall in expected range (30-100 scale documented)
- [ ] Evidence references real commits/files from git history
- [ ] Output is valid markdown and human-readable

---

### Discovery Execution Tasks

- [ ] T009 Execute gather-rules agent in full discovery mode
  - From target repo root: `./.specfarm-agents/gather-rules-agent.sh`
  - Capture full stdout to file: `... > agent-discovery-output.md 2>&1`
  - Record execution time and any warnings/errors
  - Verify exit code is 0: `echo $?`

- [ ] T010 Validate agent output structure
  - Open `agent-discovery-output.md` and verify:
    - Contains "Rule Candidates" section
    - Lists rules with confidence scores (30-100 range)
    - Evidence sections reference git commits
    - Markdown formatting is valid and readable
  - Create `output-validation-report.md` with findings

- [ ] T011 Verify evidence mapping to real commits
  - For each rule in top 10 ranked candidates:
    - Extract commit SHA from evidence section
    - Run `git log <SHA>` to verify commit exists
    - Verify commit message content matches evidence
  - Document any evidence mismatches in `evidence-accuracy-report.md`

- [ ] T012 Analyze confidence scoring accuracy
  - Review top 5-10 rules by confidence score
  - Manually assess whether rule makes sense for target repo
  - Compare confidence scores with manual assessment:
    - High-confidence rules (70+): Should be obvious, actionable rules
    - Medium-confidence rules (50-70): Should require some context knowledge
    - Lower-confidence rules (30-50): May need keyword tuning
  - Document scoring accuracy assessment in `confidence-scoring-analysis.md`

---

## Phase 4: Output Validation & Quality Assessment

### Story Goal
Systematically validate the quality, accuracy, and usefulness of the agent's rule candidates for the target repository.

### Independent Test Criteria
- [ ] 5-10+ rules scored >70 confidence that make sense for target repo
- [ ] Evidence correctly links back to real commits/files
- [ ] No crashes or undefined behavior during validation
- [ ] Validation findings documented in structured report

---

### Validation Tasks

- [ ] T013 Extract top-ranked rules (confidence >70)
  - From `agent-discovery-output.md`, list all rules with confidence >= 70
  - For each rule, record: rule name, confidence score, evidence count, description
  - Create `high-confidence-rules.md` with formatted list
  - Target: 5-10+ rules with high confidence

- [ ] T014 Verify each high-confidence rule against codebase
  - For each rule in `high-confidence-rules.md`:
    - Search codebase for examples: `grep -r "<rule-pattern>" target-repo/`
    - Verify examples make sense in context
    - Count actual violations/instances
  - Document verification results in `rules-verification-checklist.md`

- [ ] T015 Assess rule actionability for target repo governance
  - For each high-confidence rule, evaluate:
    - Is this rule clear and unambiguous? (Can developers follow it?)
    - Is this rule already mostly followed? (Is it aspirational?)
    - Is this rule language-appropriate? (Does it apply to repo's tech stack?)
    - Would this rule prevent bugs or improve code quality?
  - Score each rule: actionable (yes/no), urgency (high/medium/low)
  - Document assessment in `rules-actionability-assessment.md`

- [ ] T016 Create summary quality report
  - Compile findings from all validation tasks
  - Summary statistics:
    - Total rules discovered
    - Rules by confidence band (30-50, 50-70, 70+)
    - High-confidence actionable rules (count and list)
    - Any evidence inaccuracies found
    - Language/framework alignment score (what keywords triggered well)
  - Document in `quality-assessment-summary.md`

---

## Phase 5: Curation & Task-Context Mode Testing

### Story Goal
Manually curate top rules into rules.xml and validate task-context mode functionality with real task prompts.

### Independent Test Criteria
- [ ] 6-8 high-confidence rules are curated into rules.xml with proper XML structure
- [ ] rules.xml is valid XML and agent can read it
- [ ] Agent runs in task-context mode without errors
- [ ] Task-context output is contextual to the provided task prompt

---

### Curation Tasks

- [ ] T017 Curate top 6-8 rules into rules.xml
  - From `high-confidence-rules.md`, select 6-8 most actionable rules
  - For each rule, create `<rule>` entry in `rules.xml`:
    - `<name>`: Clear, concise rule name
    - `<description>`: Full rule description
    - `<confidence>`: Confidence score from agent
    - `<evidence>`: Summary of evidence sources
  - Example:
    ```xml
    <rule>
      <name>Test Coverage Minimum</name>
      <description>All production code must have >80% test coverage</description>
      <confidence>85</confidence>
    </rule>
    ```
  - Validate XML: `xmllint --noout rules.xml`

- [ ] T018 Verify curated rules.xml loads without errors
  - Run agent with curated rules: `./.specfarm-agents/gather-rules-agent.sh`
  - Verify exit code 0 and no parsing errors
  - Agent should reference curated rules in output
  - Document any loading issues in `curation-validation-log.md`

- [ ] T019 Execute agent in task-context mode with sample task
  - Choose a representative task from target repo: e.g., "Implement user authentication flow"
  - Run: `./.specfarm-agents/gather-rules-agent.sh --task-context "Implement user authentication flow"`
  - Capture output to file: `... > task-context-output.md 2>&1`
  - Verify:
    - Output is focused on task context (not full history)
    - Curated rules are referenced
    - Suggestions are contextual and actionable
  - Document output quality in `task-context-validation.md`

- [ ] T020 Test task-context mode with 3 different task prompts
  - Task 1 (Feature): "Add integration with external API"
  - Task 2 (Bug Fix): "Fix authentication edge case for expired tokens"
  - Task 3 (Refactor): "Improve performance of database queries"
  - For each task:
    - Execute: `./.specfarm-agents/gather-rules-agent.sh --task-context "<prompt>"`
    - Verify output is relevant to task type
    - Verify curated rules are mentioned if applicable
  - Compile results in `task-context-mode-testing.md`

- [ ] T021 Validate rules work with test harness (if copied)
  - Copy tests from specfarm2: `cp -r /path/to/specfarm2/tests target-repo/`
  - Run: `target-repo/tests/run_all_tests.sh`
  - Verify agent passes existing test suite on target repo
  - Document test results in `test-harness-validation.md`
  - Note: Skip if test harness not part of agent distribution

---

## Phase 6: Documentation & Lessons Learned

### Story Goal
Document the testing process, findings, and any gaps/improvements needed for real-repo adoption.

### Independent Test Criteria
- [ ] Comprehensive testing report captures all findings
- [ ] Lessons learned are documented with specific examples
- [ ] Recommendations for agent improvements are prioritized
- [ ] Next steps for follow-on testing are clear

---

### Documentation Tasks

- [ ] T022 Compile complete testing report
  - Create `testing-report.md` with sections:
    1. **Executive Summary**: Success/failure of validation
    2. **Repository Profile**: Commits, files, languages, test framework
    3. **Agent Performance**: Rules discovered, confidence accuracy, evidence quality
    4. **High-Confidence Rules**: Table of 5-10+ rules >70 confidence with verification status
    5. **Task-Context Testing**: Summary of task prompt testing (did it work? actionability?)
    6. **Issues Found**: Any crashes, edge cases, unexpected behavior
    7. **Evidence Quality**: Any broken links, incorrect commits, or missing context
  - Include supporting data from all validation documents

- [ ] T023 Extract lessons learned and gaps
  - From observations during testing, document:
    - **Keyword Tuning Needed**: Any keywords that didn't trigger but should have (or vice versa)
    - **Language Support**: How well did agent handle target repo's language mix?
    - **Confidence Scoring**: Were scores accurate? Any systematic over/under-scoring?
    - **Edge Cases**: Any commits, files, or patterns that confused the agent?
  - Create `lessons-learned.md` with findings organized by category
  - Flag any systematic issues that would affect other repos

- [ ] T024 Prioritize and document recommended improvements
  - From lessons learned, identify changes needed to agent:
    - High Priority: Bugs that cause crashes or invalid output
    - Medium Priority: Accuracy improvements (keyword tuning, scoring adjustments)
    - Low Priority: Nice-to-haves (new output formats, additional metrics)
  - For each improvement, provide:
    - Clear description of current behavior vs desired behavior
    - Impact estimate (how many repos would benefit?)
    - Implementation complexity (low/medium/high)
  - Document in `recommended-improvements.md`

- [ ] T025 Create follow-on testing roadmap
  - Based on this first real-repo test, plan:
    - **Next Tests**: Which other repos to test next? (Should you test Go-heavy repo? JS? monorepo?)
    - **MVP Scope for Wider Release**: What minimal set of improvements needed before public release?
    - **Windows Phase 3b Validation**: When/how to validate on Windows (if applicable)?
    - **Task Integration Flow**: How will this integrate with speckit.tasks workflow?
  - Document roadmap in `follow-on-roadmap.md`

- [ ] T026 Archive all testing artifacts
  - Create `artifacts/` subdirectory in test repo
  - Move all reports to `artifacts/`:
    - `agent-discovery-output.md`
    - `output-validation-report.md`
    - `evidence-accuracy-report.md`
    - `high-confidence-rules.md`
    - `rules-actionability-assessment.md`
    - `quality-assessment-summary.md`
    - `task-context-validation.md`
    - All other reports and logs
  - Create `artifacts/README.md` with index of all artifacts
  - Create tarball: `tar -czf spec-011-testing-artifacts.tar.gz artifacts/`

---

## Dependency Graph

```
Phase 1 (Setup)
├── T001: Repository Selection
├── T002: Clone Repository
├── T003: Analyze Structure
└── T004: Verify Signal

Phase 2 (Deployment) - Depends on Phase 1
├── T005: Copy Agent
├── T006: Copy rules.xml
├── T007: Verify Dependencies
└── T008: Pre-run Validation

Phase 3 (Discovery) - Depends on Phase 2
├── T009: Execute Agent
├── T010: Validate Output
├── T011: Verify Evidence
└── T012: Analyze Scoring

Phase 4 (Validation) - Depends on Phase 3
├── T013: Extract High-Confidence Rules
├── T014: Verify Rules in Codebase
├── T015: Assess Actionability
└── T016: Summary Report

Phase 5 (Curation) - Depends on Phase 4
├── T017: Curate rules.xml
├── T018: Verify rules.xml Loads
├── T019: Task-Context Single Test
└── T020: Task-Context Multiple Tests
└── T021: Test Harness Validation

Phase 6 (Documentation) - Depends on Phase 5
├── T022: Compile Testing Report
├── T023: Extract Lessons Learned
├── T024: Prioritize Improvements
├── T025: Create Roadmap
└── T026: Archive Artifacts
```

## Parallel Execution Opportunities

Within each phase, these tasks are parallelizable:
- **Phase 1**: T003 and T004 can run in parallel (both analyze repository)
- **Phase 2**: T005 and T006 can run in parallel (independent file copies)
- **Phase 4**: T013, T014, T015 can run in parallel (independent analysis tasks)
- **Phase 6**: T022, T023, T024, T025 can run in parallel (independent documentation)

## Success Criteria Checklist

- [ ] **Agent Execution**: Agent runs without crashes on real mid-dev repository
- [ ] **Rule Quality**: 5-10+ high-confidence rules (>70) that make sense for target repo
- [ ] **Evidence Accuracy**: Rules reference real commits with correct context
- [ ] **Task-Context**: Agent works in task-context mode with multiple task types
- [ ] **Curation**: 6-8 rules successfully curated into rules.xml
- [ ] **Documentation**: Complete testing report with lessons learned and roadmap
- [ ] **Zero External Deps**: All operations use only bash, git, xmllint (no Node/Python/etc)

## Notes for Implementer

1. **Target Repository Choice**: Choose a real project that matters to you. Personal CLI tool, data pipeline, or small internal service works great.
2. **First Run Expectations**: The agent may discover 20-40 rule candidates; confidence scores of 70+ are realistic for 5-10 of them.
3. **Task-Context Learning**: This is the key validation — proves the agent can focus on a specific task context, not just historical patterns.
4. **Keyword Tuning**: You'll likely identify 2-3 keyword additions needed for your target language/framework. That's normal and expected.
5. **Windows Phase 3b**: If testing on Windows, note any bash/xmllint compatibility issues for later (T005 reference in main roadmap).

---

**Generated**: For Spec 011 - Test SpecFarm gather-rules on Real Mid-Dev Repo  
**Status**: Ready for execution  
**Total Tasks**: 26 tasks across 6 phases
