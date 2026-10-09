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
[ -f "$TEST_WORKSPACE/repos/.gitkeep" ] || { fail "repos/.gitkeep missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.gitignore" ] || { fail ".gitignore missing"; exit 1; }
grep -q 'repos/\*' "$TEST_WORKSPACE/.gitignore" || { fail "repos/* not in .gitignore"; exit 1; }
! grep -q '^\.rnex/' "$TEST_WORKSPACE/.gitignore" || { fail ".rnex/ should not be in .gitignore"; exit 1; }
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
run_test "Gitignore reconciliation removes legacy lint_trigger_counter and strips .rnex/"
printf '\n.rnex/.lint_trigger_counter\nwiki/.lint_trigger_counter\n.lint_trigger_counter\n.rnex/\n' >> "$TEST_WORKSPACE/.gitignore"
"$TEST_WORKSPACE/rnex" fix >/dev/null
grep -q "lint_trigger_counter" "$TEST_WORKSPACE/.gitignore" && { fail "Legacy lint_trigger_counter still present in .gitignore"; exit 1; }
! grep -q '^\.rnex/' "$TEST_WORKSPACE/.gitignore" || { fail ".rnex/ still present in .gitignore after fix"; exit 1; }
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

# --------------------------------------------------------------------------
run_test "Status highlights missing custom ai_instructions file and fix creates it"
echo "ai_instructions: GEMINI.md" >> "$TEST_WORKSPACE/rnex.yaml"
_status_missing="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_missing" | grep -q "GEMINI.md" || { fail "Status did not show GEMINI.md in AI File"; exit 1; }
echo "$_status_missing" | grep -q "MISSING" || { fail "Status did not highlight GEMINI.md as MISSING"; exit 1; }
"$TEST_WORKSPACE/rnex" fix >/dev/null
[ -f "$TEST_WORKSPACE/GEMINI.md" ] || { fail "rnex fix did not create configured GEMINI.md"; exit 1; }
grep -q "Multi-Repo AI Workspace Context" "$TEST_WORKSPACE/GEMINI.md" || { fail "GEMINI.md missing routing instructions"; exit 1; }
_status_fixed="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_fixed" | grep "GEMINI.md" | grep -q "main instructions" || { fail "Status did not show GEMINI.md as main instructions"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Init with --ai flag sets custom AI instructions file"
TEST_AI_WS="$TEST_TMP/ai-workspace"
mkdir -p "$TEST_AI_WS"
cp "$CLI" "$TEST_AI_WS/rnex"
chmod +x "$TEST_AI_WS/rnex"
"$TEST_AI_WS/rnex" init -y --ai CLAUDE.md "$TEST_AI_WS" >/dev/null
[ -f "$TEST_AI_WS/CLAUDE.md" ] || { fail "CLAUDE.md was not created by init --ai"; exit 1; }
grep -q "ai_instructions:[ ]*CLAUDE.md" "$TEST_AI_WS/rnex.yaml" || { fail "ai_instructions not set in rnex.yaml"; exit 1; }
grep -q "Multi-Repo AI Workspace Context" "$TEST_AI_WS/CLAUDE.md" || { fail "CLAUDE.md missing routing rules"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Configurable code_workspace generates and updates .code-workspace file"
echo "code_workspace: true" >> "$TEST_WORKSPACE/rnex.yaml"
_status_ws="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_ws" | grep -q "nexus-workspace.code-workspace" || { fail "Status did not detect configured code_workspace file"; exit 1; }
echo "$_status_ws" | grep -q "MISSING" || { fail "Status did not highlight missing code-workspace"; exit 1; }
"$TEST_WORKSPACE/rnex" fix >/dev/null
[ -f "$TEST_WORKSPACE/nexus-workspace.code-workspace" ] || { fail "code-workspace file was not created by fix"; exit 1; }
grep -q '"folders"' "$TEST_WORKSPACE/nexus-workspace.code-workspace" || { fail "folders array missing in workspace file"; exit 1; }
grep -q 'nexus-workspace (Workspace Root)' "$TEST_WORKSPACE/nexus-workspace.code-workspace" || { fail "Root folder missing in workspace file"; exit 1; }
grep -q 'local-app' "$TEST_WORKSPACE/nexus-workspace.code-workspace" || { fail "local-app missing in workspace file"; exit 1; }
# Re-enable test-app and verify code-workspace updates automatically
"$TEST_WORKSPACE/rnex" enable --local test-app >/dev/null
grep -q 'test-app' "$TEST_WORKSPACE/nexus-workspace.code-workspace" || { fail "test-app not added to workspace file upon enable"; exit 1; }
_status_ws_ok="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_ws_ok" | grep "nexus-workspace.code-workspace" | grep -q "VS Code / Cursor workspace" || { fail "Status did not mark workspace file valid"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Init with --code-workspace flag configures and creates workspace file"
TEST_VS_WS="$TEST_TMP/vscode-workspace"
mkdir -p "$TEST_VS_WS"
cp "$CLI" "$TEST_VS_WS/rnex"
chmod +x "$TEST_VS_WS/rnex"
"$TEST_VS_WS/rnex" init -y --code-workspace "$TEST_VS_WS" >/dev/null
[ -f "$TEST_VS_WS/vscode-workspace.code-workspace" ] || { fail ".code-workspace was not created by init --code-workspace"; exit 1; }
grep -q "code_workspace:[ ]*true" "$TEST_VS_WS/rnex.yaml" || { fail "code_workspace not enabled in rnex.yaml"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Version-aware upgrade in rnex fix and update/upgrade commands"
TEST_UPGRADE_WS="$TEST_TMP/upgrade-workspace"
mkdir -p "$TEST_UPGRADE_WS"
cp "$CLI" "$TEST_UPGRADE_WS/rnex"
chmod +x "$TEST_UPGRADE_WS/rnex"
cp -r "$DIR/toolkit" "$TEST_UPGRADE_WS/toolkit"
cp "$DIR/package.json" "$TEST_UPGRADE_WS/package.json"

# Write older pre-v0.5.0 configuration (missing version & code_workspace)
cat <<'OLD_YAML' > "$TEST_UPGRADE_WS/rnex.yaml"
# Pre-versioned workspace configuration
repos_dir: ./repos
ai_instructions: AGENTS.md
plugins:
repos:
OLD_YAML

cat <<'OLD_AGENTS' > "$TEST_UPGRADE_WS/AGENTS.md"
<!-- REPO-NEXUS:START -->
# Multi-Repo AI Workspace Context
Legacy instructions without mandatory startup
<!-- REPO-NEXUS:END -->
OLD_AGENTS

# Fix with -y should detect missing/older version, upgrade config, and reconcile instructions
(cd "$TEST_UPGRADE_WS" && ./rnex fix -y >/dev/null)
_ws_cli_ver="$("$TEST_UPGRADE_WS/rnex" version 2>&1 | awk '{print $NF}')"
grep -q "version:[ ]*$_ws_cli_ver" "$TEST_UPGRADE_WS/rnex.yaml" || { fail "rnex fix -y did not add version $_ws_cli_ver to rnex.yaml"; exit 1; }
grep -q "code_workspace:[ ]*false" "$TEST_UPGRADE_WS/rnex.yaml" || { fail "rnex fix -y did not populate missing code_workspace key"; exit 1; }
grep -q "git_hooks:[ ]*false" "$TEST_UPGRADE_WS/rnex.yaml" || { fail "rnex fix -y did not populate missing git_hooks key"; exit 1; }
grep -q "Mandatory Session Startup" "$TEST_UPGRADE_WS/AGENTS.md" || { fail "AGENTS.md not updated with Mandatory Session Startup"; exit 1; }
grep -q "\.rnex/prompts/index\.md" "$TEST_UPGRADE_WS/AGENTS.md" || { fail "AGENTS.md missing prompts catalog reference"; exit 1; }

# Running update when already at current version should report up to date
_up_out="$(cd "$TEST_UPGRADE_WS" && ./rnex update 2>&1)"
echo "$_up_out" | grep -q "already up to date" || { fail "rnex update did not report already up to date"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Standardized prompts synced to .rnex/prompts/ and indexed"
[ -d "$TEST_WORKSPACE/.rnex/prompts" ] || { fail ".rnex/prompts directory was not created"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/prompts/index.md" ] || { fail "prompts/index.md missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/prompts/rnex-cross-repo-feature.md" ] || { fail "rnex-cross-repo-feature.md missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/prompts/rnex-workspace-audit.md" ] || { fail "rnex-workspace-audit.md missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/prompts/rnex-wiki-ingest.md" ] || { fail "rnex-wiki-ingest.md missing"; exit 1; }
[ -f "$TEST_WORKSPACE/.rnex/prompts/rnex-wiki-lint.md" ] || { fail "rnex-wiki-lint.md missing"; exit 1; }
# Verify member repos do not contain workspace prompts
[ ! -d "$TEST_WORKSPACE/repos/test-app/.rnex/prompts" ] || { fail "Workspace prompts leaked into member repo .rnex"; exit 1; }
# Verify status highlights prompts catalog
_status_prompts="$("$TEST_WORKSPACE/rnex" status 2>&1)"
echo "$_status_prompts" | grep -q "prompts catalog" || { fail "Status does not highlight prompts catalog"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Git hooks install, status, dispatch, and uninstall"
TEST_HOOKS_WS="$TEST_TMP/hooks-workspace"
mkdir -p "$TEST_HOOKS_WS"
cp "$CLI" "$TEST_HOOKS_WS/rnex"
chmod +x "$TEST_HOOKS_WS/rnex"
cp -r "$DIR/toolkit" "$TEST_HOOKS_WS/toolkit"
cp "$DIR/package.json" "$TEST_HOOKS_WS/package.json"
git -C "$TEST_HOOKS_WS" init -q

# Initialize without hooks first
(cd "$TEST_HOOKS_WS" && ./rnex init -y --no-hooks >/dev/null)
grep -q "^git_hooks: false" "$TEST_HOOKS_WS/rnex.yaml" || { fail "init --no-hooks did not record git_hooks: false in rnex.yaml"; exit 1; }
_pre_status="$(cd "$TEST_HOOKS_WS" && ./rnex status 2>&1)"
echo "$_pre_status" | grep -q "Git Hooks:[ ]*disabled in configuration" || { fail "Status did not report disabled hooks"; exit 1; }

# Install hooks
(cd "$TEST_HOOKS_WS" && ./rnex hooks install >/dev/null)
grep -q "^git_hooks: true" "$TEST_HOOKS_WS/rnex.yaml" || { fail "hooks install did not record git_hooks: true in rnex.yaml"; exit 1; }
[ -d "$TEST_HOOKS_WS/.rnex/hooks" ] || { fail ".rnex/hooks directory missing"; exit 1; }
[ -x "$TEST_HOOKS_WS/.rnex/hooks/post-merge" ] || { fail "post-merge hook missing or not executable"; exit 1; }
[ -x "$TEST_HOOKS_WS/.rnex/hooks/post-commit" ] || { fail "post-commit hook missing or not executable"; exit 1; }
[ -x "$TEST_HOOKS_WS/.rnex/hooks/pre-commit" ] || { fail "pre-commit hook missing or not executable"; exit 1; }
[ -x "$TEST_HOOKS_WS/.rnex/hooks/pre-push" ] || { fail "pre-push hook missing or not executable"; exit 1; }

_hooks_path_val="$(git -C "$TEST_HOOKS_WS" config --get core.hooksPath)"
[ "$_hooks_path_val" = ".rnex/hooks" ] || { fail "core.hooksPath not set to .rnex/hooks (got: $_hooks_path_val)"; exit 1; }

# Verify hooks status command
_h_status="$(cd "$TEST_HOOKS_WS" && ./rnex hooks status 2>&1)"
echo "$_h_status" | grep -q "git_hooks: true" || { fail "hooks status did not report git_hooks: true"; exit 1; }
echo "$_h_status" | grep -q "core.hooksPath: .rnex/hooks" || { fail "hooks status did not report active core.hooksPath"; exit 1; }
echo "$_h_status" | grep -q "post-merge[ ]*(installed)" || { fail "hooks status did not report post-merge installed"; exit 1; }

# Verify status integration
_post_status="$(cd "$TEST_HOOKS_WS" && ./rnex status 2>&1)"
echo "$_post_status" | grep -q "Git Hooks:[ ]*active" || { fail "Status did not report active git hooks"; exit 1; }

# Test hooks run post-merge invokes fix quietly
(cd "$TEST_HOOKS_WS" && ./rnex hooks run post-merge >/dev/null)

# Uninstall hooks
(cd "$TEST_HOOKS_WS" && ./rnex hooks uninstall >/dev/null)
[ ! -d "$TEST_HOOKS_WS/.rnex/hooks" ] || { fail ".rnex/hooks still exists after uninstall"; exit 1; }
_uninstalled_hp="$(git -C "$TEST_HOOKS_WS" config --get core.hooksPath 2>/dev/null || true)"
[ -z "$_uninstalled_hp" ] || { fail "core.hooksPath still set after uninstall"; exit 1; }
grep -q "^git_hooks: false" "$TEST_HOOKS_WS/rnex.yaml" || { fail "hooks uninstall did not record git_hooks: false in rnex.yaml"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Init with git repo configures hooks automatically"
TEST_INIT_HOOKS="$TEST_TMP/init-hooks-ws"
mkdir -p "$TEST_INIT_HOOKS"
cp "$CLI" "$TEST_INIT_HOOKS/rnex"
chmod +x "$TEST_INIT_HOOKS/rnex"
cp -r "$DIR/toolkit" "$TEST_INIT_HOOKS/toolkit"
cp "$DIR/package.json" "$TEST_INIT_HOOKS/package.json"
git -C "$TEST_INIT_HOOKS" init -q

"$TEST_INIT_HOOKS/rnex" init -y "$TEST_INIT_HOOKS" >/dev/null
_init_hp="$(git -C "$TEST_INIT_HOOKS" config --get core.hooksPath 2>/dev/null || true)"
[ "$_init_hp" = ".rnex/hooks" ] || { fail "init -y did not configure Git hooks in git repo"; exit 1; }
[ -x "$TEST_INIT_HOOKS/.rnex/hooks/post-merge" ] || { fail "init -y did not create executable post-merge hook"; exit 1; }
grep -q "^git_hooks: true" "$TEST_INIT_HOOKS/rnex.yaml" || { fail "init -y did not record git_hooks: true in rnex.yaml"; exit 1; }
pass

# --------------------------------------------------------------------------
run_test "Two-level git_hooks configuration (--local) and fix reconciliation"
TEST_LOCAL_HOOKS="$TEST_TMP/local-hooks-ws"
mkdir -p "$TEST_LOCAL_HOOKS"
cp "$CLI" "$TEST_LOCAL_HOOKS/rnex"
chmod +x "$TEST_LOCAL_HOOKS/rnex"
cp -r "$DIR/toolkit" "$TEST_LOCAL_HOOKS/toolkit"
cp "$DIR/package.json" "$TEST_LOCAL_HOOKS/package.json"
git -C "$TEST_LOCAL_HOOKS" init -q

"$TEST_LOCAL_HOOKS/rnex" init -y "$TEST_LOCAL_HOOKS" >/dev/null
grep -q "^git_hooks: true" "$TEST_LOCAL_HOOKS/rnex.yaml" || { fail "Base config does not have git_hooks: true"; exit 1; }

# Disable hooks locally (--local)
(cd "$TEST_LOCAL_HOOKS" && ./rnex hooks uninstall --local >/dev/null)
[ -f "$TEST_LOCAL_HOOKS/.local.rnex.yaml" ] || { fail ".local.rnex.yaml was not created"; exit 1; }
grep -q "^git_hooks: false" "$TEST_LOCAL_HOOKS/.local.rnex.yaml" || { fail ".local.rnex.yaml missing git_hooks: false"; exit 1; }
grep -q "^git_hooks: true" "$TEST_LOCAL_HOOKS/rnex.yaml" || { fail "Base rnex.yaml was modified by --local"; exit 1; }
_loc_hp="$(git -C "$TEST_LOCAL_HOOKS" config --get core.hooksPath 2>/dev/null || true)"
[ -z "$_loc_hp" ] || { fail "core.hooksPath still set after hooks uninstall --local"; exit 1; }

# Simulate someone manually configuring core.hooksPath, then rnex fix should uninstall it based on local override
git -C "$TEST_LOCAL_HOOKS" config core.hooksPath .rnex/hooks
mkdir -p "$TEST_LOCAL_HOOKS/.rnex/hooks"
(cd "$TEST_LOCAL_HOOKS" && ./rnex fix --quiet >/dev/null)
_reconciled_hp="$(git -C "$TEST_LOCAL_HOOKS" config --get core.hooksPath 2>/dev/null || true)"
[ -z "$_reconciled_hp" ] || { fail "rnex fix did not uninstall hooks when overridden by .local.rnex.yaml git_hooks: false"; exit 1; }

# Re-enable hooks locally (--local)
(cd "$TEST_LOCAL_HOOKS" && ./rnex hooks install --local >/dev/null)
grep -q "^git_hooks: true" "$TEST_LOCAL_HOOKS/.local.rnex.yaml" || { fail ".local.rnex.yaml missing git_hooks: true"; exit 1; }
_loc_hp2="$(git -C "$TEST_LOCAL_HOOKS" config --get core.hooksPath 2>/dev/null || true)"
[ "$_loc_hp2" = ".rnex/hooks" ] || { fail "hooks install --local did not set core.hooksPath"; exit 1; }

# Simulate someone manually unsetting core.hooksPath, then rnex fix should reinstall it based on config
git -C "$TEST_LOCAL_HOOKS" config --unset core.hooksPath
(cd "$TEST_LOCAL_HOOKS" && ./rnex fix --quiet >/dev/null)
_reconciled_hp2="$(git -C "$TEST_LOCAL_HOOKS" config --get core.hooksPath 2>/dev/null || true)"
pass

# --------------------------------------------------------------------------
run_test "Git hooks: custom wrapper preservation, self-rewrite avoidance, and .githooks chaining"
TEST_WRAPPER_WS="$TEST_TMP/wrapper-hooks-ws"
mkdir -p "$TEST_WRAPPER_WS"
cp "$CLI" "$TEST_WRAPPER_WS/rnex"
chmod +x "$TEST_WRAPPER_WS/rnex"
cp -r "$DIR/toolkit" "$TEST_WRAPPER_WS/toolkit"
cp "$DIR/package.json" "$TEST_WRAPPER_WS/package.json"
git -C "$TEST_WRAPPER_WS" init -q

"$TEST_WRAPPER_WS/rnex" init -y "$TEST_WRAPPER_WS" >/dev/null

# 1. Custom wrapper in .rnex/hooks/post-commit must not be overwritten
cat <<'WRAPPER_EOF' > "$TEST_WRAPPER_WS/.rnex/hooks/post-commit"
#!/bin/sh
# Custom tested team wrapper (not managed by rnex)
echo "CUSTOM_WRAPPER_ACTIVE"
WRAPPER_EOF
chmod +x "$TEST_WRAPPER_WS/.rnex/hooks/post-commit"

# Run fix to ensure custom wrapper is preserved
(cd "$TEST_WRAPPER_WS" && ./rnex fix --quiet >/dev/null)
grep -q "CUSTOM_WRAPPER_ACTIVE" "$TEST_WRAPPER_WS/.rnex/hooks/post-commit" || { fail "rnex fix overwrote custom wrapper in .rnex/hooks/post-commit"; exit 1; }

# 2. Existing .githooks chaining
mkdir -p "$TEST_WRAPPER_WS/.githooks"
cat <<GITHOOKS_EOF > "$TEST_WRAPPER_WS/.githooks/pre-commit"
#!/bin/sh
echo "CHAINED_GITHOOKS_PRE_COMMIT" > "$TEST_WRAPPER_WS/githooks_marker"
GITHOOKS_EOF
chmod +x "$TEST_WRAPPER_WS/.githooks/pre-commit"

(cd "$TEST_WRAPPER_WS" && ./rnex hooks run pre-commit >/dev/null)
[ -f "$TEST_WRAPPER_WS/githooks_marker" ] || { fail "rnex hooks run pre-commit did not chain to .githooks/pre-commit"; exit 1; }
grep -q "CHAINED_GITHOOKS_PRE_COMMIT" "$TEST_WRAPPER_WS/githooks_marker" || { fail "Chained .githooks/pre-commit did not execute properly"; exit 1; }

# 3. Avoidance of self-rewrite during hooks run post-merge
# shellcheck disable=SC2012
_inode_before="$(ls -i "$TEST_WRAPPER_WS/.rnex/hooks/post-merge" | awk '{print $1}')"
(cd "$TEST_WRAPPER_WS" && ./rnex hooks run post-merge >/dev/null)
# shellcheck disable=SC2012
_inode_after="$(ls -i "$TEST_WRAPPER_WS/.rnex/hooks/post-merge" | awk '{print $1}')"
[ "$_inode_before" = "$_inode_after" ] || { fail "post-merge hook was rewritten/replaced during hook execution (self-rewrite bug)"; exit 1; }
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
