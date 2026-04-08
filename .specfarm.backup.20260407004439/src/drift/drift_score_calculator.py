#!/usr/bin/env python3
"""
DriftScore Calculator for Constitutional Drift Testing

Calculates composite DriftScore from evidence accuracy, semantic similarity,
and rule count metrics. Formula:

  DriftScore = 0.50 * (1.0 - EvidenceAccuracy)
             + 0.30 * (1.0 - SemanticSimilarity)
             + 0.20 * RuleCountNormalized

Where:
  - EvidenceAccuracy: Fraction of rules with verifiable evidence [0.0-1.0]
  - SemanticSimilarity: Coherence of rule signatures [0.0-1.0]
  - RuleCountNormalized: min(RuleCount / 2000, 1.0)
"""

import sys
import json
import argparse
import logging
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import subprocess

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
log = logging.getLogger(__name__)


class DriftScoreCalculator:
    """Calculates DriftScore and component metrics."""
    
    # Weights for composite score
    WEIGHT_EVIDENCE = 0.50
    WEIGHT_SEMANTIC = 0.30
    WEIGHT_RULE_COUNT = 0.20
    
    # Rule count threshold for normalization
    RULE_COUNT_THRESHOLD = 2000
    
    def __init__(self):
        """Initialize calculator with default parameters."""
        self.evidence_search_timeout = 5  # seconds
    
    def calculate_drift_score(
        self,
        evidence_accuracy: float,
        semantic_similarity: float,
        rule_count: int
    ) -> float:
        """
        Calculate composite DriftScore.
        
        Args:
            evidence_accuracy: Float in [0.0-1.0]
            semantic_similarity: Float in [0.0-1.0]
            rule_count: Non-negative integer
            
        Returns:
            DriftScore as float in [0.0-1.0]
        """
        # Validate inputs
        if not (0.0 <= evidence_accuracy <= 1.0):
            raise ValueError(f"evidence_accuracy must be in [0.0-1.0], got {evidence_accuracy}")
        if not (0.0 <= semantic_similarity <= 1.0):
            raise ValueError(f"semantic_similarity must be in [0.0-1.0], got {semantic_similarity}")
        if rule_count < 0:
            raise ValueError(f"rule_count must be non-negative, got {rule_count}")
        
        # Normalize rule count (saturate at 1.0)
        rule_count_norm = min(rule_count / self.RULE_COUNT_THRESHOLD, 1.0)
        
        # Apply formula
        drift_score = (
            self.WEIGHT_EVIDENCE * (1.0 - evidence_accuracy) +
            self.WEIGHT_SEMANTIC * (1.0 - semantic_similarity) +
            self.WEIGHT_RULE_COUNT * rule_count_norm
        )
        
        # Ensure within valid range
        return max(0.0, min(1.0, drift_score))
    
    def calculate_semantic_similarity(self, rules_list: List[Dict]) -> float:
        """
        Calculate Jaccard-based semantic similarity of rule signatures.
        
        Similarity = average pairwise Jaccard index of tokenized signatures
        
        Args:
            rules_list: List of rule dicts with 'signature' key
            
        Returns:
            Float in [0.0-1.0]
        """
        if not rules_list or len(rules_list) < 2:
            return 1.0  # Single rule = perfect self-similarity
        
        similarities = []
        
        for i, rule1 in enumerate(rules_list):
            sig1 = rule1.get('signature', '')
            tokens1 = set(sig1.lower().split())
            
            for j in range(i + 1, len(rules_list)):
                rule2 = rules_list[j]
                sig2 = rule2.get('signature', '')
                tokens2 = set(sig2.lower().split())
                
                # Compute Jaccard similarity
                if not tokens1 and not tokens2:
                    similarity = 1.0
                elif not tokens1 or not tokens2:
                    similarity = 0.0
                else:
                    intersection = len(tokens1 & tokens2)
                    union = len(tokens1 | tokens2)
                    similarity = intersection / union if union > 0 else 0.0
                
                similarities.append(similarity)
        
        return sum(similarities) / len(similarities) if similarities else 1.0
    
    def calculate_evidence_accuracy(
        self,
        rules_list: List[Dict],
        codebase_path: str
    ) -> float:
        """
        Calculate evidence accuracy via signature matching in codebase.
        
        Evidence Accuracy = (true_positive_rules / total_rules) * avg_certainty
        
        Args:
            rules_list: List of rule dicts with 'signature' and optionally 'certainty' keys
            codebase_path: Path to target repository
            
        Returns:
            Float in [0.0-1.0]
        """
        if not rules_list:
            return 0.0
        
        total_count = len(rules_list)
        tp_count = 0
        certainty_sum = 0.0
        
        for rule in rules_list:
            sig = rule.get('signature', '').strip()
            
            # Skip rules with empty signatures
            if not sig:
                continue
            
            # Search for signature in codebase using grep
            try:
                result = subprocess.run(
                    ['grep', '-r', '-F', sig, codebase_path],
                    capture_output=True,
                    timeout=self.evidence_search_timeout,
                    text=True
                )
                
                if result.returncode == 0:
                    # Signature found in codebase
                    tp_count += 1
                    certainty = float(rule.get('certainty', 0.5))
                    certainty = max(0.0, min(1.0, certainty))  # Clamp to [0.0-1.0]
                    certainty_sum += certainty
            
            except subprocess.TimeoutExpired:
                log.warning(f"Signature search timeout for: {sig[:50]}")
                continue
            except Exception as e:
                log.warning(f"Error searching for signature: {e}")
                continue
        
        # Calculate accuracy
        if tp_count == 0:
            return 0.0
        
        matched_certainty = certainty_sum / tp_count
        evidence_accuracy = (tp_count / total_count) * matched_certainty
        
        return max(0.0, min(1.0, evidence_accuracy))
    
    def calculate_from_metrics_file(self, metrics_json_path: str) -> Dict:
        """
        Read metrics from JSON file and calculate DriftScore.
        
        Expected JSON structure:
        {
            "rule_count": 142,
            "evidence_accuracy": 0.68,
            "semantic_similarity": 0.72,
            "codebase_path": "/path/to/repo"  [optional]
        }
        
        Args:
            metrics_json_path: Path to metrics JSON file
            
        Returns:
            Dict with 'drift_score', 'evidence_accuracy', 'semantic_similarity', 'rule_count'
        """
        try:
            with open(metrics_json_path, 'r') as f:
                metrics = json.load(f)
        except Exception as e:
            log.error(f"Failed to read metrics file: {e}")
            raise
        
        rule_count = metrics.get('rule_count', 0)
        evidence_accuracy = metrics.get('evidence_accuracy', 0.0)
        semantic_similarity = metrics.get('semantic_similarity', 1.0)
        
        drift_score = self.calculate_drift_score(
            evidence_accuracy=evidence_accuracy,
            semantic_similarity=semantic_similarity,
            rule_count=rule_count
        )
        
        return {
            'drift_score': drift_score,
            'evidence_accuracy': evidence_accuracy,
            'semantic_similarity': semantic_similarity,
            'rule_count': rule_count,
            'rule_count_normalized': min(rule_count / self.RULE_COUNT_THRESHOLD, 1.0)
        }


