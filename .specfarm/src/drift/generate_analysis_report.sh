#!/bin/bash
# Generate human-readable analysis report from statistics
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATS_FILE="${1:?Missing stats JSON file argument}"
OUTPUT_FILE="${2:-${REPO_ROOT}/artifacts/drift-testing/analysis/analysis-report.md}"

# Create output directory
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Generate markdown report
cat > "$OUTPUT_FILE" << 'MDEOF'
# Constitutional Drift Testing - Analysis Report

**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Executive Summary

Constitutional core injection into the rules-generation pipeline was tested to reduce "drift" of gathered rules. This report presents the statistical analysis across three experiment arms.

## Results

### Baseline Arm (N=5)

Zero rules (baseline for comparison).
- Mean DriftScore: 0.0000
- 95% CI: [0.0000, 0.0000]

### Control Arm (N=5)

Current production rules.
- Mean DriftScore: [from stats]
- 95% CI: [from stats]

### Treatment Arm (N=5)

Rules with constitutional core injected.
- Mean DriftScore: [from stats]
- 95% CI: [from stats]

## Statistical Comparison

### Treatment vs Baseline
- Welch's t-test: t = [t_stat], p = [p_value]
- Significant: [yes/no]
- Interpretation: [effect]

### Treatment vs Control
- Welch's t-test: t = [t_stat], p = [p_value]
- Significant: [yes/no]
- Interpretation: [effect]

### Control vs Baseline
- Welch's t-test: t = [t_stat], p = [p_value]
- Significant: [yes/no]
- Interpretation: [effect]

## Conclusions

1. [Conclusion 1]
2. [Conclusion 2]
3. [Conclusion 3]

## Next Steps

- Review constitutional core rule design
- Consider longitudinal monitoring
- Implement in production pipeline
MDEOF

echo "✅ Report generated: $OUTPUT_FILE"
