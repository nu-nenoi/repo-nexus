# Repo Nexus (`rn` / `rnx`) — Multi-Repo AI Workspace

A tooling-independent system for orchestrating multiple repositories and sharing AI context across projects using Unix symlinks.

- **No git submodules, subtrees, or nested git friction**
- **No IDE lock-in** (works across VS Code, Cursor, Antigravity, Claude Code, Zed, terminal agents)
- **AI provider-agnostic** (shares `AGENTS.md`, Copilot instructions, and any custom prompts/rules)
- **Automatic AI context injection** on repository registration
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
   Edit `AGENTS.md` or `.github/copilot-instructions.md` in Repo Nexus, and the changes immediately reflect across all member repositories.

4. **Dynamic Workspace Scope**:
   Easily show or hide member repos from the active workspace without modifying disk contents.

---

## Quick Start

### 1. Interactive Setup Wizard
Run the interactive installer to set up the CLI command and configure your workspace:

```bash
./rn install
```

The wizard will:
1. Symlink `rn` and `rnx` to your chosen PATH folder (e.g. `~/.local/bin` or `/usr/local/bin`).
2. Read your `workspace.yaml` configuration.
3. Prompt to register existing repositories.
4. Synchronize all scope links and AI context files.

*(Alternative: Add `alias rn="/path/to/repo-nexus/rn"` to your `~/.zshrc`)*

---

### 2. Everyday Usage

```bash
# 1. Register a repository (links into scope & auto-injects AI context)
rn add backend ~/code/backend-api
rn add frontend ~/code/web-app

# 2. Inspect workspace status & linked AI files
rn status

# 3. List all registered repositories
rn list

# 4. Temporarily hide a repo from active indexing/agent scope
rn hide backend

# 5. Restore a hidden repo back to active scope
rn show backend

# 6. Reconcile/repair all symlinks across all repos (idempotent)
rn sync

# 7. Unregister a repository (removes scope link & cleans up injected AI files)
rn remove backend
```

---

## Workspace Manifest (`workspace.yaml`)

The manifest defines which AI context files get synced and which member repositories are registered:

```yaml
version: 1

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

| Command | Description |
|:---|:---|
| `rn install` | Run interactive setup wizard (installs CLI and synchronizes workspace) |
| `rn add <name> <path>` | Register repo, create scope symlink, and auto-inject AI context |
| `rn remove <name>` | Unregister repo, unlink from scope, and clean up injected AI files |
| `rn list` | List all registered repos and visibility scopes |
| `rn status` | Display status of AI context files, active member repos, and paths |
| `rn show <name>` | Make a hidden repo visible in workspace (`repos/<name>`) |
| `rn hide <name>` | Hide a repo from active workspace indexing |
| `rn sync` | Reconcile all scope symlinks and AI context files from `workspace.yaml` |

---

## Workspace Directory Structure

```
repo-nexus/
├── workspace.yaml                  # Manifest (AI files + repository registry)
├── rn                              # Core CLI executable
├── rnx                             # Shortcut alias to rn
├── AGENTS.md                       # Universal AI coding guidelines
├── .github/
│   └── copilot-instructions.md     # GitHub Copilot custom instructions
├── toolkit/                        # Shared prompts, scripts, templates
│   ├── prompts/
│   ├── scripts/
│   └── templates/
├── repos/                          # Active member repos (gitignored symlinks)
└── README.md
```
