# Implementation Plan: Constitutional Drift Testing Spec Updates (Distribution & Troubleshooting Integration)

**Branch**: `013-constitutional-drift-testing-spec-updates` | **Date**: 2026-04-07 | **Spec**: `specs/013-constitutional-drift-testing/spec.md`  
**Input**: Feature specification updates to integrate distribution/copying features and troubleshooting insights

## Summary

Update the constitutional drift testing specification (spec.md) to formally document the "copy to another repository" feature currently only described in COPY_TO_OTHER_REPO.md, and integrate diagnostic/troubleshooting procedures from trblshoot2.md as verification requirements. This is a **documentation-only update** with zero code changes to the experiment harness or analytics scripts.

## Technical Context

**Language/Version**: Markdown (documentation only)  
**Primary Dependencies**: None (documentation artifacts)  
**Storage**: Git-tracked markdown files in `specs/013-constitutional-drift-testing/`  
**Testing**: Manual validation of documentation completeness, internal link consistency, no automated tests required  
**Target Platform**: N/A (documentation)  
**Project Type**: Specification documentation update  
**Performance Goals**: N/A  
**Constraints**: 
- MUST NOT modify experiment harness code (experiment_harness.sh, drift_analytics_multiarm.py)
- MUST preserve all existing requirements and user stories
- MUST maintain backward compatibility with existing experiment artifacts
**Scale/Scope**: 5-7 markdown file updates across single specification directory

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Key Gates for This Project**:
- **Constitution II.A (Testing)**: No test automation required (documentation-only changes)
- **Constitution I (CLI-Centric)**: Documentation must reflect CLI-first usage patterns for distribution
- **Constitution IV (Documentation)**: All spec updates must be clear, versioned, and cross-referenced

✅ **Constitution Compliance**: PASS — Documentation updates with zero code changes; no testing infrastructure needed.

## Project Structure

### Documentation (this feature)

```text
specs/013-constitutional-drift-testing/
├── .specify-update/
│   ├── plan.md              # This file
│   └── tasks.md             # Task breakdown (generated separately)
├── spec.md                  # PRIMARY UPDATE TARGET
├── trblshoot2.md            # SOURCE (troubleshooting insights)
├── COPY_TO_OTHER_REPO.md    # SOURCE (distribution procedures)
├── EXPERIMENT_QUICKSTART.md # May need minor updates
├── data-model.md            # TO BE CREATED (entities + metrics)
└── checklists/
    └── requirements.md      # May need updates to reflect new requirements
```

### Source Code (repository root)

**NO CODE CHANGES** — This plan modifies documentation only.

## Architecture Overview

### Current State

The constitutional drift testing feature has:
1. **spec.md**: Original feature specification with 2 user stories (P1: run experiment, P2: artifact review)
2. **COPY_TO_OTHER_REPO.md**: Standalone quick reference for copying experiment to another repo (NOT integrated into main spec)
3. **trblshoot2.md**: Comprehensive troubleshooting guide documenting 5 critical bugs fixed in Runs 1-2, with diagnostic procedures

### Problem

- The "distribution/copy to another repo" capability is documented but **not specified as a formal requirement**
- Diagnostic procedures from trblshoot2.md are **not referenced in success criteria or verification requirements**
- No formal user story for "Install and run experiment in another repository"
- Missing data-model.md to define entities (Run Report, DriftScore, Experiment Arm, etc.)
- Success criteria don't include distribution speed/ease metrics

### Proposed Updates

1. **Add User Story 3** (P2): "Copy and Run Experiment in Another Repository"
   - Acceptance scenarios: copy in < 5 min, verify in < 30 min
   - Independent test: Install in fresh repo, run 1 baseline run

2. **Add Functional Requirements** for distribution:
   - FR-008: System MUST provide a single-script installation procedure
   - FR-009: System MUST validate all dependencies before running experiment
   - FR-010: System MUST verify installation integrity after copy

3. **Add Verification Requirements** section:
   - VR-001: All run-report.json files MUST pass JSON validation
   - VR-002: Metrics MUST show variance across runs (no identical values)
   - VR-003: Rule counts MUST match fixture XML `<rule>` tag counts
   - VR-004: Analytics output MUST not crash on numpy type serialization

