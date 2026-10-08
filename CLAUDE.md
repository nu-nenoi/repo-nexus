<!-- REPO-NEXUS:START -->
# Multi-Repo AI Workspace Context

This workspace operates as a **Repo Nexus Virtual Meta-Repo** uniting independent repositories.

## Mandatory Session Startup

Before answering the first task or making any task-specific tool call in a new session:

1. Read `.local.rnex.yaml` when present, then `rnex.yaml`.
2. Inspect instructions for every enabled Repo Nexus plugin under `.rnex/plugins/<plugin-name>/`.
3. If `wiki/` is present: read `wiki/hot.md` and `wiki/index.md` to orient on architecture and domain concepts.
4. Follow links from the index to wiki pages relevant to the request.
5. Only then inspect member repositories (`repos/<name>/`) or produce an answer.

This is a hard gate, not optional orientation. Complete it once per session and retain the resulting context; do not repeatedly reload these files.

## Prompts & Workflows
For task-specific agent workflows (cross-repo features, workspace audits, wiki maintenance), inspect `.rnex/prompts/index.md`.

## Member Repositories (`repos/<name>/`)
Each member repository is an autonomous Git repository. For repository-specific instructions, inspect `repos/<name>/.rnex/`.

## Git Operations
Commit and push changes directly within the respective member repository root (`repos/<name>/`).
<!-- REPO-NEXUS:END -->
