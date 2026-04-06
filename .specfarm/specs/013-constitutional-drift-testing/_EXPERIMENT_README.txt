================================================================================
                 CONSTITUTIONAL DRIFT TESTING EXPERIMENT
                     Reproducible Copy-To-Other-Repo Guide
================================================================================

OVERVIEW:
This directory contains everything needed to reproduce the constitutional
drift testing experiment in another repository. The experiment measures
whether injecting constitutional rules reduces rule gathering drift.

QUICK START (3 steps):

  1. Copy these files to another repo:
     $ cp experiment_harness.sh drift_analytics_multiarm.py rules-*.xml \
       run_full_drift_experiment.sh /path/to/other/repo/spec-013/

  2. Bootstrap SpecFarm in the target repo:
     $ bash /path/to/specfarm/scripts/install-specfarm.sh --target . --yes

  3. Run the full experiment:
     $ cd /path/to/other/repo/spec-013
     $ ./run_full_drift_experiment.sh /path/to/target-repo

  Result: artifacts/drift-testing/ with 15 runs + analysis-report.json

FILES IN THIS DIRECTORY:

  experiment_harness.sh
    ├─ Single run executor (Bash)
    ├─ Usage: bash experiment_harness.sh --repo <path> --arm <arm> \
    │                                     --run <N> --rules <xml> --output <dir>
    └─ Handles: clone setup, rules injection, metrics calculation, artifact collection

  drift_analytics_multiarm.py
    ├─ Multi-arm statistical analyzer (Python 3)
    ├─ Usage: python3 drift_analytics_multiarm.py --artifact-dir <dir>
    └─ Outputs: means, 95% CI, Welch's t-test, success criteria validation

  run_full_drift_experiment.sh
    ├─ Complete experiment wrapper (Bash)
    ├─ Runs all 15 experiments (5 per arm) and analysis automatically
    └─ Usage: ./run_full_drift_experiment.sh <target-repo-path>

  fixtures/rules-*.xml
    ├─ rules-baseline.xml   (empty fixture)
    ├─ rules-control.xml    (current production rules)
    └─ rules-treatment.xml  (constitutional core injected)

  spec.md
    └─ Full formal specification with requirements and design details

  EXPERIMENT_QUICKSTART.md
    └─ Detailed walkthrough with examples and troubleshooting

  COPY_TO_OTHER_REPO.md
    └─ Step-by-step guide for copying the experiment to another repo

  _EXPERIMENT_README.txt (this file)
    └─ Overview and quick reference

EXPERIMENT DESIGN:

  Three Arms (5 runs each):
    • Baseline: Empty rules (zero rules fixture)
    • Control:  Current production rules
    • Treatment: Constitutional core + production rules

  Metrics per Run:
    • DriftScore (composite: EvidenceAccuracy, SemanticSimilarity, RuleCount)
    • RuleCount (number of rules gathered)
    • EvidenceAccuracy (0.0–1.0)
    • SemanticSimilarity (0.0–1.0)

  Output Structure:
    artifacts/drift-testing/
    ├── baseline/run-1/run-report.json
    ├── baseline/run-1/gathered-rules.md
    ├── baseline/run-1/logs.txt
    ├── ... (baseline runs 2-5)
    ├── control/ ... (5 runs)
    ├── treatment/ ... (5 runs)
    └── ../analysis-report.json (final statistical summary)

SUCCESS CRITERIA (from spec):

  SC-001: Treatment reduces mean DriftScore by ≥20% vs Control
  SC-002: Treatment mean EvidenceAccuracy ≥ 0.95
  SC-003: Control vs Treatment difference is significant (p < 0.05)
  SC-004: 100% of runs complete with valid run-report.json

  See analysis-report.json → success_criteria for validation.

TYPICAL WORKFLOW:

  Step 1: Copy to other repo
    cd /path/to/other/repo
    mkdir spec-013-experiment
    cp /path/to/specfarm/specs/013-constitutional-drift-testing/* spec-013-experiment/

  Step 2: Install SpecFarm (if not already)
    git clone <target-repo-url> target-repo
    cd target-repo
    bash /path/to/specfarm/scripts/install-specfarm.sh --target . --yes

  Step 3: Run full experiment
    cd spec-013-experiment
    ./run_full_drift_experiment.sh ../target-repo

  Step 4: Review results
    cat artifacts/drift-testing/../analysis-report.json

EXPECTED RUNTIME:
  • 15 runs × 2–5 minutes each = ~30–75 minutes total
  • Analysis: ~10 seconds
  • Total: 30–90 minutes depending on target repo size

REQUIREMENTS:
  • Bash 4.0+ (macOS: brew install bash)
  • Python 3.7+ with scipy (pip install scipy)
  • Git (for cloning)
  • Target repo with SpecFarm installed

TROUBLESHOOTING:

  Q: "No runs generated"
  A: Check that rule fixtures exist and .specfarm/ structure is in target repo

  Q: "Analytics fails with JSON error"
  A: Verify run-report.json files are valid: jq . artifacts/drift-testing/*/run-1/run-report.json

  Q: "gather-rules-agent returns nothing"
  A: Check logs.txt in artifact directory; may indicate missing dependencies in target repo

MORE INFORMATION:
  • Full specification: spec.md
  • Detailed quickstart: EXPERIMENT_QUICKSTART.md
  • Copy guide: COPY_TO_OTHER_REPO.md

================================================================================
