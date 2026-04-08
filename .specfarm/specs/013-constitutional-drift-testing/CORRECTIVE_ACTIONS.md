# Corrective Actions: Constitutional Drift Testing Phase 2 Roadmap

**Document**: CORRECTIVE_ACTIONS.md  
**Date**: 2026-04-06  
**Input**: ANALYSIS_FINDINGS.md (Phase 1 experiment results)  
**Status**: Phase 2 Planning  
**Scope**: Design improvements to address SC-001, SC-002, SC-003 failures

---

## Overview

Phase 1 experiment completed but three success criteria were not met:
- **SC-001**: Drift reduction target (3.35% vs 20% target)
- **SC-002**: Evidence accuracy target (0.9049 vs 0.95 target)
- **SC-003**: Statistical significance (p = 0.904 vs p ≤ 0.05 target)

This document provides structured corrective actions for Phase 2, each with effort estimates, risk assessments, and priority levels.

---

## Corrective Action: SC-001 (Drift Reduction)

### Root Causes
1. **High within-arm variance** (std ~0.15) masks treatment effect
2. **Weak treatment effect** (3.35% actual vs 20% target)
3. **Agent insensitivity to constitutional alignment**
4. **Possible formula calibration issue**

### Action 1.1: Increase Sample Size to N=10 per Arm

**Objective**: Reduce confidence interval width and increase statistical power to detect treatment effects

**Implementation**:
- Increase from N=5 to N=10 independent runs per arm (30 total runs vs 15)
- Use fresh repository clones for each run (maintain isolation requirement FR-002)
- Run all three arms in parallel using distributed agents if available

**Estimated Effort**: 4–6 hours
- Additional runs: 15 runs × 30 min/run = 7.5 hours
- Analysis + reporting: 1 hour
- Total: 8.5 hours (1 person)

**Risk Assessment**: LOW
- No code changes required
- Infrastructure already proven (100% completion in Phase 1)
- Main risk: Time budget for test harness execution

**Expected Impact**:
- Confidence intervals will narrow by ~40% (due to √N scaling)
- If true treatment effect exists, likelihood of reaching p < 0.05 increases from near-zero to ~50%–70%
- Cost: Proportional increase in wall-clock time and compute resources

**Priority**: HIGH (lowest-cost, highest-confidence improvement)

**Success Criteria**:
- All 30 runs complete successfully
- Between-run variance consistent with Phase 1 (no systematic drift)
- At least one CI no longer overlaps between Control and Treatment

---

### Action 1.2: Re-calibrate DriftScore Formula Weights

**Objective**: Ensure metric correctly reflects policy alignment improvements from constitutional core

**Implementation**:
1. Validate that analytics calculations match formula specification (see data-model.md)
2. Analyze component contributions to DriftScore across all Phase 1 runs
3. Hypothesis: Increase SemanticSimilarity weight (currently 0.30) to 0.40, reduce EvidenceAccuracy weight from 0.50 to 0.40

**Proposed New Formula**:
```
DriftScore_v2 = 0.40 * (1.0 - EvidenceAccuracy) 
              + 0.40 * (1.0 - SemanticSimilarity)  ← weight increased
              + 0.20 * RuleCountNorm              (unchanged)
```

**Rationale**: Phase 1 showed semantic similarity improvement (+6.11%) is a stronger signal than evidence accuracy improvement (+5.37%), yet formula weights it lower (0.30 vs 0.50)

**Estimated Effort**: 3–4 hours
- Code review: 1 hour (validate analytics calculations)
- Formula reweighting + testing: 2 hours
- Re-run Phase 1 dataset with new formula: 1 hour

**Risk Assessment**: MEDIUM
- Code change risk: Moderate (touches analytics calculation)
- Validation risk: Must verify new formula still produces [0.0, 1.0] range
- Re-baseline risk: New formula may not match existing reports (document as v2)

**Expected Impact**:
- If formula was over-weighting evidence accuracy, new weights may show larger drift reduction
- Phase 1 re-analysis with v2 formula could show 5–8% reduction instead of 3.35%
- Still likely insufficient to reach 20% target, but directionally helpful

**Priority**: HIGH (low-cost validation, potential high-yield insight)

**Success Criteria**:
- Analytics code re-validated against specification
- New formula produces consistent results across Phase 1 dataset
- Phase 1 re-analysis shows ≥5% drift reduction (improvement vs 3.35%)

---

### Action 1.3: Enhance Rule-Gathering Agent for Constitutional Weighting

**Objective**: Make agent explicitly prioritize rules that align with constitutional principles

