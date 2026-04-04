"""Unit tests for DriftScore formula calculation."""

import pytest
import sys
from pathlib import Path

# Add src/drift to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "drift"))

from drift_score_calculator import DriftScoreCalculator


class TestDriftScoreFormula:
    """Tests for DriftScore formula."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.calc = DriftScoreCalculator()
    
    def test_drift_score_formula_max_accuracy(self):
        """If all metrics = 1.0, DriftScore should = 0.0."""
        # All perfect → no drift
        score = self.calc.calculate_drift_score(
            evidence_accuracy=1.0,
            semantic_similarity=1.0,
            rule_count=0
        )
        assert score == 0.0
    
    def test_drift_score_formula_min_accuracy(self):
        """If all metrics = 0.0, DriftScore should = 1.0."""
        # All bad → maximum drift
        score = self.calc.calculate_drift_score(
            evidence_accuracy=0.0,
            semantic_similarity=0.0,
            rule_count=2000
        )
        assert score == 1.0
    
    def test_drift_score_formula_weights(self):
        """Verify correct weight application (50%, 30%, 20%)."""
        # Test with 0.5 for each component
        score = self.calc.calculate_drift_score(
            evidence_accuracy=0.5,
            semantic_similarity=0.5,
            rule_count=1000  # 0.5 normalized
        )
        # DriftScore = 0.50 * 0.5 + 0.30 * 0.5 + 0.20 * 0.5 = 0.5
        assert abs(score - 0.5) < 0.01
    
    def test_rule_count_normalization(self):
        """RuleCount=2000 → norm=1.0; RuleCount=1000 → norm=0.5."""
        # 2000 rules = max
        score_2000 = self.calc.calculate_drift_score(
            evidence_accuracy=1.0,
            semantic_similarity=1.0,
            rule_count=2000
        )
        # 0.20 * 1.0 = 0.2
        assert abs(score_2000 - 0.2) < 0.01
        
        # 1000 rules = half
        score_1000 = self.calc.calculate_drift_score(
            evidence_accuracy=1.0,
            semantic_similarity=1.0,
            rule_count=1000
        )
        # 0.20 * 0.5 = 0.1
        assert abs(score_1000 - 0.1) < 0.01

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
