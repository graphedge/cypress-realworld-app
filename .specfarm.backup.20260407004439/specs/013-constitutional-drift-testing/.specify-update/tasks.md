# Tasks: Constitutional Drift Testing Spec Updates (Distribution, Troubleshooting, & Analysis Integration)

**Input**: Design documents from `specs/013-constitutional-drift-testing/`, analysis-report.json from experiment runs  
**Prerequisites**: plan.md (required), spec.md (current), COPY_TO_OTHER_REPO.md (source), EXPERIMENT_QUICKSTART.md (reference), analysis-report.json (external: cypress-realworld-app/.specfarm/specs/013-constitutional-drift-testing/artifacts/analysis-report.json)

**Tests**: No automated tests required (documentation-only changes). Verification via manual review and internal link validation. Analysis-driven tasks require traceability to report findings.

**Organization**: Tasks are grouped by implementation phase. New Phase 6 added for analysis-driven improvements based on experiment report.

## Format: `[ID] [P?] [Phase] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Phase]**: Which implementation phase this task belongs to (P0, P1, P2, P3, P4, P5)
- Include exact file paths in descriptions

---

## Phase 0: Analysis (Read-Only Preparation)

**Purpose**: Load all source documents and identify content to extract

### Task: T001 - Read and analyze source documents

**Description**: Review spec.md (current state), trblshoot2.md (5 bugs + diagnostics), and COPY_TO_OTHER_REPO.md (installation steps) to identify gaps and content to integrate.

**Risk Level**: LOW

**Files Modified/Created**:
- None (read-only analysis)

**Test Coverage Plan**:
- **Test Files**: N/A (documentation review)
- **Test Harness**: Manual validation
- **Success Criteria**: 
  - Analyst can list 3 source files + their key sections
  - Gap analysis identifies: 1 missing user story, 3 missing FRs, 4 missing VRs, 2 missing SCs