def main():
    """CLI entry point for drift score calculation."""
    parser = argparse.ArgumentParser(
        description='Calculate DriftScore for constitutional drift testing',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  # Calculate from metrics JSON file
  %(prog)s --metrics-file metrics.json --output results.json
  
  # Calculate with direct arguments
  %(prog)s --evidence-accuracy 0.68 --semantic-similarity 0.72 --rule-count 142
  
  # Verbose mode
  %(prog)s --metrics-file metrics.json --verbose
        '''
    )
    
    parser.add_argument(
        '--metrics-file',
        type=str,
        help='Path to metrics JSON file containing evidence_accuracy, semantic_similarity, rule_count'
    )
    parser.add_argument(
        '--evidence-accuracy',
        type=float,
        help='Evidence accuracy score [0.0-1.0]'
    )
    parser.add_argument(
        '--semantic-similarity',
        type=float,
        help='Semantic similarity score [0.0-1.0]'
    )
    parser.add_argument(
        '--rule-count',
        type=int,
        help='Number of extracted rules'
    )
    parser.add_argument(
        '--output',
        type=str,
        help='Output file for results (JSON format)'
    )
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Verbose logging'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    calculator = DriftScoreCalculator()
    
    try:
        if args.metrics_file:
            # Calculate from metrics file
            results = calculator.calculate_from_metrics_file(args.metrics_file)
        elif args.evidence_accuracy is not None and args.semantic_similarity is not None and args.rule_count is not None:
            # Calculate from command-line arguments
            drift_score = calculator.calculate_drift_score(
                evidence_accuracy=args.evidence_accuracy,
                semantic_similarity=args.semantic_similarity,
                rule_count=args.rule_count
            )
            results = {
                'drift_score': drift_score,
                'evidence_accuracy': args.evidence_accuracy,
                'semantic_similarity': args.semantic_similarity,
                'rule_count': args.rule_count,
                'rule_count_normalized': min(args.rule_count / calculator.RULE_COUNT_THRESHOLD, 1.0)
            }
        else:
            parser.print_help()
            sys.exit(1)
        
        # Output results
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(results, f, indent=2)
            log.info(f"Results written to {args.output}")
        else:
            print(json.dumps(results, indent=2))
        
        # Print summary
        log.info(f"DriftScore: {results['drift_score']:.4f}")
        sys.exit(0)
    
    except Exception as e:
        log.error(f"Calculation failed: {e}", exc_info=args.verbose)
        sys.exit(1)


if __name__ == '__main__':
    main()
