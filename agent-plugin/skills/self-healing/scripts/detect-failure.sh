#!/usr/bin/env bash
# detect-failure.sh — PostToolUse hook for Bash invocations.
# Reads the tool result JSON on stdin (per Claude Code hook spec); if exit_code != 0,
# emits a system reminder pointing the agent at self-healing.
#
# Wire up in .claude/settings.json:
#   "hooks": {
#     "PostToolUse": [{ "matcher": "Bash",
#       "hooks": [{ "type": "command",
#         "command": "./skills/self-healing/scripts/detect-failure.sh" }] }]
#   }

set -euo pipefail

# Hook payload arrives on stdin. We tolerate either jq-style JSON or raw text.
PAYLOAD="$(cat || true)"

# Try to parse exit_code; fall through silently on parse failure.
EXIT_CODE=$(printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read() or "{}")
    # Common shapes: {"tool_response": {"exit_code": N}} (Claude Code / Codex),
    # {"tool_result": {"exit_code": N}}, {"exit_code": N}, {"result": {"exit_code": N}}
    for path in (("tool_response","exit_code"), ("tool_result","exit_code"), ("exit_code",), ("result","exit_code")):
        d = data
        ok = True
        for k in path:
            if isinstance(d, dict) and k in d:
                d = d[k]
            else:
                ok = False
                break
        if ok and isinstance(d, (int, str)):
            try:
                print(int(d))
                sys.exit(0)
            except (ValueError, TypeError):
                pass
except Exception:
    pass
print(0)
' 2>/dev/null || echo 0)

# PostToolUse plain stdout is not shown to the model (Claude Code and Codex
# alike); the reminder must be returned as additionalContext JSON.
if [[ "$EXIT_CODE" != "0" ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "<self-healing-trigger>\nA Bash command just exited non-zero. This is a heal opportunity.\n\nBefore retrying the same command verbatim:\n  1. DIAGNOSE — read the error; identify the root cause (env? missing dep? wrong tool?)\n  2. Search .learnings/HEALS.md for a matching Pattern-Key (don't re-solve a solved problem)\n  3. PATCH — write the fix (or apply a known one)\n  4. VERIFY — re-run the command; require exit 0\n  5. FILE — append a HEAL entry to .learnings/HEALS.md via skills/self-healing/scripts/new-heal.sh\n</self-healing-trigger>"
  }
}
EOF
fi