**Acceptance Criteria**:
- [x] spec.md reviewed (2 user stories, 7 FRs, 4 SCs verified)
- [x] COPY_TO_OTHER_REPO.md reviewed (5-step installation procedure confirmed)
- [x] EXPERIMENT_QUICKSTART.md reviewed (quickstart steps documented)
- [x] Identified gaps: User Story 3, FR-008..011, VR-001..004, SC-005..008 all present in spec.md
- [x] Constitution checkpoint: Principle IV (Documentation clarity)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt (N/A for read-only)
- [ ] Pass rate drops below 50% → escalate (N/A)
- [ ] Scope variance > 15% → audit (if analysis takes > 20 minutes)

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/{spec.md,trblshoot2.md,COPY_TO_OTHER_REPO.md}`
- Dependencies: None
- Constitution refs: Principle IV (Documentation)

**Estimated Confidence**: 98% (straightforward document review)

---

## Phase 1: User Story & Requirements Updates

**Purpose**: Add User Story 3 and new requirements to spec.md

### Task: T002 - Add User Story 3 (Copy and Run Experiment in Another Repo)

**Description**: Insert User Story 3 after existing User Story 2 (line ~44) in spec.md. Model structure after existing user stories. Extract acceptance scenarios from COPY_TO_OTHER_REPO.md steps 1-5.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: insert after line ~44)

**Test Coverage Plan**:
- **Test Files**: N/A (documentation)
- **Test Harness**: Manual review
- **Success Criteria**: 
  - User Story 3 has priority (P2), "Why this priority", "Independent Test", and 3+ acceptance scenarios
  - Acceptance scenarios map to COPY_TO_OTHER_REPO.md steps 1-5

**Acceptance Criteria**:
- [ ] User Story 3 added with title: "Copy and Run Experiment in Another Repository (Priority: P2)"
- [ ] "Why this priority" explains distribution enables external validation
- [ ] "Independent Test" describes: "Install in fresh repo, run 1 baseline run, verify run-report.json"
- [ ] Acceptance scenario 1: "Given experiment files, When copied via install script, Then install completes in < 5 minutes"
- [ ] Acceptance scenario 2: "Given installed experiment, When verification run executed, Then results match expected format in < 30 minutes"
- [ ] Acceptance scenario 3: "Given copied experiment, When dependencies validated, Then all prerequisites detected before execution"
- [ ] Scope variance ≤ ±15% (should take ~20 minutes)
- [ ] Constitution checkpoint: Principle I (CLI-centric distribution)
- [ ] Cross-reference to COPY_TO_OTHER_REPO.md added

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (insert after line ~44)
- Dependencies: T001 (analysis)
- Constitution refs: Principle I (CLI-Centric), Principle IV (Documentation)
- Template reference: Existing User Story 1 and 2 structure in spec.md

**Estimated Confidence**: 95%

---

### Task: T003 [P] - Add FR-008, FR-009, FR-010 (Distribution Requirements)

**Description**: Add three new functional requirements to the "Functional Requirements" section (after FR-007, line ~56). Extract content from COPY_TO_OTHER_REPO.md assumptions and steps.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: insert after line ~56)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual review
- **Success Criteria**: 
  - 3 new FRs added with clear MUST statements
  - Each FR maps to COPY_TO_OTHER_REPO.md content

**Acceptance Criteria**:
- [ ] FR-008 added: "System MUST provide a single-script installation procedure (run_full_experiment.sh template)"
- [ ] FR-009 added: "System MUST validate all dependencies (SpecFarm .specfarm/ structure, git, Python3) before running experiment"
- [ ] FR-010 added: "System MUST verify installation integrity after copy (fixture files present, scripts executable)"
- [ ] Each FR cross-references COPY_TO_OTHER_REPO.md section (e.g., "Step 2" or "Key Assumptions")
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle I (CLI-centric)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (insert after line ~56)
- Dependencies: T001 (analysis)
- Constitution refs: Principle I (CLI-Centric)
- Source: COPY_TO_OTHER_REPO.md lines 22-36 (Step 2), lines 142-152 (Assumptions)

**Estimated Confidence**: 95%

---

### Task: T004 - Add Verification Requirements section (VR-001..VR-004)

**Description**: Create new subsection "Verification Requirements" under "Requirements" section (after Functional Requirements, before "Key Entities"). Extract content from trblshoot2.md diagnostic procedures (Checks 1-4, lines 259-329).

**Risk Level**: MEDIUM

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: insert new subsection after line ~56)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual review
- **Success Criteria**: 
  - New subsection created with 4 verification requirements
  - Each VR maps to specific diagnostic check in trblshoot2.md

**Acceptance Criteria**:
- [ ] New subsection "### Verification Requirements" added after Functional Requirements
- [ ] VR-001: "All run-report.json files MUST pass JSON validation (jq empty)" → References trblshoot2.md Check 1 (line 260)
- [ ] VR-002: "Metrics MUST show variance across runs (no identical DriftScore values)" → References trblshoot2.md Check 2 (line 280)
- [ ] VR-003: "Rule counts MUST match fixture XML `<rule>` tag counts" → References trblshoot2.md Check 3 (line 300)
- [ ] VR-004: "Analytics output MUST not crash on numpy type serialization" → References trblshoot2.md Issue #5 (line 202)
- [ ] Each VR includes example validation command (copied from trblshoot2.md)
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)
- [ ] Cross-platform validation: N/A (bash commands only)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (new subsection after line ~56)
- Dependencies: T001 (analysis)
- Constitution refs: Principle IV (Documentation)
- Source: trblshoot2.md lines 259-329 (Checks 1-4), line 202 (Issue #5)

**Estimated Confidence**: 85% (requires careful cross-referencing)

---

### Task: T005 - Update Success Criteria with SC-005 and SC-006

**Description**: Add two new success criteria to the "Success Criteria" section (after SC-004, line ~71). SC-005 for distribution speed, SC-006 for integrity checks.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: insert after line ~71)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual review
- **Success Criteria**: 
  - 2 new SCs added with measurable outcomes
  - SC-005 references < 30 minutes target from COPY_TO_OTHER_REPO.md

**Acceptance Criteria**:
- [ ] SC-005 added: "Experiment can be copied to another repo and verified (1 baseline run) in < 30 minutes total time"
- [ ] SC-006 added: "100% of copied installations pass integrity checks (fixture files present, scripts executable, JSON schemas valid)"
- [ ] SC-005 references User Story 3 acceptance scenario 2
- [ ] SC-006 references Verification Requirements (VR-001, VR-003, VR-004)
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (insert after line ~71)
- Dependencies: T002 (User Story 3), T004 (Verification Requirements)
- Constitution refs: Principle IV (Documentation)
- Source: COPY_TO_OTHER_REPO.md (30-minute target implicit in "Quick Reference" title)

**Estimated Confidence**: 95%

---

## Phase 2: Troubleshooting Integration

**Purpose**: Add "Known Issues & Troubleshooting" section to spec.md

### Task: T006 - Add Known Issues & Troubleshooting section

**Description**: Create new top-level section after "Execution Runbook" (line ~96) that summarizes the 5 critical bugs from trblshoot2.md (Issues #1-#5) and references diagnostic procedures.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: insert new section after line ~96)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual review
- **Success Criteria**: 
  - New section created with 5 bug summaries + 4 diagnostic procedure references
  - All references to trblshoot2.md sections are valid

**Acceptance Criteria**:
- [ ] New section "## Known Issues & Troubleshooting" added after "Execution Runbook"
- [ ] Introduction paragraph: "This experiment framework has identified and resolved 5 critical bugs during Runs 1-2. See `trblshoot2.md` for authoritative troubleshooting reference."
- [ ] Subsection "### Critical Bugs Fixed" with 5 entries:
  - Issue #1: Variable Scope Bug in Rule Count (trblshoot2.md line 24)
  - Issue #2: JSON Formatting with Trailing Newlines (trblshoot2.md line 63)
  - Issue #3: Identical Metrics Across Runs (RNG seeding) (trblshoot2.md line 105)
  - Issue #4: Rule Count Source Inconsistency (trblshoot2.md line 154)
  - Issue #5: Python JSON Serialization of NumPy Types (trblshoot2.md line 202)
- [ ] Each bug entry includes: symptom, root cause (1 sentence), fix applied (1 sentence), reference to trblshoot2.md section
- [ ] Subsection "### Diagnostic Procedures" with references to trblshoot2.md Checks 1-4 (lines 259-329)
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (insert after line ~96)
- Dependencies: T001 (analysis)
- Constitution refs: Principle IV (Documentation)
- Source: trblshoot2.md lines 24-255 (Issues #1-#5), lines 259-329 (Checks 1-4)

**Estimated Confidence**: 90%

---

## Phase 3: Data Model Creation

**Purpose**: Create data-model.md with entity definitions, formulas, and JSON schemas

### Task: T007 - Create data-model.md (Entities and Metrics)

**Description**: Create new file `specs/013-constitutional-drift-testing/data-model.md` with entity definitions (Experiment Arm, Run Report, Run Artifacts, DriftScore) and metric formulas extracted from spec.md and trblshoot2.md.

**Risk Level**: MEDIUM

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/data-model.md` (create)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual review
- **Success Criteria**: 
  - 4 entities defined with attributes and validation rules
  - All formulas match existing spec.md content

