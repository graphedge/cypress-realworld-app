devstep [ promptflow lines factor ] [ priority task description]

1 look down lowest #'d specs & the  [ arg priority task descrip ] to list unworked tasks

2 update specs/nexttasks.md (see specs/next.md for template)

3 use promptflow lines factor to downselect max feasible tasks that should fit, 80% sure

4 promptflow those tasks

5 update both tasks.md  & the home spec folder with completions

Workflow features:
- GitHub Actions workflow (`.github/workflows/specfarm-promptflow-gemini.yml`): 5-phase orchestration with graceful degradation, circuit breaker, dry-run support
- Gemini CLI agent (`.github/agents/specfarm.promptflow-gemini.agent.md`): Gemini 2.5 Flash Lite integration with CLI commands and piping support
- Heuristic agent selection (plan4speckit vs implement4speckit) based on task keywords
- Context gathering from specs/ directory with graceful fallback
- Progress tracking in specs/next.md + respective task files
- Output format: `=== Task N done === [status] [agent]`