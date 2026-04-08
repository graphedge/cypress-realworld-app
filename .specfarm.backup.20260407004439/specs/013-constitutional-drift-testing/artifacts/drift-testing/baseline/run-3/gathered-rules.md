[0;34m
╔══════════════════════════════════════════════════╗
║     Generic Rules Gathering Agent                ║
║     Project-Agnostic Rule Discovery & Generation ║
╚══════════════════════════════════════════════════╝
[0m

[0;32m===[0m [0;34mValidating Environment[0m [0;32m===[0m
  [0;32m[✓][0m Git repository detected
  [1;33m[WARN][0m Schema file not found: /tmp/drift-baseline-run-3-8997/rules-schema.xsd
  [1;33m[INFO][0m Continuing without schema validation
  [0;32m[✓][0m Output directory writable: /tmp/drift-baseline-run-3-8997
  [1;33m[INFO][0m Auto-enabled --scan-tests (rules: 0 < param(1) × tests: 175)
  [1;33m[INFO][0m Invalidating commit cache: rules.xml mtime changed (1775364222 -> 1775450312)
  [1;33m[INFO][0m Re-created commit cache (last_cached_sha=5146f7c32175a6db73755fd984fd60f50635cc1f)

[0;32m===[0m [0;34mScanning Repository[0m [0;32m===[0m
  [1;33m[INFO][0m Repository: /tmp/drift-baseline-run-3-8997
  [1;33m[INFO][0m Commit range: HEAD~20..HEAD
  [1;33m[WARN][0m Commit range may not exist; using HEAD~10..HEAD as fallback
  [0;32m[✓][0m Found 18 commits in range
  [1;33m[INFO][0m Recent commits:
    5146f7c drift trial 3 prep
    73c2de2 drift trial 2
    b07fa13 experiment(013): Run 2 — 15/15 complete, analytics fixed
    56956ac docs: Add constitutional drift testing experiment results
    5c821cb Fix: Correct JSON generation in experiment_harness.sh

[0;32m===[0m [0;34mGenerating Report[0m [0;32m===[0m
  [0;32m[✓][0m Report generated: /tmp/drift-baseline-run-3-8997/gathered-rules.md

[0;32m===[0m [0;34m✓ Execution Complete[0m [0;32m===[0m
  [0;32m[✓][0m Report available: /tmp/drift-baseline-run-3-8997/gathered-rules.md
  [1;33m[INFO][0m Review the report and follow integration instructions