**Acceptance Criteria**:
- [ ] File created: `specs/013-constitutional-drift-testing/data-model.md`
- [ ] Header: "# Data Model: Constitutional Drift Testing" with metadata (Date, Version)
- [ ] Entity: **Experiment Arm**
  - Attributes: `arm_name` (Baseline | Control | Treatment), `fixture_file` (path), `rule_count` (integer)
  - Validation: `rule_count` matches `grep -c '<rule ' fixture_file`
  - Source: spec.md lines 77-80, trblshoot2.md lines 180-186
- [ ] Entity: **Run Report**
  - Attributes: `run_id` (integer 1-5), `arm` (string), `DriftScore` (float 0.0-1.0), `EvidenceAccuracy` (float 0.0-1.0), `SemanticSimilarity` (float 0.0-1.0), `RuleCount` (integer), `timestamp` (ISO 8601)
  - Validation: All floats in range [0.0, 1.0], JSON structure valid
  - JSON Schema: Embedded in data-model.md
  - Source: spec.md lines 60-62, trblshoot2.md lines 260-275
- [ ] Entity: **Run Artifacts**
  - Attributes: `artifact_dir` (path), `run_report_json` (file), `gathered_rules_md` (file), `agent_config_json` (file), `logs_txt` (file)
  - Validation: All files present, run_report.json passes `jq empty`
  - Directory structure diagram included
  - Source: spec.md line 96, COPY_TO_OTHER_REPO.md lines 116-134
- [ ] Entity: **DriftScore**
  - Formula: `DriftScore = 0.50 * (1.0 - EvidenceAccuracy) + 0.30 * (1.0 - SemanticSimilarity) + 0.20 * RuleCountNorm`
  - Component: `RuleCountNorm = min(RuleCount / 2000, 1.0)`
  - Validation: Result in range [0.0, 1.0]
  - Source: spec.md lines 82-84
