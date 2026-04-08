# Artifact Layout Specification

**Version**: 1.0  
**Purpose**: Define the directory and file structure for experiment artifacts

---

## Directory Structure

```
artifacts/drift-testing/
│
├── baseline/
│   ├── run-001/
│   │   ├── run-report.json              [REQUIRED] - Metrics and metadata
│   │   ├── gathered-rules.md            [REQUIRED] - Extracted rules
│   │   ├── logs.txt                     [REQUIRED] - Execution logs
│   │   └── git-ref.txt                  [OPTIONAL] - Git commit SHA
│   ├── run-002/ through run-005/
│
├── control/
│   ├── run-001/ through run-005/
│
├── treatment/
│   ├── run-001/ through run-005/
│
└── analysis/
    ├── experiment-analysis.json         [REQUIRED]
    └── experiment-summary.txt           [REQUIRED]
```

## File Count

- Per arm: 5 runs × 4 files/run = 20 files per arm
- Total runs: 3 arms × 20 files = 60 run files  
- Analysis files: 2+ files
- **Total**: 62+ artifact files

## Storage Size

- Per run: ~70 KB average
- Total 15 runs: ~1.1 MB
- Long-term storage for 10 experiments: ~100 MB
