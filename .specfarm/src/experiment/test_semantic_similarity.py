"""Unit tests for SemanticSimilarity calculation."""

import pytest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "drift"))

from drift_score_calculator import DriftScoreCalculator


class TestSemanticSimilarity:
    """Tests for semantic similarity calculation."""
    
    def setup_method(self):
        self.calc = DriftScoreCalculator()
    
    def test_identical_rules_similarity_1_0(self):
        """Same rule text → 1.0 similarity."""
        rules = [
            {"signature": "shell prefer posix"},
            {"signature": "shell prefer posix"}
        ]
        similarity = self.calc.calculate_semantic_similarity(rules)
        assert similarity == 1.0
    
    def test_completely_different_rules_similarity_0_0(self):
        """No overlap → 0.0 similarity."""
        rules = [
            {"signature": "alpha beta gamma"},
            {"signature": "echo foxtrot hotel"}
        ]
        similarity = self.calc.calculate_semantic_similarity(rules)
        assert similarity == 0.0
    
    def test_partial_overlap(self):
        """Token overlap → [0.0-1.0] similarity."""
        rules = [
            {"signature": "shell prefer posix safe"},
            {"signature": "shell disable pagination"}
        ]
        similarity = self.calc.calculate_semantic_similarity(rules)
        # Tokens overlap on "shell" only: |{shell}| / |{shell, prefer, posix, safe, disable, pagination}| = 1/6
        assert 0.0 < similarity < 1.0
    
    def test_single_rule_perfect_similarity(self):
        """Single rule = perfect self-similarity."""
        rules = [{"signature": "some rule"}]
        similarity = self.calc.calculate_semantic_similarity(rules)
        assert similarity == 1.0
    
    def test_empty_rules_perfect_similarity(self):
        """No rules = perfect similarity (vacuously true)."""
        similarity = self.calc.calculate_semantic_similarity([])
        assert similarity == 1.0

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
