# Data Model: Constitutional Drift Testing

**Version**: 1.0  
**Date**: 2026-04-06  
**Status**: Stable

This document defines the data structures, entities, and metrics used in the constitutional drift testing experiment framework.

## Entities

### 1. Experiment Arm

Represents a configuration state in the controlled experiment.

**Attributes**:
- `arm_name` (string): One of `baseline`, `control`, or `treatment`
  - `baseline` = zero rules (empty fixture)
  - `control` = current production rules (rules-control.xml)
  - `treatment` = production rules + injected constitutional core (rules-treatment.xml)
- `fixture_file` (string): Path to XML fixture file for this arm (e.g., `fixtures/rules-baseline.xml`)
- `rule_count` (integer): Number of `<rule>` elements in the fixture file

**Validation Rules**:
- `arm_name` must be one of the three predefined values
- `fixture_file` must exist and be readable
- `rule_count` must match `grep -c '<rule ' fixture_file` output
- `rule_count` must be >= 0 (zero for baseline is valid)

**Sources**:
- Specification: `spec.md` lines 77-80 (Experimental Design)
- Implementation: `COPY_TO_OTHER_REPO.md` lines 59-89

---

### 2. Run Report

Contains metrics from a single independent experiment run.

**Attributes**:
- `run_id` (integer): Sequential run number [1-5] within an arm
- `arm` (string): Arm identifier (`baseline`, `control`, or `treatment`)
- `DriftScore` (float): Composite drift metric [0.0, 1.0]
  - 0.0 = no drift (perfect policy adherence)
  - 1.0 = maximum drift (complete policy divergence)
- `EvidenceAccuracy` (float): Proportion of gathered rules that cite valid evidence [0.0, 1.0]
- `SemanticSimilarity` (float): Cosine similarity of rule semantics to policy core [0.0, 1.0]
- `RuleCount` (integer): Number of rules gathered in this run (>= 0)
- `fixture_file` (string): Path to the rule fixture used in this run
- `timestamp` (string): ISO 8601 timestamp of run completion (e.g., `2026-04-06T14:32:11Z`)
- `git_ref` (string): Git commit SHA of target repository at run time
- `agent_version` (string): Version identifier of the rule-gathering agent used

**Validation Rules**:
- `run_id` must be in range [1, 5]
- `arm` must be one of: `baseline`, `control`, `treatment`
- All float fields must be in range [0.0, 1.0]
- `RuleCount` must be non-negative integer
- `timestamp` must parse as valid ISO 8601
- `git_ref` must be 40-character SHA or tag reference
- File must parse as valid JSON

**JSON Schema**:
```json
{
  "type": "object",
  "required": ["run_id", "arm", "DriftScore", "EvidenceAccuracy", "SemanticSimilarity", "RuleCount", "timestamp"],
  "properties": {
    "run_id": {"type": "integer", "minimum": 1, "maximum": 5},
    "arm": {"type": "string", "enum": ["baseline", "control", "treatment"]},
    "DriftScore": {"type": "number", "minimum": 0.0, "maximum": 1.0},
    "EvidenceAccuracy": {"type": "number", "minimum": 0.0, "maximum": 1.0},
    "SemanticSimilarity": {"type": "number", "minimum": 0.0, "maximum": 1.0},
    "RuleCount": {"type": "integer", "minimum": 0},
    "fixture_file": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"},
    "git_ref": {"type": "string"},
    "agent_version": {"type": "string"}
  }
}
```

**Example**:
```json
{
  "run_id": 1,
  "arm": "treatment",
  "DriftScore": 0.32,
  "EvidenceAccuracy": 0.97,
  "SemanticSimilarity": 0.88,
  "RuleCount": 142,
  "fixture_file": "fixtures/rules-treatment.xml",
  "timestamp": "2026-04-06T14:32:11Z",
  "git_ref": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0",
  "agent_version": "specfarm-gather-rules-v1.2.3"
}
```

**Sources**:
- Specification: `spec.md` lines 60-62 (Key Entities)
- Verification: `spec.md` lines 69-76 (Verification Requirements)

---

### 3. Run Artifacts

Complete set of files produced by a single experiment run.

**Attributes**:
- `artifact_dir` (string): Path to artifact directory (format: `artifacts/drift-testing/<arm>/run-<run_id>/`)
- `run_report_json` (file): `run-report.json` (see Run Report schema above)
- `gathered_rules_md` (file): `gathered-rules.md` (markdown format, agent output)
- `agent_config_json` (file): `agent-config.json` (agent metadata and parameters)
- `logs_txt` (file): `logs.txt` (full execution log)