4. **Add Known Issues & Troubleshooting** section:
   - Reference trblshoot2.md as authoritative source
   - Summarize the 5 critical bugs and their fixes
   - Link to diagnostic procedures (Checks 1-4)

5. **Update Success Criteria**:
   - SC-005: Experiment can be copied to another repo and verified in < 30 minutes
   - SC-006: 100% of copied installations pass integrity checks

6. **Create data-model.md**:
   - Define: Experiment Arm, Run Report, Run Artifacts, DriftScore
   - Document: Metric formulas, JSON schemas
   - Specify: Artifact directory structure

## Cross-Platform Considerations

**N/A** — Documentation artifacts are platform-agnostic markdown files.

Distribution procedures documented in COPY_TO_OTHER_REPO.md already address bash-only requirements (compatible with macOS, Linux).

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Breaking existing experiment runs | LOW | No code changes; only documentation updates |
| Spec drift from implementation | MEDIUM | Cross-reference all new requirements with existing scripts (experiment_harness.sh, COPY_TO_OTHER_REPO.md) |
| Internal link rot | LOW | Validate all cross-references between spec.md, trblshoot2.md, data-model.md |
| User confusion (multiple sources of truth) | MEDIUM | Clearly designate spec.md as primary source, others as reference guides |
| Missing edge cases | LOW | Leverage trblshoot2.md's lessons learned (5 bugs documented) |

## Verification Plan

After spec updates, verify:

1. **Completeness**: All 3 source documents (spec.md, trblshoot2.md, COPY_TO_OTHER_REPO.md) are cross-referenced
2. **Consistency**: New user story (US3) has acceptance scenarios matching COPY_TO_OTHER_REPO.md steps
3. **Traceability**: Each new requirement (FR-008..FR-010, VR-001..VR-004) maps to specific content in trblshoot2.md or COPY_TO_OTHER_REPO.md
4. **Link Integrity**: All internal references (e.g., "See trblshoot2.md Issue #3") point to valid sections
5. **No Scope Creep**: Confirm zero code changes requested; all updates are documentation-only

## Dependencies & Prerequisites

**Required Reading** (all files exist):
- `specs/013-constitutional-drift-testing/spec.md` (lines 1-97: current spec)
- `specs/013-constitutional-drift-testing/trblshoot2.md` (lines 1-521: troubleshooting guide)
- `specs/013-constitutional-drift-testing/COPY_TO_OTHER_REPO.md` (lines 1-152: copy instructions)
- `specs/013-constitutional-drift-testing/EXPERIMENT_QUICKSTART.md` (existing quickstart)

**Templates**:
- `.specify/templates/spec-template.md` (for consistent formatting)

**Constitutional References**:
- Principle IV: Documentation MUST be clear, versioned, and maintainable
- Principle I: CLI-centric design (distribution via bash scripts)

## Implementation Phases

### Phase 0: Analysis (Read-Only)

**Goal**: Load all source documents and identify gaps

- Review current spec.md structure (user stories, requirements, success criteria)
- Extract all distributable procedures from COPY_TO_OTHER_REPO.md
- Extract all diagnostic procedures from trblshoot2.md
- Map content to new sections (User Story 3, FR-008..010, VR-001..004, SC-005..006)

### Phase 1: User Story & Requirements Updates

**Goal**: Add User Story 3 and functional/verification requirements to spec.md

- Add User Story 3: "Copy and Run Experiment in Another Repository" (after current US2, before Requirements section)
- Add FR-008, FR-009, FR-010 to Functional Requirements section
- Add new "Verification Requirements" subsection with VR-001..VR-004
- Update Success Criteria with SC-005 and SC-006

### Phase 2: Troubleshooting Integration

**Goal**: Add "Known Issues & Troubleshooting" section referencing trblshoot2.md