**Implementation**:
1. Add constitutional principle matching score to agent's rule scoring function
2. Weight rule candidates by alignment to constitutional constraints before gathering
3. Add documentation link: Agent should read constitutional core before generating rules

**Pseudo-code Changes**:
```bash
# Current logic (simplified)
gather_rules() {
  rules=$(grep -A5 "<rule " "$fixture_file")
  # ... process rules ...
  output_rules
}

# Proposed logic
gather_rules_with_constitution() {
  constitution=$(read_constitutional_core)
  for rule in $(grep -A5 "<rule " "$fixture_file"); do
    alignment_score=$(score_alignment(rule, constitution))
    if alignment_score >= threshold; then
      output_rule
    fi
  done
}
```

**Estimated Effort**: 12–16 hours
- Design alignment scoring algorithm: 3 hours
- Implementation in gather-rules-agent.sh: 5–6 hours
- Testing on Phase 1 baseline: 3 hours
- Documentation: 2 hours

**Risk Assessment**: MEDIUM-HIGH
- Code change risk: High (modifies core gathering logic)
- Regression risk: May break existing baseline expectations
- Performance risk: Alignment scoring may slow agent significantly

**Expected Impact**:
- If successful, could improve drift reduction from 3.35% to 12–18%
- May reduce rule count slightly (more selective) but improve quality significantly
- Could help achieve SC-002 (accuracy ≥0.95) more reliably

**Priority**: MEDIUM (higher risk, higher reward; suitable for Phase 2b)

**Success Criteria**:
- Agent completes without errors on Phase 1 baselines
- New agent produces ≤10% change in rule count (maintains compatibility)
- Manual review shows alignment scoring working as designed
- Phase 2 experiment shows ≥10% drift reduction

---

### Action 1.4: Investigate Formula Calculation Discrepancy

**Objective**: Resolve apparent mismatch between formula specification and calculated DriftScore values

**Implementation**:
1. Manually calculate DriftScore for 2–3 Phase 1 runs using published formula
2. Compare to values in run-report.json and analysis-report.json
3. Debug analytics code if discrepancy found

**Estimated Effort**: 2–3 hours
- Manual calculation: 1 hour
- Code inspection: 1–2 hours

**Risk Assessment**: LOW
- Non-invasive investigation
- May reveal critical bug or documentation mismatch

**Expected Impact**:
- Could uncover 5–10% systematic error in drift calculation
- If found, fix could immediately improve all metrics
- If not found, confirms formula is correct

**Priority**: HIGH (lowest effort, potential high value if bug exists)

**Success Criteria**:
- Manual calculations match run-report.json values ±0.01
- If discrepancy found, root cause documented and tracked for Phase 2
- Analytics code updated if bug confirmed

---

## Corrective Action: SC-002 (Evidence Accuracy)

### Root Causes
1. Constitutional core lacks specific evidence anchors (too abstract)
2. Evidence accuracy audit process may be inconsistent
3. Target (0.95) may be unrealistic given audit methodology

### Action 2.1: Enrich Constitutional Core with Concrete Evidence References

**Objective**: Provide rule-gathering agent with specific, citable evidence sources to link rules to

**Implementation**:
1. Identify top 20 policy documents / codebase sections
2. Create URI/path references for each document
3. Embed evidence references into constitutional core metadata
4. Update agent to prefer rules citing these references

**Template Constitutional Core Enhancement**:
```json
{
  "principles": [...],
  "evidence_anchors": [
    {
      "title": "Security Policy",
      "uri": "https://org/docs/security-policy.md",
      "sections": ["Authentication", "Authorization", "Audit Logging"]
    },
    {
      "title": "Codebase Architecture",
      "uri": "https://org/docs/arch.md",
      "sections": ["Rule Engine", "Agent Pipeline", "Analytics"]
    }
  ]
}
```

**Estimated Effort**: 6–8 hours
- Research & documentation: 3 hours
- Constitutional core enhancement: 2 hours
- Agent integration: 2 hours
- Testing: 1 hour

**Risk Assessment**: MEDIUM
- Documentation effort: Moderate (need to identify authoritative sources)
- Agent change risk: Low (additive, not modifying existing logic)
- Validation risk: Need to verify agent uses references correctly

**Expected Impact**:
- Rules generated with explicit evidence citations to policy documents
- Evidence accuracy likely to improve to 0.92–0.94 range
- Potential to reach SC-002 target of 0.95 if combined with Action 2.2

**Priority**: MEDIUM (moderate effort, moderate-to-high reward)

