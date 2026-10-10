# Changelog

All notable changes to Repo Nexus (`rnex`) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **AI Provider Plugins for Claude, Gemini, Cursor, and Windsurf**:
  - Built-in provider plugins (`toolkit/plugins/claude/`, `toolkit/plugins/gemini/`, `toolkit/plugins/cursor/`, `toolkit/plugins/windsurf/`) alongside `copilot`.
  - Native instructions synthesis and sync for each provider: `CLAUDE.md`, `GEMINI.md`, `.cursorrules` (and `.cursor/rules/repo-nexus.mdc`), and `.windsurfrules`.
  - Standardized prompt mirroring to `.claude/commands/`, `.gemini/prompts/`, `.cursor/prompts/`, and `.windsurf/prompts/`.
  - Skill mirroring to `.claude/skills/`, `.gemini/skills/`, `.cursor/skills/`, and `.windsurf/skills/`.
  - Granular configuration options per plugin (`instructions: true|false`, `prompts: true|false`, `skills: true|false`).
  - Added `--claude`, `--gemini`, `--cursor`, and `--windsurf` initialization flags to `rnex init`.
  - Diagnostics and configurable provider options displayed in `rnex status`.
- **Unified Single-Process Workspace Reconcile & Upgrade (`rnex fix`)**:
  - Merged configuration version updates directly into `rnex fix` as a single, idempotent process.
  - Automatically migrates older workspace manifests to the current CLI version on `rnex fix` without requiring separate update commands.
  - `rnex update` and `rnex upgrade` are maintained as clean aliases pointing directly to `rnex fix`.
- **Explicit `git_hooks` Workspace Configuration (`rnex.yaml` & `.local.rnex.yaml`)**:
  - Top-level `git_hooks: true|false` setting establishes the workspace configuration as the single source of truth for automated Git hooks.
  - Two-level configuration support allowing per-workstation overrides in `.local.rnex.yaml` (e.g. keeping hooks globally enabled in `rnex.yaml` while disabling locally via `rnex hooks uninstall --local`).
  - `rnex hooks install [--local]` and `rnex hooks uninstall [--local]` record preference directly to `rnex.yaml` or `.local.rnex.yaml`.
  - `rnex fix` (and `rnex sync`) automatically reconciles Git's `core.hooksPath` against the resolved `git_hooks` configuration.
  - Interactive `rnex init` determines and records `git_hooks` preference upfront in new workspaces.
  - Workspace schema migration in `rnex update` and `rnex fix -y` non-destructively inserts `git_hooks` into older configurations.
  - `rnex status` and `rnex hooks status` display configuration state alongside runtime Git hooks status.
- **Modular GitHub Copilot Plugin & Extensible Provider Sync (`plugins: copilot: ...`)**:
  - Encapsulated GitHub Copilot integration as a built-in Repo Nexus plugin (`copilot`) located in `toolkit/plugins/copilot/`.
  - Extensible configuration options per provider under `plugins:` in `rnex.yaml` and `.local.rnex.yaml`:
    - `prompts: true|false`: Syncs operational prompts into `.github/prompts/*.prompt.md` with YAML frontmatter for VS Code Copilot Chat prompt picker & slash commands.
    - `skills: true|false`: Syncs agent skills into `.github/skills/<name>/SKILL.md` for Copilot Agent mode & `gh skill`.
    - `instructions: true|false`: Synthesizes workspace routing and active plugin guidelines into `.github/copilot-instructions.md`, preserving manual user instructions outside `<!-- REPO-NEXUS -->` markers.
    - `agents: true|false`: Syncs active plugin custom agents into `.github/agents/*.agent.md` and Copilot skills.
    - `enabled: false`: Allows local machine overrides in `.local.rnex.yaml` without altering team configuration.
  - Decoupled cross-plugin asset discovery: `copilot` provider inspects all active plugins (e.g. `karpathy-llm`) and mirrors their prompts, workflows, skills, agents, and guidelines without introducing plugin dependencies.
  - CLI management via `rnex plugin enable [--local] copilot`, `rnex plugin disable [--local] copilot`, and `rnex plugin info copilot`.
  - Added `--copilot` initialization flag to `rnex init` enabling the plugin in newly generated workspaces.
  - Clean reconciliation in `rnex fix`: safely removes `.github/prompts/`, `.github/skills/`, `.github/agents/`, and `.github/copilot-instructions.md` when disabled or when specific target options are toggled off.
  - Diagnostics and configurable options reporting integrated into `rnex status`.