- Add new top-level section after "Execution Runbook"
- Summarize 5 critical bugs (Issues #1-#5 from trblshoot2.md)
- Reference diagnostic procedures (Checks 1-4)
- Link to trblshoot2.md as authoritative source

### Phase 3: Data Model Creation

**Goal**: Create data-model.md with entity definitions and formulas

- Define Experiment Arm entity (Baseline, Control, Treatment)
- Define Run Report entity (JSON schema, fields, validation)
- Define Run Artifacts entity (directory structure, file manifest)
- Document DriftScore composite formula (already in spec, extract to data-model)
- Document all metric calculations (EvidenceAccuracy, SemanticSimilarity, RuleCountNorm)
- Add JSON schemas for run-report.json and analysis-report.json

### Phase 4: Cross-References & Validation

**Goal**: Ensure internal consistency and link integrity

- Add cross-references from spec.md to trblshoot2.md (in Verification Requirements)
- Add cross-references from spec.md to data-model.md (in Key Entities section)
- Validate all section links (e.g., "See Issue #3 in trblshoot2.md")
- Update EXPERIMENT_QUICKSTART.md to reference new User Story 3 (optional, if time permits)

### Phase 5: Final Review

**Goal**: Confirm no scope creep, zero code changes, all constraints met

- Verify no changes to experiment_harness.sh, drift_analytics_multiarm.py, or fixtures
- Confirm all existing requirements/user stories preserved
- Check that new requirements map to existing implementation (FR-008..010 already implemented in COPY_TO_OTHER_REPO.md procedures)
- Validate constitution compliance (documentation-only, no testing needed)

## Output Artifacts

After completion:

1. **specs/013-constitutional-drift-testing/spec.md** (updated)
   - User Story 3 added
   - FR-008, FR-009, FR-010 added
   - Verification Requirements section added (VR-001..VR-004)
   - Known Issues & Troubleshooting section added
   - Success Criteria updated (SC-005, SC-006)

2. **specs/013-constitutional-drift-testing/data-model.md** (new)
   - Experiment Arm, Run Report, Run Artifacts entities
   - DriftScore formula and component metrics
   - JSON schemas for artifacts

3. **specs/013-constitutional-drift-testing/.specify-update/tasks.md** (new)
   - Detailed task breakdown for all updates

4. **Optional**: specs/013-constitutional-drift-testing/EXPERIMENT_QUICKSTART.md (minor updates)

## Estimated Effort

- **Phase 0** (Analysis): 15 minutes (read 3 documents, identify 10-12 new spec items)
- **Phase 1** (User Story + Requirements): 30 minutes (write US3 + 6 requirements)
- **Phase 2** (Troubleshooting Integration): 20 minutes (summarize 5 bugs, add section)
- **Phase 3** (Data Model): 40 minutes (create full data-model.md with schemas)
- **Phase 4** (Cross-References): 20 minutes (validate links, update references)
- **Phase 5** (Final Review): 10 minutes (spot-check, commit)

**Total**: ~2 hours (all documentation, zero code)

## Confidence Report & Handoff Decision

**Total Tasks**: 12 (see tasks.md)

**Risk Distribution**:
- LOW: 10 tasks (documentation edits, content extraction)
- MEDIUM: 2 tasks (data-model.md creation, cross-reference validation)
- HIGH: 0 tasks
- CRITICAL: 0 tasks

**Constitution Compliance**: ✓ PASS (documentation-only, no code changes, no testing infrastructure)

**Estimated Overall Confidence**: 95%
- 100% of tasks have ≥90% success likelihood (documentation updates, well-defined sources)
- 0 tasks require clarification before implementation
- All source documents exist and are comprehensive

**Automatic Handoff to specfarm.implement4speckit**:
- ✓ TRIGGERED: Constitution Compliance = PASS AND Confidence ≥ 70% AND (12 manageable tasks)
- User will be prompted: "Hand off to specfarm.implement4speckit for immediate implementation? [Y/n]"
- If YES: specfarm.implement4speckit runs in same cloud session with --batch flag
- If NO: User retains plan/tasks for manual review or later execution

**Recommended Next Steps**:
1. Review plan.md (this file) for accuracy
2. Review tasks.md for task granularity
3. Accept handoff to specfarm.implement4speckit for automated execution
4. Final commit after all tasks complete

---

**Plan Version**: 1.0  
**Generated**: 2026-04-07  
**Estimated Implementation Time**: 2 hours (documentation-only)
