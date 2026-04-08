"""pytest configuration for constitutional drift testing experiment."""

import pytest
import json
import tempfile
from pathlib import Path


@pytest.fixture
def sample_baseline_rules():
    """Fixture: Baseline rules (empty)."""
    return []


@pytest.fixture
def sample_control_rules():
    """Fixture: Sample control rules from production."""
    return [
        {
            "id": "rule-1",
            "signature": "shell-prefer-posix",
            "certainty": 0.85,
            "description": "Prefer POSIX shells"
        },
        {
            "id": "rule-2",
            "signature": "shell-disable-pagination",
            "certainty": 0.80,
            "description": "Disable pagination"
        }
    ]


@pytest.fixture
def sample_treatment_rules():
    """Fixture: Treatment rules with constitutional core."""
    baseline = [
        {
            "id": "const-core-1",
            "signature": "constitutional principle",
            "certainty": 0.95,
            "description": "Constitutional core enforcement"
        }
    ]
    return baseline


@pytest.fixture
def temp_run_directory():
    """Fixture: Temporary directory for run artifacts."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)


@pytest.fixture
def mock_run_report(temp_run_directory):
    """Fixture: Mock run-report.json file."""
    report = {
        "experiment_metadata": {
            "run_id": "baseline-001",
            "arm": "baseline",
            "run_number": 1,
            "timestamp": "2026-04-04T00:00:00Z",
            "target_repo": "cypress-realworld-app",
            "target_repo_commit": "abc123def456"
        },
        "metrics": {
            "rule_count": 0,
            "evidence_accuracy": 0.0,
            "semantic_similarity": 1.0,
            "drift_score": 0.0
        }
    }
    
    report_file = temp_run_directory / "run-report.json"
    with open(report_file, "w") as f:
        json.dump(report, f)
    
    return report_file


def pytest_configure(config):
    """pytest hook: Register custom markers."""
    config.addinivalue_line("markers", "integration: mark as integration test")
    config.addinivalue_line("markers", "unit: mark as unit test")
