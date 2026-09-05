#!/bin/bash
# Syncs canonical skills into native and portable plugin distributions.
#
# Each plugin SKILL.md is rebuilt from the SOURCE body + SOURCE description, while
# preserving the plugin-only frontmatter (hooks, user-invocable, argument-hint) that
# makes the skill register as a native plugin. agent-plugin/skills/ receives canonical
# Agent Skills metadata and runtime support files, excluding development-only evals.
#
# Delegates to scripts/sync_plugin.py (requires python3 + PyYAML).
#
# Usage: ./scripts/sync-plugin.sh [skill-name ...]
#   No args: sync the curated set present in both skills/ and plugin/skills/.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$REPO_ROOT/scripts/sync_plugin.py" "$@"
