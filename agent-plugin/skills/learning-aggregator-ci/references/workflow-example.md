# Workflow Example (Non-Active)

This is an example template only.
Keep it outside `.github/workflows` so nothing runs automatically.

When you are ready to enable CI automation:
1. Copy this template into `.github/workflows/learning-aggregator-ci.md`
2. Customize the schedule for your team's cadence
3. Validate with `gh aw compile` (add `--actionlint --zizmor` for security scan)

```markdown
---
on:
  schedule:
    - cron: '0 9 * * 1'
  workflow_dispatch:
  issue_comment:
    types: [created]

permissions:
  contents: read
  actions: read
  issues: read
  pull-requests: read

tools:
  github:
    toolsets: [pull_requests, actions, issues]
  cache-memory: true
  # Optional: durable git-branch persistence for the aggregation state.
  # Survives beyond the 7-day cache-memory window and is readable from interactive
  # sessions via `git fetch origin learnings/default` (branch name = branch-prefix/default).
  repo-memory:
    branch-prefix: learnings
    max-file-size: 51200  # 50KB — aggregation state can be larger than default 10KB

safe-outputs:
  add-comment:
    max: 1
    hide-older-comments: true
  upload-artifact:
    max-uploads: 1
  call-workflow:
    workflows: [eval-creator-ci]
    max: 1

tracker-id: learning-aggregator

concurrency:
  group: learning-aggregator
  cancel-in-progress: false

strict: true
---

1. Read all files in `.learnings/` directory: `LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md`, `HEALS.md`. If the directory does not exist or is empty, report zero findings and exit.

2. Check cache-memory at `/tmp/gh-aw/cache-memory/learning-aggregator-state.json` for previous aggregation state. Load it only when `aggregation_schema` is exactly `provenance-v1` and it includes canonical occurrence fingerprints, stable task lineage, and terminal-event boundaries. Otherwise ignore the old aggregate counts and rebuild from all entries. With a valid cache, only re-process entries with `Last-Seen` newer than the cached scan date.

3. Parse each entry's structured metadata fields: `Pattern-Key`, `Recurrence-Count`, `First-Seen`, `Last-Seen`, `Priority`, `Status`, `Area`, `Related Files`, `Source`, `Tags`, plus optional provenance fields `Task-ID`, `Session-ID`, `Occurrence-ID`, `Source-Ref`, and `Copied-From`.

4. Collapse copied entries and mirrored trace/log evidence into canonical occurrences before grouping. Prefer `Occurrence-ID`; otherwise use entry ID, task/session/source lineage, and normalized content. Different paths, checkpoints, forks, forwards, or cloud/local copies are not independent evidence.

5. Group canonical occurrences by exact `Pattern-Key` match. Do not attempt fuzzy grouping — false positives are worse than ungrouped entries in CI.

6. For each group: count deduplicated recurrences, count distinct tasks from stable provenance, compute the time window between earliest `First-Seen` and latest `Last-Seen`, and collect all evidence summaries. Legacy unknown-lineage evidence counts as at most one distinct task.

7. Exclude terminal-only groups (`promoted`, `promoted_to_skill`, `resolved`, `wont_fix`) from promotion candidates. Reopen only when newer active evidence exists after the latest terminal event.

8. Identify promotion-ready patterns: deduplicated recurrence `>= 3` AND provenance-proven distinct tasks `>= 2` AND within a `30-day window`.

9. Identify approaching patterns: deduplicated recurrence `>= 2` OR `Priority: high/critical` with any active recurrence.

10. Flag entries without `Pattern-Key` as ungrouped with a recommendation to assign one.

11. Flag active entries with `Last-Seen` older than 90 days as stale with a recommendation to dismiss, and report terminal-only groups as historical.

12. Classify each promotion-ready pattern's gap type: knowledge gap (agent didn't know), tool gap (agent improvised), skill gap (same behavior fails), ambiguity (conflicting interpretations), reasoning failure (agent had knowledge but reasoned wrong).

13. Write updated aggregation state to cache-memory at `/tmp/gh-aw/cache-memory/learning-aggregator-state.json` for the next run with `aggregation_schema: provenance-v1`, canonical occurrence fingerprints, stable task lineage, terminal-event boundaries, and the scan date.

14. Emit the full gap report as structured YAML under key `learning_aggregator_ci` following the output schema in the skill definition.

15. Upload the gap report YAML as a workflow artifact named `gap-report`.

16. Post a human-readable summary as a comment. Format: promotion-ready patterns first (with evidence and recommended action), then approaching patterns, then ungrouped entries, then stale and historical entries.

17. If any promotion-ready patterns have `eval_candidate: true`, trigger `eval-creator-ci` via call-workflow to create eval cases from the newly promoted patterns.

18. Do not modify any repository files. This workflow is read-only.
```