- [ ] Subsection: "### Metric Definitions" with EvidenceAccuracy, SemanticSimilarity, RuleCountNorm
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/data-model.md` (create new)
- Dependencies: T001 (analysis), T004 (VR requirements provide validation context)
- Constitution refs: Principle IV (Documentation)
- Source: spec.md lines 60-62, 77-84, 96; trblshoot2.md lines 180-186, 260-275; COPY_TO_OTHER_REPO.md lines 116-134

**Estimated Confidence**: 85% (requires synthesis from 3 sources)

---

### Task: T008 - Add JSON schemas to data-model.md

**Description**: Add JSON schema definitions for `run-report.json` and `analysis-report.json` to data-model.md based on actual artifact structure from trblshoot2.md examples.

**Risk Level**: MEDIUM

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/data-model.md` (modify: add schemas section)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual validation against actual artifacts (if available)
- **Success Criteria**: 
  - 2 JSON schemas provided with required/optional fields
  - Schemas match validation requirements from VR-001, VR-004

**Acceptance Criteria**:
- [ ] Subsection added: "### JSON Schemas"
- [ ] Schema: **run-report.json**
  ```json
  {
    "run_id": "integer (1-5)",
    "arm": "string (baseline | control | treatment)",
    "DriftScore": "float [0.0, 1.0]",
    "EvidenceAccuracy": "float [0.0, 1.0]",
    "SemanticSimilarity": "float [0.0, 1.0]",
    "RuleCount": "integer >= 0",
    "fixture_file": "string (path)",
    "timestamp": "string (ISO 8601)"
  }
  ```
- [ ] Schema: **analysis-report.json**
  ```json
  {
    "arms": {
      "baseline": { "mean": "float", "std": "float", "ci_lower": "float", "ci_upper": "float" },
      "control": { ... },
      "treatment": { ... }
    },
    "statistical_tests": {
      "control_vs_treatment": { "p_value": "float", "significant": "boolean" }
    },
    "success_criteria": {
      "SC-001": "boolean",
      "SC-002": "boolean",
      "SC-003": "boolean",
      "SC-004": "boolean"
    }
  }
  ```
- [ ] Note added: "All numpy types (numpy.float64, numpy.bool_) MUST be cast to Python native types before JSON serialization (see trblshoot2.md Issue #5)"
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/data-model.md` (modify)
- Dependencies: T007 (data-model.md created)
- Constitution refs: Principle IV (Documentation)
- Source: trblshoot2.md lines 202-254 (Issue #5), lines 260-275 (Check 1)

**Estimated Confidence**: 85%

---

## Phase 4: Cross-References & Validation

**Purpose**: Ensure internal consistency and link integrity

### Task: T009 [P] - Add cross-references from spec.md to trblshoot2.md

**Description**: Update spec.md to add internal links from Verification Requirements (VR-001..VR-004) and Known Issues section to specific sections in trblshoot2.md.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: add markdown links)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual link validation (open trblshoot2.md, verify sections exist)
- **Success Criteria**: 
  - All 4 VRs link to corresponding diagnostic checks
  - All 5 bug summaries link to detailed sections

**Acceptance Criteria**:
- [ ] VR-001 links to: `[Check 1 in trblshoot2.md](./trblshoot2.md#check-1-validate-all-run-reportjson-files)`
- [ ] VR-002 links to: `[Check 2 in trblshoot2.md](./trblshoot2.md#check-2-verify-metric-variance)`
- [ ] VR-003 links to: `[Check 3 in trblshoot2.md](./trblshoot2.md#check-3-verify-rule-counts-match-fixtures)`
- [ ] VR-004 links to: `[Issue #5 in trblshoot2.md](./trblshoot2.md#issue-5-python-json-serialization-of-numpy-types-run-2)`
- [ ] Each of 5 bugs in "Known Issues" section links to corresponding `#issue-N` anchor
- [ ] All links verified (anchor names match trblshoot2.md headers)
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (modify existing sections)
- Dependencies: T004 (VR section), T006 (Known Issues section)
- Constitution refs: Principle IV (Documentation)
- Link format: Relative markdown links `[text](./trblshoot2.md#anchor)`

**Estimated Confidence**: 90%

---

### Task: T010 [P] - Add cross-references from spec.md to data-model.md

**Description**: Update spec.md "Key Entities" section (line ~57) to reference data-model.md for detailed definitions and add link in Experimental Design section for DriftScore formula.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: add markdown links)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual link validation
- **Success Criteria**: 
  - "Key Entities" section links to data-model.md
  - DriftScore formula section links to data-model.md

