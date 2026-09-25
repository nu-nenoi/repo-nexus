# Karpathy LLM Agent Guidelines & Behavioral Principles

> "The delicate art and science of context engineering: filling the context window with just the right information for the next step." — Andrej Karpathy

These guidelines provide standing operational instructions for AI coding assistants (Cursor, Claude Code, GitHub Copilot, Antigravity, Windsurf) working within multi-repository environments.

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

2. **Repository Autonomy:**
   - Member repositories are independent projects. Do not introduce cross-repository source imports or shared runtime dependencies unless an explicit monorepo architecture is configured.
   - Run git operations (commits, branches, pushes) within the respective member repository root.

3. **Context Economy:**
   - Do not redundantly read entire files or directory trees when targeted symbol lookups or line ranges suffice.
   - Rely on active workspace context, indexing, and compiled documentation rather than re-scanning raw files repeatedly.

---

## 3. The LLM Wiki Knowledge Pattern

To prevent architectural knowledge and multi-repo relationships from evaporating between conversation sessions:

* **Compile Knowledge into Markdown:** Document cross-repo dependencies, API contracts, and service boundaries in workspace documentation (see `docs/LLM_WIKI.sample.md`).
* **Treat the Wiki as Living Context:** When an architectural decision or schema change is made, update the corresponding markdown note in the workspace.
* **Query the Wiki First:** Before embarking on complex multi-repository refactors, inspect the workspace notes to understand existing contracts and constraints.
