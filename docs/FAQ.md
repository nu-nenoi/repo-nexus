# Frequently Asked Questions (FAQ)

This document answers common questions about **Repo Nexus (`rnex`)**, why it exists, who it helps, how it handles Git and AI context, and how to use it effectively.

---

## Table of Contents

- [General Setup & Philosophy](#general-setup--philosophy)
  - [What is repo-nexus?](#what-is-repo-nexus)
  - [How does it differ from "monster" monorepo orchestrators?](#how-does-it-differ-from-monster-monorepo-orchestrators)
  - [Does it require Git Submodules?](#does-it-require-git-submodules)
  - [Why do I need rnex?](#why-do-i-need-rnex)
  - [Who is this useful and interesting for?](#who-is-this-useful-and-interesting-for)
  - [Why not just use a monorepo or Git submodules?](#why-not-just-use-a-monorepo-or-git-submodules)
- [Architecture & Mechanics](#architecture--mechanics)
  - [How does rnex work without copying files?](#how-does-rnex-work-without-copying-files)
  - [What is "Scope In" vs. "Inject Out"?](#what-is-scope-in-vs-inject-out)
  - [Can I use Git commands (pull, push, commit) on symlinked repos?](#can-i-use-git-commands-pull-push-commit-on-symlinked-repos)
  - [Can AI agents create and modify files inside member repos via symlinks?](#can-ai-agents-create-and-modify-files-inside-member-repos-via-symlinks)
  - [Will rnex interfere with Git branches, remotes, or commit histories?](#will-rnex-interfere-with-git-branches-remotes-or-commit-histories)
- [AI Context & IDE Workspace Integration](#ai-context--ide-workspace-integration)
  - [How does it optimize workspaces for IDEs?](#how-does-it-optimize-workspaces-for-ides)
  - [How does it support accurate AI context?](#how-does-it-support-accurate-ai-context)
  - [What is the risk of tool lock-in?](#what-is-the-risk-of-tool-lock-in)
  - [Do I need rnex to inject symlinks into my member repos?](#do-i-need-rnex-to-inject-symlinks-into-my-member-repos)
  - [How should AI instructions be structured across repos? (Committed files vs. symlinks)](#how-should-ai-instructions-be-structured-across-repos-committed-files-vs-symlinks)
  - [What happens if a member repository already has an existing AI configuration file?](#what-happens-if-a-member-repository-already-has-an-existing-ai-configuration-file)
  - [Which AI assistants and configuration files are supported?](#which-ai-assistants-and-configuration-files-are-supported)
  - [How do I prevent AI agents from running out of context or token bloat?](#how-do-i-prevent-ai-agents-from-running-out-of-context-or-token-bloat)
- [Platforms & Setup](#platforms--setup)
  - [What are the system requirements? Does it work on Windows?](#what-are-the-system-requirements-does-it-work-on-windows)
  - [Does rnex have external dependencies?](#does-rnex-have-external-dependencies)
  - [What files in a workspace should be committed to Git?](#what-files-in-a-workspace-should-be-committed-to-git)
  - [How do I fix broken or missing symlinks?](#how-do-i-fix-broken-or-missing-symlinks)

---

## General Setup & Philosophy

### What is repo-nexus?

It is a zero-dependency workspace utility designed to treat multiple independent Git repositories as subprojects under a single, unified development workspace.

---

### How does it differ from "monster" monorepo orchestrators?

Unlike heavy, invasive tools that take over your entire terminal workflow, execute automated pipelines, or bundle massive dependency trees, repo-nexus acts strictly as a lightweight, metadata-only layout manager. It does not inject wrapper scripts or run automated build pipelines.

---

### Does it require Git Submodules?

No. It manages the directory mappings internally via configuration files. Your independent Git repositories remain clean, isolated, and completely untouched at the Git history level.

---

### Why do I need rnex?

Modern AI coding assistants (like Cursor, Claude Code, GitHub Copilot, and Antigravity) are designed around a single project root. In real-world software development, applications are rarely confined to a single repository—they are split into frontend apps, backend APIs, shared libraries, infrastructure, and documentation.

This creates two major frictions:
1. **Siloed Context**: To perform cross-service tasks (e.g. updating an API endpoint and consuming it in the web frontend), you must juggle multiple IDE windows or repeatedly explain code structures between projects.
2. **Instruction Drift**: As you tune your AI coding guidelines (like coding style, testing requirements, or forbidden patterns), keeping these instructions synced across 5, 10, or 20 separate repositories requires tedious manual updates.

**`rnex` solves both problems**:
- It unites independent repositories under one virtual workspace using Unix symlinks.
- It provides a single source of truth for shared AI context files (`AGENTS.md`, Copilot instructions, Cursor rules) without requiring monorepo migrations.

---

### Who is this useful and interesting for?

- **Polyrepo & Microservice Developers**: Engineers whose day-to-day work spans multiple microservices or separated frontends and backends, and who want an AI assistant that can navigate across repository boundaries seamlessly.
- **Tech Leads & Platform Teams**: Engineering leaders who want to standardize AI instructions and architectural constraints across team repositories without forcing developers into a monorepo.
- **Solo Developers & Indie Hackers**: Creators juggling a collection of related projects (e.g., mobile app + backend API + landing page + SDK) who want rapid cross-project AI capabilities.
- **AI Agent Power Users**: Developers using multi-repo autonomous agents (such as Claude Code, Aider, or Antigravity) that require unified file tree visibility.

---

### Why not just use a monorepo or Git submodules?

| Solution | Drawbacks | How `rnex` compares |
| :--- | :--- | :--- |
| **Git Monorepo** | Heavy migration effort, combined CI/CD pipelines, complex permission management, slow Git checkouts. | **Zero migration**: Repositories remain completely independent with their own remotes, histories, and deployment pipelines. |
| **Git Submodules** | Detached HEAD states, tricky merge conflicts, complex multi-step commits, rigid parent-child coupling. | **No Git friction**: Member repositories are linked via filesystem symlinks. Git never tracks other repos as submodules. |
| **Manual Copy-Paste** | AI configuration files rapidly drift out of sync across repositories. | **Auto-synced**: Edit `AGENTS.md` once in the workspace; changes immediately reflect across all member repositories. |

---

## Architecture & Mechanics

### How does rnex work without copying files?

`rnex` uses native **Unix symbolic links (symlinks)**. Symlinks act as transparent pointers at the filesystem level. Rather than duplicating files or creating complex mount points, your operating system, Git, and IDE resolve the symlinks directly to the original directories on disk.

---

### What is "Scope In" vs. "Inject Out"?

`rnex` offers two complementary symlink flows:

1. **Scope In (Repos into Workspace)**:
   When you run `rnex add <name> <path>`, a symlink is created at `repos/<name>` pointing to the source project directory. Opening the workspace directory in your editor gives you (and your AI assistant) full access to all linked repositories in a single file tree.
2. **Inject Out (AI Context into Member Repos)**:
   Shared configuration files defined in `rnex.yaml` (such as `AGENTS.md`) can be symlinked from the workspace into the root of every member repository. Opening a repository standalone allows standalone IDE windows to discover the shared rules as local files.

---

### Can I use Git commands (pull, push, commit) on symlinked repos?

**Yes.** Git works completely normally.
* **Operating inside `repos/<name>/`**: When you or your IDE navigate into `repos/<name>/` and run `git status`, `git commit`, `git pull`, or `git push`, Git follows the symlink, discovers the real `.git` directory, and operates directly against that repository's own branches and remotes.
* **Operating in the source directory**: Any changes made from the workspace are immediately present in the source repo on disk. You can run all Git operations in the original folder as usual.

---

### Can AI agents create and modify files inside member repos via symlinks?

**Yes.** Any file an AI agent creates or edits under `repos/<name>/...` (e.g. `repos/backend/src/service.ts`) is written **directly through the symlink into the underlying repository on disk**.
- These are genuine application files, not symlinks.
- They are immediately detected by Git in that member repo.
- You or the agent can commit and push them directly to that repository.

---

### Will rnex interfere with Git branches, remotes, or commit histories?

**No.** Each member repository retains its own Git history, remotes, and branch topology.
The Repo Nexus workspace ignores `repos/` in `.gitignore`, ensuring your workspace Git repository never accidentally tracks or commits member repository contents.

---

## AI Context & IDE Workspace Integration

### How does it optimize workspaces for IDEs?

By defining your multi-repo structure through repo-nexus, it bridges the gap across decoupled project folders to generate seamless multi-root workspaces for modern code editors.

---

### How does it support accurate AI context?

It serves as an informational metadata layer across repositories. It allows you to synchronize and propagate AI rule parameters, prompt setups, and documentation frameworks (like `.cursorrules`, `AGENTS.md`, or `CLAUDE.md`) globally so that coding assistants see the entire multi-repo architecture as one coherent context.

---

### What is the risk of tool lock-in?

Zero. Because repo-nexus only overlays structural configuration metadata rather than refactoring your code, removing it from your stack is as simple as deleting its single config file. Your codebases remain independent and functional.

---

### Do I need rnex to inject symlinks into my member repos?

**Not necessarily.** If your primary workflow is opening the Nexus workspace root (or relying on global workstation AI configs), you do **not** need `rnex` to inject symlinks into member repos.

Running in **Zero-Touch Mode** (`ai_files: []` in `rnex.yaml`):
- Keeps member repositories 100% pristine.
- Prevents temporary symlinks or `.gitignore` modifications inside member repos.
- The AI agent will read `AGENTS.md` directly from the workspace root and apply it across all linked projects.

"Inject Out" is only needed if you frequently open individual member repositories standalone in an editor without opening the Nexus workspace, yet still want that standalone window to pick up shared rules.

---

### How should AI instructions be structured across repos? (Committed files vs. symlinks)

The cleanest architecture separates concerns into two distinct layers:

1. **Workspace Level (Nexus Root)**:
   Contains multi-repo context, cross-service orchestrations, and workspace-wide rules in `AGENTS.md`.
2. **Member Repo Level (Committed Files)**:
   Individual repositories can maintain their own domain-specific AI instructions (e.g., repository `.cursorrules`, `CLAUDE.md`, or component conventions) as **real, first-class files committed to Git**.

**Why real committed files are better than injected symlinks for member repos**:
- **Shared with the Team**: Anyone on the team who clones the repo immediately gets the rules without needing `rnex` or symlinks.
- **No Path Fragility**: Symlinks pointing back to an external workspace break if cloned on another computer or Windows. Committed files never break.
- **Repository Autonomy**: Each project remains self-documenting and independent.

---

### What happens if a member repository already has an existing AI configuration file?

`rnex` will **never replace or overwrite** existing AI files in a member repository.

When you run `rnex add <name> <path>`, `rnex` detects any pre-existing AI context files (such as `AGENTS.md` or `.cursorrules`) and prompts you whether to update them. If confirmed, `rnex` **extends** the existing file by appending the workspace context enclosed within clearly demarcated markers (`# --- REPO-NEXUS AI CONTEXT ---`).

This preserves all repository-specific rules while layering universal workspace guidelines on top. Subsequent `rnex sync` calls keep the extended block synchronized without duplicating content or modifying the repository's custom instructions. Pass `-y` / `--yes` to `rnex add` to auto-confirm updating existing files.

---

### Which AI assistants and configuration files are supported?

`rnex` is tool-agnostic and auto-detects or syncs standard configuration files for:

- **Universal Agents**: `AGENTS.md`
- **Claude Code**: `CLAUDE.md`
- **Cursor**: `.cursorrules`, `.cursor/rules/`
- **Windsurf / Codeium**: `.windsurfrules`, `.windsurf/rules/`
- **GitHub Copilot**: `.github/copilot-instructions.md`
- **Aider**: `.aider.conf.yml`, `CONVENTIONS.md`
- **Cline / Roo Code**: `.clinerules`
- **Codex**: `CODEX.md`
- **Continue.dev**: `.continue/`
- **Skills Standards**: `SKILL.md`

You can add any custom file or prompt template to the `ai_files` list in `rnex.yaml`.

---

### How do I prevent AI agents from running out of context or token bloat?

When managing many repositories, exposing all of them at once can fill your AI model's context window or increase prompt latency.

`rnex` provides scope toggles:
- **`rnex hide <name>`**: Temporarily removes the symlink from `repos/`, hiding the repo from active AI indexing without unregistering it.
- **`rnex show <name>`**: Restores the symlink to active workspace scope when you need to work on it again.
- **`rnex list`**: Displays which repos are currently `visible` or `hidden`.

---

## Platforms & Setup

### What are the system requirements? Does it work on Windows?

- **Supported Platforms**: macOS and Linux.
- **Windows**: Not officially supported natively due to Windows symlink permission restrictions (requiring Developer Mode or elevated privileges) and POSIX shell requirements. However, `rnex` runs smoothly inside **WSL2 (Windows Subsystem for Linux)**.

---

### Does rnex have external dependencies?

**No.** The `rnex` executable is written in pure POSIX shell script (`/bin/sh`) with zero runtime dependencies. It does not require Node.js, Python, or external package managers to function.

For convenience, `rnex` is also published as an npm package (`npm install -g repo-nexus`) so JavaScript/TypeScript developers can install it globally via standard tooling.

---

### What files in a workspace should be committed to Git?

In your Repo Nexus workspace repository:
- **Commit**: `rnex.yaml`, `AGENTS.md`, documentation (`docs/`), toolkit prompts/templates, and CI configs.
- **Do NOT Commit**: `repos/` (this directory should always be in `.gitignore`, as it only contains local symlinks to your projects).

---

### How do I fix broken or missing symlinks?

If you move a repository, clone a workspace on a new machine, or notice missing symlinks, run:

```bash
rnex sync
```

This command reconciles all symlinks for member repositories and AI context files defined in `rnex.yaml`, repairing broken links and ensuring your workspace is healthy. To inspect the current status, run:

```bash
rnex status
```
