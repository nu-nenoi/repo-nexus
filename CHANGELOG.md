# Changelog

All notable changes to Repo Nexus (`rnex`) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
