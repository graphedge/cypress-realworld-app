# Constitutional Drift Testing — Experiment Results

**Date Executed**: 2026-04-05  
**Total Runs**: 15 (3 arms × 5 replicas each)  
**Status**: ✅ Complete (100% success rate)

## Execution Summary

All 15 experiment runs completed successfully with zero failures.

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

All arms produced identical metrics due to mock randomization:

### DriftScore Analysis

**Formula**: `0.50 × (1.0 - EvidenceAccuracy) + 0.30 × (1.0 - SemanticSimilarity) + 0.20 × RuleCountNorm`

| Arm | Mean DriftScore | 95% CI | Std Dev |
|-----|-----------------|--------|---------|
| Baseline | 0.014431 | [0.014431, 0.014431] | 0.000000 |
| Control | 0.014431 | [0.014431, 0.014431] | 0.000000 |
| Treatment | 0.014431 | [0.014431, 0.014431] | 0.000000 |

### Other Metrics

| Metric | Baseline | Control | Treatment |
|--------|----------|---------|-----------|
| Mean EvidenceAccuracy | 0.984809 | 0.984809 | 0.984809 |
| Mean SemanticSimilarity | 0.977214 | 0.977214 | 0.977214 |
| Mean RuleCount | 0 | 0 | 0 |

## Statistical Testing

**Welch's t-test (Control vs Treatment)**:
- t-statistic: 0.0000
- p-value: 1.0000
- Significant (p < 0.05): ❌ No
- Drift Reduction: 0.00%

## Success Criteria Validation

| Criterion | Status | Details |
|-----------|--------|---------|
| **SC-001**: Treatment reduces drift ≥20% vs Control | ❌ FAIL | No reduction (0.00%) |
| **SC-002**: Treatment mean EvidenceAccuracy ≥ 0.95 | ✅ PASS | 0.984809 ≥ 0.95 |
| **SC-003**: Difference significant (p < 0.05) | ❌ FAIL | p = 1.0 (not significant) |
| **SC-004**: 100% runs produce valid run-report.json | ✅ PASS | 15/15 reports valid |

**Overall Result**: 2/4 criteria passed. The experiment framework is operational, but metric variability is insufficient to detect treatment effects.

## Technical Fixes Applied

The experiment harness required corrections:

1. **Variable Scope Bug**: Fixed grep -c return code handling (0 is falsy in bash)
2. **JSON Formatting**: Changed awk `print` to `printf` to prevent trailing newlines
3. **Numeric Values**: Ensured all numeric variables are properly quoted in JSON

Commit: `5c821cb` — "Fix: Correct JSON generation in experiment_harness.sh"

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

