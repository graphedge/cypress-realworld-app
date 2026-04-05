# Constitutional Drift Testing — Experiment Results

**Date Executed**: 2026-04-05 (Run 2, updated)
**Total Runs**: 15 (3 arms × 5 replicas each)  
**Status**: ✅ Complete (100% success rate)

## Execution Summary

All 15 experiment runs completed successfully with zero failures. This run uses
per-run seeded randomization (`srand(nanosecond + PID + run_num × 97)`) and
fixture-based rule counts, producing genuine variance across runs.

| Arm | Runs | Status |
|-----|------|--------|
| Baseline | 5 | ✅ Complete |
| Control | 5 | ✅ Complete |
| Treatment | 5 | ✅ Complete |

## Artifact Inventory

- **Total Files**: 75
- **Artifact Size**: 384 KB
- **Per-Run Files**: 5 (run-report.json, gathered-rules.md, agent-config.json, logs.txt, harness.log)
- **Location**: `artifacts/drift-testing/<arm>/run-<N>/`

## Metrics Summary

### DriftScore Analysis

**Formula**: `0.50 × (1.0 - EvidenceAccuracy) + 0.30 × (1.0 - SemanticSimilarity) + 0.20 × RuleCountNorm`

| Arm | Mean DriftScore | 95% CI | Fixture Rules |
|-----|-----------------|--------|---------------|
| Baseline | 0.088662 | [0.053815, 0.123509] | 0 |
| Control | 0.069034 | [0.031587, 0.106481] | 19 |
| Treatment | 0.111695 | [0.065412, 0.157978] | 19 |

### Per-Run Raw DriftScores

| Run | Baseline | Control | Treatment |
|-----|----------|---------|-----------|
| 1 | 0.148287 | 0.129455 | 0.086047 |
| 2 | 0.085329 | 0.040511 | 0.147290 |
| 3 | 0.036307 | 0.062501 | 0.071755 |
| 4 | 0.088558 | 0.091506 | 0.186618 |
| 5 | 0.084829 | 0.021197 | 0.066764 |

### Evidence Accuracy (mock, per-run seeded)

| Arm | Mean EvidenceAccuracy |
|-----|-----------------------|
| Baseline | 0.913113 |
| Control | 0.906954 |
| Treatment | 0.871587 |

## Statistical Testing

**Welch's t-test (Control vs Treatment)**:
- t-statistic: -1.4045
- p-value: 0.199373
- Significant (p < 0.05): ❌ No
- Drift Reduction (Treatment vs Control): **-61.80%** (treatment is _higher_ than control)

## Success Criteria Validation

| Criterion | Status | Details |
|-----------|--------|---------|
| **SC-001**: Treatment reduces drift ≥20% vs Control | ❌ FAIL | Treatment DriftScore increased +61.80% vs Control |
| **SC-002**: Treatment mean EvidenceAccuracy ≥ 0.95 | ❌ FAIL | 0.8716 < 0.95 |
| **SC-003**: Difference significant (p < 0.05) | ❌ FAIL | p = 0.199 |
| **SC-004**: 100% runs produce valid run-report.json | ✅ PASS | 15/15 reports valid |

**Overall Result**: 1/4 criteria passed (SC-004 only).

**Interpretation**: The framework infrastructure is fully operational. The mock metrics are seeded
per-run with actual variance, but the treatment arm's random seed happened to produce lower
EvidenceAccuracy/SemanticSimilarity values. The constitutional core injection has no effect
on the mock metrics — real NLP-based scoring against constitution text is needed to produce
meaningful arm differentiation.

## Technical Fixes Applied (Cumulative)

### Run 1 Fixes (commit 5c821cb)
1. **Variable Scope Bug**: Fixed grep -c return code handling (0 is falsy in bash)
2. **JSON Formatting**: Changed awk `print` to `printf` to prevent trailing newlines

### Run 2 Fixes (this run)
3. **Identical Metrics Bug**: awk `rand()` uses a fixed default seed — added `srand(ns+PID+run_num×97)` for genuine per-run variance
4. **Fixture Rule Counts**: Switched RULE_COUNT to count `<rule ` tags in the fixture XML rather than `^### ` headers in gathered output
5. **JSON Serialization Bug**: Fixed numpy `bool_` not serializable — added explicit `bool()` cast in analytics script

## Analysis Report

Full statistical analysis saved to: `analysis-report.json`

To view results:
```bash
python3 -m json.tool analysis-report.json | less
```

## Next Steps for Constitutional Core Validation

The mock metrics (randomized evidence accuracy and semantic similarity) need to be replaced with:

1. **Real Rule Extraction**: Implement actual rule gathering from the target repository
2. **Semantic Analysis**: Add code-to-constitution comparison using actual NLP or AST-based similarity
3. **Evidence Scoring**: Implement confidence-based evidence accuracy from constitutional audit logs
4. **Multi-Run Variance**: Introduce deterministic rules variations to create observable differences between arms

See `spec.md` for measurement methodology.

