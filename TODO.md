# Repo Nexus — TODO & Roadmap

A collection of planned features, improvements, and prompt templates for Repo Nexus.

## Multi-Repo Developer Experience
- [ ] **Multi-Repo Git Summary Helper** (`toolkit/scripts/git-summary.sh` or `rnex status --git`)
  - A lightweight read-only script that iterates over member clones in `repos/` and prints a 1-line branch and dirty status (`clean`, modified count, ahead/behind remote) without using Git submodules.
- [x] **VS Code / Cursor Multi-Root Workspace Integration** (`code_workspace` config option)
  - Configurable in `rnex.yaml` and `.local.rnex.yaml` (`code_workspace: true|false|<name>.code-workspace`). Automatically generates and maintains multi-root folders mapping the root workspace and active member repositories, preserving custom settings.

## AI Context & Prompt Engineering
- [x] **Cross-Repo Task Prompt Template & Workflows** (`toolkit/prompts/rnex-cross-repo-feature.md` & `index.md`)
  - Standardized prompts catalog synced to `.rnex/prompts/` and referenced cleanly in `AGENTS.md` / `CLAUDE.md`.
  - Includes `rnex-cross-repo-feature.md`, `rnex-workspace-audit.md`, `rnex-wiki-ingest.md`, and `rnex-wiki-lint.md`.
- [x] **Mandatory Session Startup Protocol**
  - Hard gate in workspace AI instructions enforcing reading of config, plugins, and Karpathy LLM Wiki (`wiki/hot.md` & `wiki/index.md`) before taking actions.
- [x] **Configurable AI Instructions File & Tool-Specific Bridges** (`ai_instructions` config option)
  - Configurable in `rnex.yaml` (`ai_instructions: AGENTS.md|CLAUDE.md|GEMINI.md`) with automatic status highlighting and reconciliation. Supports `--ai <file>` in `rnex init`.

## Workspace Lifecycle & Automation
- [x] **Version-Aware Upgrade Command** (`rnex update` / `rnex upgrade` and `rnex fix -y`)
  - Safely detects schema version changes across CLI releases and prompts to non-destructively upgrade configuration and instructions.
- [x] **Config-Driven Automated Git Hooks** (`rnex hooks install|uninstall|status`)
  - Workspace hooks (`.rnex/hooks/post-merge`, `post-commit`, `pre-commit`, `pre-push`) driven dynamically by `rnex.yaml` (`lint_trigger`). Prompted during `rnex init` and integrated into `rnex status`.