### Changed
- **Removed `ai_instructions` Configuration in Favor of AI Provider Plugins**:
  - Removed the legacy `ai_instructions` configuration key. `AGENTS.md` is now the workspace standard.
  - Users choosing provider-specific files (`CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`) enable the respective AI provider plugin (`claude`, `gemini`, `cursor`, `windsurf`).
  - When an AI provider plugin is enabled, `rnex fix` does not enforce or force-recreate `AGENTS.md`. If all provider plugins are disabled, `AGENTS.md` is cleanly restored as the fallback default.
  - Older configurations specifying `ai_instructions: CLAUDE.md | GEMINI.md | .cursorrules` are automatically migrated to enable the respective plugin and stripped of the legacy key during `rnex fix`.

### Fixed
- **Variable Shadowing and Directory Creation in Hook / Init Synchronization**:
  - Fixed variable name shadowing (`_target_dir`) across `cmd_init` and provider sync routines in POSIX shell.
  - Ensured target directories are created before moving temporary hook files in `_create_hook_script`.

### Fixed
- **Git Hooks Self-Rewrite & Wrapper Preservation**:
  - Resolved self-rewrite bug where `rnex hooks run post-merge` invoked `cmd_fix`, which truncated and replaced `.rnex/hooks/post-merge` while the shell interpreter was actively executing it.
  - Added in-hook execution guard (`_RNEX_INSIDE_HOOK=1`) preventing hook script regeneration during active hook dispatch.
  - Preserved custom / repository-owned wrappers in `.rnex/hooks/` that are not auto-managed by `rnex`.
  - Added `cmp -s` check before writing hook files to eliminate unnecessary file churn and in-place overwrites.
  - Automatically chain to existing repository-owned `.githooks/` scripts if present.
- **Track Workspace `.rnex/` in Version Control**:
  - Removed `.rnex/` from `.gitignore` templates and generation.
  - `reconcile_gitignore` and `rnex fix` actively strip legacy `.rnex/` ignore rules from `.gitignore` so that team prompts (`.rnex/prompts/`), plugins (`.rnex/plugins/`), and hooks (`.rnex/hooks/`) are tracked in git.
  - Updated `rnex status` to expect `.rnex/` to remain tracked by git.

## [0.5.1] - 2026-10-08

### Added
- Comprehensive CLI Reference Manual (`docs/CLI.md`) documenting all workspace lifecycle commands, member repository operations, automated Git hooks, scoped plugins, standardized prompts catalog, and shell completion recipes.

### Fixed
- Dynamic version matching in test suite (`tests/test_cli.sh`, Test 26) resolving hardcoded version assertion on `package.json` bumps.
- Default version fallback in `rnex` CLI aligned with `package.json`.

## [0.5.0] - 2026-10-08

### Added
- **Version-Aware Upgrade System (`rnex update` / `rnex upgrade` and `rnex fix`)**:
  - Automatically compares workspace configuration against the running CLI version using semantic versioning.
  - Interactive upgrade prompt (`[y/N]`, bypassable with `-y` or `--yes`).
  - Non-destructively inserts missing schema keys (`version`, `ai_instructions`, `code_workspace`) while preserving comments and repo mappings.
  - Updates routing instructions in `AGENTS.md`, `CLAUDE.md`, and other detected AI assistant instruction files.
- **Config-Driven Automated Git Hooks (`rnex hooks`)**:
  - Native Git hooks managed under `.rnex/hooks/` via `git config core.hooksPath .rnex/hooks`.
  - Dynamic dispatchers for `post-merge`, `post-commit`, `pre-commit`, and `pre-push` that evaluate workspace triggers defined in `rnex.yaml` and `.local.rnex.yaml`.
  - Automated `post-merge` hook runs `rnex fix -y --quiet` to keep member clones and plugin scopes in sync after pulling team changes.
  - Subcommands: `rnex hooks install`, `rnex hooks uninstall`, and `rnex hooks status`.
  - Interactive hooks setup prompt during `rnex init` (controllable via `--hooks` and `--no-hooks` flags).
  - Health check integrated into `rnex status` reporting active hooks and triggers.