**Acceptance Criteria**:
- [ ] "Key Entities" section (line ~57) updated with: "See [data-model.md](./data-model.md) for detailed entity definitions, validation rules, and JSON schemas."
- [ ] "DriftScore Composite Formula" section (line ~82) updated with: "See [data-model.md](./data-model.md#driftscore) for detailed metric definitions and component calculations."
- [ ] Both links verified (data-model.md exists, anchors valid)
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md` (modify lines ~57, ~82)
- Dependencies: T007 (data-model.md created), T008 (schemas added)
- Constitution refs: Principle IV (Documentation)

**Estimated Confidence**: 95%

---

### Task: T011 - Validate all internal links and section anchors

**Description**: Verify that all markdown links added in T009 and T010 point to valid sections. Open each linked file and confirm anchor/header exists.

**Risk Level**: LOW

**Files Modified/Created**:
- None (validation only)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual inspection
- **Success Criteria**: 
  - 100% of links resolve to valid sections
  - No broken anchors

**Acceptance Criteria**:
- [ ] All links to trblshoot2.md (9 total: 4 VRs + 5 bugs) verified
- [ ] All links to data-model.md (2 total: Key Entities + DriftScore) verified
- [ ] Link to COPY_TO_OTHER_REPO.md in User Story 3 verified
- [ ] All anchors match header IDs (GitHub markdown auto-generates lowercase-with-hyphens IDs)
- [ ] Scope variance ≤ ±15%
- [ ] Constitution checkpoint: Principle IV (Documentation)

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: Open `trblshoot2.md`, `data-model.md`, `COPY_TO_OTHER_REPO.md` for inspection
- Dependencies: T009 (cross-refs to trblshoot2.md), T010 (cross-refs to data-model.md)
- Constitution refs: Principle IV (Documentation)
- Validation method: Manual inspection (open files in markdown viewer, click links)

**Estimated Confidence**: 95%

---

## Phase 5: Final Review

**Purpose**: Confirm no scope creep, zero code changes, all constraints met

### Task: T012 - Final verification and constraint compliance check

**Description**: Review all modified/created files to ensure: (1) Zero code changes to experiment harness or analytics scripts, (2) All existing requirements/user stories preserved, (3) New requirements map to existing implementation, (4) Constitution compliance.

**Risk Level**: LOW

**Files Modified/Created**:
- None (review only)

**Test Coverage Plan**:
- **Test Files**: N/A
- **Test Harness**: Manual checklist verification
- **Success Criteria**: 
  - Zero files outside `specs/013-constitutional-drift-testing/` modified
  - All constraints from plan.md satisfied

**Acceptance Criteria**:
- [ ] Verified: `experiment_harness.sh` NOT modified (no code changes)
- [ ] Verified: `drift_analytics_multiarm.py` NOT modified (no code changes)
- [ ] Verified: `fixtures/rules-*.xml` files NOT modified
- [ ] Verified: All existing requirements (FR-001..FR-007) still present in spec.md
- [ ] Verified: All existing success criteria (SC-001..SC-004) still present
- [ ] Verified: All existing user stories (US1, US2) still present with original acceptance scenarios
- [ ] Verified: New requirements (FR-008..010) map to existing implementation in COPY_TO_OTHER_REPO.md
- [ ] Verified: No new test infrastructure added (documentation-only change)
- [ ] Constitution checkpoint: Principle IV (Documentation), Principle I (CLI-centric)
- [ ] Scope variance ≤ ±15%

**Stop Conditions**:
- [ ] 3× consecutive failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: Review all files in `specs/013-constitutional-drift-testing/`
- Dependencies: All previous tasks (T001-T011)
- Constitution refs: All principles (final compliance check)
- Checklist: Use plan.md "Constraints" section as reference

**Estimated Confidence**: 98%

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 0 (Analysis)**: No dependencies — can start immediately
- **Phase 1 (User Story + Requirements)**: Depends on Phase 0 completion
- **Phase 2 (Troubleshooting)**: Depends on Phase 0 completion — can run in parallel with Phase 1
- **Phase 3 (Data Model)**: Depends on Phase 0 completion — can run in parallel with Phase 1 and 2
- **Phase 4 (Cross-References)**: Depends on Phases 1, 2, 3 completion (all content must exist before linking)
- **Phase 5 (Final Review)**: Depends on all previous phases

### Task Dependencies

- **T001**: No dependencies (read-only analysis)
- **T002, T003, T004, T005**: Depend on T001 (analysis identifies gaps)
- **T002 → T005**: Sequential (T005 references User Story 3 from T002)
- **T004 → T005**: Sequential (T005 references VRs from T004)
- **T006**: Depends on T001 (independent of T002-T005, can run in parallel)
- **T007**: Depends on T001 (independent of T002-T006, can run in parallel)
- **T007 → T008**: Sequential (T008 adds to T007's output)
- **T009**: Depends on T004, T006 (sections must exist before linking)
- **T010**: Depends on T007, T008 (data-model.md must exist)
- **T011**: Depends on T009, T010 (all links must be added before validation)
- **T012**: Depends on all previous tasks (final review)

### Parallel Opportunities

- **After T001**: T002, T003, T006, T007 can all run in parallel (different content areas)
- **T003 and T004**: Can run in parallel (both add to spec.md but different sections)
- **T009 and T010**: Can run in parallel (different link targets)

### Sequential Critical Path

```
T001 (analysis)
  ↓
