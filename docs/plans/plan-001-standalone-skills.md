# Plan 001: Ensure Pipeline Skills Work Standalone

## Success Criteria

- Context-surfing works when launched without plan-interview or intent-framed-agent
- All references to "intent frame" and "plan file" have graceful fallbacks
- The recovery protocol works with whatever anchor is available
- Fallbacks are silent — no nagging about missing upstream artifacts

## Risk Assessment

- **Over-scoping**: Only context-surfing needs changes. The other four are already standalone.
- **Breaking the pipeline flow**: Changes must preserve existing behavior when upstream artifacts DO exist.

## Affected Files/Areas

- `skills/context-surfing/SKILL.md` — public copy
- `.claude/skills/context-surfing/SKILL.md` — local copy

## Implementation Checklist

### In context-surfing SKILL.md:

1. **Activation section (lines 77-83)**: Add fallback — when intent frame or plan are absent, use the user's original task description + project context files as the wave anchor.

2. **Wave anchor definition (line 98)**: Expand to a three-tier definition:
   - Full pipeline: intent frame + plan + Entire CLI
   - Partial: whichever of intent frame or plan exists + project context
   - Standalone: user's original prompt + project context files (CLAUDE.md, AGENTS.md, README.md)

3. **Monitoring Paradox (lines 152-153)**: Make "re-read the intent frame" and "cross-check against the plan" conditional — "if available, re-read X; otherwise re-read the original task description."

4. **Recovery Protocol Step 1 (lines 167-168)**: Same conditional pattern for re-anchor sources.

5. **Handoff template (lines 223-227)**: Make Intent Frame and Plan sections conditional — include them if they exist, mark as "N/A — standalone session" if not.

6. Apply identical changes to local copy.

## Test Strategy

- Manual read-through: does the skill read coherently in both pipeline and standalone modes?
- No code to test — this is documentation/specification only.