- **Standardized Prompts Suite & Master Catalog (`toolkit/prompts/`)**:
  - Master index catalog at `toolkit/prompts/index.md` (synced to `.rnex/prompts/index.md`).
  - New workflow prompts:
    - `rnex-cross-repo-feature.md`: Multi-repository feature planning and contract implementation.
    - `rnex-workspace-audit.md`: Multi-repo status, branch tracking, and configuration validation.
    - `rnex-wiki-ingest.md`: Autonomous intake decomposition into atomic Karpathy LLM Wiki pages.
    - `rnex-wiki-lint.md`: Graph integrity validation, backlink recalculation, and index rebuilding.
    - `rnex-setup-karpathy-wiki.md`: Deterministic knowledge base scaffolding.
  - Workspace `AGENTS.md` and `CLAUDE.md` maintain a minimal 1-line pointer to `.rnex/prompts/index.md` to conserve agent context.
- **Mandatory Session Startup Protocol**:
  - Enforced hard-gate instruction block in `AGENTS.md` and `CLAUDE.md` requiring AI coding assistants to inspect configuration (`.local.rnex.yaml`, `rnex.yaml`), plugin guidelines, and orientation notes (`wiki/hot.md` and `wiki/index.md`) before taking task actions.

## [0.4.7] - 2026-10-06

### Fixed
- Quoted variable expansion in parameter pattern removal (`_repos_rel="${REPOS_DIR#"$NEXUS_DIR"/}"`) resolving ShellCheck SC2295.

## [0.4.6] - 2026-10-06

### Added
- **Configurable AI Instructions Routing** (`ai_instructions` in `rnex.yaml`):
  - Support custom instruction files (e.g. `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, defaulting to `AGENTS.md`).
  - `rnex status` detects and highlights missing instruction files.
  - `rnex init` supports `--ai <file>` flag.
- **VS Code & Cursor Multi-Root Workspace Support** (`code_workspace` in `rnex.yaml`):
  - Automatically generates and synchronizes `.code-workspace` files mapping the workspace root and active member repositories.
  - `rnex init` supports `--code-workspace [file]` flag.

## [0.4.5] - 2026-10-06

### Fixed
- Guaranteed deterministic workspace initialization by tracking `repos/.gitkeep`.
- Prevented empty member directory creation during init.

## [0.4.4] - 2026-10-06

### Documentation
- Standardized deterministic Karpathy LLM Wiki initialization in `toolkit/plugins/karpathy-llm/`.

## [0.4.3] - 2026-10-05

### Refactored
- Separated behavioral rules (`rules/behavioral.md`) from architectural specifications (`instructions/wiki-architecture.md`) in `karpathy-llm` plugin.

## [0.4.2] - 2026-10-05

### Fixed
- Updated automated CLI test suite to dynamically inspect version from `package.json`.

## [0.4.1] - 2026-10-05

### Added
- Streamlined delimited routing protocol in `AGENTS.md` (`<!-- REPO-NEXUS:START -->` / `<!-- REPO-NEXUS:END -->`).
- Automated `.gitignore` reconciliation stripping legacy counters and ensuring `.rnex/` encapsulation.
- Purged legacy symlink mechanics in favor of physical autonomy.

## [0.4.0] - 2026-10-05

### Added
- **Virtual Meta-Repo 2.0**:
  - Physical member repository clones in `./repos/<name>` with complete Git isolation (no submodules).
  - Two-level configuration (`rnex.yaml` team manifest and `.local.rnex.yaml` machine overrides).
  - Cross-repository batch execution (`rnex exec <command...>`).
  - Member repository state management (`rnex enable`, `rnex disable`, `rnex list`, `rnex remove`).
  - Scoped workspace plugins (`.rnex/plugins/<plugin-name>/`).