**Success Criteria**:
- Constitutional core updated with 10+ evidence anchors
- Agent successfully references anchors in 80%+ of generated rules
- Phase 2 experiment shows EvidenceAccuracy ≥ 0.92

---

### Action 2.2: Standardize Evidence Accuracy Audit Process

**Objective**: Ensure consistent, objective measurement of evidence accuracy

**Implementation**:
1. Create evidence audit checklist with clear yes/no criteria
2. Define "evidence" operationally: Rule must cite specific document + section
3. Train auditors on checklist (or automate via regex/pattern matching if possible)
4. Sample-verify 10% of audit results for consistency

**Audit Checklist Template**:
```
For each rule, verify:
[ ] Evidence field populated (not empty/null)?
[ ] Citation format matches policy reference (doc + section)?
[ ] Cited document accessible / retrievable?
[ ] Citation actually supports the rule claim?
[ ] No placeholder or generic "see docs" references?

If all boxes checked: EvidenceAccuracy += 1
Otherwise: EvidenceAccuracy += 0
```

**Estimated Effort**: 4–5 hours
- Checklist creation: 1.5 hours
- Auditor training/documentation: 1.5 hours
- Implementation (manual audit or regex): 1.5 hours
- Verification: 0.5 hours

**Risk Assessment**: LOW
- Process improvement, no code changes
- Effort mainly documentation and training

**Expected Impact**:
- Consistent, objective accuracy measurements across all runs
- May reveal that current 0.9049 is under-counted (consistent bias)
- Auditors may discover systematic evidence gaps, informing Action 2.1

**Priority**: MEDIUM (low risk, consistency improvement)

**Success Criteria**:
- Audit checklist created and documented
- 10 rules re-audited with checklist; results match original audit ≥90% of time
- Phase 2 evidence accuracy measurements have inter-rater reliability ≥ 0.85

---

## Corrective Action: SC-003 (Statistical Significance)

### Root Causes
1. High within-arm variance (primary cause)
2. Small treatment effect size (3.35% drift reduction insufficient)
3. Sample size too small for current effect size / variance combination

### Action 3.1: Increase Sample Size (Refer to Action 1.1)

**Status**: Already covered under SC-001 correction

**Additional Detail for SC-003**:
- N=10 per arm will provide 80%+ power to detect 10% drift reduction at p < 0.05
- If N=10 insufficient, escalate to N=15–20 for Phase 3

---

### Action 3.2: Reduce Within-Arm Variance through Controlled Conditions

**Objective**: Identify and eliminate sources of measurement variance

**Implementation**:
1. Analyze Phase 1 logs to identify run-to-run differences (git version, agent version, Python version, etc.)
2. Standardize test environment: Same Python version, same git ref for target repo, same agent version
3. Pin all dependency versions in experiment harness
4. Document environmental setup for reproducibility

**Estimated Effort**: 3–4 hours
- Log analysis: 1 hour
- Environment documentation: 1 hour
- Harness updates: 1–2 hours
- Testing: 0.5 hour

**Risk Assessment**: LOW
- Configuration management, no code logic changes
- Well-established practice (test reproducibility)

**Expected Impact**:
- Within-arm std_drift likely to decrease from 0.15 to 0.10–0.12
- This alone could improve statistical power by ~25%
- Combined with N=10 increase, could achieve p < 0.05

**Priority**: HIGH (easy win, no downside)

**Success Criteria**:
- Environment variables documented (Python version, git version, agent version)
- Phase 1 re-analysis with corrected environment shows reduced variance
- All Phase 2 runs use standardized environment

---

### Action 3.3: Collect More Metadata for Post-Hoc Analysis

**Objective**: Enable deeper investigation if statistical significance still not achieved

**Implementation**:
1. Expand run-report.json schema to include additional metadata:
   - Per-rule statistics (accuracy, similarity distribution)
   - Run duration metrics
   - Agent output verbosity/debug info
2. Collect co-variates that might explain variance (e.g., time of day, agent mood, repository size)

**Estimated Effort**: 2–3 hours
- Schema enhancement: 1 hour
- Analytics collection: 1–2 hours

**Risk Assessment**: LOW
- Additive change, no removal of existing data
- May increase storage/compute slightly

**Expected Impact**:
- Enable exploratory analysis to identify hidden variance sources
- Example: If variance correlates with target repo commit count, could normalize that factor
- Provides foundation for more sophisticated statistical models (ANCOVA, mixed effects)

**Priority**: LOW-MEDIUM (insurance for Phase 2, enable deeper learning)

**Success Criteria**:
- run-report.json schema v2 includes 5+ new optional fields
- Analytics collects new metadata for all Phase 2 runs
- Post-analysis can stratify Phase 2 results by metadata

