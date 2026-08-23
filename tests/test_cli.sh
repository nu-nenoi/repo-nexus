#!/bin/sh
# ============================================================================
# tests/test_cli.sh — Automated Test Suite for rnex
# ============================================================================
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$DIR/rnex"

# Setup temporary sandbox for testing
TEST_TMP="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP"' EXIT

TEST_WORKSPACE="$TEST_TMP/nexus-workspace"
TEST_REPO="$TEST_TMP/dummy-repo"
TEST_OUTSIDE="$TEST_TMP/outside-dir"

mkdir -p "$TEST_WORKSPACE" "$TEST_REPO/src" "$TEST_OUTSIDE"

# Initialize dummy target repo
echo 'console.log("hello world");' > "$TEST_REPO/src/app.js"
git -C "$TEST_REPO" init -q
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -m "init" -q

# Copy CLI to isolated test workspace
cp "$CLI" "$TEST_WORKSPACE/rnex"
chmod +x "$TEST_WORKSPACE/rnex"

cd "$TEST_WORKSPACE"

echo "==> Test 1: Initialize workspace"
"$TEST_WORKSPACE/rnex" init "$TEST_WORKSPACE" >/dev/null
[ -f "$TEST_WORKSPACE/workspace.yaml" ] || { echo "workspace.yaml missing"; exit 1; }
[ -f "$TEST_WORKSPACE/AGENTS.md" ] || { echo "AGENTS.md missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.github/copilot-instructions.md" ] || { echo "copilot-instructions.md missing"; exit 1; }
echo "  [✓] Passed"

echo "==> Test 2: Add member repository (Scope link + AI injection)"
"$TEST_WORKSPACE/rnex" add test-app "$TEST_REPO" >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { echo "Scope link missing"; exit 1; }
[ -L "$TEST_REPO/AGENTS.md" ] || { echo "AGENTS.md symlink missing in repo"; exit 1; }
[ -L "$TEST_REPO/.github/copilot-instructions.md" ] || { echo "Copilot symlink missing in repo"; exit 1; }
grep -q "AGENTS.md" "$TEST_REPO/.gitignore" || { echo ".gitignore not updated"; exit 1; }
echo "  [✓] Passed"

echo "==> Test 3: Write-Through propagation via symlink"
echo 'console.log("updated via nexus");' > "$TEST_WORKSPACE/repos/test-app/src/app.js"
grep -q "updated via nexus" "$TEST_REPO/src/app.js" || { echo "Write-through failed"; exit 1; }
echo "  [✓] Passed"

echo "==> Test 4: Hide and Show repository scope"
"$TEST_WORKSPACE/rnex" hide test-app >/dev/null
[ ! -e "$TEST_WORKSPACE/repos/test-app" ] || { echo "Hide failed"; exit 1; }
"$TEST_WORKSPACE/rnex" show test-app >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { echo "Show failed"; exit 1; }
echo "  [✓] Passed"

echo "==> Test 5: Idempotent Sync"
"$TEST_WORKSPACE/rnex" sync >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { echo "Sync scope failed"; exit 1; }
[ -L "$TEST_REPO/AGENTS.md" ] || { echo "Sync AI files failed"; exit 1; }
echo "  [✓] Passed"

echo "==> Test 6: Explicit --config / -c from an external directory"
cd "$TEST_OUTSIDE"
"$TEST_WORKSPACE/rnex" --config "$TEST_WORKSPACE/workspace.yaml" status >/dev/null
"$TEST_WORKSPACE/rnex" -c "$TEST_WORKSPACE/workspace.yaml" list >/dev/null
cd "$TEST_WORKSPACE"
echo "  [✓] Passed"

echo "==> Test 7: Remove member repository"
"$TEST_WORKSPACE/rnex" remove test-app >/dev/null
[ ! -e "$TEST_WORKSPACE/repos/test-app" ] || { echo "Remove scope link failed"; exit 1; }
[ ! -e "$TEST_REPO/AGENTS.md" ] || { echo "Remove AI symlink failed"; exit 1; }
[ -d "$TEST_REPO/src" ] || { echo "Target repo was accidentally deleted"; exit 1; }
echo "  [✓] Passed"

echo ""
echo "===================================="
echo "  All 7 Automated Tests Passed! ✓"
echo "===================================="
