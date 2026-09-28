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
run_test "Add member repository (links scope and creates member .rnex/ by default)"
"$TEST_WORKSPACE/rnex" add test-app "$TEST_REPO" >/dev/null
[ -L "$TEST_WORKSPACE/repos/test-app" ] || { fail "Scope link missing"; exit 1; }
[ ! -e "$TEST_REPO/AGENTS.md" ] || { fail "AGENTS.md incorrectly injected into member repo root"; exit 1; }
[ -d "$TEST_REPO/.rnex" ] || { fail ".rnex/ missing in member repo"; exit 1; }
[ -f "$TEST_REPO/.rnex/README.md" ] || { fail ".rnex/README.md missing in member repo"; exit 1; }
grep -q "rnex_dir:[ ]*true" "$TEST_WORKSPACE/rnex.yaml" || { fail "rnex_dir: true not in rnex.yaml"; exit 1; }
if [ -f "$TEST_REPO/.gitignore" ]; then
  ! grep -q "AGENTS.md" "$TEST_REPO/.gitignore" || { fail ".gitignore was incorrectly modified"; exit 1; }
fi
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
[ ! -e "$TEST_REPO/AGENTS.md" ] || { fail "Sync should not inject files into member repo"; exit 1; }
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
[ -d "$TEST_REPO/src" ] || { fail "Target repo was accidentally deleted"; exit 1; }
[ ! -e "$TEST_REPO/.rnex" ] || { fail "Clean repo removal should remove auto-generated .rnex"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Clean workspace init creates config and directories"
_detect_ws="$TEST_TMP/detect-workspace"
mkdir -p "$_detect_ws"
cp "$CLI" "$_detect_ws/rnex"
chmod +x "$_detect_ws/rnex"
if [ -d "$DIR/docs" ]; then
  cp -r "$DIR/docs" "$_detect_ws/docs"
fi
"$_detect_ws/rnex" init "$_detect_ws" >/dev/null
[ -f "$_detect_ws/rnex.yaml" ] || { fail "rnex.yaml missing"; exit 1; }
[ -f "$_detect_ws/AGENTS.md" ] || { fail "AGENTS.md missing"; exit 1; }
[ -d "$_detect_ws/.rnex" ] || { fail ".rnex/ missing"; exit 1; }
! grep -q 'ai_files:' "$_detect_ws/rnex.yaml" || { fail "ai_files should not exist in rnex.yaml"; exit 1; }
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
_expected_ver="$(awk '/"version"[ ]*:/ { sub(/.*"version"[ ]*:[ ]*"/, ""); sub(/".*/, ""); print; exit }' "$TEST_WORKSPACE/package.json")"
echo "$_ver" | grep -q "$_expected_ver" || { fail "Version not displayed"; exit 1; }
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
grep -q "lint_trigger_enabled:[ ]*true" "$TEST_WORKSPACE/rnex.yaml" || { fail "lint_trigger_enabled not in rnex.yaml"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md missing in workspace root"; exit 1; }
[ -L "$TEST_REPO/.rnex/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md symlink missing in member repo .rnex"; exit 1; }
[ ! -e "$TEST_REPO/KARPATHY_RULES.md" ] || { fail "Plugin rule should not be loose at member repo root"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/templates/LLM_WIKI.sample.md" ] || { fail "LLM_WIKI.sample.md not initialized in .rnex/templates/"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/scripts/wiki-lint-trigger.sh" ] || { fail "wiki-lint-trigger.sh not initialized in .rnex/scripts/"; exit 1; }
[ -f "$TEST_WORKSPACE/wiki/index.md" ] || { fail "wiki/index.md not initialized in workspace"; exit 1; }
grep -q "title: Wiki Index" "$TEST_WORKSPACE/wiki/index.md" || { fail "wiki/index.md missing title: Wiki Index"; exit 1; }
grep -q ".rnex/.lint_trigger_counter" "$TEST_WORKSPACE/.gitignore" || { fail ".rnex/.lint_trigger_counter not added to .gitignore"; exit 1; }
_status_out="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_out" | grep -q "karpathy-llm" || { fail "Active plugin not listed in status"; exit 1; }

# Verify updating lint_trigger_enabled: false reconciles wiki/index.md upon sync
sed -i.bak 's/lint_trigger_enabled: true/lint_trigger_enabled: false/' "$TEST_WORKSPACE/rnex.yaml"
"$TEST_WORKSPACE/rnex" sync >/dev/null
grep -q "lint_trigger: disabled" "$TEST_WORKSPACE/wiki/index.md" || { fail "sync did not reconcile lint_trigger: disabled"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin disable command"
"$TEST_WORKSPACE/rnex" plugin disable karpathy-llm >/dev/null
grep -q "karpathy-llm" "$TEST_WORKSPACE/rnex.yaml" && { fail "karpathy-llm still in rnex.yaml"; exit 1; }
[ ! -e "$TEST_WORKSPACE/.rnex/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md not unlinked from workspace root"; exit 1; }
[ ! -e "$TEST_REPO/.rnex/rules/KARPATHY_RULES.md" ] || { fail "KARPATHY_RULES.md not unlinked from member repo .rnex"; exit 1; }
[ -f "$TEST_REPO/.rnex/README.md" ] || { fail "Member repo .rnex/README.md should still exist"; exit 1; }
_plist_after="$("$TEST_WORKSPACE/rnex" plugin list 2>&1)"
echo "$_plist_after" | grep -q "available" || { fail "karpathy-llm not returned to available status"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Toggle rnex-dir disable and enable"
"$TEST_WORKSPACE/rnex" rnex-dir disable test-app >/dev/null
grep -q "rnex_dir:[ ]*false" "$TEST_WORKSPACE/rnex.yaml" || { fail "rnex_dir: false not set in rnex.yaml"; exit 1; }
[ ! -e "$TEST_REPO/.rnex" ] || { fail ".rnex/ not removed from test-app when disabled"; exit 1; }
_list_out="$("$TEST_WORKSPACE/rnex" list 2>&1)"
echo "$_list_out" | grep "test-app" | grep -q "disabled" || { fail "list did not show rnex_dir disabled"; exit 1; }

"$TEST_WORKSPACE/rnex" rnex-dir enable test-app >/dev/null
grep -q "rnex_dir:[ ]*true" "$TEST_WORKSPACE/rnex.yaml" || { fail "rnex_dir: true not restored in rnex.yaml"; exit 1; }
[ -d "$TEST_REPO/.rnex" ] || { fail ".rnex/ not re-created when enabled"; exit 1; }
[ -f "$TEST_REPO/.rnex/README.md" ] || { fail ".rnex/README.md missing after re-enabling"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Add repo with --no-rnex-dir leaves repo completely untouched"
_no_dir_repo="$TEST_TMP/no-dir-repo"
mkdir -p "$_no_dir_repo/src"
git -C "$_no_dir_repo" init -q
git -C "$_no_dir_repo" add .
git -C "$_no_dir_repo" commit -m "init" -q --allow-empty
"$TEST_WORKSPACE/rnex" add --no-rnex-dir no-dir-app "$_no_dir_repo" >/dev/null
[ -L "$TEST_WORKSPACE/repos/no-dir-app" ] || { fail "Scope link missing for no-dir-app"; exit 1; }
[ ! -e "$_no_dir_repo/.rnex" ] || { fail ".rnex/ created despite --no-rnex-dir flag"; exit 1; }
grep -q "rnex_dir:[ ]*false" "$TEST_WORKSPACE/rnex.yaml" || { fail "rnex_dir: false not set for no-dir-app"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Zero-Touch: Adding repo with existing local AGENTS.md leaves member repo untouched"
_existing_repo="$TEST_TMP/existing-ai-repo"
mkdir -p "$_existing_repo/src"
printf '# Repo Original Rules\n- Original custom rule\n' > "$_existing_repo/AGENTS.md"
git -C "$_existing_repo" init -q
git -C "$_existing_repo" add .
git -C "$_existing_repo" commit -m "init" -q

_add_out="$("$TEST_WORKSPACE/rnex" add existing-app "$_existing_repo" 2>&1)"
[ -L "$TEST_WORKSPACE/repos/existing-app" ] || { fail "Scope link missing for existing-app"; exit 1; }
[ -f "$_existing_repo/AGENTS.md" ] || { fail "AGENTS.md missing in existing-repo"; exit 1; }
[ ! -L "$_existing_repo/AGENTS.md" ] || { fail "AGENTS.md was replaced by a symlink"; exit 1; }
grep -q "Repo Original Rules" "$_existing_repo/AGENTS.md" || { fail "Original rules were lost"; exit 1; }
! grep -q "REPO-NEXUS" "$_existing_repo/AGENTS.md" || { fail "Workspace markers injected into member repo"; exit 1; }
if [ -f "$_existing_repo/.gitignore" ]; then
  ! grep -q "AGENTS.md" "$_existing_repo/.gitignore" || { fail ".gitignore was incorrectly modified"; exit 1; }
fi
pass

# --------------------------------------------------------------------------
run_test "Zero-Touch: Sync preserves existing member repo files untouched"
printf '# Updated Workspace Nexus AI Context\n- New sync rule\n' > "$TEST_WORKSPACE/AGENTS.md"
"$TEST_WORKSPACE/rnex" sync >/dev/null
grep -q "Repo Original Rules" "$_existing_repo/AGENTS.md" || { fail "Original rules lost during sync"; exit 1; }
! grep -q "New sync rule" "$_existing_repo/AGENTS.md" || { fail "Member repo was modified during sync"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Zero-Touch: Remove unlinks scope without modifying member repo files"
"$TEST_WORKSPACE/rnex" remove existing-app >/dev/null
[ ! -e "$TEST_WORKSPACE/repos/existing-app" ] || { fail "Scope link still present after remove"; exit 1; }
[ -f "$_existing_repo/AGENTS.md" ] || { fail "AGENTS.md was deleted upon remove"; exit 1; }
grep -q "Repo Original Rules" "$_existing_repo/AGENTS.md" || { fail "Original rules lost upon remove"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Zero-Touch: Adding repo with -y flag works identically and leaves repo untouched"
_auto_repo="$TEST_TMP/auto-yes-repo"
mkdir -p "$_auto_repo/src"
printf '# Pre-existing Custom Rules\n' > "$_auto_repo/AGENTS.md"
git -C "$_auto_repo" init -q
git -C "$_auto_repo" add .
git -C "$_auto_repo" commit -m "init" -q

_add_y_out="$("$TEST_WORKSPACE/rnex" add -y auto-app "$_auto_repo" 2>&1)"
[ -L "$TEST_WORKSPACE/repos/auto-app" ] || { fail "Scope link missing for auto-app"; exit 1; }
grep -q "Pre-existing Custom Rules" "$_auto_repo/AGENTS.md" || { fail "Custom rules lost"; exit 1; }
! grep -q "REPO-NEXUS" "$_auto_repo/AGENTS.md" || { fail "Workspace markers injected with -y"; exit 1; }
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
