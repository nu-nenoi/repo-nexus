# Multi-Repo AI Workspace Context

This workspace operates as a **Repo Nexus** linking multiple independent repositories via symlinks.

## Rules for AI Coding Assistants

1. **Workspace Structure & Settings**: AI coding assistants MUST inspect and read `rnex.yaml` at the workspace root to understand the workspace structure (such as `repos_dir`), registered member repositories, and active configuration settings.
2. **Symlink Write-Through**: Files edited under `repos/<name>/` directly modify the target repository.
3. **Repo Boundaries**: Each repository is isolated. Do not introduce cross-repo imports unless explicitly architected.
4. **Shared Context**: This file governs AI assistant behavior across all member repositories. Keep instructions universal. Use local instructions for repo-specific rules.
5. **Member Repo RNEX Context**: Member repositories may contain an `.rnex/` directory (accessible via `repos/<name>/.rnex/`) containing repository-specific documents, instructions, rules, workflows, and scripts managed by Repo Nexus. AI assistants operating at the workspace level MUST inspect `repos/<name>/.rnex/` for member-specific context, guidelines, and commands.
6. **Plugin Instructions**: If plugins are enabled in `rnex.yaml` (under `plugins:`), AI coding assistants MUST read instructions for each enabled plugin from its separate instruction files (located in `.rnex/instructions/` or `.rnex/rules/`).
7. **Git Operations**: Commit and push changes directly within the respective member repository root.
