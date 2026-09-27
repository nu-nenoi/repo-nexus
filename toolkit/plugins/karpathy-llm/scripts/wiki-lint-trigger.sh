#!/bin/sh
# ============================================================================
# .rnex/scripts/wiki-lint-trigger.sh — Autonomous Karpathy Wiki Lint Trigger
# ============================================================================

# 1. Check rnex.yaml configuration if present
if [ -f "rnex.yaml" ]; then
  _disabled=$(awk '
    /^plugins:/ { in_p=1; next }
    in_p && /^[^ #]/ { exit }
    in_p && /^  karpathy-llm:[ ]*$/ { in_k=1; next }
    in_k && /^    lint_trigger_enabled:[ ]*false/ { print "yes"; exit }
    in_k && !/^    / && !/^[ ]*#/ { in_k=0 }
  ' rnex.yaml)
  if [ "$_disabled" = "yes" ]; then
    exit 0
  fi
fi

# 2. Check if wiki/index.md exists and contains lint_trigger: enabled
grep -q "lint_trigger: enabled" wiki/index.md 2>/dev/null || exit 0

COUNTER_DIR=".rnex"
[ -d "$COUNTER_DIR" ] || COUNTER_DIR="wiki"
COUNTER_FILE="$COUNTER_DIR/.lint_trigger_counter"

# Read and increment session counter
count=0
if [ -f "$COUNTER_FILE" ]; then
  count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
case "$count" in
  ''|*[!0-9]*) count=0 ;;
esac

count=$((count + 1))
printf '%s\n' "$count" > "$COUNTER_FILE" 2>/dev/null || true

# If counter is 1 or a multiple of 15, print maintenance due notice
if [ "$count" -eq 1 ] || [ $((count % 15)) -eq 0 ]; then
  printf '[WIKI MAINTENANCE DUE]: Pending /raw/ files or wiki health checks detected. Run wiki-lint.\n'
fi

exit 0
