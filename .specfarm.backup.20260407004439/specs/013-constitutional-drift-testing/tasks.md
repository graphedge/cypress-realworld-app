---
description: "Task list for Constitutional Drift Testing experiment implementation"
---

# Tasks: Constitutional Drift Testing

**Input**: Design documents from `.specfarm/specs/013-constitutional-drift-testing/`  
**Prerequisites**: plan.md (required), spec.md (required), research.md (required for implementation tasks)

**Organization**: Tasks are grouped by implementation phase, with dependencies marked. All setup/foundation tasks MUST complete before user story work begins.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files/no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- **Exact paths**: All file paths are absolute from repo root

---

## Phase 0: Research (Blocking Prerequisites)

**Status**: MUST COMPLETE BEFORE PHASE 1

These tasks resolve unknowns identified in plan.md Technical Context:

- [ ] **T000** [Phase 0] Research: Constitutional core injection into rules.xml
  - **Description**: Investigate how to safely inject constitutional core XML into rules-*.xml fixture without validation errors. Document xmlstarlet commands, namespace handling, and rollback procedures.
  - **Output**: `.specfarm/specs/013-constitutional-drift-testing/research.md` section RQ-001 with tested injection pattern
  - **Validation**: Pattern can successfully inject constitutional rules into sample XML without errors

- [ ] **T001** [Phase 0] Research: Statistical approach for N=5 experiment
  - **Description**: Validate that Welch's t-test is appropriate for comparing two arms with N=5 samples each. Investigate normality assumptions, bootstrap alternatives, confidence interval computation. Document scipy.stats functions required.
  - **Output**: `.specfarm/specs/013-constitutional-drift-testing/research.md` section RQ-002 with statistical approach validated
  - **Validation**: Documented scipy functions verified to exist; normality testing approach decided

- [ ] **T002** [Phase 0] Research: Evidence accuracy measurement algorithm
  - **Description**: Define algorithm to score EvidenceAccuracy (0.0-1.0) from gathered rules. Investigate how drift_analytics.sh computes rule status. Document evidence-matching heuristics (grep patterns, signature matching, false-positive prevention).
  - **Output**: `.specfarm/specs/013-constitutional-drift-testing/research.md` section RQ-003 with algorithm pseudocode + heuristics
  - **Validation**: Algorithm can be traced through drift_analytics.sh code; edge cases documented

- [ ] **T003** [Phase 0] Research: Semantic similarity metric
  - **Description**: Define SemanticSimilarity metric (0.0-1.0) for rule-signature alignment. Compare approaches: token overlap, fuzzy matching, embedding distance. Choose one based on trade-off between accuracy and computation time.
  - **Output**: `.specfarm/specs/013-constitutional-drift-testing/research.md` section RQ-004 with chosen algorithm, complexity analysis, and Python implementation sketch
  - **Validation**: Chosen approach can compute similarity for sample rules in < 1ms per rule

- [ ] **T004** [Phase 0] Research: Git clone strategy for experiment isolation
  - **Description**: Investigate shallow clones, reference repos, disk space tradeoffs. Choose strategy for managing 15 fresh clones efficiently. Document cleanup procedures and parallel clone safety.
  - **Output**: `.specfarm/specs/013-constitutional-drift-testing/research.md` section RQ-005 with chosen clone strategy and shell code
  - **Validation**: Strategy tested locally; clone+cleanup completes in < 5min; disk usage documented

**Gate**: Phase 1 cannot start until all T000-T004 output is in research.md with ✅ Validation passed

---

## Phase 1: Setup (Shared Infrastructure)

**Status**: FOUNDATION FOR ALL LATER TASKS

These tasks create directories, fixtures, and templates required by all experiment runs:

- [ ] **T005** [P] [Setup] Create experiment directory structure
  - **Description**: Create required directories:
    - `.specfarm/src/experiment/` (orchestration code)
    - `.specfarm/specs/fixtures/` (rule fixtures)
    - `artifacts/drift-testing/` (output root with subdirs baseline/, control/, treatment/, analysis/)
  - **Command**: `mkdir -p .specfarm/src/experiment artifacts/drift-testing/{baseline,control,treatment,analysis}`
  - **Output**: Empty directories created
  - **Validation**: All directories exist and are writable

