#!/bin/bash
# Validates all interactive skills against the Agent Skills spec and project conventions.
# Usage: bash skills/skill-tester/scripts/run-tests.sh [skill-name]
#   No args: test all non-CI skills
#   With arg: test only the named skill

set -e

# Automates SKILL.md Checks 1-4. Provider-specific semantic comparison,
# reference existence, and Check 5 (plugin validation) remain agent-performed.
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
VALIDATE="$REPO_ROOT/.claude/skills/skill-creator/scripts/quick_validate.py"

tested=0; pass=0; warn=0; fail=0
instruction_status="not-run"
instruction_fail=0
failures=""
warnings=""
passed_skills=""

check_instruction_files() {
  local instruction_file
  for instruction_file in \
    "$REPO_ROOT/AGENTS.md" \
    "$REPO_ROOT/CLAUDE.md" \
    "$REPO_ROOT/.github/copilot-instructions.md"; do
    if [ ! -f "$instruction_file" ]; then
      failures="${failures}\n  ✗ instructions: missing ${instruction_file#"$REPO_ROOT/"}"
      instruction_status="failed"
      instruction_fail=1
      return
    fi
  done

  if ! cmp -s "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/CLAUDE.md"; then
    failures="${failures}\n  ✗ instructions: AGENTS.md and CLAUDE.md differ"
    instruction_status="failed"
    instruction_fail=1
    return
  fi

  instruction_status="passed"
}

check_skill() {
  local skill_dir="$1"
  local skill=$(basename "$skill_dir")

  # Skip CI skills
  [[ "$skill" == *-ci ]] && return
  [[ "$skill" == "skill-tester" ]] && return
  [[ "$skill" == "skill-tester-ci" ]] && return
  tested=$((tested + 1))

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    failures="${failures}\n  ✗ $skill: missing SKILL.md"
    fail=$((fail + 1))
    return
  fi

  # 1. Anthropic spec validation
  if [ -f "$VALIDATE" ]; then
    if result=$(python3 "$VALIDATE" "$skill_dir" 2>&1); then
      :
    else
      code=$?
      failures="${failures}\n  ✗ $skill: spec: $result"
      fail=$((fail + 1))
      return
    fi
  fi

  # 2. Name matches folder
  name=$(head -10 "$skill_dir/SKILL.md" | grep "^name:" | sed 's/name: *//' | tr -d '"')
  if [ "$name" != "$skill" ]; then
    failures="${failures}\n  ✗ $skill: name mismatch: frontmatter='$name' folder='$skill'"
    fail=$((fail + 1))
    return
  fi

  # 3. Line count
  lines=$(wc -l < "$skill_dir/SKILL.md" | tr -d ' ')
  if [ "$lines" -gt 600 ]; then
    failures="${failures}\n  ✗ $skill: $lines lines (hard limit 600)"
    fail=$((fail + 1))
    return
  elif [ "$lines" -gt 500 ]; then
    warnings="${warnings}\n  ⚠ $skill: $lines lines (soft limit 500)"
    warn=$((warn + 1))
  fi

  # 4. No README.md
  if [ -f "$skill_dir/README.md" ]; then
    failures="${failures}\n  ✗ $skill: contains README.md (not allowed per spec)"
    fail=$((fail + 1))
    return
  fi

  # 5. Scripts executable
  if [ -d "$skill_dir/scripts" ]; then
    for script in "$skill_dir"/scripts/*.sh; do
      [ -f "$script" ] || continue
      if [ ! -x "$script" ]; then
        failures="${failures}\n  ✗ $skill: $(basename $script) not executable"
        fail=$((fail + 1))
        return
      fi
      # Syntax check
      if ! bash -n "$script" 2>/dev/null; then
        failures="${failures}\n  ✗ $skill: $(basename $script) has syntax errors"
        fail=$((fail + 1))
        return
      fi
      # Shebang check (either bash form)
      if ! head -1 "$script" | grep -qE "^#!(/bin/bash|/usr/bin/env bash)"; then
        failures="${failures}\n  ✗ $skill: $(basename $script) missing bash shebang"
        fail=$((fail + 1))
        return
      fi
    done
  fi

  # 6. Description non-empty
  desc=$(head -10 "$skill_dir/SKILL.md" | grep "^description:" | sed 's/description: *//')
  if [ -z "$desc" ] || [ "$desc" = '""' ]; then
    failures="${failures}\n  ✗ $skill: empty description"
    fail=$((fail + 1))
    return
  fi

  pass=$((pass + 1))
  passed_skills="${passed_skills}${skill}"$'\n'
}

echo "## Skill Test Results"
echo
echo "**Date:** $(date +%Y-%m-%d)"

if [ -n "$1" ]; then
  # Test single skill
  if [ -d "$SKILLS_DIR/$1" ]; then
    check_skill "$SKILLS_DIR/$1"
  else
    echo "Skill not found: $1"
    exit 1
  fi
else
  # Test all
  check_instruction_files
  for d in "$SKILLS_DIR"/*/; do
    check_skill "$d"
  done
fi

echo "**Skills tested:** $tested"
echo "**Passed:** $pass"
echo "**Warnings:** $warn"
echo "**Failed:** $((fail + instruction_fail))"
if [ -z "$1" ]; then
  echo "**Instruction files:** $instruction_status"
fi
echo

if [ $((fail + instruction_fail)) -gt 0 ]; then
  echo "### Failures"
  echo -e "$failures"
  echo
fi

if [ $warn -gt 0 ]; then
  echo "### Warnings"
  echo -e "$warnings"
  echo
fi

if [ $pass -gt 0 ]; then
  echo "### Passed"
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    echo "  ✓ $skill"
  done <<< "$passed_skills"
fi

exit $((fail + instruction_fail))
