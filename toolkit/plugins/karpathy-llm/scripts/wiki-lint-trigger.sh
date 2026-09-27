#!/bin/sh
# ============================================================================
# scripts/wiki-lint-trigger.sh — Autonomous Karpathy Wiki Lint Trigger
# ============================================================================
set -e

WIKI_DIR="wiki"
INDEX_FILE="$WIKI_DIR/index.md"
COUNTER_FILE="$WIKI_DIR/.lint_trigger_counter"

# Check if wiki/index.md exists and contains lint_trigger: enabled
grep -q "lint_trigger: enabled" "$INDEX_FILE" 2>/dev/null || exit 0

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

# Trigger on session 1 or every 15 sessions
if [ "$count" -eq 1 ] || [ $((count % 15)) -eq 0 ]; then
  printf '\n[WIKI MAINTENANCE DUE]: Pending /raw/ files or wiki health checks detected. Run wiki-lint.\n\n'
fi

exit 0
