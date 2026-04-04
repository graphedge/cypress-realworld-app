# Feature Specification: Constitutional Drift Testing

**Feature Branch**: `013-constitutional-drift-testing`  
**Created**: 2026-04-01  
**Status**: Draft  
**Input**: User description: "Measure whether injecting a constitutional core into the rules-generation pipeline reduces 'drift' of gathered rules compared to baseline and current rules."

## Short Summary
Measure whether injecting a constitutional core into the rules-generation pipeline reduces "drift" of gathered rules compared to baseline and current rules. We run a controlled experiment (Baseline, Control, Treatment) with repeatable, isolated runs and produce artifact-backed run reports for statistical comparison.

## Motivation
Model-driven rule gathering can slowly diverge from intended policy (constitutional drift). This spec defines an experiment to quantify drift, compare the effect of a constitutional core injection, and provide an auditable, reproducible procedure for validating improvements.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quantify Drift via Controlled Experiment (Priority: P1)

As a researcher, I want to run a controlled experiment across multiple arms (Baseline, Control, Treatment) so that I can quantify the impact of a constitutional core on rule drift.

**Why this priority**: Core hypothesis validation. Without this, we cannot measure progress.

**Independent Test**: Can be tested by running the test harness for a single arm and verifying it produces the expected `run-report.json`.

**Acceptance Scenarios**:

1. **Given** a target repo and three rule fixtures, **When** the experiment is run, **Then** it must execute N=5 runs per arm independently.
2. **Given** a single run, **When** it completes, **Then** it must emit a `run-report.json` containing `DriftScore`, `RuleCount`, and `EvidenceAccuracy`.
3. **Given** all runs are complete, **When** the analysis script is run, **Then** it must calculate the mean, 95% CI, and p-value for `DriftScore` across arms.

---

### User Story 2 - Artifact Review and Validation (Priority: P2)

As an auditor, I want to review the gathered rules and logs from each run so that I can verify the `EvidenceAccuracy` and `SemanticSimilarity` metrics.

**Why this priority**: Ensures the metrics used in the statistical analysis are grounded in verifiable data.

**Independent Test**: Manually review artifacts in `artifacts/drift-testing/<arm>/run-<i>/` and cross-reference with the `run-report.json`.

**Acceptance Scenarios**:

1. **Given** a completed run, **When** I check the artifact directory, **Then** it must contain `gathered-rules.md`, `agent-config.json`, and `logs.txt`.
2. **Given** a set of gathered rules, **When** I perform a human review of evidence accuracy, **Then** the results must align with the reported `EvidenceAccuracy` in `run-report.json`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support three experiment arms: Baseline (empty rules), Control (current rules), and Treatment (constitutional core).
- **FR-002**: System MUST use a fresh clone of the target repository (e.g., `cypress-realworld-app`) for every independent run to ensure isolation.
- **FR-003**: System MUST execute N=5 independent runs per arm to allow for statistical analysis.
- **FR-004**: System MUST capture the exact git-ref of the target repo and the agent version/config for every run.
- **FR-005**: System MUST NOT push any changes to remote repositories or branches during the experiment.
- **FR-006**: System MUST calculate a composite `DriftScore` based on `EvidenceAccuracy`, `SemanticSimilarity`, and `RuleCount`.
- **FR-007**: System MUST emit artifacts in a structured layout under `artifacts/drift-testing/`.

### Key Entities *(include if feature involves data)*

- **Experiment Arm**: Represents a configuration state (Baseline, Control, Treatment).
- **Run Artifacts**: The set of files produced by a single run (logs, gathered rules, report).
- **Run Report**: A JSON file containing the key metrics for a single run.
- **DriftScore**: A normalized composite metric [0..1] representing the degree of divergence from policy.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Treatment must reduce mean `DriftScore` by at least 20% relative to the Control mean.
- **SC-002**: Mean `EvidenceAccuracy` across Treatment runs must be >= 0.95.
- **SC-003**: The difference in `DriftScore` between Control and Treatment must be statistically significant (p < 0.05 via Welch's t-test).
- **SC-004**: 100% of runs must produce a valid `run-report.json` and associated log artifacts.

---

## Experimental Design Detail

### Arms
- Baseline: zero rules fixture (`specs/fixtures/rules-baseline.xml`).
- Control: current production `rules.xml` fixture (`specs/fixtures/rules-control.xml`).
- Treatment: `rules.xml` + injected constitutional core fixture (`specs/fixtures/rules-treatment.xml`).

### DriftScore Composite Formula
DriftScore = 0.50 * (1.0 - EvidenceAccuracy) + 0.30 * (1.0 - SemanticSimilarity) + 0.20 * RuleCountNorm
- Where `RuleCountNorm = min(RuleCount / 2000, 1.0)`.

### Statistical Analysis Steps
1. Collect DriftScore values per arm.
2. Compute mean, SEM, and 95% CI per arm.
3. Perform two-sample Welch's t-test between Control and Treatment.
4. Calculate percentage reduction in mean DriftScore.

## Execution Runbook

(Refer to original `spec-013` for full bash script examples and detailed artifact layout).
- Scripts: `scripts/run-single-drift-run.sh`
- Artifact Layout: `artifacts/drift-testing/<arm>/run-<i>/`