T002 (User Story 3) → T004 (VR section) → T005 (Success Criteria)
                                              ↓
                                            T009 (links to trblshoot2.md)
                                              ↓
                                            T011 (validate links)
                                              ↓
                                            T012 (final review)

T001 → T007 (data-model.md) → T008 (JSON schemas) → T010 (links to data-model.md) → T011
T001 → T006 (Known Issues) → T009
```

---

## Phase 6: Verification of Completed Fixes & Analysis-Driven Improvements

**Purpose**: Verify all above fixes are correctly implemented and identify new improvement tasks based on experiment analysis

### Task: T013 - [P] Verification Checkpoint: Confirm all Phase 1-5 fixes applied

**Description**: Verify that all specifications from Tasks T001-T012 have been successfully applied to spec.md. Cross-check against the original requirements and trblshoot2.md to ensure complete adoption. This task ensures continuity before analysis-driven improvements.

**Risk Level**: LOW

**Files Modified/Created**:
- None (verification only)

**Test Coverage Plan**:
- **Test Files**: N/A (document verification)
- **Test Harness**: Grep-based validation script
- **Success Criteria**: 
  - All new sections present in spec.md (User Story 3, FR-008..010, VR-001..004, SC-005..008, Known Issues, Distribution)
  - All 5 bugs from trblshoot2.md referenced in spec.md
  - All cross-references to COPY_TO_OTHER_REPO.md intact

**Acceptance Criteria**:
- [x] User Story 3 present with "Copy and Run Experiment in Another Repository" title
- [x] FR-008, FR-009, FR-010, FR-011 all present in spec.md
- [x] VR-001, VR-002, VR-003, VR-004 all present in spec.md
- [x] SC-005, SC-006, SC-007, SC-008 all present in spec.md
- [x] "Known Issues & Troubleshooting" section references EXPERIMENT_QUICKSTART.md
- [x] "Distribution & Installation" section contains COPY_TO_OTHER_REPO.md steps
- [x] No breaking changes to existing requirements
- [x] Constitution checkpoint: Principle IV (Documentation completeness)

**Stop Conditions**:
- [ ] >10% of new content missing → fail verification
- [ ] Cross-references broken → halt and fix

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md`
- Dependencies: T001-T012 (all previous tasks)
- Constitution refs: Principle IV (Documentation)

**Estimated Confidence**: 95%

---

### Task: T014 - [P] Analyze experiment findings and identify root causes (SC-001..004 not met)

**Description**: Analyze `artifacts/analysis-report.json` from experiment runs to understand why success criteria SC-001 through SC-004 were not met. Extract quantitative findings and map to specification gaps or implementation issues. Document findings as input for corrective action tasks.

