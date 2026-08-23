# Repo Nexus (`rnex`)

[![CI](https://img.shields.io/badge/CI-Passing-brightgreen?logo=github-actions)](https://github.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![POSIX Compatible](https://img.shields.io/badge/POSIX-compatible-success)](#)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-validated-brightgreen)](#)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)](#)

A tooling-independent, zero-dependency workspace orchestrator for multiple repositories with shared, auto-synced AI context across projects using Unix symlinks.

- **No git submodules, subtrees, or nested git friction**
- **No IDE lock-in** (works across VS Code, Cursor, Antigravity, Claude Code, Zed, terminal agents)
- **AI provider-agnostic** (shares `AGENTS.md`, Copilot instructions, Cursor rules, and custom prompts)
- **Automatic AI context injection** on repository registration
- **Context-aware**: Finds and uses `workspace.yaml` automatically from your current directory or parent tree
- **Zero dependencies** (pure POSIX shell CLI)

---

## How It Works: The Two Symlink Flows

```
┌─────────────────────────────────────────────────────────────┐
│  1. SCOPE IN — Bring member repos INTO Repo Nexus           │
│                                                             │
│  repo-nexus/                                                │
│    repos/                                                   │
│      backend/   ──(symlink)──>  ~/code/backend-api          │
│      frontend/  ──(symlink)──>  ~/code/web-app              │
│    AGENTS.md         (universal AI instructions)            │
│    workspace.yaml    (manifest: AI files + repos)           │
│                                                             │
│  Agent opens repo-nexus → sees all repos in one workspace.  │
│  Edits through symlinks modify the original files directly. │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  2. INJECT OUT — Auto-sync AI context INTO member repos     │
│                                                             │
│  ~/code/backend-api/                                        │
│    AGENTS.md     ──(symlink)──>  repo-nexus/AGENTS.md       │
│    .github/copilot-instructions.md                          │
│                  ──(symlink)──>  repo-nexus/.github/...     │
│    src/              (real codebase)                        │
│                                                             │
│  Open backend-api standalone → AI tools automatically see   │
│  shared instructions as if they were local files.           │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Principles

1. **Symlink Write-Through**:
   Symlinks are transparent pointers. When an AI agent or developer edits `repos/backend/src/index.ts`, the OS resolves the link and writes directly to the source repository on disk.

2. **Autonomous Git Repositories**:
   Each member repository retains its own Git history, branches, and remotes. Git operations (commit, push, pull) are executed directly inside each member repo.

3. **Single Source of Truth for AI Context**:
   Edit `AGENTS.md` or `.github/copilot-instructions.md` in Repo Nexus, and changes immediately reflect across all member repositories.

4. **Dynamic Workspace Scope**:
   Easily show or hide member repos from the active workspace without modifying disk contents.

---

## Installation & Setup

### 1. Global Installation
Install the `rnex` command into your PATH:

```bash
./rnex install
```
*(Default destination: `~/.local/bin/rnex`)*

Or create an alias in your shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
alias rnex="/path/to/repo-nexus/rnex"
```

### 2. Initializing a Workspace
Initialize a new Repo Nexus workspace in any directory:

```bash
mkdir my-workspace && cd my-workspace
rnex init
```

When you invoke `rnex` from any directory inside your workspace, it automatically detects `workspace.yaml` and displays a confirmation note:
```
[i] Using workspace at /path/to/my-workspace (workspace.yaml found)
```

---

## Everyday Usage

```bash
# 1. Register a repository (links into scope & auto-injects AI context)
rnex add backend ~/code/backend-api
rnex add frontend ~/code/web-app

# 2. Inspect workspace status & linked AI files
rnex status

# 3. List all registered repositories
rnex list

# 4. Temporarily hide a repo from active indexing/agent scope
rnex hide backend

# 5. Restore a hidden repo back to active scope
rnex show backend

# 6. Reconcile/repair all symlinks across all repos (idempotent)
rnex sync

# 7. Unregister a repository (removes scope link & cleans up injected AI files)
rnex remove backend
```

---

## Workspace Manifest (`workspace.yaml`)

The manifest defines which AI context files get synced and which member repositories are registered:

```yaml
# List of AI context files to automatically sync into every member repo
ai_files:
  - AGENTS.md
  - .github/copilot-instructions.md
  # Add more files/directories as needed:
  # - .cursorrules
  # - toolkit/prompts/review-guidelines.md

# Member repositories managed by Repo Nexus
repos:
  backend:
    path: /Users/admin/code/backend-api
    scope: visible
  frontend:
    path: /Users/admin/code/web-app
    scope: visible
  analytics:
    path: /Users/admin/code/analytics-service
    scope: hidden
```

---

## CLI Command Reference

### Global Options
| Option | Description |
|:---|:---|
| `-c, --config <file>` | Explicit path to `workspace.yaml` (executes in that workspace directory) |
| `-h, --help` | Display command help and usage instructions |

### Commands
| Command | Description |
|:---|:---|
| `rnex init [dir]` | Initialize a new Repo Nexus workspace in current (or target) directory |
| `rnex install` | Install the `rnex` CLI command globally into `~/.local/bin` |
| `rnex add <name> <path>` | Register repo, create scope symlink, and auto-inject AI context |
| `rnex remove <name>` | Unregister repo, unlink from scope, and clean up injected AI files |
| `rnex list` | List all registered repos and visibility scopes |
| `rnex status` | Display status of AI context files, active member repos, and paths |
| `rnex show <name>` | Make a hidden repo visible in workspace (`repos/<name>`) |
| `rnex hide <name>` | Hide a repo from active workspace indexing |
| `rnex sync` | Reconcile all scope symlinks and AI context files from `workspace.yaml` |

---

## Operating on External Workspaces via `--config`

You can run `rnex` commands targeting any workspace without changing directories by providing `-c` or `--config`:

```bash
# Inspect status of a workspace stored elsewhere
rnex -c /path/to/my-workspace/workspace.yaml status

# Add a repository to an external workspace directly
rnex --config /path/to/my-workspace/workspace.yaml add api-service ~/code/api-service
```
Any command executed with an explicit config file operates directly within the directory where that configuration file is stored.

---

## Workspace Directory Structure

```
repo-nexus/
├── workspace.yaml                  # Manifest (AI files + repository registry)
├── rnex                            # Core CLI executable
├── AGENTS.md                       # Universal AI coding guidelines
├── .github/
│   ├── copilot-instructions.md     # GitHub Copilot custom instructions
│   ├── workflows/ci.yml            # Automated GitHub Actions CI workflow
│   └── ISSUE_TEMPLATE/             # Bug report and feature request templates
├── tests/
│   └── test_cli.sh                 # Automated CLI test suite
├── toolkit/                        # Shared prompts, scripts, templates
├── repos/                          # Active member repos (gitignored symlinks)
├── LICENSE                         # MIT License
└── README.md
```

---

## Running Tests

Run the automated test suite locally:

```bash
./tests/test_cli.sh
```
