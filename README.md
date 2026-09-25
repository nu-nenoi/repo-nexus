# Repo Nexus (`rnex`)

[![CI](https://github.com/nu-nenoi/repo-nexus/actions/workflows/ci.yml/badge.svg)](https://github.com/nu-nenoi/repo-nexus/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/repo-nexus.svg)](https://www.npmjs.com/package/repo-nexus)
[![License: MIT](https://img.shields.io/github/license/nu-nenoi/repo-nexus)](LICENSE)
[![POSIX Compatible](https://img.shields.io/badge/POSIX-compatible-success)](#)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)](#)
[![FAQ](https://img.shields.io/badge/docs-FAQ-blue.svg)](docs/FAQ.md)

A **simple, lightweight companion tool** for multi-repo workflows. It links multiple independent repositories and shares universal AI instructions (like `AGENTS.md`) using standard Unix symlinks — **without Git submodules, monorepo migrations, or complex setup**.

- **No Git Submodules or Nested Git Friction**: Keep your repositories completely independent. No detached HEADs, no `.gitmodules`, and no merge conflicts between repos.
- **A Lean Companion, Not a Workspace Replacer**: It does not replace your editor, terminal, build tools, or package manager. It is a tiny (~20 KB) helper that seamlessly complements your existing workflow.
- **Unified Workspace for AI Coding Assistants**: Open one folder to give Cursor, Claude Code, GitHub Copilot, or Antigravity complete cross-repo visibility.
- **Single Source of Truth for AI Guidelines**: Share and sync `AGENTS.md`, Copilot instructions (`.github/copilot-instructions.md`), Cursor rules (`.cursorrules`), Claude instructions (`CLAUDE.md`), and custom prompts across all projects.
- **Zero Dependencies**: Pure POSIX shell CLI (`rnex`). Works out of the box with zero external runtimes required.
A **simple, lightweight companion tool** for multi-repo workflows. It links multiple independent repositories and shares universal AI instructions (like `AGENTS.md`) using standard Unix symlinks — **without Git submodules, monorepo migrations, or complex setup**.

- **No Git Submodules or Nested Git Friction**: Keep your repositories completely independent. No detached HEADs, no `.gitmodules`, and no merge conflicts between repos.
- **A Lean Companion, Not a Workspace Replacer**: It does not replace your editor, terminal, build tools, or package manager. It is a tiny (~20 KB) helper that seamlessly complements your existing workflow.
- **Unified Workspace for AI Coding Assistants**: Open one folder to give Cursor, Claude Code, GitHub Copilot, or Antigravity complete cross-repo visibility.
- **Single Source of Truth for AI Guidelines**: Share and sync `AGENTS.md`, Copilot instructions (`.github/copilot-instructions.md`), Cursor rules (`.cursorrules`), Claude instructions (`CLAUDE.md`), and custom prompts across all projects.
- **Zero Dependencies**: Pure POSIX shell CLI (`rnex`). Works out of the box with zero external runtimes required.

> 💡 **Have questions?** Check out the **[Frequently Asked Questions (FAQ)](docs/FAQ.md)** for architecture deep dives, Git workflows, and AI context strategies.

---

## What Repo Nexus Is (and What It Isn't)

| What It Is | What It Isn't |
| :--- | :--- |
| **A lightweight companion utility** (~20 KB POSIX script). | **NOT a replacement for your workspace or tools.** It doesn't replace VS Code, Cursor, JetBrains, or your terminal. |
| **A simple symlink manager** that groups existing repos into one folder for convenience. | **NOT a build tool or monorepo orchestrator.** It doesn't manage builds or replace tools like Nx, Turborepo, Cargo, or Gradle. |
| **Zero Git friction.** Repositories remain normal, autonomous Git repos. | **NOT Git submodules or subtrees.** No `.gitmodules` files, no detached HEADs, no commit coordination lock-in. |
| **Non-invasive.** If you delete the workspace, your repos remain completely untouched. | **NOT a proprietary platform.** No background daemons, no database, no vendor lock-in. |

---

## What Repo Nexus Is (and What It Isn't)

| What It Is | What It Isn't |
| :--- | :--- |
| **A lightweight companion utility** (~20 KB POSIX script). | **NOT a replacement for your workspace or tools.** It doesn't replace VS Code, Cursor, JetBrains, or your terminal. |
| **A simple symlink manager** that groups existing repos into one folder for convenience. | **NOT a build tool or monorepo orchestrator.** It doesn't manage builds or replace tools like Nx, Turborepo, Cargo, or Gradle. |
| **Zero Git friction.** Repositories remain normal, autonomous Git repos. | **NOT Git submodules or subtrees.** No `.gitmodules` files, no detached HEADs, no commit coordination lock-in. |
| **Non-invasive.** If you delete the workspace, your repos remain completely untouched. | **NOT a proprietary platform.** No background daemons, no database, no vendor lock-in. |

---

## How It Works: The Two Symlink Flows

```
┌─────────────────────────────────────────────────────────────┐
│  1. SCOPE IN — Bring member repos INTO Repo Nexus           │
│                                                             │
│  my-workspace/                                              │
│    repos/                                                   │
│      backend/   ──(symlink)──>  ~/code/backend-api          │
│      frontend/  ──(symlink)──>  ~/code/web-app              │
│    AGENTS.md         (universal AI instructions)            │
│    rnex.yaml         (manifest: AI files + repos)           │
│                                                             │
│  Agent opens workspace → sees all repos in one place.       │
│  Edits through symlinks modify the original files directly. │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  2. INJECT OUT — Auto-sync AI context INTO member repos     │
│                                                             │
│  ~/code/backend-api/                                        │
│    AGENTS.md     ──(symlink)──>  my-workspace/AGENTS.md     │
│    src/              (real codebase)                        │
│                                                             │
│  Open backend-api standalone → AI tools automatically see   │
│  shared instructions as if they were local files.           │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Principles

1. **No Git Submodules (Complete Repository Autonomy)**:
   Member repositories are never converted into Git submodules or subtrees. Each repository keeps its own standalone Git history, remotes, branches, and commits. `rnex` simply links them on your local filesystem.
1. **No Git Submodules (Complete Repository Autonomy)**:
   Member repositories are never converted into Git submodules or subtrees. Each repository keeps its own standalone Git history, remotes, branches, and commits. `rnex` simply links them on your local filesystem.

2. **Symlink Write-Through**:
   Symlinks are transparent pointers resolved by your OS. When you or an AI agent edit `repos/backend/src/index.ts`, the OS resolves the link and writes directly to the source repository on disk.
2. **Symlink Write-Through**:
   Symlinks are transparent pointers resolved by your OS. When you or an AI agent edit `repos/backend/src/index.ts`, the OS resolves the link and writes directly to the source repository on disk.

3. **Single Source of Truth for AI Context**:
   Edit `AGENTS.md` once in Repo Nexus, and changes immediately reflect across all member repositories.
   Edit `AGENTS.md` once in Repo Nexus, and changes immediately reflect across all member repositories.

4. **Dynamic Workspace Scope**:
   Easily show or hide member repos from the active workspace without modifying disk contents.

---

## Installation

Install `rnex` via npm, GitHub Packages, or the zero-dependency native installer:

### Option 1: Via npm (Recommended)

```bash
npm install -g repo-nexus
```
*(Installs both `repo-nexus` and `rnex` commands globally, or run via `npx repo-nexus init`)*

### Option 2: Via GitHub Packages

```bash
npm install -g @nu-nenoi/repo-nexus --registry=https://npm.pkg.github.com
```
Install `rnex` via npm, GitHub Packages, or the zero-dependency native installer:

### Option 1: Via npm (Recommended)

```bash
npm install -g repo-nexus
```
*(Installs both `repo-nexus` and `rnex` commands globally, or run via `npx repo-nexus init`)*

### Option 2: Via GitHub Packages

```bash
npm install -g @nu-nenoi/repo-nexus --registry=https://npm.pkg.github.com
```

### Option 3: Native Installer (Zero Dependencies)
### Option 3: Native Installer (Zero Dependencies)

Clone the repository and run the built-in installer:

```bash
git clone https://github.com/nu-nenoi/repo-nexus.git
cd repo-nexus
./rnex install
```
*(Installs `rnex` and `repo-nexus` symlinks into `~/.local/bin`, or pass a custom directory like `./rnex install /usr/local/bin`)*

### Option 4: Shell Alias
### Option 4: Shell Alias

Add to your `~/.zshrc` or `~/.bashrc`:
```bash
alias rnex="/path/to/repo-nexus/rnex"
alias repo-nexus="/path/to/repo-nexus/rnex"
```

---

## Quick Start

```bash
# 1. Initialize a new workspace
mkdir my-workspace && cd my-workspace
rnex init

# 2. Register repositories
rnex add backend ~/code/backend-api
rnex add frontend ../web-app          # relative paths work too

# 3. Check workspace health
rnex status
```

During `rnex init`, the CLI automatically scans for existing AI configuration files (like `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`) and adds them to your config.

---

## Everyday Usage

```bash
# Register a repository (links into scope & auto-injects AI context)
rnex add my-app ~/code/my-app

# Inspect workspace status & linked AI files
rnex status

# List all registered repositories
rnex list

# Temporarily hide a repo from active indexing/agent scope
rnex hide my-app

# Restore a hidden repo back to active scope
rnex show my-app

# Reconcile/repair all symlinks across all repos (idempotent)
rnex sync

# Unregister a repository (removes scope link & cleans up injected AI files)
rnex remove my-app
```

---

## Plugins & AI Context Packs

Repo Nexus features a zero-dependency plugin architecture. Plugins package curated AI instructions, agent behavioral rules, and architecture templates that are automatically synchronized into member repositories via symlinks.

```bash
# List available and active plugins
rnex plugin list

# Inspect plugin details and provided files
rnex plugin info karpathy-llm

# Enable a plugin across your workspace
rnex plugin enable karpathy-llm

# Disable a plugin and clean up injected files
rnex plugin disable karpathy-llm
```

### Built-in Plugin: `karpathy-llm`
The `karpathy-llm` plugin packages Andrej Karpathy's verified LLM agent design patterns and context engineering principles:
* **The 4 Cardinal Agent Rules** (`.agents/rules/KARPATHY_RULES.md`):
  1. *Think Before Coding:* Formulate explicit assumptions, boundary checks, and trade-offs before writing code.
  2. *Simplicity First:* Minimal abstractions, readable implementations, zero speculative boilerplate.
  3. *Surgical Changes:* Minimal blast radius, preserved comments/docstrings, and tight diffs.
  4. *Goal-Driven Execution:* Upfront verification criteria, automated tests, and diff inspection.
* **Multi-Repo Context Engineering:** Guidelines for AI agents respecting member repo autonomy and symlink write-through semantics.
* **LLM Wiki Knowledge Pattern** (`docs/LLM_WIKI.sample.md`): Persistent, indexed multi-repo architecture documentation that compounds across agent sessions.

---

## Workspace Configuration (`rnex.yaml`)

The configuration file defines repo symlink directory, AI context files to sync, enabled plugins, and registered repositories:

```yaml
# Directory for repository symlinks (relative or absolute)
repos_dir: ./repos

# AI context files to automatically sync into every member repo
ai_files:
  - AGENTS.md
  - .github/copilot-instructions.md
  # - .cursorrules
  # - CLAUDE.md

# Workspace plugins
plugins:
  - karpathy-llm

# Member repositories
repos:
  backend:
    path: /Users/dev/code/backend-api
    scope: visible
  frontend:
    path: ../web-app
    scope: visible
  analytics:
    path: /Users/dev/code/analytics
    scope: hidden
```

> See [`docs/rnex.example.yaml`](docs/rnex.example.yaml) for a comprehensive example with all options and supported AI tool configs.
> For common questions and architecture details, see the [Frequently Asked Questions (FAQ)](docs/FAQ.md).

---

## CLI Command Reference

### Global Options
| Option | Description |
|:---|:---|
| `-c, --config <file>` | Explicit path to `rnex.yaml` (executes in that workspace directory) |
| `-h, --help` | Display command help and usage instructions |
| `-v, --version` | Display version |

### Commands
| Command | Description |
|:---|:---|
| `rnex init [dir]` | Initialize a new workspace in current (or target) directory |
| `rnex install [dir]` | Install `rnex` & `repo-nexus` globally into `~/.local/bin` (or custom dir) |
| `rnex add [-y] <name> <path>` | Register repo, create scope symlink, and sync AI context (prompts to extend existing files) |
| `rnex remove <name>` | Unregister repo, unlink from scope, and clean up injected AI files |
| `rnex list` | List all registered repos and visibility scopes |
| `rnex status` | Display status of AI context files, active member repos, and paths |
| `rnex show <name>` | Make a hidden repo visible in workspace |
| `rnex hide <name>` | Hide a repo from active workspace indexing |
| `rnex sync` | Reconcile all scope symlinks and AI context files from config |

> **Note on Existing AI Files**: Pre-existing files in member repositories are never overwritten. When adding a new repo, `rnex` prompts whether to update existing files and safely extends them with workspace context between managed markers. Pass `-y` / `--yes` to auto-confirm.

---

## Operating on External Workspaces via `--config`

Run `rnex` commands targeting any workspace without changing directories:

```bash
# Inspect status of a workspace stored elsewhere
rnex -c /path/to/my-workspace/rnex.yaml status

# Add a repository to an external workspace
rnex --config /path/to/my-workspace/rnex.yaml add api-service ~/code/api
```

Any command executed with an explicit config file operates within the directory where that config lives.

---

## Supported AI Configuration Files

`rnex init` auto-detects these files and includes them in your workspace config:

| File / Directory | AI Tool |
|:---|:---|
| `AGENTS.md` | Universal AI agent instructions |
| `CLAUDE.md` | Claude Code |
| `.cursorrules` | Cursor |
| `.cursor/rules/` | Cursor (directory) |
| `.windsurfrules` | Windsurf / Codeium |
| `.windsurf/rules/` | Windsurf (directory) |
| `.github/copilot-instructions.md` | GitHub Copilot |
| `.aider.conf.yml` | Aider |
| `CONVENTIONS.md` | Coding conventions |
| `.clinerules` | Cline / Roo Code |
| `CODEX.md` | Codex |
| `.continue/` | Continue.dev |
| `SKILL.md` | Skills (emerging standard) |

---

## Project Structure

```
repo-nexus/
├── rnex.yaml                       # Workspace configuration
├── rnex                            # CLI executable (POSIX shell)
├── AGENTS.md                       # Universal AI coding guidelines
├── docs/
│   ├── AGENTS.sample.md            # Template for AGENTS.md
│   ├── FAQ.md                      # Frequently Asked Questions
│   └── rnex.example.yaml           # Full config reference with examples
├── .github/
│   ├── workflows/ci.yml            # GitHub Actions CI workflow
│   └── ISSUE_TEMPLATE/             # Bug report and feature request templates
├── tests/
│   └── test_cli.sh                 # Automated CLI test suite (11 tests)
├── toolkit/                        # Shared prompts, scripts, templates
├── package.json                    # npm package manifest
├── LICENSE                         # MIT License
└── README.md
```

---

## Running Tests

```bash
./tests/test_cli.sh
```

---

## License

[MIT](LICENSE)
