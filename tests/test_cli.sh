#!/bin/sh
# ============================================================================
# tests/test_cli.sh — Automated Test Suite for rnex
# ============================================================================
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$DIR/rnex"

# Configure git identity for test repository commits
export GIT_AUTHOR_NAME="Test Runner"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test Runner"
export GIT_COMMITTER_EMAIL="test@example.com"

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
if [ -f "$DIR/package.json" ]; then
  cp "$DIR/package.json" "$TEST_WORKSPACE/package.json"
fi
# Copy docs and toolkit for templates and built-in plugins
if [ -d "$DIR/docs" ]; then
  cp -r "$DIR/docs" "$TEST_WORKSPACE/docs"
fi
if [ -d "$DIR/toolkit" ]; then
  cp -r "$DIR/toolkit" "$TEST_WORKSPACE/toolkit"
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
echo "$_ver" | grep -q "0.2.0" || { fail "Version not displayed"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Install command (native global installer)"
_install_dir="$TEST_TMP/custom_bin"
"$TEST_WORKSPACE/rnex" install "$_install_dir" >/dev/null
[ -x "$_install_dir/rnex" ] || { fail "rnex not installed to custom bin"; exit 1; }
[ -x "$_install_dir/repo-nexus" ] || { fail "repo-nexus not installed to custom bin"; exit 1; }
_reinstall_out="$("$TEST_WORKSPACE/rnex" install "$_install_dir" 2>&1)"
echo "$_reinstall_out" | grep -qi "already installed" || { fail "Did not detect already installed"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin list command"
# Re-add test-app for plugin tests
"$TEST_WORKSPACE/rnex" add test-app "$TEST_REPO" >/dev/null
_plist_out="$("$TEST_WORKSPACE/rnex" plugin list 2>&1)"
echo "$_plist_out" | grep -q "karpathy-llm" || { fail "karpathy-llm not found in plugin list"; exit 1; }
echo "$_plist_out" | grep -q "available" || { fail "karpathy-llm not marked available"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin info command"
_pinfo_out="$("$TEST_WORKSPACE/rnex" plugin info karpathy-llm 2>&1)"
echo "$_pinfo_out" | grep -q "karpathy-llm" || { fail "Plugin name missing from info"; exit 1; }
echo "$_pinfo_out" | grep -q "KARPATHY_RULES.md" || { fail "KARPATHY_RULES.md missing from info"; exit 1; }
echo "$_pinfo_out" | grep -q "LLM_WIKI.sample.md" || { fail "LLM_WIKI.sample.md missing from info"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin enable command"
"$TEST_WORKSPACE/rnex" plugin enable karpathy-llm >/dev/null
grep -q "karpathy-llm" "$TEST_WORKSPACE/rnex.yaml" || { fail "karpathy-llm not in rnex.yaml"; exit 1; }
[ -f "$TEST_WORKSPACE/.agents/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md missing in workspace root"; exit 1; }
[ -L "$TEST_REPO/.agents/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md symlink missing in member repo"; exit 1; }
[ -f "$TEST_WORKSPACE/docs/LLM_WIKI.sample.md" ] || { fail "LLM_WIKI.sample.md not initialized in docs/"; exit 1; }
_status_out="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_out" | grep -q "karpathy-llm" || { fail "Active plugin not listed in status"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin disable command"
"$TEST_WORKSPACE/rnex" plugin disable karpathy-llm >/dev/null
grep -q "karpathy-llm" "$TEST_WORKSPACE/rnex.yaml" && { fail "karpathy-llm still in rnex.yaml"; exit 1; }
[ ! -e "$TEST_REPO/.agents/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md not unlinked from repo"; exit 1; }
_plist_after="$("$TEST_WORKSPACE/rnex" plugin list 2>&1)"
echo "$_plist_after" | grep -q "available" || { fail "karpathy-llm not returned to available status"; exit 1; }
pass
# --------------------------------------------------------------------------
run_test "Add repo with existing AI file prompts user and extends (Yes answered)"
_existing_repo="$TEST_TMP/existing-ai-repo"
mkdir -p "$_existing_repo/src"
printf '# Repo Original Rules\n- Original custom rule\n' > "$_existing_repo/AGENTS.md"
git -C "$_existing_repo" init -q
git -C "$_existing_repo" add .
git -C "$_existing_repo" commit -m "init" -q

# Piped 'y' to simulate user confirming update
_add_out="$(printf "y\n" | "$TEST_WORKSPACE/rnex" add existing-app "$_existing_repo" 2>&1)"
echo "$_add_out" | grep -qi "already exists" || { fail "Did not ask about existing file"; exit 1; }
[ -f "$_existing_repo/AGENTS.md" ] || { fail "AGENTS.md missing"; exit 1; }
[ ! -L "$_existing_repo/AGENTS.md" ] || { fail "AGENTS.md was replaced by a symlink instead of extended"; exit 1; }
grep -q "Repo Original Rules" "$_existing_repo/AGENTS.md" || { fail "Original rules were lost"; exit 1; }
grep -q "REPO-NEXUS AI CONTEXT" "$_existing_repo/AGENTS.md" || { fail "Workspace context was not extended"; exit 1; }
# Should not add non-symlink file to .gitignore
if [ -f "$_existing_repo/.gitignore" ]; then
  grep -q "AGENTS.md" "$_existing_repo/.gitignore" && { fail "Extended regular file was incorrectly added to .gitignore"; exit 1; }
fi
pass

# --------------------------------------------------------------------------
run_test "Add repo with existing AI file preserves content when No answered"
_no_repo="$TEST_TMP/no-update-repo"
mkdir -p "$_no_repo/src"
printf '# Untouched Rules\n' > "$_no_repo/AGENTS.md"
git -C "$_no_repo" init -q
git -C "$_no_repo" add .
git -C "$_no_repo" commit -m "init" -q

# Piped 'n' to decline updating
_add_no_out="$(printf "n\n" | "$TEST_WORKSPACE/rnex" add no-app "$_no_repo" 2>&1)"
echo "$_add_no_out" | grep -qi "already exists" || { fail "Did not ask about existing file"; exit 1; }
[ ! -L "$_no_repo/AGENTS.md" ] || { fail "AGENTS.md was replaced by symlink"; exit 1; }
grep -q "Untouched Rules" "$_no_repo/AGENTS.md" || { fail "Original content changed"; exit 1; }
grep -q "REPO-NEXUS AI CONTEXT" "$_no_repo/AGENTS.md" && { fail "Markers should not be added when No answered"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Sync reconciles and updates extended section without duplicating"
printf '# Updated Workspace Nexus AI Context\n- New sync rule\n' > "$TEST_WORKSPACE/AGENTS.md"
"$TEST_WORKSPACE/rnex" sync >/dev/null
grep -q "Repo Original Rules" "$_existing_repo/AGENTS.md" || { fail "Original rules lost during sync"; exit 1; }
grep -q "New sync rule" "$_existing_repo/AGENTS.md" || { fail "Extended section was not updated during sync"; exit 1; }
# Ensure markers only appear once
_marker_count="$(grep -c "REPO-NEXUS AI CONTEXT (START)" "$_existing_repo/AGENTS.md")"
[ "$_marker_count" -eq 1 ] || { fail "Marker duplicated during sync: count=$_marker_count"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Remove unextends AI context restoring original file"
"$TEST_WORKSPACE/rnex" remove existing-app >/dev/null
[ -f "$_existing_repo/AGENTS.md" ] || { fail "AGENTS.md was deleted upon remove"; exit 1; }
grep -q "Repo Original Rules" "$_existing_repo/AGENTS.md" || { fail "Original rules lost upon remove"; exit 1; }
grep -q "REPO-NEXUS AI CONTEXT" "$_existing_repo/AGENTS.md" && { fail "AI markers were not removed upon repo removal"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Add repo with -y flag auto-confirms extending existing AI files"
_auto_repo="$TEST_TMP/auto-yes-repo"
mkdir -p "$_auto_repo/src"
printf '# Pre-existing Custom Rules\n' > "$_auto_repo/AGENTS.md"
git -C "$_auto_repo" init -q
git -C "$_auto_repo" add .
git -C "$_auto_repo" commit -m "init" -q

_add_y_out="$("$TEST_WORKSPACE/rnex" add -y auto-app "$_auto_repo" 2>&1)"
echo "$_add_y_out" | grep -q "auto" || { fail "Did not auto-confirm"; exit 1; }
grep -q "Pre-existing Custom Rules" "$_auto_repo/AGENTS.md" || { fail "Custom rules lost"; exit 1; }
grep -q "REPO-NEXUS AI CONTEXT" "$_auto_repo/AGENTS.md" || { fail "Context not extended"; exit 1; }
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
