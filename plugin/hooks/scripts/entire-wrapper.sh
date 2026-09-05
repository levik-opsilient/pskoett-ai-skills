#!/bin/bash
# Entire is optional telemetry; its absence or failure must not block agent work.

timeout_seconds=5

if ! command -v entire >/dev/null 2>&1; then
  echo "pskoett-ai-skills: Entire integration unavailable; hook skipped." >&2
  exit 0
fi

if ! output_file="$(mktemp "${TMPDIR:-/tmp}/pskoett-entire-hook.XXXXXX")"; then
  echo "pskoett-ai-skills: Entire hook output could not be buffered; optional hook skipped." >&2
  exit 0
fi
trap 'rm -f "$output_file"' EXIT

# Monitor mode gives the background adapter its own process group so a timeout
# terminates the adapter and every child it spawned.
set -m
entire "$@" >"$output_file" &
entire_pid=$!
set +m

deadline=$((SECONDS + timeout_seconds))
while kill -0 "$entire_pid" 2>/dev/null; do
  if (( SECONDS >= deadline )); then
    kill -TERM -- "-$entire_pid" 2>/dev/null
    sleep 0.2
    kill -KILL -- "-$entire_pid" 2>/dev/null
    wait "$entire_pid" 2>/dev/null
    echo "pskoett-ai-skills: Entire hook timed out after ${timeout_seconds}s; continuing because the integration is optional." >&2
    exit 0
  fi
  sleep 0.1
done

if wait "$entire_pid"; then
  if [ -s "$output_file" ]; then
    cat "$output_file"
  fi
  exit 0
else
  status=$?
  echo "pskoett-ai-skills: Entire hook failed with exit $status; continuing because the integration is optional." >&2
  exit 0
fi