**Directory Structure**:
```
artifacts/drift-testing/
├── baseline/
│   ├── run-1/
│   │   ├── run-report.json          ← Run Report (see schema)
│   │   ├── gathered-rules.md        ← Extracted rules (markdown format)
│   │   ├── agent-config.json        ← Agent metadata
│   │   └── logs.txt                 ← Full execution log
│   ├── run-2/ ... run-5/
├── control/ ... (same structure)
└── treatment/ ... (same structure)
```

**Validation Rules**:
- All files must exist in the artifact directory
- `run-report.json` must pass `jq empty` validation (valid JSON)
- `gathered-rules.md` must contain at least the header `# Gathered Rules`
- `agent-config.json` must be valid JSON
- `logs.txt` must be readable and non-empty
- File permissions: All files readable by current user

**Retention Policy**:
- Keep artifacts for at least 30 days to enable post-mortem analysis
- Archive after 30 days if regulatory compliance requires longer retention
- Include in final analysis package for audit trail

**Sources**:
- Specification: `spec.md` line 96 (Execution Runbook)
- Distribution: `COPY_TO_OTHER_REPO.md` lines 116-134

---

### 4. DriftScore

Composite metric representing the degree of rule policy divergence.

**Formula**:
```
DriftScore = 0.50 * (1.0 - EvidenceAccuracy) 
           + 0.30 * (1.0 - SemanticSimilarity) 
           + 0.20 * RuleCountNorm
```

**Component Definitions**:

#### RuleCountNorm
Normalized rule count with saturation at 2000 rules:
```
RuleCountNorm = min(RuleCount / 2000, 1.0)
```
- Rationale: Beyond 2000 rules, additional rules have diminishing impact on drift (saturation avoids extreme values)
- Example: 1000 rules → 0.50, 2000+ rules → 1.0

#### EvidenceAccuracy
Proportion of gathered rules that cite valid, retrievable evidence:
- Range: [0.0, 1.0]
- Calculation: count(rules with valid evidence) / count(total gathered rules)
- Interpretation: 1.0 = all rules well-supported; 0.0 = no evidentiary support

#### SemanticSimilarity
Cosine similarity between gathered rules' semantic embedding and the constitutional core:
- Range: [0.0, 1.0]
- Calculation: Done via embedding comparison (see analytics script)
- Interpretation: 1.0 = rules perfectly align with constitution; 0.0 = complete semantic divergence

#### RuleCount
Absolute number of rules gathered in a single run:
- Range: [0, ∞)
- Derived from: Word count or list item count in `gathered-rules.md`
- Interpretation: Higher count may indicate more comprehensive or less filtered rules

**Validation**:
- Result must be in range [0.0, 1.0]
- All component values must be in range [0.0, 1.0] before formula application
- If any component is NaN or Inf, calculation fails (catch in analytics)

**Interpretation**:
- **0.0–0.3**: Low drift (good policy adherence)
- **0.3–0.6**: Moderate drift (acceptable variance, watch trends)
- **0.6–0.8**: High drift (significant divergence from policy)
- **0.8–1.0**: Very high drift (critical divergence, requires intervention)

**Sources**:
- Formula: `spec.md` lines 82–84 (DriftScore Composite Formula)
- Weights rationale: Prioritizes evidence accuracy (0.50) > semantic alignment (0.30) > volume (0.20)

---

## Metric Definitions

### Evidence Accuracy
The extent to which gathered rules cite retrievable, valid evidence from the policy document or codebase.

**Measurement Method**:
1. Extract all evidence citations from gathered rules
2. For each citation, verify it exists and matches the rule content
3. Calculate: (valid citations) / (total citations)

**Thresholds** (from spec.md SC-002):
- Target: >= 0.95 for Treatment arm
- Success: All arms show >= 0.90 (audit confidence)

---

### Semantic Similarity
The degree of textual and conceptual alignment between gathered rules and the constitutional core principles.

**Measurement Method**:
1. Vectorize gathered rules using embeddings (e.g., TF-IDF or transformer model)
2. Vectorize constitutional core principles
3. Compute cosine similarity between sets
4. Average across all rules

**Interpretation**:
- High similarity (>0.85): Rules closely align with constitution
- Moderate similarity (0.65–0.85): Some rules diverge, but overall coherent
- Low similarity (<0.65): Significant semantic drift detected

---

### Rule Count
The absolute number of rules extracted during a single experiment run.

**Measurement Method**:
1. Parse `gathered-rules.md` output from agent
2. Count top-level markdown list items (marked with `- `)
3. Exclude header rows and metadata

**Interpretation**:
- Baseline (zero rules): Establishes lower bound (typically 0)
- Control (production rules): Establishes current state (typically 50–200)
- Treatment (with constitution): Should show slight increase due to policy-driven generation

**Note**: Higher rule count doesn't necessarily indicate better outcomes; quality (accuracy, similarity) is prioritized.

