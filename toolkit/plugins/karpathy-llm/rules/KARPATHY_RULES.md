# Karpathy LLM Agent Guidelines & Behavioral Principles

> "The delicate art and science of context engineering: filling the context window with just the right information for the next step." — Andrej Karpathy

These guidelines provide standing operational instructions for AI coding assistants (Cursor, Claude Code, GitHub Copilot, Antigravity, Windsurf) working within multi-repository environments and managing Karpathy LLM Wiki knowledge bases.

---

## 1. The Four Cardinal Principles

### Principle 1: Think Before Coding
* **State Assumptions Explicitly:** Before implementing any non-trivial change, state your understanding of the problem, assumptions made, and proposed solution.
* **Surface Trade-Offs:** If multiple approaches exist, outline the alternatives with their trade-offs before generating code.
* **Verify Repository Boundaries:** In multi-repo workspaces, determine which member repositories are affected. Never make silent architectural assumptions that span across repo boundaries.

### Principle 2: Simplicity First
* **Favor Readable Over Clever:** Write the simplest code that solves the immediate problem. Avoid unnecessary abstractions, speculative generics, and premature optimizations.
* **Zero Boilerplate Bloat:** Do not introduce extra wrapper layers, helper classes, or framework-heavy patterns unless explicitly requested or required by existing codebase conventions.
* **Less Code is Better Code:** If an existing utility, POSIX primitive, or library function does the job, reuse it.

### Principle 3: Surgical Changes
* **Minimal Blast Radius:** Touch *only* the lines and files required to achieve the goal.
* **Preserve Documentation & Comments:** Never delete or overwrite existing comments, documentation, or code structure unrelated to your changes.
* **Zero Unintended Reformatting:** Avoid running blanket code formatters across entire files that create massive, unreadable git diffs. Keep diffs tight, focused, and reviewable.

### Principle 4: Goal-Driven Execution & Verification
* **Define Success Criteria Upfront:** Know how you will prove that your change works before you write the first line of code.
* **Verify with Automated Checks:** Run linters, unit tests, and build commands before declaring a task complete.
* **Inspect the Diff:** Review your own git diff before committing or presenting the solution to ensure no extraneous changes were introduced.

---

## 2. Multi-Repo Context Engineering

In a Repo Nexus workspace, independent repositories are unified into a single active scope via Unix symlinks. Coding agents must follow these rules:

1. **Symlink Write-Through:**
   - Edits made to `repos/<name>/` write directly through to the underlying member repository on disk.
   - Do not attempt to move or replace symlinks with regular directories.

2. **Repository Autonomy & Member .rnex Directory:**
   - Member repositories are independent projects. Do not introduce cross-repository source imports or shared runtime dependencies unless an explicit monorepo architecture is configured.
   - Member repositories may contain an `.rnex/` directory (e.g. `repos/<name>/.rnex/`) containing repository-specific documents, instructions, rules, workflows, and scripts. Coding assistants must inspect this directory for member-specific instructions.
   - Run git operations (commits, branches, pushes) within the respective member repository root.

3. **Context Economy:**
   - Do not redundantly read entire files or directory trees when targeted symbol lookups or line ranges suffice.
   - Rely on active workspace context, indexing, and compiled documentation rather than re-scanning raw files repeatedly.

---

## 3. Karpathy Wiki Rules

When working in a repository with an active Karpathy LLM Wiki (`/wiki/` and `/raw/` directories):

- **Intake**: All source material (articles, transcripts, docs, notes) goes to `/raw/` unmodified. Never write directly to `/wiki/` without ingesting.
- **Orientation**: Before answering domain questions, read `/wiki/index.md` to find relevant pages, then read only those pages. If `hot.md` exists, read it first as a quick-orient step.
- **Ingestion**: When files appear in `/raw/`, run the `wiki-ingest` workflow (`.rnex/workflows/wiki-ingest.md`). One source document typically produces many atomic pages (commonly 5–25 pages) — do not collapse a source into a single file.
- **Maintenance**: Run the `wiki-lint` workflow (`.rnex/workflows/wiki-lint.md`) to validate paths, update `mentioned_in`, and preserve graph integrity.

---

## 4. Typed Frontmatter Relation Schema

Every page in `/wiki/` must maintain typed frontmatter relations:

```yaml
---
title: ""
tags: []
last_updated: YYYY-MM-DD
# Typed relation fields — paths relative to /wiki/
sources: []          # /raw/ files this page was derived from
related: []          # thematically related wiki pages
extends: []          # pages this one builds upon or specialises
contradicts: []      # pages with conflicting information
mentioned_in: []     # pages that link to this one (maintained by lint)
---
```

**Body:** concise summary, key facts or insights, and inline standard Markdown links (`[Label](./path.md)`) where contextually useful in prose.

The relation graph lives in frontmatter, not in prose links. Agents traverse the graph by reading frontmatter fields, not by scanning body text.
