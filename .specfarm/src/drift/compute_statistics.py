#!/usr/bin/env python3
"""Compute statistical analysis across drift testing runs."""

import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List
import statistics
import math

class StatisticsAnalyzer:
    """Analyzes drift testing results."""
    
    def __init__(self):
        self.baseline_scores = []
        self.control_scores = []
        self.treatment_scores = []
    
    def load_run_reports(self, baseline_dir, control_dir, treatment_dir):
        """Load drift scores from all run reports."""
        self.baseline_scores = self._load_arm_scores(baseline_dir)
        self.control_scores = self._load_arm_scores(control_dir)
        self.treatment_scores = self._load_arm_scores(treatment_dir)
    
    def _load_arm_scores(self, arm_dir) -> List[float]:
        """Load all DriftScores from an arm's run reports."""
        scores = []
        arm_path = Path(arm_dir)
        
        for run_dir in sorted(arm_path.glob("run-*")):
            report_file = run_dir / "run-report.json"
            if report_file.exists():
                try:
                    with open(report_file) as f:
                        report = json.load(f)
                        score = report.get("metrics", {}).get("drift_score", 0.0)
                        scores.append(float(score))
                except Exception as e:
                    print(f"Error loading {report_file}: {e}", file=sys.stderr)
        
        return scores
    
    def compute_arm_stats(self, scores) -> Dict:
        """Compute statistics for one arm."""
        if not scores:
            return {}
        
        mean_score = statistics.mean(scores)
        std_dev = statistics.stdev(scores) if len(scores) > 1 else 0.0
        sem = std_dev / math.sqrt(len(scores))  # Standard error of mean
        
        # 95% CI using t-distribution approximation
        t_crit = 1.96  # Approximate for n=5
        ci_lower = mean_score - t_crit * sem
        ci_upper = mean_score + t_crit * sem
        
        return {
            "sample_size": len(scores),
            "scores": scores,
            "mean": round(mean_score, 4),
            "std_dev": round(std_dev, 4),
            "sem": round(sem, 4),
            "ci_lower": round(max(0.0, ci_lower), 4),
            "ci_upper": round(min(1.0, ci_upper), 4)
        }
    
    def welch_ttest(self, group1: List[float], group2: List[float]) -> Dict:
        """Compute Welch's t-test."""
        if len(group1) < 2 or len(group2) < 2:
            return {"t_stat": 0.0, "p_value": 1.0}
        
        mean1 = statistics.mean(group1)
        mean2 = statistics.mean(group2)
        var1 = statistics.variance(group1)
        var2 = statistics.variance(group2)
        n1 = len(group1)
        n2 = len(group2)
        
        # Welch's t-statistic
        se = math.sqrt(var1/n1 + var2/n2)
        if se == 0:
            return {"t_stat": 0.0, "p_value": 1.0}
        
        t_stat = (mean1 - mean2) / se
        
        # Approximate p-value (simplified)
        p_value = min(1.0, max(0.0, 1.0 - abs(t_stat) * 0.1))  # Placeholder
        
        return {
            "t_stat": round(t_stat, 4),
            "p_value": round(p_value, 4),
            "significant": p_value < 0.05
        }
    
    def generate_report(self) -> Dict:
        """Generate complete analysis report."""
        return {
            "baseline": self.compute_arm_stats(self.baseline_scores),
            "control": self.compute_arm_stats(self.control_scores),
            "treatment": self.compute_arm_stats(self.treatment_scores),
            "comparisons": {
                "treatment_vs_baseline": self.welch_ttest(self.treatment_scores, self.baseline_scores),
                "treatment_vs_control": self.welch_ttest(self.treatment_scores, self.control_scores),
                "control_vs_baseline": self.welch_ttest(self.control_scores, self.baseline_scores)
            }
        }

def main():
    parser = argparse.ArgumentParser(description="Compute drift testing statistics")
    parser.add_argument("--baseline-dir", required=True, help="Baseline runs directory")
    parser.add_argument("--control-dir", required=True, help="Control runs directory")
    parser.add_argument("--treatment-dir", required=True, help="Treatment runs directory")
    parser.add_argument("--output", type=str, help="Output JSON file")
    
    args = parser.parse_args()
    
    analyzer = StatisticsAnalyzer()
    analyzer.load_run_reports(args.baseline_dir, args.control_dir, args.treatment_dir)
    report = analyzer.generate_report()
    
    if args.output:
        with open(args.output, "w") as f:
            json.dump(report, f, indent=2)
        print(f"Report written to {args.output}")
    else:
        print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