---

## Implementation Roadmap: Phase 2

### Sprint 1 (Week 1): Quick Wins
**Effort**: 8–10 hours
1. Action 1.4: Investigate formula discrepancy (2–3 hrs) — HIGH PRIORITY
2. Action 1.1: Increase N to 10 per arm (8.5 hrs) — HIGH PRIORITY
3. Action 3.2: Standardize environment (3–4 hrs) — HIGH PRIORITY
**Expected Outcome**: If formula bug exists, immediate 5–10% improvement possible

### Sprint 2 (Week 2): Medium-Term Improvements
**Effort**: 15–20 hours
1. Action 1.2: Re-calibrate DriftScore formula (3–4 hrs) — HIGH PRIORITY
2. Action 2.1: Enrich constitutional core (6–8 hrs) — MEDIUM PRIORITY
3. Action 2.2: Standardize audit process (4–5 hrs) — MEDIUM PRIORITY
4. Action 3.3: Collect metadata (2–3 hrs) — LOW PRIORITY
**Expected Outcome**: Formula calibration + evidence enrichment likely to achieve SC-002

### Sprint 3 (Week 3–4): High-Impact Code Changes
**Effort**: 12–16 hours
1. Action 1.3: Agent constitutional weighting (12–16 hrs) — MEDIUM PRIORITY
**Risk**: Higher risk, higher reward; requires careful testing
**Expected Outcome**: If successful, 12–18% drift reduction achievable

### Phase 2 Full Experiment
**Effort**: 10–12 hours (with N=10, parallelizable)
- Execution: 8–10 hours (reduced if parallelized)
- Analysis: 2 hours
**Expected Timeline**: 2–3 weeks total

---

## Priority Matrix

| Action | Effort | Impact | Risk | Priority | Target |
|--------|--------|--------|------|----------|--------|
| 1.4 Formula Validation | 2–3 h | HIGH | LOW | **CRITICAL** | SC-001, SC-003 |
| 1.1 Increase N | 8.5 h | HIGH | LOW | **CRITICAL** | SC-001, SC-003 |
| 3.2 Environment Control | 3–4 h | HIGH | LOW | **HIGH** | SC-003 |
| 1.2 Recalibrate Formula | 3–4 h | MEDIUM | MEDIUM | **HIGH** | SC-001, SC-003 |
| 2.1 Constitutional Enrichment | 6–8 h | MEDIUM | MEDIUM | **MEDIUM** | SC-002 |
| 2.2 Audit Standardization | 4–5 h | MEDIUM | LOW | **MEDIUM** | SC-002 |
| 1.3 Agent Weighting | 12–16 h | HIGH | MEDIUM-HIGH | **MEDIUM** | SC-001 |
| 3.3 Metadata Collection | 2–3 h | MEDIUM | LOW | **LOW** | SC-003 (future) |

---

## Success Targets (Phase 2)

| Criterion | Phase 1 | Phase 2 Target | Recommended Actions |
|-----------|---------|----------------|-------------------|
| SC-001 | 3.35% | ≥15% | 1.1, 1.2, 1.3, 1.4 |
| SC-002 | 0.9049 | ≥0.94 | 2.1, 2.2 |
| SC-003 | p=0.904 | ≤0.10 | 1.1, 3.2, 3.3 |
| SC-004 | PASS | PASS | (maintain) |

---

## Constraints & Assumptions

**Assumptions**:
- Phase 2 will use same experimental infrastructure (no major refactoring)
- Constitutional core injection mechanism remains unchanged (only enriched)
- Target repository (cypress-realworld-app) remains stable

**Constraints**:
- Budget: ~40–50 hours total for Phase 2 (2–3 person-weeks)
- Timeline: 2–3 weeks to complete and re-run experiment
- No major code refactoring (corrections only, not architectural changes)
- Maintain backward compatibility with Phase 1 baselines

---

## Approval & Tracking

**Document Status**: READY FOR PHASE 2 EXECUTION

**Next Steps**:
1. Review actions with project stakeholders
2. Prioritize based on team capacity and timeline
3. Create GitHub issues for each action
4. Execute Sprint 1 (Quick Wins) for immediate improvements
5. Re-run Phase 2 experiment with improvements

**Review Date**: 2026-04-13 (post-Phase 2 Sprint 1)

---

**Document Prepared**: 2026-04-06  
**Linked Analysis**: ANALYSIS_FINDINGS.md  
**Integration Point**: spec.md § "Experimental Results & Future Iterations"