**Risk Level**: MEDIUM

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/ANALYSIS_FINDINGS.md` (create new)

**Test Coverage Plan**:
- **Test Files**: `analysis-report.json` (input)
- **Test Harness**: Manual analysis + jq validation
- **Success Criteria**: 
  - All 4 failed success criteria analyzed with root cause explanations
  - Statistical findings extracted (p-value, CI, effect sizes, accuracy metrics)
  - Findings mapped to specification requirements

**Acceptance Criteria**:
- [ ] SC-001 (Treatment reduces drift by 20%): Gap documented — 3.35% reduction vs. target 20%
- [ ] SC-002 (Treatment evidence accuracy ≥ 0.95): Gap documented — 0.9049 vs. target 0.95
- [ ] SC-003 (Difference significant at p ≤ 0.05): Gap documented — p=0.904 vs. target ≤0.05
- [ ] SC-004 (All runs complete): SUCCESS — Status TRUE
- [ ] Analysis document created at: `specs/013-constitutional-drift-testing/ANALYSIS_FINDINGS.md`
- [ ] Constitution checkpoint: Principle II (Evidence-based design)

**Stop Conditions**:
- [ ] JSON parsing fails → use `jq empty` to validate report structure
- [ ] Analysis incomplete → block downstream tasks

**Implementation Notes**:
- File paths: 
  - Input: `artifacts/analysis-report.json` (in cypress-realworld-app copy)
  - Output: `specs/013-constitutional-drift-testing/ANALYSIS_FINDINGS.md`
- Dependencies: T013 (verification) — should run after fixes confirmed
- Constitution refs: Principle II (Evidence-based), Principle IV (Documentation)
- Analysis template: Root cause → Gap → Recommendation structure

**Estimated Confidence**: 90%

---

### Task: T015 - [P] Create corrective action tasks for unmet success criteria

**Description**: Based on T014 analysis findings, create new tasks to address why SC-001, SC-002, SC-003 were not met. Recommend design improvements (larger sample size, more aggressive rules, longer runs) and estimate effort. Output as structured task list for future implementation phases.

**Risk Level**: MEDIUM

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/CORRECTIVE_ACTIONS.md` (create new)

**Test Coverage Plan**:
- **Test Files**: `ANALYSIS_FINDINGS.md` (input from T014)
- **Test Harness**: Manual review + cross-reference to spec.md requirements
- **Success Criteria**: 
  - Each unmet criterion has ≥2 recommended actions
  - Actions include effort estimates and risk assessments
  - Actions map to design or implementation changes

**Acceptance Criteria**:
- [ ] Corrective actions documented for each unmet criterion
- [ ] Each action includes effort estimates and risk assessments
- [ ] Actions map to design or implementation changes
- [ ] Document created at: `specs/013-constitutional-drift-testing/CORRECTIVE_ACTIONS.md`
- [ ] Constitution checkpoint: Principle II (Evidence-based), Principle III (Quality over speed)

**Stop Conditions**:
- [ ] Insufficient analysis from T014 → block until complete
- [ ] Recommendations lack effort estimates → audit and rework

**Implementation Notes**:
- File paths: 
  - Input: `ANALYSIS_FINDINGS.md` (from T014)
  - Output: `specs/013-constitutional-drift-testing/CORRECTIVE_ACTIONS.md`
- Dependencies: T014 (analysis must be complete)
- Constitution refs: Principle II (Evidence-based), Principle III (Quality)
- Format: Table with columns: [Unmet SC | Root Cause | Recommended Action | Effort | Risk]

**Estimated Confidence**: 85%

---

### Task: T016 - [P] Update spec.md with analysis insights and recommended improvements

**Description**: Integrate findings from ANALYSIS_FINDINGS.md and CORRECTIVE_ACTIONS.md back into spec.md. Add new section "Experimental Results & Future Iterations" that documents baseline metrics, links to corrective actions, and explains next steps for the project.

**Risk Level**: LOW

**Files Modified/Created**:
- `specs/013-constitutional-drift-testing/spec.md` (modify: add new section)

**Test Coverage Plan**:
- **Test Files**: N/A (documentation update)
- **Test Harness**: Manual cross-reference + link validation
- **Success Criteria**: 
  - New section references both analysis documents
  - Baseline metrics documented with links to analysis-report.json
  - Future iterations roadmap clear and actionable

**Acceptance Criteria**:
- [ ] New section "Experimental Results & Future Iterations" added to spec.md
- [ ] Section includes subsections: Baseline Metrics, Success Criteria Status, Identified Improvements, Roadmap for Phase 2
- [ ] Cross-references added to ANALYSIS_FINDINGS.md and CORRECTIVE_ACTIONS.md
- [ ] Constitution checkpoint: Principle IV (Documentation), Principle II (Evidence-based)

**Stop Conditions**:
- [ ] 3× consecutive edit failure → halt
- [ ] Scope variance > 15% → audit

**Implementation Notes**:
- File paths: `specs/013-constitutional-drift-testing/spec.md`
- Dependencies: T014, T015 (analysis documents must exist)
- Constitution refs: Principle IV (Documentation), Principle II (Evidence)

