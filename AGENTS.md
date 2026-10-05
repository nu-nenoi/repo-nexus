<!-- REPO-NEXUS:START -->
# Multi-Repo AI Workspace Context

This workspace operates as a **Repo Nexus Virtual Meta-Repo** uniting independent repositories.

## Rules for AI Coding Assistants

1. **Read Configuration First (Mandatory)**: AI coding assistants MUST inspect and read `.local.rnex.yaml` (if present) and `rnex.yaml` before planning or executing tasks to understand the workspace structure (`repos_dir`), registered member repositories, and active plugins.
   - **Highest Priority**: `.local.rnex.yaml` takes highest priority over `rnex.yaml`.
   - **Default State**: Repositories are enabled by default unless explicitly set to `enabled: false`. Disabled repositories must be excluded from active tasks.
2. **Repository Boundaries**: Member repositories reside under `repos/<name>/` as independent Git repositories. Edits directly modify files in the respective repository. Do not introduce cross-repo imports unless architected.
3. **Plugin Instructions & Rules Routing**: Detailed guidelines and workflows for enabled plugins are strictly scoped. AI assistants MUST read instructions for each enabled plugin from its separate directory under:
   `.rnex/plugins/<plugin-name>/`
4. **Member Repo RNEX Context Routing**: AI assistants operating at the workspace level MUST inspect `repos/<name>/.rnex/` for member-specific instructions, guidelines, and commands.
5. **Git Operations**: Commit and push changes directly within the respective member repository root (`repos/<name>/`).
<!-- REPO-NEXUS:END -->
