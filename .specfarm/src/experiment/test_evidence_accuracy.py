"""Unit tests for EvidenceAccuracy calculation."""

import pytest
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "drift"))

from drift_score_calculator import DriftScoreCalculator


class TestEvidenceAccuracy:
    """Tests for evidence accuracy calculation."""
    
    def setup_method(self):
        self.calc = DriftScoreCalculator()
        self.temp_repo = tempfile.TemporaryDirectory()
    
    def teardown_method(self):
        self.temp_repo.cleanup()
    
    def test_all_rules_found_accuracy_1_0(self):
        """All rule signatures in codebase → 1.0."""
        # Create test file with matching signatures
        test_file = Path(self.temp_repo.name) / "test.py"
        test_file.write_text("shell prefer posix\nshell disable pagination\n")
        
        rules = [
            {"signature": "shell prefer posix", "certainty": 1.0},
            {"signature": "shell disable pagination", "certainty": 1.0}
        ]
        
        accuracy = self.calc.calculate_evidence_accuracy(rules, self.temp_repo.name)
        # 2/2 rules found, all with certainty 1.0 → 1.0
        assert accuracy == 1.0
    
    def test_no_rules_found_accuracy_0_0(self):
        """No signatures match → 0.0."""
        rules = [
            {"signature": "nonexistent_pattern_xyz", "certainty": 1.0}
        ]
        
        accuracy = self.calc.calculate_evidence_accuracy(rules, self.temp_repo.name)
        assert accuracy == 0.0
    
    def test_partial_evidence_accuracy(self):
        """Some rules found → [0.0-1.0]."""
        # Create test file with only one signature
        test_file = Path(self.temp_repo.name) / "test.py"
        test_file.write_text("shell prefer posix\n")
        
        rules = [
            {"signature": "shell prefer posix", "certainty": 1.0},
            {"signature": "nonexistent_pattern", "certainty": 1.0}
        ]
        
        accuracy = self.calc.calculate_evidence_accuracy(rules, self.temp_repo.name)
        # 1/2 rules found, certainty 1.0 → 0.5
        assert 0.0 < accuracy < 1.0
        assert abs(accuracy - 0.5) < 0.1
    
    def test_empty_rules_zero_accuracy(self):
        """No rules = 0.0 accuracy."""
        accuracy = self.calc.calculate_evidence_accuracy([], self.temp_repo.name)
        assert accuracy == 0.0

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
