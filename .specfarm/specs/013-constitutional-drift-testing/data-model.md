# Data Model: Constitutional Drift Testing

**Version**: 1.0  
**Date**: 2026-04-04  
**Purpose**: Define the entities, relationships, and calculations for the drift testing experiment

---

## Core Entities

### 1. ExperimentRun

Represents a single isolated execution of the drift engine with one rule fixture.

```
ExperimentRun {
  run_id: string (format: "{arm}-{number:03d}" e.g., "baseline-001")
  arm: "baseline" | "control" | "treatment"
  run_number: integer (1-5)
  timestamp: ISO 8601 datetime
  target_repo_path: string (absolute path to cloned repo)
  target_repo_commit: string (git SHA from clone)
  rules_fixture_file: string (relative path to .specfarm/specs/fixtures/rules-*.xml)
  status: "pending" | "running" | "completed" | "failed"
  duration_seconds: float
}
```

### 2. DriftMetrics

Calculated metrics for a single run.

```
DriftMetrics {
  rule_count: integer
  evidence_accuracy: float (0.0-1.0)
  semantic_similarity: float (0.0-1.0)
  drift_score: float (0.0-1.0) [COMPOSITE]
}
```

### 3. RunReport

Complete artifact and metadata for a single run. Persisted to `run-report.json`.

```
RunReport {
  experiment_metadata: ExperimentRun
  input_configuration: {
    rules_fixture: string
    fixture_sha256: string
    agent_config_file: string
    environment: "isolated_clone"
  }
  execution_summary: {
    status: "completed" | "failed"
    duration_seconds: float
    drift_engine_version: string
    total_steps: integer
    steps_completed: integer
  }
  metrics: DriftMetrics
  drift_analysis: {
    rules_extracted: integer
    rules_with_evidence: integer
    rules_without_evidence: integer
    signature_matches: integer
    signature_mismatches: integer
    average_certainty: float
  }
  artifacts: {
    gathered_rules_md: string (file path)
    agent_config_json: string (file path)
    logs_txt: string (file path)
    git_ref: string (file path)
  }
  validation: {
    xml_valid: boolean
    rules_parsed: boolean
    drift_score_calculated: boolean
    all_artifacts_present: boolean
  }
}
```

### 4. ExperimentAnalysis

Aggregated statistical analysis across all runs for all arms.

```
ExperimentAnalysis {
  baseline: ArmStatistics
  control: ArmStatistics
  treatment: ArmStatistics
  comparisons: {
    control_vs_baseline: ComparisonResult
    treatment_vs_baseline: ComparisonResult
    treatment_vs_control: ComparisonResult
  }
  timestamp: ISO 8601 datetime
}
```

### 5. ArmStatistics

Summary statistics for one experiment arm (N=5 runs).

```
ArmStatistics {
  arm: "baseline" | "control" | "treatment"
  sample_size: integer (always 5)
  drift_scores: float[] (length 5)
  mean_drift_score: float
  std_dev: float
  sem: float (standard error of mean)
  ci_lower: float (95% confidence interval lower bound)
  ci_upper: float (95% confidence interval upper bound)
  rule_count_mean: float
  evidence_accuracy_mean: float
  semantic_similarity_mean: float
}
```

### 6. ComparisonResult

Statistical comparison between two arms.

```
ComparisonResult {
  arm_1: "baseline" | "control" | "treatment"
  arm_2: "baseline" | "control" | "treatment"
  test_type: "welch_ttest" | "permutation_test"
  test_applied_because: string (e.g., "normality check: p=0.234 > 0.05")
  t_statistic: float (for Welch's t-test)
  p_value: float
  effect_size: float (Cohen's d or similar)
  significant_at_0_05: boolean
  interpretation: string
}
```

---

## DriftScore Formula

**DriftScore** is a composite metric indicating how much the gathered rules have "drifted" from the intended constitutional core.

### Formula

```
DriftScore = 0.50 * (1.0 - EvidenceAccuracy) 
           + 0.30 * (1.0 - SemanticSimilarity) 
           + 0.20 * RuleCountNormalized

Where:
  RuleCountNormalized = min(RuleCount / 2000, 1.0)
```

### Interpretation

- **DriftScore = 0.0**: Perfect alignment (high evidence accuracy, high semantic consistency, baseline rule count)
- **DriftScore = 1.0**: Maximum drift (low evidence accuracy, low semantic consistency, excessive rules)
- **Treatment Effect**: Successful constitutional injection reduces DriftScore (lower is better)

### Weighting Rationale

| Component | Weight | Rationale |
|-----------|--------|-----------|
| Evidence Accuracy | 50% | Primary indicator of drift; rules without evidence are speculative (highest concern) |
| Semantic Similarity | 30% | Secondary indicator; similar rules suggest coherent drift vs chaotic divergence |
| Rule Count Normalized | 20% | Tertiary indicator; excessive rules suggest unfocused gathering (early warning) |

### Component Definitions

**Evidence Accuracy** (detailed in research.md RQ-003)
- Calculated as: (true_positive_rules / total_extracted_rules) × average_certainty
- Measures: What fraction of extracted rules have verifiable evidence in the codebase

**Semantic Similarity** (detailed in research.md RQ-004)
- Calculated as: Jaccard token overlap of rule signatures
- Measures: How cohesive/consistent the rule set is (high similarity = coherent rules)

**Rule Count Normalized**
- Calculated as: min(actual_count / 2000, 1.0)
- Rationale: 2000 rules is considered "over-gathered"; saturates at 1.0 to avoid runaway drift
- Capped at 1.0 to prevent single metric from dominating score