**Estimated Confidence**: 92%

---

## Phase 6 Dependencies & Execution Order

### Phase 6 Task Sequence

1. **T013**: Verification Checkpoint (0 dependencies, must run first)
2. **T014**: Analyze experiment findings (depends on T013 ✓)
3. **T015**: Create corrective actions (depends on T014 ✓)
4. **T016**: Update spec with insights (depends on T014 + T015 ✓)

### Critical Path
```
T013 (verification)
  ↓
T014 (analysis)
  ↓
├─→ T015 (corrective actions)
│     ↓
└─→ T016 (spec update)
```

All Phase 6 tasks depend on successful completion of Phase 1-5. Recommend running after T012 (final review) is complete and all prior phases verified.

---

## Implementation Strategy (Updated)

### Recommended Execution Order (Serial, Full Workflow)

1. **Phase 0**: T001 (analysis) — 15 minutes
2. **Phase 1**: T002, T003, T004, T005 (spec.md updates) — 1 hour
3. **Phase 2**: T006 (Known Issues section) — 20 minutes
4. **Phase 3**: T007, T008 (data-model.md creation) — 40 minutes
5. **Phase 4**: T009, T010, T011 (cross-references + validation) — 30 minutes
6. **Phase 5**: T012 (final review) — 10 minutes
7. **Phase 6**: T013 (verification) → T014 (analysis) → T015 (corrective actions) → T016 (spec update) — 1.5 hours

**Total Time**: ~4.5 hours (includes analysis and improvements)

### Recommended Execution Order (Serial)
6. **Phase 5**: T012 (final review) — 10 minutes

**Total Time**: ~2 hours 15 minutes

### Recommended Execution Order (Serial)

1. **Phase 0**: T001 (analysis) — 15 minutes
2. **Phase 1**: T002, T003, T004, T005 (spec.md updates) — 1 hour
3. **Phase 2**: T006 (Known Issues section) — 20 minutes
4. **Phase 3**: T007, T008 (data-model.md creation) — 40 minutes
5. **Phase 4**: T009, T010, T011 (cross-references + validation) — 30 minutes
6. **Phase 5**: T012 (final review) — 10 minutes
7. **Phase 6**: T013 (verification) → T014 (analysis) → T015 (corrective actions) → T016 (spec update) — 1.5 hours

**Total Time**: ~4.5 hours (includes analysis and improvements)

### Recommended Execution Order (Parallel, 3 agents)

**Agent 1** (spec.md + verification focus):
1. T001 (analysis)
2. T002, T003, T004, T005 (spec.md updates)
3. T006 (Known Issues)
4. T009 (links to trblshoot2.md)
5. T013 (verification checkpoint)
6. T016 (spec update with analysis insights)
7. Wait for Agent 2 to complete T007, T008
8. T010 (links to data-model.md)
9. T011 (validate all links)
10. T012 (final review)

**Agent 2** (data-model.md focus):
1. Wait for T001 (shared analysis)
2. T007, T008 (create data-model.md with schemas)
3. Signal Agent 1 (data-model.md complete)

**Agent 3** (analysis focus):
1. Wait for T001 (shared analysis)
2. Wait for T013 (verification checkpoint)
3. T014 (analyze experiment findings)
4. T015 (create corrective actions)
5. Signal Agent 1 (ready for T016)

**Total Time**: ~2.5 hours (parallel reduces sequential bottleneck)

### Previous Parallel Plan (2 agents)

---

## Notes

- All tasks are documentation-only (no code changes)
- [P] tasks (T003, T009, T010, T013, T014, T015, T016) can run in parallel if dependencies met
- Each task references specific line numbers from source files for precision
- Stop conditions included per Phase 3B requirements (circuit breaker pattern)
- Commit after Phase 1, Phase 2, Phase 3, Phase 5, and Phase 6 (5 total commits recommended)
- All tasks include constitution checkpoints and scope variance limits (±15%)
- Zero test coverage required (documentation changes validated manually)
- **NEW Phase 6**: Analysis-driven improvements based on experiment results from analysis-report.json
  - T013: Verification checkpoint ensures all prior fixes applied before analysis
  - T014-T016: Extract insights from experimental findings and integrate back into spec.md
  - Links analysis-report.json (baseline metrics) to specification requirements
  - Documents corrective actions for unmet success criteria (SC-001, SC-002, SC-003)
