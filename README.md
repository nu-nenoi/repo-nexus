# Repo Nexus (`rnex`)

[![CI](https://github.com/nu-nenoi/repo-nexus/actions/workflows/ci.yml/badge.svg)](https://github.com/nu-nenoi/repo-nexus/actions/workflows/ci.yml)
[![npm version](https://img.shields.io/npm/v/repo-nexus.svg)](https://www.npmjs.com/package/repo-nexus)
[![License: MIT](https://img.shields.io/github/license/nu-nenoi/repo-nexus)](LICENSE)
[![POSIX Compatible](https://img.shields.io/badge/POSIX-compatible-success)](#)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)](#)

A tooling-independent, zero-dependency workspace orchestrator for multiple repositories with shared, auto-synced AI context across projects using Unix symlinks.

- **No git submodules, subtrees, or nested git friction**
- **No IDE lock-in** (works across VS Code, Cursor, Antigravity, Claude Code, Zed, terminal agents)
- **AI provider-agnostic** (shares `AGENTS.md`, Copilot instructions, Cursor rules, and custom prompts)
- **Automatic AI context injection** on repository registration
- **Auto-detects existing AI configs** (`CLAUDE.md`, `.cursorrules`, `.windsurfrules`, Copilot instructions, etc.)
- **Context-aware**: Finds and uses `rnex.yaml` automatically from your current directory or parent tree
- **Zero dependencies** (pure POSIX shell CLI)

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

1. **Symlink Write-Through**:
   Symlinks are transparent pointers. When an AI agent or developer edits `repos/backend/src/index.ts`, the OS resolves the link and writes directly to the source repository on disk.

2. **Autonomous Git Repositories**:
   Each member repository retains its own Git history, branches, and remotes. Git operations (commit, push, pull) are executed directly inside each member repo.

3. **Single Source of Truth for AI Context**:
   Edit `AGENTS.md` in Repo Nexus, and changes immediately reflect across all member repositories.

4. **Dynamic Workspace Scope**:
   Easily show or hide member repos from the active workspace without modifying disk contents.

---

## Installation

### Via npm (recommended)

```bash
npm install -g repo-nexus
```

This installs both `repo-nexus` and `rnex` commands globally.

### Manual

Clone the repo and add the `rnex` script to your PATH:

```bash
git clone https://github.com/nu-nenoi/repo-nexus.git
ln -s "$(pwd)/repo-nexus/rnex" ~/.local/bin/rnex
```

Or create a shell alias in `~/.zshrc` / `~/.bashrc`:
```bash
alias rnex="/path/to/repo-nexus/rnex"
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

## Workspace Configuration (`rnex.yaml`)

The configuration file defines repo symlink directory, AI context files to sync, and registered repositories:

```yaml
# Directory for repository symlinks (relative or absolute)
repos_dir: ./repos

# AI context files to automatically sync into every member repo
ai_files:
  - AGENTS.md
  - .github/copilot-instructions.md
  # - .cursorrules
  # - CLAUDE.md

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
| `rnex add <name> <path>` | Register repo, create scope symlink, and auto-inject AI context |
| `rnex remove <name>` | Unregister repo, unlink from scope, and clean up injected AI files |
| `rnex list` | List all registered repos and visibility scopes |
| `rnex status` | Display status of AI context files, active member repos, and paths |
| `rnex show <name>` | Make a hidden repo visible in workspace |
| `rnex hide <name>` | Hide a repo from active workspace indexing |
| `rnex sync` | Reconcile all scope symlinks and AI context files from config |

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
