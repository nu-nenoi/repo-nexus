#!/bin/sh
# ============================================================================
# tests/test_cli.sh — Automated Test Suite for rnex 2.0 (v0.4.0)
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
run_test "Initialize workspace with gitignore and routing instructions"
"$TEST_WORKSPACE/rnex" init -y "$TEST_WORKSPACE" >/dev/null
[ -f "$TEST_WORKSPACE/rnex.yaml" ] || { fail "rnex.yaml missing"; exit 1; }
[ -f "$TEST_WORKSPACE/AGENTS.md" ] || { fail "AGENTS.md missing"; exit 1; }
[ -d "$TEST_WORKSPACE/repos" ] || { fail "repos/ dir missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.gitignore" ] || { fail ".gitignore missing"; exit 1; }
grep -q 'repos/\*' "$TEST_WORKSPACE/.gitignore" || { fail "repos/* not in .gitignore"; exit 1; }
grep -q '^\.rnex/' "$TEST_WORKSPACE/.gitignore" || { fail ".rnex/ not in .gitignore"; exit 1; }
grep -q '.local.rnex.yaml' "$TEST_WORKSPACE/.gitignore" || { fail ".local.rnex.yaml not in .gitignore"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Re-init warns and suggests fix"
_reinit_output="$("$TEST_WORKSPACE/rnex" init -y "$TEST_WORKSPACE" 2>&1)"
echo "$_reinit_output" | grep -qi "already" || { fail "No already-initialized warning"; exit 1; }
echo "$_reinit_output" | grep -qi "fix" || { fail "No fix suggestion"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Add member repository (clones into repos/ and creates member .rnex/)"
"$TEST_WORKSPACE/rnex" add test-app "$TEST_REPO" >/dev/null
[ -d "$TEST_WORKSPACE/repos/test-app/.git" ] || { fail "Physical clone in repos/test-app missing"; exit 1; }
[ -d "$TEST_WORKSPACE/repos/test-app/.rnex" ] || { fail ".rnex/ missing in member repo"; exit 1; }
[ -f "$TEST_WORKSPACE/repos/test-app/.rnex/README.md" ] || { fail ".rnex/README.md missing in member repo"; exit 1; }
grep -q "test-app:" "$TEST_WORKSPACE/rnex.yaml" || { fail "test-app not in rnex.yaml"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Batch command execution (rnex exec)"
_exec_out="$("$TEST_WORKSPACE/rnex" exec "git status -s" 2>&1)"
echo "$_exec_out" | grep -q "test-app" || { fail "rnex exec did not execute in test-app"; exit 1; }
echo "$_exec_out" | grep -q "succeeded" || { fail "rnex exec reported failure"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Disable and enable repository"
"$TEST_WORKSPACE/rnex" disable test-app >/dev/null
_list_out="$("$TEST_WORKSPACE/rnex" list 2>&1)"
echo "$_list_out" | grep "test-app" | grep -q "disabled" || { fail "test-app not listed as disabled"; exit 1; }

# Disabled repos are skipped by rnex exec
_exec_dis="$("$TEST_WORKSPACE/rnex" exec "echo running" 2>&1)"
! echo "$_exec_dis" | grep -q "running" || { fail "Disabled repo should be skipped by exec"; exit 1; }

"$TEST_WORKSPACE/rnex" enable test-app >/dev/null
_list_en="$("$TEST_WORKSPACE/rnex" list 2>&1)"
echo "$_list_en" | grep "test-app" | grep -q "enabled" || { fail "test-app not listed as enabled"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Clone command restores missing repositories"
# Temporarily remove test-app physical folder
rm -rf "$TEST_WORKSPACE/repos/test-app"
[ ! -d "$TEST_WORKSPACE/repos/test-app" ] || { fail "Failed to remove test-app dir"; exit 1; }

"$TEST_WORKSPACE/rnex" clone >/dev/null
[ -d "$TEST_WORKSPACE/repos/test-app/.git" ] || { fail "rnex clone did not restore test-app"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Idempotent Fix (and sync alias)"
"$TEST_WORKSPACE/rnex" fix >/dev/null
[ -d "$TEST_WORKSPACE/repos/test-app/.rnex" ] || { fail ".rnex missing after fix"; exit 1; }
"$TEST_WORKSPACE/rnex" sync >/dev/null
pass

# --------------------------------------------------------------------------
run_test "Explicit --config / -c from an external directory"
cd "$TEST_OUTSIDE"
"$TEST_WORKSPACE/rnex" --config "$TEST_WORKSPACE/rnex.yaml" status >/dev/null
"$TEST_WORKSPACE/rnex" -c "$TEST_WORKSPACE/rnex.yaml" list >/dev/null
cd "$TEST_WORKSPACE"
pass

# --------------------------------------------------------------------------
run_test "Remove member repository (unregisters and deletes repos/<name>)"
"$TEST_WORKSPACE/rnex" remove test-app >/dev/null
[ ! -e "$TEST_WORKSPACE/repos/test-app" ] || { fail "Physical repo folder was not deleted on remove"; exit 1; }
! grep -q "test-app:" "$TEST_WORKSPACE/rnex.yaml" || { fail "test-app still in rnex.yaml"; exit 1; }
[ -d "$TEST_REPO/src" ] || { fail "Original source repo was deleted"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Version command outputs version dynamically from package.json"
_expected_ver="$(grep '"version"' "$DIR/package.json" 2>/dev/null | head -n1 | sed -e 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/')"
_ver="$("$TEST_WORKSPACE/rnex" version 2>&1)"
echo "$_ver" | grep -q "$_expected_ver" || { fail "Version $_expected_ver not displayed: got $_ver"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Shell completion generator"
_zsh_comp="$("$TEST_WORKSPACE/rnex" completion zsh 2>&1)"
echo "$_zsh_comp" | grep -q "compdef rnex" || { fail "zsh completion missing compdef"; exit 1; }
_bash_comp="$("$TEST_WORKSPACE/rnex" completion bash 2>&1)"
echo "$_bash_comp" | grep -q "complete -F _rnex_completions" || { fail "bash completion missing complete -F"; exit 1; }
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
run_test "Plugin info shows scoped directory"
_pinfo_out="$("$TEST_WORKSPACE/rnex" plugin info karpathy-llm 2>&1)"
echo "$_pinfo_out" | grep -q "karpathy-llm" || { fail "Plugin name missing from info"; exit 1; }
echo "$_pinfo_out" | grep -q "Scoped Directory" || { fail "Scoped Directory missing from info"; exit 1; }
echo "$_pinfo_out" | grep -q ".rnex/plugins/karpathy-llm" || { fail ".rnex/plugins/karpathy-llm missing from info"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin enable command scopes assets to .rnex/plugins/karpathy-llm/"
"$TEST_WORKSPACE/rnex" plugin enable karpathy-llm >/dev/null
grep -q "karpathy-llm" "$TEST_WORKSPACE/rnex.yaml" || { fail "karpathy-llm not in rnex.yaml"; exit 1; }
[ -d "$TEST_WORKSPACE/.rnex/plugins/karpathy-llm" ] || { fail "Scoped plugin dir missing in workspace"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/plugins/karpathy-llm/rules/behavioral.md" ] || { fail "behavioral.md missing in scoped plugin dir"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/plugins/karpathy-llm/instructions/wiki-architecture.md" ] || { fail "wiki-architecture.md missing in scoped plugin dir"; exit 1; }
[ -d "$TEST_WORKSPACE/repos/test-app/.rnex/plugins/karpathy-llm" ] || { fail "Scoped plugin dir missing in member repo"; exit 1; }
[ -f "$TEST_WORKSPACE/wiki/index.md" ] || { fail "wiki/index.md not initialized in workspace"; exit 1; }
grep -q "title: Wiki Index" "$TEST_WORKSPACE/wiki/index.md" || { fail "wiki/index.md missing title: Wiki Index"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Plugin disable command cleans up scoped plugin assets while preserving wiki"
"$TEST_WORKSPACE/rnex" plugin disable karpathy-llm >/dev/null
grep -q "karpathy-llm" "$TEST_WORKSPACE/rnex.yaml" && { fail "karpathy-llm still in rnex.yaml"; exit 1; }
[ ! -d "$TEST_WORKSPACE/.rnex/plugins/karpathy-llm" ] || { fail "Scoped plugin dir still present in workspace"; exit 1; }
[ ! -d "$TEST_WORKSPACE/repos/test-app/.rnex/plugins/karpathy-llm" ] || { fail "Scoped plugin dir still present in member repo"; exit 1; }
[ -f "$TEST_WORKSPACE/wiki/index.md" ] || { fail "User wiki data was incorrectly deleted"; exit 1; }
pass

# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
run_test "Routing-Only Instructions in AGENTS.md"
_agents_content="$(cat "$TEST_WORKSPACE/AGENTS.md")"
echo "$_agents_content" | grep -q "Read Configuration First" || { fail "AGENTS.md missing Read Configuration First"; exit 1; }
echo "$_agents_content" | grep -q ".local.rnex.yaml" || { fail "AGENTS.md missing .local.rnex.yaml"; exit 1; }
echo "$_agents_content" | grep -q "Highest Priority" || { fail "AGENTS.md missing Highest Priority notice"; exit 1; }
echo "$_agents_content" | grep -q ".rnex/plugins/<plugin-name>/" || { fail "AGENTS.md missing plugin routing"; exit 1; }
echo "$_agents_content" | grep -q "Routing Protocol for AI Assistants" || { fail "AGENTS.md missing Routing Protocol heading"; exit 1; }
! echo "$_agents_content" | grep -qi "symlink" || { fail "AGENTS.md should not contain symlink mentions"; exit 1; }
! echo "$_agents_content" | grep -q "Think Before Coding" || { fail "AGENTS.md should not contain inlined plugin rules"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Gitignore reconciliation removes legacy lint_trigger_counter and ensures .rnex/"
printf '\n.rnex/.lint_trigger_counter\nwiki/.lint_trigger_counter\n.lint_trigger_counter\n' >> "$TEST_WORKSPACE/.gitignore"
"$TEST_WORKSPACE/rnex" fix >/dev/null
grep -q "lint_trigger_counter" "$TEST_WORKSPACE/.gitignore" && { fail "Legacy lint_trigger_counter still present in .gitignore"; exit 1; }
grep -q '^\.rnex/' "$TEST_WORKSPACE/.gitignore" || { fail ".rnex/ missing from .gitignore after fix"; exit 1; }
grep -q 'repos/\*' "$TEST_WORKSPACE/.gitignore" || { fail "repos/* missing from .gitignore after fix"; exit 1; }
grep -q '.local.rnex.yaml' "$TEST_WORKSPACE/.gitignore" || { fail ".local.rnex.yaml missing from .gitignore after fix"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Legacy un-delimited AGENTS.md with symlinks upgraded cleanly to routing protocol"
cat <<'LEGACY_EOF' > "$TEST_WORKSPACE/AGENTS.md"
# Multi-Repo AI Workspace Context

This workspace operates as a **Repo Nexus** linking multiple independent repositories via symlinks.

## Rules for AI Coding Assistants

1. **Workspace Structure & Settings**: AI coding assistants MUST inspect and read `rnex.yaml`.
2. **Symlink Write-Through**: Files edited under `repos/<name>/` directly modify the target repository.
3. **Plugin Instructions**: If plugins are enabled in `rnex.yaml` (under `plugins:`), AI coding assistants MUST read instructions.
LEGACY_EOF

"$TEST_WORKSPACE/rnex" fix >/dev/null
_upgraded_agents="$(cat "$TEST_WORKSPACE/AGENTS.md")"
echo "$_upgraded_agents" | grep -q "<!-- REPO-NEXUS:START -->" || { fail "Missing start delimiter after upgrade"; exit 1; }
echo "$_upgraded_agents" | grep -q "<!-- REPO-NEXUS:END -->" || { fail "Missing end delimiter after upgrade"; exit 1; }
echo "$_upgraded_agents" | grep -q "Routing Protocol for AI Assistants" || { fail "Missing Routing Protocol after upgrade"; exit 1; }
! echo "$_upgraded_agents" | grep -qi "symlink" || { fail "Upgraded AGENTS.md still contains symlink mentions"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Two-level config: add --local writes to .local.rnex.yaml"
_local_repo_dir="$TEST_TMP/local-repo"
mkdir -p "$_local_repo_dir/src"
git -C "$_local_repo_dir" init -q
git -C "$_local_repo_dir" add .
git -C "$_local_repo_dir" commit -m "init" -q --allow-empty

"$TEST_WORKSPACE/rnex" add --local local-app "$_local_repo_dir" >/dev/null
[ -f "$TEST_WORKSPACE/.local.rnex.yaml" ] || { fail ".local.rnex.yaml not created"; exit 1; }
grep -q "local-app" "$TEST_WORKSPACE/.local.rnex.yaml" || { fail "local-app not found in .local.rnex.yaml"; exit 1; }
! grep -q "local-app" "$TEST_WORKSPACE/rnex.yaml" || { fail "local-app should not be written to rnex.yaml"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Two-level config: disable --local overrides rnex.yaml"
"$TEST_WORKSPACE/rnex" disable --local test-app >/dev/null
grep -q "test-app:" "$TEST_WORKSPACE/.local.rnex.yaml" || { fail "test-app not in .local.rnex.yaml"; exit 1; }
grep -q "enabled:[ ]*false" "$TEST_WORKSPACE/.local.rnex.yaml" || { fail "enabled: false not set in .local.rnex.yaml"; exit 1; }
! grep -q "enabled:[ ]*false" "$TEST_WORKSPACE/rnex.yaml" || { fail "rnex.yaml was mutated by --local"; exit 1; }

# Verify list shows disabled
_list_chk="$("$TEST_WORKSPACE/rnex" list 2>&1)"
echo "$_list_chk" | grep "test-app" | grep -q "disabled" || { fail "test-app not recognized as disabled from local config"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Status highlights Git Ignore and Workspace AI Context"
_status_out="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_out" | grep -q "Git Ignore:" || { fail "Status did not show Git Ignore"; exit 1; }
echo "$_status_out" | grep -q "Workspace AI Context" || { fail "Status did not show AI Context"; exit 1; }
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
