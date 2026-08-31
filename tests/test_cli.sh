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
# Copy docs for AGENTS.sample.md
if [ -d "$DIR/docs" ]; then
  cp -r "$DIR/docs" "$TEST_WORKSPACE/docs"
fi

cd "$TEST_WORKSPACE"

PASS=0
FAIL=0
TOTAL=0

run_test() {
  TOTAL=$((TOTAL + 1))
  _desc="$1"
  echo "==> Test $TOTAL: $_desc"
}

pass() {
  PASS=$((PASS + 1))
  echo "  [✓] Passed"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "  [✗] FAILED: $1"
}

# --------------------------------------------------------------------------
run_test "Initialize workspace"
"$TEST_WORKSPACE/rnex" init "$TEST_WORKSPACE" >/dev/null
[ -f "$TEST_WORKSPACE/rnex.yaml" ] || { fail "rnex.yaml missing"; exit 1; }
[ -f "$TEST_WORKSPACE/AGENTS.md" ] || { fail "AGENTS.md missing"; exit 1; }
grep -q 'repos_dir:' "$TEST_WORKSPACE/rnex.yaml" || { fail "repos_dir not in config"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Re-init warns and suggests sync"
_reinit_output="$("$TEST_WORKSPACE/rnex" init "$TEST_WORKSPACE" 2>&1)"
echo "$_reinit_output" | grep -qi "already" || { fail "No already-initialized warning"; exit 1; }
echo "$_reinit_output" | grep -qi "sync" || { fail "No sync suggestion"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Add member repository (Scope link + AI injection)"
"$TEST_WORKSPACE/rnex" add test-app "$TEST_REPO" >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { fail "Scope link missing"; exit 1; }
[ -L "$TEST_REPO/AGENTS.md" ] || { fail "AGENTS.md symlink missing in repo"; exit 1; }
grep -q "AGENTS.md" "$TEST_REPO/.gitignore" || { fail ".gitignore not updated"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Write-Through propagation via symlink"
echo 'console.log("updated via nexus");' > "$TEST_WORKSPACE/repos/test-app/src/app.js"
grep -q "updated via nexus" "$TEST_REPO/src/app.js" || { fail "Write-through failed"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Hide and Show repository scope"
"$TEST_WORKSPACE/rnex" hide test-app >/dev/null
[ ! -e "$TEST_WORKSPACE/repos/test-app" ] || { fail "Hide failed"; exit 1; }
"$TEST_WORKSPACE/rnex" show test-app >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { fail "Show failed"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Idempotent Sync"
"$TEST_WORKSPACE/rnex" sync >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { fail "Sync scope failed"; exit 1; }
[ -L "$TEST_REPO/AGENTS.md" ] || { fail "Sync AI files failed"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Explicit --config / -c from an external directory"
cd "$TEST_OUTSIDE"
"$TEST_WORKSPACE/rnex" --config "$TEST_WORKSPACE/rnex.yaml" status >/dev/null
"$TEST_WORKSPACE/rnex" -c "$TEST_WORKSPACE/rnex.yaml" list >/dev/null
cd "$TEST_WORKSPACE"
pass

# --------------------------------------------------------------------------
run_test "Remove member repository"
"$TEST_WORKSPACE/rnex" remove test-app >/dev/null
[ ! -e "$TEST_WORKSPACE/repos/test-app" ] || { fail "Remove scope link failed"; exit 1; }
[ ! -e "$TEST_REPO/AGENTS.md" ] || { fail "Remove AI symlink failed"; exit 1; }
[ -d "$TEST_REPO/src" ] || { fail "Target repo was accidentally deleted"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "AI config auto-detection during init"
_detect_ws="$TEST_TMP/detect-workspace"
mkdir -p "$_detect_ws"
# Create known AI files
touch "$_detect_ws/CLAUDE.md"
touch "$_detect_ws/.cursorrules"
mkdir -p "$_detect_ws/.github"
touch "$_detect_ws/.github/copilot-instructions.md"
# Copy CLI
cp "$CLI" "$_detect_ws/rnex"
chmod +x "$_detect_ws/rnex"
if [ -d "$DIR/docs" ]; then
  cp -r "$DIR/docs" "$_detect_ws/docs"
fi
"$_detect_ws/rnex" init "$_detect_ws" >/dev/null
grep -q 'CLAUDE.md' "$_detect_ws/rnex.yaml" || { fail "CLAUDE.md not auto-detected"; exit 1; }
grep -q '.cursorrules' "$_detect_ws/rnex.yaml" || { fail ".cursorrules not auto-detected"; exit 1; }
grep -q 'copilot-instructions.md' "$_detect_ws/rnex.yaml" || { fail "copilot-instructions.md not auto-detected"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Custom repos_dir configuration"
_rd_ws="$TEST_TMP/custom-reposdir"
_rd_repo="$TEST_TMP/rd-repo"
mkdir -p "$_rd_ws" "$_rd_repo/src"
git -C "$_rd_repo" init -q
git -C "$_rd_repo" add .
git -C "$_rd_repo" commit -m "init" -q --allow-empty
cp "$CLI" "$_rd_ws/rnex"
chmod +x "$_rd_ws/rnex"
if [ -d "$DIR/docs" ]; then
  cp -r "$DIR/docs" "$_rd_ws/docs"
fi
"$_rd_ws/rnex" init "$_rd_ws" >/dev/null
# Modify repos_dir in config
sed -i.bak 's|repos_dir: ./repos|repos_dir: ./linked|' "$_rd_ws/rnex.yaml"
cd "$_rd_ws"
"$_rd_ws/rnex" add rd-test "$_rd_repo" >/dev/null
[ -L "$_rd_ws/linked/rd-test" ] || { fail "Custom repos_dir link not created"; exit 1; }
cd "$TEST_WORKSPACE"
pass

# --------------------------------------------------------------------------
run_test "Version command"
_ver="$("$TEST_WORKSPACE/rnex" version 2>&1)"
echo "$_ver" | grep -q "0.1.0" || { fail "Version not displayed"; exit 1; }
pass

# ==========================================================================

echo ""
echo "===================================="
if [ "$FAIL" -eq 0 ]; then
  echo "  All $TOTAL Automated Tests Passed! ✓"
else
  echo "  $PASS/$TOTAL passed, $FAIL FAILED"
fi
echo "===================================="

[ "$FAIL" -eq 0 ] || exit 1