- [ ] **T006** [P] [Setup] Create rule fixture files (baseline)
  - **Description**: Create `.specfarm/specs/fixtures/rules-baseline.xml` containing zero rules (empty XML skeleton only).
  - **Template**: 
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <rules>
      <!-- Baseline: zero rules for comparison -->
    </rules>
    ```
  - **Output**: `.specfarm/specs/fixtures/rules-baseline.xml` created
  - **Validation**: `xmlstarlet val .specfarm/specs/fixtures/rules-baseline.xml` succeeds

- [ ] **T007** [P] [Setup] Create rule fixture files (control)
  - **Description**: Copy current production `.specfarm/rules.xml` to `.specfarm/specs/fixtures/rules-control.xml`.
  - **Command**: `cp .specfarm/rules.xml .specfarm/specs/fixtures/rules-control.xml`
  - **Output**: `.specfarm/specs/fixtures/rules-control.xml` created with production rules
  - **Validation**: File is not empty; contains >0 rule elements

- [ ] **T008** [Setup] Create rule fixture files (treatment)
  - **Description**: Copy control rules to `.specfarm/specs/fixtures/rules-treatment.xml` and inject constitutional core using pattern from research.md T000 output.
  - **Pattern**: Use xmlstarlet or sed to add `<constitutional_core>` block with injected rules
  - **Output**: `.specfarm/specs/fixtures/rules-treatment.xml` created with control rules + constitutional core
  - **Validation**: `xmlstarlet val .specfarm/specs/fixtures/rules-treatment.xml` succeeds; contains more rules than control

- [ ] **T009** [P] [Setup] Create run-report template
  - **Description**: Create `.specfarm/src/drift/templates/run-report-template.json` with schema matching `contracts/run-report-schema.json`.
  - **Template**: Include all required fields with placeholder values (null/0/empty strings where appropriate)
  - **Output**: `.specfarm/src/drift/templates/run-report-template.json` created
  - **Validation**: `jsonschema validate --schema contracts/run-report-schema.json run-report-template.json` succeeds

- [ ] **T010** [P] [Setup] Copy design documents to spec directory
  - **Description**: Ensure all Phase 1 design documents exist:
    - `research.md` (from Phase 0 - T000-T004)
    - `data-model.md` (defines entities, DriftScore formula)
    - `quickstart.md` (how to run experiment)
    - `contracts/run-report-schema.json` (JSON schema)
    - `contracts/artifact-layout-spec.md` (directory structure)
  - **Validation**: All 5 files exist and are readable

**Gate**: All T005-T010 must complete before Phase 2 (foundation) tasks begin

---

## Phase 2: Foundation (Core Infrastructure)

**Status**: BLOCKS ALL USER STORIES - MUST COMPLETE

These tasks create the core orchestration and calculation logic:

- [ ] **T011** [Foundation] Create experiment_harness.sh (single-run orchestration)
  - **Description**: Create `.specfarm/src/drift/experiment_harness.sh` - orchestrates one complete run:
    1. Accept parameters: --arm (baseline|control|treatment), --run-number (1-5), --target-repo (path)
    2. Create fresh clone of target repo in isolated temp directory
    3. Copy rules fixture to `.specfarm/rules.xml` in clone
    4. Call existing drift_engine.sh to extract rules
    5. Call drift_analytics.sh to compute metrics
    6. Collect artifacts (logs, gathered-rules.md, agent-config.json, git-ref.txt)
    7. Call drift_score_calculator.py to compute DriftScore
    8. Generate run-report.json using template
    9. Copy all artifacts to final location
    10. Cleanup temp clone
  - **Error Handling**: Capture all errors to logs.txt; exit with status code if any step fails
  - **Output**: `.specfarm/src/drift/experiment_harness.sh` created (600+ lines)
  - **Validation**: Shellcheck passes; script sources properly; no hard-coded paths (uses $SCRIPT_DIR)

- [ ] **T012** [Foundation] Create drift_score_calculator.py (DriftScore formula)
  - **Description**: Create `.specfarm/src/drift/drift_score_calculator.py` - implements DriftScore calculation:
    1. Import scipy, numpy, json, argparse
    2. Implement `calculate_drift_score(evidence_accuracy, semantic_similarity, rule_count)` function:
       - RuleCountNorm = min(rule_count / 2000, 1.0)
       - DriftScore = 0.50 * (1.0 - evidence_accuracy) + 0.30 * (1.0 - semantic_similarity) + 0.20 * RuleCountNorm
    3. Implement `calculate_semantic_similarity(rules_list)` function using algorithm from research.md T003
    4. Implement `calculate_evidence_accuracy(rules_list, codebase_path)` function using algorithm from research.md T002
    5. Implement main CLI: accept JSON file with metrics, output computed DriftScore
  - **Output**: `.specfarm/src/drift/drift_score_calculator.py` created (150+ lines)
  - **Validation**: Python syntax passes; script runs with --help; all functions tested (see T020 unit tests)

- [ ] **T013** [P] [Foundation] Create conftest.py for experiment tests
  - **Description**: Create `.specfarm/src/experiment/conftest.py` - pytest configuration:
    1. Define fixtures for sample rules (baseline, control, treatment)
    2. Define fixtures for temporary run directories
    3. Define fixtures for mock git repos
    4. Provide utilities for comparing JSON schemas
  - **Output**: `.specfarm/src/experiment/conftest.py` created
  - **Validation**: pytest can collect tests with this conftest

- [ ] **T014** [Foundation] Create run-single-drift-run.sh (executable wrapper)
  - **Description**: Create `.specfarm/bin/run-single-drift-run.sh` - user-facing script:
    1. Accept parameters: --arm, --run-number, --target-repo, --dry-run, --verbose
    2. Validate parameters
    3. Call experiment_harness.sh with appropriate flags
    4. Print progress/status to stdout
    5. On completion, show path to run-report.json
  - **Output**: `.specfarm/bin/run-single-drift-run.sh` created (100+ lines)
  - **Validation**: Script is executable; --help works; runs successfully for --dry-run

- [ ] **T015** [Foundation] Create run-drift-experiment.sh (multi-run orchestrator)
  - **Description**: Create `.specfarm/bin/run-drift-experiment.sh` - orchestrates all 15 runs:
    1. Accept parameters: --arm (specific arm or "all"), --parallel (parallelism level), --sequential, --dry-run
    2. If --arm specified: run only that arm (5 runs)
    3. If --parallel N: execute N runs concurrently using xargs/gnu-parallel
    4. If --sequential: run all 15 runs serially
    5. After each run completes, print status (✅ or ❌)
    6. Call analysis script after all runs complete (if not --dry-run)
  - **Output**: `.specfarm/bin/run-drift-experiment.sh` created (200+ lines)
  - **Validation**: Script is executable; --help works; --dry-run lists 15 runs without executing

- [ ] **T016** [Foundation] Create compute-statistics.py (statistical analysis)
  - **Description**: Create `.specfarm/src/drift/compute_statistics.py` - post-experiment analysis:
    1. Import scipy.stats, json, pathlib
    2. Read all run-report.json files from artifacts/drift-testing/*/run-*/
    3. Group DriftScore values by arm
    4. For each arm: compute mean, SEM, 95% CI
    5. Perform Welch's t-test between control and treatment
    6. Compute percentage reduction: (control_mean - treatment_mean) / control_mean * 100%
    7. Output JSON with all statistics
  - **Output**: `.specfarm/src/drift/compute_statistics.py` created (150+ lines)
  - **Validation**: Python syntax passes; can parse sample run-report.json files; outputs valid JSON

- [ ] **T017** [Foundation] Create generate-analysis-report.sh (human-readable report)
  - **Description**: Create `.specfarm/src/drift/generate_analysis_report.sh` - creates markdown summary:
    1. Read statistics.json
    2. Generate markdown with:
       - Mean DriftScore per arm (with ±SEM)
       - 95% CI ranges per arm
       - Welch's t-test p-value
       - Percentage reduction: treatment vs control
       - Pass/fail for each success criterion (SC-001, SC-002, SC-003, SC-004)
       - Interpretation guide
    3. Output to artifacts/drift-testing/analysis/analysis-report.md
  - **Output**: `.specfarm/src/drift/generate_analysis_report.sh` created (200+ lines)
  - **Validation**: Produces valid markdown; reads statistics.json successfully

- [ ] **T018** [Foundation] Update agent context
  - **Description**: Run `.specify/scripts/bash/update-agent-context.sh copilot` to register:
    - New scripts in `.specfarm/bin/run-*.sh`
    - Output directory `artifacts/drift-testing/`
    - DriftScore formula documentation
    - Key concepts (experiment arms, metrics, success criteria)
  - **Output**: Agent context file updated (platform-specific: `.copilot/agent-context.md` or equivalent)
  - **Validation**: Agent context file exists and contains references to drift-testing feature

**Gate**: All T011-T018 must complete and pass validation before Phase 3 (user story) tasks begin

---

## Phase 3: User Story 1 - Quantify Drift via Controlled Experiment (Priority: P1) 🎯 MVP

**Goal**: Single run per arm executes successfully, producing all required artifacts and valid DriftScore

**Independent Test**: Run baseline arm 1 time; verify run-report.json contains DriftScore, all artifacts present

### Tests for US1

- [ ] **T019** [P] [US1] Unit test: DriftScore formula
  - **File**: `.specfarm/src/experiment/test_drift_score_formula.py`
  - **Tests**:
    - `test_drift_score_formula_max_accuracy()`: If all metrics = 1.0, DriftScore = 0.0
    - `test_drift_score_formula_min_accuracy()`: If all metrics = 0.0, DriftScore = 1.0
    - `test_drift_score_formula_weights()`: Verify correct weight application (50%, 30%, 20%)
    - `test_rule_count_normalization()`: RuleCount=2000 → norm=1.0; RuleCount=1000 → norm=0.5
  - **Run**: `python -m pytest test_drift_score_formula.py -v`
  - **Validation**: All 4 tests pass

- [ ] **T020** [P] [US1] Unit test: SemanticSimilarity calculation
  - **File**: `.specfarm/src/experiment/test_semantic_similarity.py`
  - **Tests**:
    - `test_identical_rules_similarity_1_0()`: Same rule text → 1.0
    - `test_completely_different_rules_similarity_0_0()`: No overlap → 0.0
    - `test_partial_overlap()`: Token overlap → [0.0-1.0]
  - **Run**: `python -m pytest test_semantic_similarity.py -v`
  - **Validation**: All tests pass using algorithm from research.md

- [ ] **T021** [P] [US1] Unit test: Evidence accuracy calculation
  - **File**: `.specfarm/src/experiment/test_evidence_accuracy.py`
  - **Tests**:
    - `test_all_rules_found_accuracy_1_0()`: All rule signatures in codebase → 1.0
    - `test_no_rules_found_accuracy_0_0()`: No signatures match → 0.0
    - `test_partial_evidence_accuracy()`: Some rules found → [0.0-1.0]
  - **Run**: `python -m pytest test_evidence_accuracy.py -v`
  - **Validation**: All tests pass; algorithm matches drift_analytics.sh logic

- [ ] **T022** [US1] Integration test: Single baseline run
  - **File**: `.specfarm/src/experiment/test_single_baseline_run.py`
  - **Test**: `test_baseline_run_produces_all_artifacts()`
    1. Call `run-single-drift-run.sh --arm baseline --run-number 1 --dry-run`
    2. Verify run-report.json exists and is valid JSON
    3. Verify all 5 required artifact files exist (logs.txt, gathered-rules.md, agent-config.json, git-ref.txt, run-report.json)
    4. Verify run-report.json matches run-report-schema.json
    5. Verify DriftScore ∈ [0.0-1.0]
  - **Run**: `python -m pytest test_single_baseline_run.py::test_baseline_run_produces_all_artifacts -v`
  - **Validation**: Test passes

### Implementation for US1

- [ ] **T023** [US1] Implement: DriftScore calculator tests pass (depends on T019-T021)
  - **Validation**: `python -m pytest .specfarm/src/experiment/test_*.py -v` → all pass

- [ ] **T024** [US1] Implement: Single baseline run
  - **Command**: `.specfarm/bin/run-single-drift-run.sh --arm baseline --run-number 1`
  - **Expected Output**:
    - Artifacts created in `artifacts/drift-testing/baseline/run-1/`
    - run-report.json contains valid DriftScore
    - logs.txt shows successful rule extraction
    - gathered-rules.md non-empty (at least 1 rule)
  - **Validation**: All 5 artifact files exist; run-report.json valid; can manually verify logs.txt

- [ ] **T025** [US1] Implement: Verify artifact contract
  - **Validation**: 
    - Run `jsonschema validate --schema contracts/run-report-schema.json artifacts/drift-testing/baseline/run-1/run-report.json` → passes
    - Verify artifact layout matches `contracts/artifact-layout-spec.md`
    - No extra files in run directory (only 5 required files)

**Checkpoint**: User Story 1 complete - single baseline run is fully functional and testable independently ✅

---

## Phase 4: User Story 2 - Multi-Arm Orchestration (Priority: P2)

**Goal**: All 15 runs (3 arms × 5 runs each) execute successfully with consistent metrics and valid statistics

**Independent Test**: Run full experiment; verify 15 run directories created with valid run-report.json in each

### Tests for US2

- [ ] **T026** [P] [US2] Integration test: Clone strategy
  - **File**: `.specfarm/src/experiment/test_clone_strategy.py`
  - **Test**: `test_fresh_clone_isolation()`
    1. Create two runs with different rules fixtures (baseline vs control)
    2. Verify each has different rule counts
    3. Verify no cross-contamination of state
  - **Validation**: Test passes

- [ ] **T027** [P] [US2] Integration test: Multi-run consistency
  - **File**: `.specfarm/src/experiment/test_multirun_consistency.py`
  - **Test**: `test_two_baseline_runs_have_similar_drift_scores()`
    1. Run baseline arm twice (run-1 and run-2)
    2. Compare DriftScore values
    3. Verify they are within ±10% (expected variance from minor state differences)
  - **Validation**: Test passes

- [ ] **T028** [US2] Integration test: All 15 runs complete
  - **File**: `.specfarm/src/experiment/test_experiment_completion.py`
  - **Test**: `test_all_15_runs_produce_valid_reports()`
    1. Run full experiment: `run-drift-experiment.sh --sequential` (slower but deterministic)
    2. Verify 15 directories created: baseline/run-{1..5}, control/run-{1..5}, treatment/run-{1..5}
    3. For each run, verify run-report.json is valid and matches schema
    4. Verify no errors in any logs.txt
  - **Timeout**: 3 hours
  - **Validation**: Test passes; all 15 reports valid

### Implementation for US2

- [ ] **T029** [US2] Implement: All 15 runs execute
  - **Command**: `.specfarm/bin/run-drift-experiment.sh --sequential`
  - **Expected Output**: 
    - Progress shown every ~10 minutes
    - All 15 artifacts created under artifacts/drift-testing/
    - Final summary: "✅ 15/15 runs completed successfully"
  - **Validation**: Command returns exit code 0; 15 run directories exist

- [ ] **T030** [P] [US2] Implement: Parallel execution support (--parallel flag)
  - **Command**: `.specfarm/bin/run-drift-experiment.sh --parallel 3`
  - **Expected Output**: 
    - 3 runs execute in parallel (via gnu-parallel or xargs)
    - Total time < 1.5 hours (vs 2.5 hours sequential)
  - **Validation**: Command returns exit code 0; timing confirms parallelization

- [ ] **T031** [US2] Implement: Verify no remote pushes
  - **Description**: Add safety check to experiment_harness.sh:
    - Disable git push globally during run via `git config --global receive.deny push`
    - Or detect if any git push attempted and fail the run
  - **Validation**: Run experiment; verify no pushes to remote (check git log --all)

**Checkpoint**: User Story 2 complete - full experiment orchestration works independently ✅

---

## Phase 5: User Story 3 - Statistical Analysis and Success Criteria (Priority: P3)

**Goal**: Analyze results from all 15 runs; compute statistics; validate all success criteria (SC-001 through SC-004)

**Independent Test**: Run analysis script; verify statistics.json contains mean, CI, p-value; manually verify success criteria

### Tests for US3

- [ ] **T032** [P] [US3] Unit test: Welch's t-test computation
  - **File**: `.specfarm/src/experiment/test_statistics_welchs_ttest.py`
  - **Test**: `test_welchs_ttest_with_sample_data()`
    1. Create sample DriftScore arrays (baseline: [0.5, 0.52, 0.48, 0.51, 0.49], control: [0.45, 0.47, 0.43, 0.46, 0.44])
    2. Call Welch's t-test via scipy
    3. Verify p-value is computed correctly
    4. Verify p-value ∈ (0.0-1.0)
  - **Validation**: Test passes; p-value matches manual scipy call

- [ ] **T033** [P] [US3] Unit test: Confidence interval calculation
  - **File**: `.specfarm/src/experiment/test_statistics_ci.py`
  - **Tests**:
    - `test_95_ci_calculation()`: Verify 95% CI around mean
    - `test_ci_width_for_small_n()`: CI wider for N=5 than N=100
  - **Validation**: Tests pass; CI calculation matches scipy.stats

- [ ] **T034** [US3] Integration test: Full analysis pipeline
  - **File**: `.specfarm/src/experiment/test_analysis_pipeline.py`
  - **Test**: `test_analyze_15_runs_produces_statistics()`
    1. Assume 15 valid run-report.json files already exist (from US2)
    2. Run analysis script: `python compute_statistics.py`
    3. Verify statistics.json created with all required fields:
       - baseline: {mean, sem, ci_lower, ci_upper, n}
       - control: {mean, sem, ci_lower, ci_upper, n}
       - treatment: {mean, sem, ci_lower, ci_upper, n}
       - welchs_ttest: {t_statistic, p_value, df}
       - percentage_reduction: float
    4. Verify analysis-report.md generated and is non-empty markdown
  - **Validation**: Test passes; both JSON and markdown readable

- [ ] **T035** [US3] Manual test: Success criteria validation
  - **Description**: After all 15 runs and analysis complete, manually verify:
    - **SC-001**: Treatment reduces mean DriftScore by ≥20% vs Control
      - Check: `(control_mean - treatment_mean) / control_mean * 100% >= 20.0`
    - **SC-002**: Mean EvidenceAccuracy in Treatment ≥ 0.95
      - Check: Average `evidence_accuracy` value from all treatment runs ≥ 0.95
    - **SC-003**: Control vs Treatment p-value < 0.05
      - Check: Welch's t-test p-value < 0.05 in statistics.json
    - **SC-004**: 100% of 15 runs produce valid run-report.json and logs
      - Check: All 15 run directories have valid run-report.json; no "failed" status
  - **Validation**: Manual checklist completed; document result in SPECKIT_DONE_TASKS.md

### Implementation for US3

- [ ] **T036** [US3] Implement: Statistical analysis script
  - **Output**: `artifacts/drift-testing/analysis/statistics.json` created with all required fields
  - **Validation**: `python -m json.tool statistics.json` succeeds; all fields present

- [ ] **T037** [US3] Implement: Generate analysis report
  - **Output**: `artifacts/drift-testing/analysis/analysis-report.md` created with all success criteria evaluated
  - **Validation**: Markdown renders without errors; human-readable summary clear

- [ ] **T038** [US3] Implement: Success criteria evaluation
  - **Description**: Add to generate_analysis_report.sh:
    - For each success criterion (SC-001 through SC-004):
      - Compute/verify criterion
      - Output ✅ or ❌
      - Explain result (e.g., "SC-001: PASS - Treatment reduced DriftScore by 35% (vs 20% threshold)")
  - **Validation**: analysis-report.md clearly shows pass/fail for all 4 criteria

**Checkpoint**: User Story 3 complete - full analysis and success criteria validation works independently ✅

---

## Phase 6: Testing & Validation (Optional - Include if Tests Requested)

These tasks provide comprehensive testing coverage:

- [ ] **T039** [P] [Testing] Unit test suite execution
  - **Command**: `python -m pytest .specfarm/src/experiment/test_*.py -v --tb=short`
  - **Expected**: All tests pass (T019-T021, T032-T034)
  - **Coverage Target**: > 80% of drift_score_calculator.py and compute_statistics.py

- [ ] **T040** [Testing] Integration test: Experiment harness
  - **File**: `.specfarm/src/experiment/test_harness_integration.py`
  - **Test**: `test_experiment_harness_with_all_arms()`
    1. For each arm (baseline, control, treatment):
       2. Call experiment_harness.sh
       3. Verify artifacts created
       4. Verify DriftScore computed
  - **Validation**: All 3 arms tested; all pass

- [ ] **T041** [Testing] E2E test: Full experiment
  - **File**: `.specfarm/src/experiment/test_experiment_e2e.py`
  - **Test**: `test_full_experiment_sequential()`
    1. Run full experiment: `run-drift-experiment.sh --sequential`
    2. Verify all 15 runs complete
    3. Run analysis: `python compute_statistics.py`
    4. Verify statistics and report generated
    5. Verify success criteria evaluated
  - **Timeout**: 3 hours
  - **Validation**: Full test passes end-to-end

- [ ] **T042** [Testing] Performance test: Single run timing
  - **File**: `.specfarm/src/experiment/test_performance.py`
  - **Test**: `test_single_run_completes_within_10_minutes()`
    1. Time a single baseline run
    2. Verify completion < 10 minutes
  - **Validation**: Single run < 600 seconds

- [ ] **T043** [Testing] Manual audit: Evidence accuracy
  - **Description**: For one completed run (e.g., baseline/run-1):
    1. Read artifacts/drift-testing/baseline/run-1/gathered-rules.md
    2. Count rules manually
    3. Spot-check 5 random rules: verify signatures match codebase
    4. Compare manual count to run-report.json evidence_accuracy value
    5. Document findings
  - **Output**: Manual audit report (markdown)
  - **Validation**: Manual count within ±5% of reported EvidenceAccuracy

**Checkpoint**: All tests passing; manual audit complete ✅

---

## Phase 7: Documentation & Polish

These tasks finalize deliverables:

- [ ] **T044** [P] [Polish] Update SPECIFICATION_README.md
  - **Description**: Add section under "Experiments" explaining Constitutional Drift Testing feature:
    - What it measures
    - How to run it
    - Where to find results
  - **Validation**: README updated; links to quickstart.md work

- [ ] **T045** [P] [Polish] Create experiment CLI documentation
  - **File**: `.specfarm/bin/README.md` or `.specfarm/README.md`
  - **Content**: Usage for all three scripts:
    - `run-drift-experiment.sh --help`
    - `run-single-drift-run.sh --help`
    - Examples of common workflows
  - **Validation**: Documentation clear; examples copy-pasteable

- [ ] **T046** [P] [Polish] Add inline comments to shell scripts
  - **Description**: Ensure all new shell scripts have:
    - File-level header explaining purpose
    - Function-level comments explaining inputs/outputs
    - Inline comments for complex logic
  - **Files**: 
    - `.specfarm/bin/run-drift-experiment.sh`
    - `.specfarm/bin/run-single-drift-run.sh`
    - `.specfarm/src/drift/experiment_harness.sh`
    - `.specfarm/src/drift/generate_analysis_report.sh`
  - **Validation**: Shellcheck passes; comments are present

- [ ] **T047** [Polish] Final validation checklist
  - **Description**: Before marking complete, verify:
    - [ ] All Phase 0 research.md complete (T000-T004)
    - [ ] All Phase 1 design documents exist (T005-T010)
    - [ ] All Phase 2 foundation scripts created and tested (T011-T018)
    - [ ] All Phase 3 US1 tests pass (T019-T025)
    - [ ] All Phase 4 US2 tests pass (T026-T031)
    - [ ] All Phase 5 US3 tests pass (T032-T038)
    - [ ] All Phase 6 tests passing (T039-T043)
    - [ ] Documentation complete (T044-T046)
    - [ ] No breaking changes to existing drift_engine or drift_analytics
    - [ ] All new code passes shellcheck (bash) and pylint/black (Python)
    - [ ] Commit message references spec-013
  - **Output**: SPECKIT_DONE_TASKS.md updated with completion date
  - **Validation**: Checklist 100% complete

**Checkpoint**: Feature complete and ready for review ✅

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 0 (Research)**: No dependencies - start immediately
  - **Blocks**: Phase 1 - all research questions must be answered before design

- **Phase 1 (Setup)**: Depends on Phase 0 completion
  - **Blocks**: Phase 2 - all fixtures and templates must exist

- **Phase 2 (Foundation)**: Depends on Phase 1 completion
  - **Blocks**: Phase 3 - core orchestration must be ready

- **Phase 3 (US1)**: Depends on Phase 2 completion
  - **Can proceed in parallel with**: US2/US3 (if separate team members)
  - **Must complete before**: Phase 5 (need test infrastructure first)

- **Phase 4 (US2)**: Depends on Phase 3 completion (reuses US1 infrastructure)
  - **Can proceed in parallel with**: Phase 5 (separate test runs)

- **Phase 5 (US3)**: Depends on Phase 4 completion (needs 15 runs to analyze)

- **Phase 6 (Testing)**: Depends on all of Phase 3-5
  - **Optional**: Can skip if time-constrained; Phase 6 tests validate Phase 3-5 work

- **Phase 7 (Polish)**: Depends on Phase 6 (all features tested before documenting)

### Task Dependencies Within Phases

**Phase 0**:
- T000-T004 independent (can parallelize)

**Phase 1**:
- T005-T007 independent (create directories and basic fixtures)
- T008 depends on T007 (needs control rules to inject constitutional core)
- T009-T010 independent

**Phase 2**:
- T011 (experiment_harness.sh) independent
- T012 (drift_score_calculator.py) independent from T011
- T013 (conftest.py) independent
- T014 (run-single-drift-run.sh) depends on T011, T012
- T015 (run-drift-experiment.sh) depends on T014
- T016 (compute_statistics.py) independent
- T017 (generate_analysis_report.sh) depends on T016
- T018 (update agent context) depends on T014, T015 (need scripts to exist)

**Phase 3 (US1)**:
- T019-T021 (unit tests) independent, run first
- T022 (integration test) depends on T019-T021 (tests must pass)
- T023-T025 (implementation) depends on T022 (test must exist)

**Phase 4 (US2)**:
- T026-T028 (integration tests) independent
- T029-T031 (implementation) depends on T026-T028 (tests must exist)

**Phase 5 (US3)**:
- T032-T034 (tests) independent from implementation
- T035 (manual test) depends on T029-T031 (need 15 completed runs)
- T036-T038 (implementation) depends on T035 (manual test validates criteria)

### Parallel Opportunities

**Within Phase 1**:
- T005, T006, T009, T010 can run in parallel (different files)

**Within Phase 2**:
- T011, T012, T013, T016 can run in parallel (independent components)
- T014, T017, T018 depend on earlier tasks but can start once their dependencies ready

**Within Phase 3**:
- T019, T020, T021 can run in parallel (independent unit tests)
- Once T019-T021 pass, T022-T025 can proceed

**Within Phase 4**:
- T026, T027, T028 can run in parallel (independent integration tests)

**Across Phases 3-5**:
- After Phase 2 completes, US1, US2, US3 can be implemented by separate team members if available
- US1 must complete before US2 (dependency: US1 infrastructure used by US2)
- US2 must complete before US3 (dependency: need 15 runs to analyze)

### Fastest Sequential Path

1. Complete Phase 0 (research): ~1 day
2. Complete Phase 1 (setup): ~2 hours
3. Complete Phase 2 (foundation): ~8 hours
4. Complete Phase 3 (US1): ~4 hours (includes testing)
5. Complete Phase 4 (US2): ~10 hours (includes 15 runs: 2.5 hours + overhead)
6. Complete Phase 5 (US3): ~4 hours (analysis)
7. Complete Phase 6-7 (testing + polish): ~4 hours

**Total**: ~33 hours of focused work across 1-2 weeks

### Parallel Team Path

With 3 developers (after Phase 2 completes):
- Dev A: US1 (Phase 3) - 4 hours
- Dev B: US2 (Phase 4) - 10 hours (includes experiment runs)
- Dev C: Phase 6 (Testing) - parallel with US1-2

**Faster overall**: ~14 hours wall-clock time (components complete in parallel)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

**Recommended for initial validation**:

1. Complete Phase 0 (research)
2. Complete Phase 1 (setup)
3. Complete Phase 2 (foundation)
4. Complete Phase 3 (US1) - single baseline run validated
5. **STOP and VALIDATE**: Manual audit of baseline/run-1 artifacts
6. Decide whether to proceed to multi-arm experiment (Phase 4-5)

**Time to MVP**: ~14 hours

### Incremental Delivery

1. Phases 0-2: Foundation ready
2. Phase 3 (US1): Single run works ✅ Demo to stakeholders
3. Phase 4 (US2): Multi-run orchestration ✅ Full experiment works
4. Phase 5 (US3): Statistical analysis ✅ Success criteria validated

**Each phase is independently deliverable and testable**

### Risk Mitigation Tasks (Priority)

If any of these become blockers, address immediately:
- T000 (Constitutional injection): Critical - test locally before any automation
- T008 (Treatment fixture): Critical - validate XML before T024
- T011 (experiment_harness): Critical - core orchestration logic
- T028 (All 15 runs test): Critical - validates end-to-end before claiming success

---

## Notes

- [P] tasks = different files, no explicit dependencies (can parallelize)
- All paths are absolute from repository root
- Each task includes validation criteria (how to verify completion)
- Phase gates ensure prerequisites completed before advancing
- Tests are written FIRST (T019-T021, T026-T028, T032-T034) before implementation
- Manual validation required (T035, T043) - cannot be fully automated
- Documentation (T044-T047) ensures future maintainers understand feature
- Commits should be grouped logically (e.g., one commit per phase or per task group)

---

## Exit Criteria (Feature Complete)

The feature is considered COMPLETE when:

- ✅ All Phase 0 tasks (T000-T004) complete with research.md output
- ✅ All Phase 1 tasks (T005-T010) complete with design documents
- ✅ All Phase 2 tasks (T011-T018) complete with core scripts
- ✅ All Phase 3 tasks (T019-T025) complete with US1 validated
- ✅ All Phase 4 tasks (T026-T031) complete with 15 runs successful
- ✅ All Phase 5 tasks (T032-T038) complete with success criteria evaluated
- ✅ Phase 6 tasks (T039-T043) all pass (if tests requested)
- ✅ Phase 7 tasks (T044-T047) complete with documentation
- ✅ Zero violations of project Constitution (verified against plan.md)
- ✅ All new code passes shellcheck (bash) and pylint (Python)
- ✅ SPECKIT_DONE_TASKS.md updated with feature completion date and sign-off

---

## Questions / Unknowns Requiring Clarification

If any of these arise during implementation, escalate immediately:

1. **Constitutional core format**: Does injected core need to match specific XML schema? (Addressed in T000 research)
2. **Agent version tracking**: How to capture/store SpecFarm version during run? (Add to T011 artifact collection)
3. **Evidence accuracy ground truth**: Are there test cases or manual audits available to validate our algorithm? (T043 manual audit addresses)
4. **Parallel git clone strategy**: Should we use shallow clones to save space? (Addressed in T004 research)
5. **Test environment**: Can full experiment run locally or requires CI infrastructure? (Clarify in T022 setup)

---

## Appendix: Task ID Mapping

| Phase | ID Range | Description |
|-------|----------|-------------|
| 0 | T000-T004 | Research (5 tasks) |
| 1 | T005-T010 | Setup (6 tasks) |
| 2 | T011-T018 | Foundation (8 tasks) |
| 3 | T019-T025 | User Story 1 (7 tasks) |
| 4 | T026-T031 | User Story 2 (6 tasks) |
| 5 | T032-T038 | User Story 3 (7 tasks) |
| 6 | T039-T043 | Testing (5 tasks) |
| 7 | T044-T047 | Polish (4 tasks) |
| **Total** | **47 tasks** | |

