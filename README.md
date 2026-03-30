# pskoett-ai-skills

A collection of skills for AI agents. Follows the [Agent Skills specification](https://agentskills.io/specification).
This repository is my personal skill testing ground.

## Philosophy

Every skill in this collection is built around a philosophy — a principle that addresses a specific failure mode in how agents work today. `plan-interview` is about collaborative planning: before codebase exploration starts, user and agent run a structured interview to align on constraints, scope, risk, and success criteria — and to surface whether a preparatory refactor should come before the main change. `intent-framed-agent` makes execution intent explicit so scope drift becomes visible. `context-surfing` monitors context quality and exits cleanly before degradation corrupts output. `simplify-and-harden` uses the peak context at end-of-task for a focused quality and security review. `self-improvement` turns repeated mistakes into durable rules that persist across sessions.

The common thread: agents have peak context at specific moments — after planning, mid-execution, at completion, after learning — and these skills are designed to exploit those peaks. Each skill encodes a philosophy that agents struggle to internalize on their own, turning it into a structured workflow they can follow reliably. `skill-pipeline` ties these pieces together by classifying the task and routing it through the right depth of process.

## Install

```bash
npx skills add pskoett/pskoett-ai-skills
```

## Structure

```
skills/
  skill-name/
    SKILL.md         # Required - skill definition with YAML frontmatter
    scripts/         # Optional - executable code
    references/      # Optional - documentation loaded on demand
    assets/          # Optional - templates, images, data files
```

## Skills

| Skill | Description |
|-------|-------------|
| [agent-teams-simplify-and-harden](skills/agent-teams-simplify-and-harden/) | Implementation + audit loop using parallel agent teams with structured simplify, harden, and document passes |
| [context-surfing](skills/context-surfing/) | Monitors context window health and rides peak context quality for maximum output fidelity during multi-step execution |
| [dx-data-navigator](skills/dx-data-navigator/) | Query DX Data Cloud for developer productivity metrics, DORA metrics, PR/deployment data, and engineering analytics |
| [intent-framed-agent](skills/intent-framed-agent/) | Captures a lightweight intent contract at execution start and monitors coding-task drift until resolution |
| [plan-interview](skills/plan-interview/) | Runs a structured interview before planning non-trivial implementations |
| [self-improvement](skills/self-improvement/) | Captures learnings and errors with hook-based activation and automatic skill extraction |
| [skill-pipeline](skills/skill-pipeline/) | Pipeline orchestrator that classifies tasks and routes them through the right skill combination at the right depth |
| [simplify-and-harden](skills/simplify-and-harden/) | Post-completion self-review that runs simplify, harden, and micro-documentation passes before signaling done |

## Experimental (CI Skills)

These skills are experimental and currently part of the testing ground setup.

| Skill | Description |
|-------|-------------|
| [self-improvement-ci](skills/self-improvement-ci/) | CI-only self-improvement workflow for recurring failure-pattern capture using gh-aw |
| [simplify-and-harden-ci](skills/simplify-and-harden-ci/) | CI-only simplify/harden workflow for pull requests using gh-aw with headless scan/report gates |

## Skill Pipeline

Each skill prevents a distinct failure mode:

| Skill | Failure it prevents |
|-------|-------------------|
| `plan-interview` | Building the wrong thing |
| `intent-framed-agent` | Scope creep during execution |
| `context-surfing` | Degraded-context corruption |
| `simplify-and-harden` | Shipping rough/insecure code |
| `self-improvement` | Repeating the same mistakes |

### Lifecycle

```
[plan-interview] → [intent-framed-agent] ⟂ [context-surfing] → [simplify-and-harden] → [self-improvement]
                                          ↑   concurrent    ↑
```

**Stage 1 — Planning** (manual gate): `plan-interview` runs a structured interview and produces a plan file in `docs/plans/`. This is the only skill that requires explicit invocation (`/plan-interview`). Downstream skills activate automatically when present, but each works independently if earlier stages are skipped.

**Stage 2 — Execution** (concurrent monitoring): `intent-framed-agent` captures the intent frame and monitors *scope* drift. `context-surfing` monitors *context quality* drift. Both run simultaneously. If both fire at once, context-surfing's exit takes precedence — degraded context makes scope checks unreliable.

**Stage 3 — Review** (post-completion): `simplify-and-harden` runs three passes (simplify, harden, document) on the completed work.

**Stage 4 — Learning** (automatic): `self-improvement` captures recurring patterns from the session and promotes them to project-level instruction files.

### Artifacts at each stage

| Stage | Artifact | Location |
|-------|----------|----------|
| Planning | Plan file | `docs/plans/plan-NNN-<slug>.md` |
| Execution | Intent frame | Emitted in session output |
| Execution | Handoff file (on drift exit) | `.context-surfing/handoff-<slug>-<timestamp>.md` |
| Review | Structured YAML summary | Appended to task output |
| Learning | Learning entries | `.learnings/LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md` |

### Pipeline depth

Every skill works standalone. The pipeline is the recommended combination, not a hard dependency — each skill silently adapts when upstream artifacts are absent.

Match depth to complexity:

| Task | Skills |
|------|--------|
| Trivial (typo fix, rename) | None |
| Small (isolated bug fix) | `simplify-and-harden` |
| Medium (feature, multi-file) | `intent-framed-agent` + `simplify-and-harden` |
| Large (refactor, new architecture) | Full pipeline |
| Long-running (multi-session) | Full pipeline — `context-surfing` is critical |

## Usage

To use a skill, add it to your agent's configuration or reference it directly.

### Hook Setup

Several skills support automatic activation via hooks. Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "./skills/self-improvement/scripts/activator.sh"
        },
        {
          "type": "command",
          "command": "./skills/context-surfing/scripts/handoff-checker.sh"
        }
      ]
    }]
  }
}
```

| Hook Script | Skill | Purpose |
|-------------|-------|---------|
| `self-improvement/scripts/activator.sh` | self-improvement | Reminds to evaluate learnings after tasks |
| `context-surfing/scripts/handoff-checker.sh` | context-surfing | Detects unread handoff files from previous context exits |

Both hooks are lightweight (~50-100 tokens) and skip silently when not applicable.

## Contributing

Feel free to submit PRs with new skills or improvements to existing ones.
