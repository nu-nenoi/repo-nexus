# Repo Nexus — TODO & Roadmap

A collection of planned features, improvements, and prompt templates for Repo Nexus.

## Multi-Repo Developer Experience
- [ ] **Multi-Repo Git Summary Helper** (`toolkit/scripts/git-summary.sh` or `rnex status --git`)
  - A lightweight read-only script that iterates over member clones in `repos/` and prints a 1-line branch and dirty status (`clean`, modified count, ahead/behind remote) without using Git submodules.
- [x] **VS Code / Cursor Multi-Root Workspace Integration** (`code_workspace` config option)
  - Configurable in `rnex.yaml` and `.local.rnex.yaml` (`code_workspace: true|false|<name>.code-workspace`). Automatically generates and maintains multi-root folders mapping the root workspace and active member repositories, preserving custom settings.

## AI Context & Prompt Engineering
- [ ] **Cross-Repo Task Prompt Template** (`toolkit/prompts/cross-repo-feature.md`)
  - A reusable prompt template guiding AI coding assistants through multi-repo changes (e.g. backend API contract changes paired with frontend client updates).
  - Outlines a structured workflow:
    1. Inspect types and schemas in the source repository.
    2. Implement corresponding caller/client updates in dependent repositories.
    3. Verify cross-service interface alignment before committing.
- [x] **Configurable AI Instructions File & Tool-Specific Bridges** (`ai_instructions` config option)
  - Configurable in `rnex.yaml` (`ai_instructions: AGENTS.md|CLAUDE.md|GEMINI.md`) with automatic status highlighting and reconciliation. Supports `--ai <file>` in `rnex init`.
