# Multi-Repo AI Workspace Context

This workspace operates as a **meta-repo** linking multiple independent repositories via symlinks.

## Rules for AI Coding Assistants

1. **Symlink Write-Through**: Files edited under `repos/<name>/` directly modify the target repository.
2. **Repo Boundaries**: Each repository is isolated. Do not introduce cross-repo imports unless explicitly architected.
3. **Shared Context**: This file is symlinked across member repositories. Keep instructions universal. Use local instructions for repo-specific rules.
4. **Git Operations**: Commit and push changes directly within the respective member repository root.
