---
name: "gatherrules-enhancement-phase3"
status: "proposed"
scope: "optional-enhancement"
applies-to: ["specfarm.gather-rules", "gatherrules-agent"]
binding: false
model-bias: "caller-model"
---

# Phase 3 Enhancement: Model-Aware Gatherrules Agent

**Status**: Proposed (not yet binding)  
**Scope**: Optional enhancement for context gathering with model-specific fallback  
**Depends on**: Phase 1 & 2 complete (model-bias framework in place)  

---

## Enhancement Overview

Enhance `specfarm.gather-rules` agent to:
1. Accept `--preferred-model` parameter (default: caller model)
2. Implement model-specific output formatting (compact for Haiku, detailed for Sonnet)
3. Add graceful fallback (Gemini → Haiku → Manual)
4. Support `--task-context` mode for granular task-specific context

**Current state**: Gatherrules available but lacks model awareness  
**Proposed state**: Model-aware with fallback and task-context support  

---

## Tasks T110–T112

### T110: Add --preferred-model parameter to gatherrules agent

**Description**: Update gatherrules agent to accept `--preferred-model` parameter with fallback chain.

**Scope**:
- Add `--preferred-model` parameter (optional, default: "caller-model")
- Document fallback chain: "Gemini → Haiku → Manual"
- Add examples showing preferred model and fallback behavior
- Implement graceful skip if no models available

**Acceptance Criteria**:
- ✅ Parameter table includes `--preferred-model` with description
- ✅ Fallback chain documented (Gemini primary, Haiku secondary, manual tertiary)
- ✅ Examples show both successful gather and fallback scenario
- ✅ Error handling: "If all models unavailable, log warning and continue"

**Risk**: LOW (additive feature)

---

### T111: Implement model-specific output formatting

**Description**: Add model-specific output formatting to gatherrules agent.

**Scope**:
- Compact format for Haiku: Key rules only (name + type, no descriptions)
- Detailed format for Sonnet/Opus: Full rules (name + type + description + examples)
- Add output schema validation for both formats
- Add examples showing both compact and detailed YAML

**Acceptance Criteria**:
- ✅ Output formats documented (compact vs detailed)
- ✅ Schema examples provided for both
- ✅ Model-to-format mapping clear (Haiku → compact, Sonnet/Opus → detailed)
- ✅ YAML validation before output

**Risk**: LOW (output formatting only)

---

### T112: Add graceful degradation (Gemini unavailable → Haiku parser)

**Description**: Implement fallback for gatherrules when Gemini unavailable.

**Scope**:
- Detect Gemini availability; if unavailable, use Haiku parser
- Document degraded-mode behavior (compact output, no full descriptions)
- Add health check (connectivity test or capability check)
- Add retry strategy (up to 3x before giving up)

**Acceptance Criteria**:
- ✅ Fallback condition documented (Gemini unavailable → Haiku)
- ✅ Health check described
- ✅ Degraded-mode output example provided
- ✅ Retry strategy documented (max 3 attempts)
- ✅ User notification: Log message on fallback

**Risk**: MEDIUM (fallback logic must be robust)

---

## Implementation Timeline (Proposed)

**Not yet scheduled** — Proposed for post-Phase-2 execution  
**Est. effort**: 20–30 minutes  
**Recommended**: After Phase 1 & 2 validation passes  

If approved, execute with:
```bash
specfarm.promptflow4speckit --model=haiku --line-factor=1.0 -- \
  "T110 [FEAT] Add --preferred-model parameter to gatherrules agent" \
  "T111 [FEAT] Implement model-specific output formatting" \
  "T112 [FEAT] Add graceful degradation (Gemini→Haiku fallback)"
```

---

## Constitution Alignment

✅ **Principle I (CLI-Centric)**: Gatherrules agent invoked via CLI; orchestrates model dispatch  
✅ **Principle V (Stability)**: Graceful fallback ensures robustness when primary unavailable  
✅ **Model Bias (NFR 4.2)**: Caller model preference for context gathering  
✅ **Zero External Dependencies**: Fallback to Haiku uses only built-in agent capabilities  

---

## Decision Gates

- [ ] Phase 1 & 2 complete and validated
- [ ] User confirms Phase 3 is desired (not mandatory)
- [ ] Estimated effort (20–30 min) acceptable
- [ ] No conflicts with other in-flight agent work

**Recommendation**: Keep as proposed until Phase 1 & 2 fully validated.