---

## Experiment Flow

### Phase 1: Single-Run Orchestration (User Story 1)

```
┌─ ExperimentRun (arm, run_number)
│
├─ Clone target repo (fresh, isolated)
├─ Copy rules fixture to .specfarm/rules.xml
├─ Execute drift_engine.sh → gathered-rules.md
├─ Execute drift_analytics.sh → metrics
│
├─ Calculate DriftMetrics:
│   ├─ evidence_accuracy (from drift_analytics output)
│   ├─ semantic_similarity (Jaccard on signatures)
│   └─ drift_score (formula above)
│
├─ Collect artifacts:
│   ├─ gathered-rules.md
│   ├─ agent-config.json
│   ├─ logs.txt
│   └─ git-ref.txt
│
└─ Generate RunReport JSON
   └─ Persist to artifacts/drift-testing/{arm}/run-{n}/run-report.json
```

### Phase 2: Multi-Arm Orchestration (User Story 2)

```
FOR each arm IN [baseline, control, treatment]:
  FOR each run IN [1,2,3,4,5]:
    Execute Single-Run Orchestration
    Aggregate metrics
```

### Phase 3: Statistical Analysis (User Story 3)

```
FOR each arm IN [baseline, control, treatment]:
  Load all 5 run-report.json files
  Extract DriftScore values
  Calculate ArmStatistics (mean, CI, etc.)

FOR each pair IN [(C,B), (T,B), (T,C)]:
  Perform Welch's t-test or permutation test
  Calculate p-value, effect size
  Generate ComparisonResult

Aggregate into ExperimentAnalysis
Persist to artifacts/drift-testing/analysis/experiment-analysis.json
```

---

## Storage Layout

```
artifacts/drift-testing/
├── baseline/
│   ├── run-001/
│   │   ├── run-report.json
│   │   ├── gathered-rules.md
│   │   ├── agent-config.json
│   │   ├── logs.txt
│   │   └── git-ref.txt
│   ├── run-002/
│   ├── run-003/
│   ├── run-004/
│   └── run-005/
├── control/
│   ├── run-001/ ... run-005/
└── treatment/
    ├── run-001/ ... run-005/
└── analysis/
    └── experiment-analysis.json
```

---

## Key Calculations

### Evidence Accuracy (Python implementation sketch)

```python
def calculate_evidence_accuracy(rules_list, codebase_path):
    tp_count = 0
    total_count = len(rules_list)
    certainty_sum = 0.0
    
    for rule in rules_list:
        sig = rule.get('signature', '')
        if not sig:
            continue  # No evidence → false positive
        
        # Search codebase for signature
        try:
            result = subprocess.run(
                ['grep', '-r', '-F', sig, codebase_path],
                capture_output=True, timeout=5
            )
            if result.returncode == 0:  # Found
                tp_count += 1
                certainty = float(rule.get('certainty', 0.5))
                certainty_sum += certainty
        except:
            pass  # Timeout or error → not counted as match
    
    if total_count == 0:
        return 0.0
    if tp_count == 0:
        return 0.0
    
    matched_certainty = certainty_sum / tp_count
    evidence_accuracy = (tp_count / total_count) * matched_certainty
    return min(evidence_accuracy, 1.0)
```

### Semantic Similarity (Python implementation sketch)

```python
def calculate_semantic_similarity(rules_list):
    if not rules_list or len(rules_list) < 2:
        return 1.0  # Single rule = perfect self-similarity
    
    similarities = []
    
    for i, rule1 in enumerate(rules_list):
        tokens1 = set(rule1['signature'].lower().split())
        
        for j in range(i + 1, len(rules_list)):
            rule2 = rules_list[j]
            tokens2 = set(rule2['signature'].lower().split())
            
            if not tokens1 or not tokens2:
                similarity = 0.0
            else:
                intersection = len(tokens1 & tokens2)
                union = len(tokens1 | tokens2)
                similarity = intersection / union
            
            similarities.append(similarity)
    
    return sum(similarities) / len(similarities) if similarities else 1.0
```

---

## API Contracts

### run-report.json Schema

See `contracts/run-report-schema.json` for JSON Schema definition.

Key validation:
- Required fields: experiment_metadata, input_configuration, execution_summary, metrics, artifacts
- metrics.drift_score must be 0.0-1.0
- All file paths must be relative to repo root

### Experiment Analysis Export

Format: JSON  
Schema: See `contracts/experiment-analysis-schema.json`  
Expected output locations:
- `artifacts/drift-testing/analysis/experiment-analysis.json` (comprehensive)
- `artifacts/drift-testing/analysis/experiment-summary.txt` (human-readable)

---

## Validation Rules

All RunReport instances must satisfy:

1. **Completeness**: All required fields present and non-null
2. **Range Validation**: All float metrics in [0.0, 1.0]
3. **Consistency**: DriftScore must equal formula result (within 0.01 tolerance)
4. **Artifact Integrity**: All referenced artifact files must exist and be readable
5. **Chronology**: timestamp must be recent (within 1 hour of analysis)

---

## Extensibility

This model is designed to support future enhancements:

- **Additional Metrics**: Add new keys to DriftMetrics (e.g., BehaviorConsistency)
- **Multi-Repository Experiments**: Extend ExperimentRun.target_repo to array
- **Longitudinal Studies**: Add metadata for comparing drift across versions
- **Nested Comparisons**: Support comparisons of specific rule categories
