# Multi-Repo AI Workspace Context

This workspace operates as a **meta-repo** linking multiple independent repositories via symlinks.

## Rules for AI Coding Assistants

1. **Symlink Write-Through**: Files edited under `repos/<name>/` directly modify the target repository.
2. **Repo Boundaries**: Each repository is isolated. Do not introduce cross-repo imports unless explicitly architected.
3. **Shared Context**: This file governs AI assistant behavior across all member repositories. Keep instructions universal. Use local instructions for repo-specific rules.
4. **Member Repo RNEX Context**: Member repositories may contain an `.rnex/` directory (accessible via `repos/<name>/.rnex/`) containing repository-specific documents, instructions, rules, workflows, and scripts managed by Repo Nexus. AI assistants operating at the workspace level MUST inspect `repos/<name>/.rnex/` for member-specific context, guidelines, and commands.
5. **Git Operations**: Commit and push changes directly within the respective member repository root.
