# Agent Instructions

Principles, conventions, and workflows for AI agents working in this repository. `AGENTS.md` and `CLAUDE.md` are kept identical; `.github/copilot-instructions.md` mirrors the same principles with Copilot-specific framing. Keep these files free of details that go stale easily (such as enumerated skill lists) — favor durable principles, guidelines, and how the repo functions.

## Core Principles

### 1. Think Before Coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- **State assumptions explicitly** — if uncertain, ask rather than guess.
- **Present multiple interpretations** — don't pick silently when ambiguity exists.
- **Push back when warranted** — if a simpler approach exists, say so.
- **Stop when confused** — name what's unclear and ask for clarification.

### 2. Simplicity First

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.

The test: would a senior engineer say this is overcomplicated? If yes, simplify.

### 3. Surgical Changes

Touch only what you must. Clean up only your own mess.

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

Define success criteria. Loop until verified. Transform imperative tasks into verifiable goals:

| Instead of... | Transform to... |
| --- | --- |
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi-step tasks, state a brief plan as `[Step] -> verify: [check]`. Strong success criteria let you loop independently; weak criteria ("make it work") require constant clarification.

### 5. Learn and Improve

Every mistake is a learning opportunity. Log it, learn from it, prevent it.

- After ANY correction from the user, log the lesson and write a rule for yourself that prevents the same mistake.
- Log to `.learnings/ERRORS.md`, `LEARNINGS.md`, or `FEATURE_REQUESTS.md`. For active runtime failures with verified fixes, use the Self-Healing Workflow below (files to `HEALS.md`) instead.
- Review and promote broadly applicable learnings — including heal handoffs at `Recurrence-Count >= 3` — to `CLAUDE.md` (project facts and conventions), `AGENTS.md` (workflows and automation), and `.github/copilot-instructions.md` (Copilot context).
- For CI-only/headless learning capture, use `skills/self-improvement-ci/SKILL.md` (gh-aw).

## Project Overview

A collection of skills for AI agents following the [Agent Skills specification](https://agentskills.io/specification).

## Structure

- `skills/` - Public skills for distribution
- `.claude/skills/` - Local Claude Code skills
- `.learnings/` - Captured learnings, errors, and feature requests

## Skill Format

Each skill folder must contain:

- `SKILL.md` - Required, with YAML frontmatter (`name`, `description`)
- `scripts/` - Optional executable code
- `references/` - Optional documentation
- `assets/` - Optional templates and resources

## Creating a New Skill

1. Create folder in `skills/` with skill name (lowercase, hyphens)
2. Create `SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: What it does and when to use it.
   ---
   ```
3. Add optional directories: `scripts/`, `references/`, `assets/`
4. Ensure folder name matches `name` field

## Validating Skills

Check against the spec at https://agentskills.io/specification:

- Frontmatter has required `name` and `description`
- `name` is lowercase, hyphens only, matches folder
- `description` explains what AND when to use
- No README.md or other auxiliary files in skill folder
- Provider guidance should cover Copilot when tool calls are referenced

## Conventions

- The `name` field in frontmatter must match the folder name
- No README.md files inside skill folders (per spec)
- Use lowercase with hyphens for skill names
- Keep SKILL.md under 600 lines; use references/ for detailed content
- When tool calls are referenced, add Copilot-compatible guidance for asking in chat

## Plugin Bundle Sync

`plugin/skills/` is generated from `skills/` — do not hand-edit it. The public `skills/` copy is the single source of truth for each SKILL.md body and description; the plugin copy only adds plugin-registration frontmatter (`hooks`, `user-invocable`, `argument-hint`). After changing any `skills/` source, resync:

```bash
./scripts/sync-plugin.sh            # sync every bundled skill
./scripts/sync-plugin.sh <skill>    # sync one
```

Intentionally NOT bundled into `plugin/skills/`:

- `skill-tester`, `skill-tester-ci` — internal dev/validation tooling, not end-user skills.
- `self-improvement-ci`, `simplify-and-harden-ci` — not currently shipped in the bundle.

`harness-updater` is a plugin **agent** (`plugin/agents/`), not a skill, and ships only in the full plugin bundle.

## Self-Healing Workflow

When a command, test, build, or external call fails mid-task — or when the agent needs a helper that doesn't exist yet:

1. Run `skills/self-healing/SKILL.md` to diagnose, patch, verify, and file a `HEAL-` entry to `.learnings/HEALS.md`.
2. Mandatory verify before persist — re-run the failing operation; only `verified` if it passes. Use `pending-verify` honestly when sandboxed; use `abandoned` when the fix can't be made to work.
3. Most heals are recurrences — search `HEALS.md` by `Pattern-Key` first; increment `Recurrence-Count` on the existing entry rather than creating a duplicate.
4. At `Recurrence-Count >= 3` across distinct tasks, append a `Handoff` block to flag the entry for promotion via self-improvement.

Self-healing files the verified patch; self-improvement promotes it (see Core Principle 5). Do not overlap.

## Simplify and Harden Workflow

When a coding task with non-trivial code changes is complete:

1. Run `skills/simplify-and-harden/SKILL.md` for a bounded simplify/harden/document/re-verification pass in interactive coding sessions.
2. For CI-only/headless runs, use `skills/simplify-and-harden-ci/SKILL.md` (gh-aw).
3. For larger multi-file efforts, coordinate bounded work units through `control-session-orchestrator`, then run the same verification and independent review gates.
4. Treat independent review findings as the external merge gate and address or explicitly waive them.

Keep `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` synchronized.