---

## Analysis Report

Aggregated statistical results from all runs across arms.

**JSON Schema**:
```json
{
  "type": "object",
  "properties": {
    "arms": {
      "type": "object",
      "patternProperties": {
        "baseline|control|treatment": {
          "type": "object",
          "properties": {
            "n_runs": {"type": "integer"},
            "mean_drift": {"type": "number"},
            "std_drift": {"type": "number"},
            "sem_drift": {"type": "number"},
            "ci_lower_drift": {"type": "number"},
            "ci_upper_drift": {"type": "number"},
            "mean_accuracy": {"type": "number"},
            "mean_similarity": {"type": "number"},
            "mean_rule_count": {"type": "number"}
          }
        }
      }
    },
    "statistical_tests": {
      "type": "object",
      "properties": {
        "control_vs_treatment": {
          "type": "object",
          "properties": {
            "test_type": {"type": "string", "const": "welchs_t_test"},
            "t_statistic": {"type": "number"},
            "p_value": {"type": "number"},
            "significant": {"type": "boolean", "description": "true if p < 0.05"},
            "percent_reduction": {"type": "number", "description": "Percentage reduction in mean DriftScore from Control to Treatment"}
          }
        }
      }
    },
    "success_criteria": {
      "type": "object",
      "properties": {
        "SC-001": {"type": "boolean", "description": "Treatment DriftScore ≥20% lower than Control"},
        "SC-002": {"type": "boolean", "description": "Treatment mean EvidenceAccuracy ≥ 0.95"},
        "SC-003": {"type": "boolean", "description": "Control vs Treatment p-value < 0.05"},
        "SC-004": {"type": "boolean", "description": "100% of runs produced valid reports"}
      }
    }
  }
}
```

**Important Notes**:
- All numpy types (numpy.float64, numpy.bool_) MUST be cast to Python native types (float, bool) before JSON serialization (see Troubleshooting #5)
- Confidence intervals use 95% confidence level (alpha = 0.05)
- Welch's t-test is used (does not assume equal variances across arms)

---

## JSON Schemas (Detailed)

### run-report.json Schema (Production)

This is the primary output of each experiment run.

**Schema Definition** (JSON Schema Draft 7):
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://specfarm.io/schemas/run-report.json",
  "title": "Drift Testing Run Report",
  "type": "object",
  "required": [
    "run_id",
    "arm",
    "DriftScore",
    "EvidenceAccuracy",
    "SemanticSimilarity",
    "RuleCount",
    "timestamp"
  ],
  "properties": {
    "run_id": {
      "type": "integer",
      "minimum": 1,
      "maximum": 5,
      "description": "Sequential run identifier within arm"
    },
    "arm": {
      "type": "string",
      "enum": ["baseline", "control", "treatment"],
      "description": "Experiment arm configuration"
    },
    "DriftScore": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Composite drift metric"
    },
    "EvidenceAccuracy": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Proportion of rules with valid evidence citations"
    },
    "SemanticSimilarity": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Cosine similarity to constitutional core"
    },
    "RuleCount": {
      "type": "integer",
      "minimum": 0,
      "description": "Number of rules gathered in this run"
    },
    "fixture_file": {
      "type": "string",
      "description": "Path to rule fixture used (e.g., rules-treatment.xml)"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 completion timestamp"
    },
    "git_ref": {
      "type": "string",
      "description": "Git commit SHA of target repository"
    },
    "agent_version": {
      "type": "string",
      "description": "Version of rule-gathering agent"
    }
  },
  "additionalProperties": false
}
```

**Validation Notes**:
- All numeric fields must serialize to JSON-native float (not numpy.float64)
- Timestamp must be ISO 8601 format (RFC 3339)
- Sum of DriftScore components must equal DriftScore (allow 0.01 tolerance for rounding)

### analysis-report.json Schema (Aggregated Results)

This is the final statistical summary produced by the analytics script.

**Schema Definition**:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://specfarm.io/schemas/analysis-report.json",
  "title": "Constitutional Drift Analysis Report",
  "type": "object",
  "properties": {
    "analysis_metadata": {
      "type": "object",
      "properties": {
        "timestamp": {"type": "string", "format": "date-time"},
        "artifact_dir": {"type": "string"},
        "python_version": {"type": "string"},
        "scipy_version": {"type": "string"},
        "numpy_version": {"type": "string"}
      }
    },
    "arms": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "n_runs": {"type": "integer", "minimum": 1},
          "runs": {
            "type": "array",
            "items": {"type": "number"},
            "description": "List of DriftScore values for each run"
          },
          "mean_drift": {"type": "number"},
          "std_drift": {"type": "number"},
          "sem_drift": {
            "type": "number",
            "description": "Standard error of mean"
          },
          "ci_lower_drift": {
            "type": "number",
            "description": "Lower bound of 95% confidence interval"
          },
          "ci_upper_drift": {
            "type": "number",
            "description": "Upper bound of 95% confidence interval"
          },
          "mean_accuracy": {"type": "number"},
          "mean_similarity": {"type": "number"},
          "mean_rule_count": {"type": "number"}
        }
      }
    },
    "statistical_tests": {
      "type": "object",
      "properties": {
        "control_vs_treatment": {
          "type": "object",
          "properties": {
            "test_type": {
              "type": "string",
              "const": "welchs_t_test",
              "description": "Two-sample t-test not assuming equal variances"
            },
            "t_statistic": {"type": "number"},
            "p_value": {
              "type": "number",
              "minimum": 0.0,
              "maximum": 1.0
            },
            "degrees_of_freedom": {"type": "number"},
            "significant": {
              "type": "boolean",
              "description": "true if p_value < 0.05"
            },
            "mean_control": {"type": "number"},
            "mean_treatment": {"type": "number"},
            "percent_reduction": {
              "type": "number",
              "description": "Percentage reduction: 100 * (Control - Treatment) / Control"
            }
          }
        }
      }
    },
    "success_criteria": {
      "type": "object",
      "properties": {
        "SC-001": {
          "type": "boolean",
          "description": "Treatment DriftScore ≥20% lower than Control"
        },
        "SC-002": {
          "type": "boolean",
          "description": "Treatment mean EvidenceAccuracy ≥ 0.95"
        },
        "SC-003": {
          "type": "boolean",
          "description": "Control vs Treatment p-value < 0.05"
        },
        "SC-004": {
          "type": "boolean",
          "description": "100% of expected runs (15) produced valid reports"
        },
        "SC-005": {
          "type": "boolean",
          "description": "Distribution & verification completed within 30 minutes"
        },
        "SC-006": {
          "type": "boolean",
          "description": "Installation integrity checks passed (100% fixtures present, executable)"
        }
      }
    },
    "summary": {
      "type": "object",
      "properties": {
        "total_runs": {"type": "integer"},
        "successful_runs": {"type": "integer"},
        "failed_runs": {"type": "integer"},
        "all_criteria_met": {"type": "boolean"}
      }
    }
  }
}
```

