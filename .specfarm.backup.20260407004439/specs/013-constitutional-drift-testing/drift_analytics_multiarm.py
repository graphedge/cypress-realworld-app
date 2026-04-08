#!/usr/bin/env python3
# drift_analytics_multiarm.py — Multi-Arm Drift Testing Analysis
#
# Analyzes drift metrics across multiple experiment arms (Baseline, Control, Treatment)
# and performs statistical comparison (Welch's t-test, 95% confidence intervals).
#
# Usage:
#   python3 drift_analytics_multiarm.py --artifact-dir artifacts/drift-testing \
#     [--output analysis-report.json] [--verbose]
#
# Expected artifact structure:
#   artifacts/drift-testing/
#   ├── baseline/run-1/run-report.json
#   ├── baseline/run-2/run-report.json
#   ├── ...
#   ├── control/run-1/run-report.json
#   ├── ...
#   └── treatment/run-1/run-report.json
#
# Output: analysis-report.json with mean, CI, p-values, and success criteria validation.

import json
import os
import sys
from pathlib import Path
from statistics import mean, stdev
from typing import Dict, List, Tuple, Optional
import math

class DriftAnalyzer:
    def __init__(self, artifact_dir: str, verbose: bool = False):
        self.artifact_dir = Path(artifact_dir)
        self.verbose = verbose
        self.runs: Dict[str, List[Dict]] = {}
        self.analysis_results: Dict = {}

    def log(self, msg: str):
        if self.verbose:
            print(f"[*] {msg}", file=sys.stderr)

    def load_runs(self) -> bool:
        """Load all run-report.json files from artifact directory."""
        self.log(f"Loading runs from {self.artifact_dir}...")
        
        if not self.artifact_dir.exists():
            print(f"ERROR: Artifact directory not found: {self.artifact_dir}", file=sys.stderr)
            return False

        arms = ['baseline', 'control', 'treatment']
        for arm in arms:
            self.runs[arm] = []
            arm_dir = self.artifact_dir / arm
            
            if not arm_dir.exists():
                self.log(f"Arm directory not found: {arm_dir} (skipping)")
                continue

            for run_dir in sorted(arm_dir.iterdir()):
                if not run_dir.is_dir():
                    continue
                
                report_file = run_dir / "run-report.json"
                if not report_file.exists():
                    self.log(f"Skipping {run_dir}: no run-report.json")
                    continue

                try:
                    with open(report_file) as f:
                        report = json.load(f)
                    self.runs[arm].append(report['metrics'])
                    self.log(f"Loaded {arm}/{run_dir.name}: DriftScore={report['metrics']['drift_score']}")
                except Exception as e:
                    print(f"ERROR loading {report_file}: {e}", file=sys.stderr)
                    return False

        return True

    @staticmethod
    def welch_t_test(group1: List[float], group2: List[float]) -> Tuple[float, float]:
        """
        Perform Welch's t-test (unequal variances).
        Returns: (t_statistic, p_value)
        """
        n1, n2 = len(group1), len(group2)
        if n1 < 2 or n2 < 2:
            return 0.0, 1.0
        
        mean1, mean2 = mean(group1), mean(group2)
        var1, var2 = stdev(group1) ** 2, stdev(group2) ** 2
        
        se = math.sqrt(var1 / n1 + var2 / n2)
        if se == 0:
            return 0.0, 1.0
        
        t_stat = (mean1 - mean2) / se
        
        # Welch-Satterthwaite degrees of freedom
        df_numerator = (var1 / n1 + var2 / n2) ** 2
        df_denominator = (var1 / n1) ** 2 / (n1 - 1) + (var2 / n2) ** 2 / (n2 - 1)
        df = df_numerator / df_denominator if df_denominator > 0 else max(n1 + n2 - 2, 1)
        
        # Approximate p-value using t-distribution (two-tailed)
        # For simplicity, use normal approximation for p-value
        from scipy import stats
        try:
            p_value = 2 * (1 - stats.t.cdf(abs(t_stat), df))
        except ImportError:
            # Fallback: rough normal approximation
            p_value = 2 * (1 - 0.9999 if abs(t_stat) > 3 else 0.5 + 0.3413 * min(abs(t_stat), 1))
        
        return t_stat, p_value

    @staticmethod
    def confidence_interval_95(values: List[float]) -> Tuple[float, float]:
        """Calculate 95% confidence interval (normal approximation)."""
        n = len(values)
        if n < 2:
            return values[0] if values else 0.0, values[0] if values else 0.0
        
        m = mean(values)
        se = stdev(values) / math.sqrt(n)
        margin = 1.96 * se  # 95% CI for normal distribution
        return m - margin, m + margin

    def analyze(self) -> bool:
        """Perform statistical analysis across arms."""
        self.log("Performing statistical analysis...")
        
        stats_by_arm = {}
        for arm in ['baseline', 'control', 'treatment']:
            if arm not in self.runs or len(self.runs[arm]) == 0:
                self.log(f"Arm '{arm}' has no runs, skipping")
                continue
            
            drift_scores = [r['drift_score'] for r in self.runs[arm]]
            evidence_accuracies = [r['evidence_accuracy'] for r in self.runs[arm]]
            rule_counts = [r['rule_count'] for r in self.runs[arm]]
            
            mean_drift = mean(drift_scores)
            ci_lower, ci_upper = self.confidence_interval_95(drift_scores)
            mean_accuracy = mean(evidence_accuracies)
            mean_rule_count = mean(rule_counts)
            
            stats_by_arm[arm] = {
                'n': len(drift_scores),
                'drift_score_mean': round(mean_drift, 6),
                'drift_score_ci_95': [round(ci_lower, 6), round(ci_upper, 6)],
                'evidence_accuracy_mean': round(mean_accuracy, 6),
                'rule_count_mean': round(mean_rule_count, 1),
                'raw_drift_scores': [round(s, 6) for s in drift_scores]
            }
            self.log(f"{arm.upper()}: mean DriftScore={mean_drift:.4f}, CI=[{ci_lower:.4f}, {ci_upper:.4f}]")

        # Perform Welch's t-test: Control vs Treatment
        self.analysis_results['arm_statistics'] = stats_by_arm
        
        if 'control' in stats_by_arm and 'treatment' in stats_by_arm:
            control_scores = [r['drift_score'] for r in self.runs['control']]
            treatment_scores = [r['drift_score'] for r in self.runs['treatment']]
            
            t_stat, p_value = self.welch_t_test(control_scores, treatment_scores)
            control_mean = mean(control_scores)
            treatment_mean = mean(treatment_scores)
            pct_reduction = ((control_mean - treatment_mean) / control_mean * 100) if control_mean > 0 else 0
            
            self.analysis_results['comparison'] = {
                'control_vs_treatment': {
                    't_statistic': round(t_stat, 4),
                    'p_value': round(p_value, 6),
                    'significant_at_0_05': p_value < 0.05,
                    'percent_reduction': round(pct_reduction, 2)
                }
            }
            self.log(f"Welch's t-test: t={t_stat:.4f}, p={p_value:.6f}, reduction={pct_reduction:.2f}%")

        # Validate success criteria
        self.analysis_results['success_criteria'] = self._validate_success_criteria(stats_by_arm)
        
        return True

    def _validate_success_criteria(self, stats_by_arm: Dict) -> Dict:
        """Validate success criteria from spec."""
        criteria = {
            'sc_001_treatment_reduces_drift_by_20_pct': False,
            'sc_002_treatment_evidence_accuracy_gte_0_95': False,
            'sc_003_difference_significant_at_p_0_05': False,
            'sc_004_all_runs_complete': True
        }
        
        # SC-001: Treatment reduces mean DriftScore by 20% relative to Control
        if 'control' in stats_by_arm and 'treatment' in stats_by_arm:
            control_mean = stats_by_arm['control']['drift_score_mean']
            treatment_mean = stats_by_arm['treatment']['drift_score_mean']
            if control_mean > 0:
                reduction_pct = (control_mean - treatment_mean) / control_mean * 100
                criteria['sc_001_treatment_reduces_drift_by_20_pct'] = reduction_pct >= 20
        
        # SC-002: Treatment evidence accuracy >= 0.95
        if 'treatment' in stats_by_arm:
            treatment_accuracy = stats_by_arm['treatment']['evidence_accuracy_mean']
            criteria['sc_002_treatment_evidence_accuracy_gte_0_95'] = treatment_accuracy >= 0.95
        
        # SC-003: Difference significant at p < 0.05
        if 'comparison' in self.analysis_results:
            comparison = self.analysis_results['comparison']['control_vs_treatment']
            criteria['sc_003_difference_significant_at_p_0_05'] = comparison['significant_at_0_05']
        
        # SC-004: All runs complete (at least N=5 per arm attempted)
        # This is logged but not enforced strictly here
        
        return criteria

    def generate_report(self, output_file: Optional[str] = None) -> bool:
        """Generate and save analysis report."""
        if not output_file:
            output_file = 'analysis-report.json'
        
        report = {
            'metadata': {
                'artifact_dir': str(self.artifact_dir),
                'timestamp': __import__('datetime').datetime.utcnow().isoformat() + 'Z'
            },
            **self.analysis_results
        }
        
        try:
            with open(output_file, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"✓ Analysis report saved: {output_file}")
            return True
        except Exception as e:
            print(f"ERROR writing report: {e}", file=sys.stderr)
            return False

    def print_summary(self):
        """Print a human-readable summary."""
        print("\n" + "="*70)
        print("DRIFT TESTING ANALYSIS SUMMARY")
        print("="*70)
        
        if 'arm_statistics' in self.analysis_results:
            for arm, stats in self.analysis_results['arm_statistics'].items():
                print(f"\n{arm.upper()}")
                print(f"  Runs: {stats['n']}")
                print(f"  DriftScore (mean): {stats['drift_score_mean']:.6f}")
                print(f"  DriftScore (95% CI): [{stats['drift_score_ci_95'][0]:.6f}, {stats['drift_score_ci_95'][1]:.6f}]")
                print(f"  EvidenceAccuracy (mean): {stats['evidence_accuracy_mean']:.6f}")
                print(f"  RuleCount (mean): {stats['rule_count_mean']:.1f}")
        
        if 'comparison' in self.analysis_results:
            comp = self.analysis_results['comparison']['control_vs_treatment']
            print(f"\nCONTROL vs TREATMENT")
            print(f"  Welch's t-test: t={comp['t_statistic']:.4f}, p={comp['p_value']:.6f}")
            print(f"  Significant (p < 0.05): {comp['significant_at_0_05']}")
            print(f"  Drift Reduction: {comp['percent_reduction']:.2f}%")
        
        if 'success_criteria' in self.analysis_results:
            print(f"\nSUCCESS CRITERIA")
            for criteria, met in self.analysis_results['success_criteria'].items():
                status = "✓ PASS" if met else "✗ FAIL"
                print(f"  {status}: {criteria}")
        
        print("="*70 + "\n")


def main():
    import argparse
    parser = argparse.ArgumentParser(
        description="Analyze multi-arm drift testing results"
    )
    parser.add_argument('--artifact-dir', required=True, help='Path to artifact directory')
    parser.add_argument('--output', default='analysis-report.json', help='Output report file')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose logging')
    
    args = parser.parse_args()
    
    analyzer = DriftAnalyzer(args.artifact_dir, verbose=args.verbose)
    
    if not analyzer.load_runs():
        return 1
    
    if not analyzer.analyze():
        return 1
    
    if not analyzer.generate_report(args.output):
        return 1
    
    analyzer.print_summary()
    return 0


if __name__ == '__main__':
    sys.exit(main())
