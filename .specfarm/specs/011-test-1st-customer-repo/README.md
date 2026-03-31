# Spec 011 - Test SpecFarm gather-rules on Real Mid-Dev Repo

## Overview
This specification defines a comprehensive testing workflow to validate SpecFarm's gather-rules agent on a real, production mid-development repository. The goal is to bootstrap Spec-Driven Development (SDD) into an existing codebase by automatically discovering and scoring rules from git history and tests.

## Quick Start
```bash
cd spec-011-customer-repo
cat tasks.md
```

## Deliverables
- **tasks.md**: Comprehensive task list (26 tasks, 6 phases)
- All supporting documentation (reports, assessments, roadmap)

## Key Phases
1. **Phase 1**: Repository Selection & Preparation
2. **Phase 2**: Agent Deployment & Validation
3. **Phase 3**: Discovery Run (Full Mode)
4. **Phase 4**: Output Validation & Quality Assessment
5. **Phase 5**: Curation & Task-Context Mode Testing
6. **Phase 6**: Documentation & Lessons Learned

## Success Criteria
- Agent runs without crashes on real mid-dev repository
- 5-10+ high-confidence rules (>70) discovered
- Evidence correctly maps to real commits
- Task-context mode works with multiple task prompts
- Comprehensive testing report with lessons learned

## Expected Timeline
- Phase 1: 30 minutes (repository identification and setup)
- Phase 2: 15 minutes (agent deployment)
- Phase 3: 10 minutes (discovery execution)
- Phase 4: 45 minutes (validation and verification)
- Phase 5: 30 minutes (curation and task-context testing)
- Phase 6: 45 minutes (documentation and synthesis)
**Total: ~3 hours for complete validation**

## Next Steps After Testing
1. Curate top 6-8 rules into rules.xml
2. Identify keyword tuning needed for target language/framework
3. Plan Phase 3b Windows compatibility testing
4. Integrate into speckit.tasks workflow for SDD in real repos