**Serialization Safety**:
- Before writing JSON, convert all numpy types:
  ```python
  def convert_numpy_types(obj):
      if isinstance(obj, np.ndarray):
          return obj.tolist()
      elif isinstance(obj, (np.integer, np.int64)):
          return int(obj)
      elif isinstance(obj, (np.floating, np.float64)):
          return float(obj)
      elif isinstance(obj, (np.bool_, np.bool8)):
          return bool(obj)
      return obj
  ```
- Use `json.dumps(..., default=convert_numpy_types)` when serializing
- Test before analysis: `python3 << 'EOF'` ... validate conversion works

---

## Data Quality Assurance

### Pre-Run Checks
1. Validate experiment arm configurations
2. Verify fixture files exist and contain valid XML
3. Check target repository has SpecFarm installed
4. Confirm all scripts are executable

### Post-Run Checks
1. Validate all `run-report.json` files (JSON schema compliance)
2. Check metric variance across runs (rules out RNG/seeding bugs)
3. Verify rule counts match fixture + gathered rules
4. Test numpy type serialization before analytics

### Audit Trail
- Retain all run artifacts (logs, rules, configs) for 30+ days
- Log all experiment parameters (git refs, agent versions, fixture paths)
- Record start/end timestamps for each run
- Enable reproducibility via `git_ref` + `agent_version` + `fixture_file`

---

## Cross-References

- **Specification**: `spec.md` (sections on Experimental Design, Requirements, Success Criteria)
- **Distribution**: `COPY_TO_OTHER_REPO.md` (artifact layout, installation validation)
- **Quickstart Guide**: `EXPERIMENT_QUICKSTART.md` (running experiments, metrics definitions, troubleshooting, output structure)
  - See "Running a Single Arm" (lines 19–41) for experiment harness usage
  - See "Analyzing Results" (lines 92–105) for analytics workflow
  - See "Output Structure" (lines 108–120) for artifact layout details
  - See "Key Features" (lines 122–129) for isolation, metrics, and statistical analysis overview
  - See "Troubleshooting" (lines 157–170) for diagnostic procedures
  - See "Success Criteria" (lines 172–179) for validation checklist
- **Troubleshooting**: `spec.md` Known Issues & Troubleshooting section (bug fixes, diagnostic procedures)
- **Installation**: `COPY_TO_OTHER_REPO.md` (step-by-step distribution workflow)
