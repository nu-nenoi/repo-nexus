# MetaWeave (`mw`) — Multi-Repo AI Workspace

A lightweight, tooling-independent system for orchestrating multiple repositories and sharing AI context using Unix symlinks.

- **No git submodules or subtrees**
- **No IDE-specific workspace lock-in** (works seamlessly across VS Code, Cursor, Zed, terminal agents, etc.)
- **AI provider-agnostic** (works with Copilot, Claude Code, Antigravity, local LLMs, and any tool reading standard markdown instructions)
- **Zero dependencies** (pure POSIX shell CLI)

---

## Architecture: The Two Symlink Flows

```
┌─────────────────────────────────────────────────────────────┐
│  1. SCOPE IN — Bring repos INTO the meta-workspace         │
│                                                             │
│  meta-repo/                                                 │
│    repos/                                                   │
│      project-a/  ──(symlink)──>  ~/code/project-a           │
│      project-b/  ──(symlink)──>  ~/code/project-b           │
│    AGENTS.md          (shared instructions)                 │
│    toolkit/           (shared prompts & templates)          │
│                                                             │
│  Agent/IDE opens meta-repo → sees all repos in single scope │
│  Edits via symlinks modify original repos directly ✓        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  2. INJECT OUT — Push AI context INTO standalone repos      │
│                                                             │
│  ~/code/project-a/                                          │
│    AGENTS.md     ──(symlink)──>  meta-repo/AGENTS.md        │
│    .github/copilot-instructions.md                          │
│                  ──(symlink)──>  meta-repo/.github/...      │
│    src/               (actual project code)                 │
│                                                             │
│  Open project-a standalone → AI tools automatically see     │
│  shared instructions as if they were local ✓                │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Characteristics & Findings

1. **Write-Through Guarantee**:
   In Unix systems, symlinks are transparent pointers. When an AI agent or developer edits a file inside `repos/my-app/src/index.ts`, the OS resolves the link and directly modifies the original file on disk.

2. **Isolated Version Control**:
   Each member repository remains a completely independent Git repo. Branching, staging, committing, and pushing occur in the respective target repo.

3. **Dynamic Scope (Hide / Show)**:
   Toggle any repo's visibility inside the meta-workspace instantly. Hiding a repo removes only the symlink under `repos/`, keeping the source codebase intact.

---

## Quick Start

### 1. Global Command Setup (Optional)
Run the script directly or install `mw` into your PATH:

```bash
# Option A: Run installer
./mw install

# Option B: Add shell alias to ~/.zshrc or ~/.bashrc
alias mw="/path/to/meta-repo/mw"
```

### 2. Basic Workflow

```bash
# Register an existing local repo
mw add backend ~/code/backend-api
mw add frontend ~/code/web-app

# List all registered repositories
mw list

# Inject shared AI instructions into a member repo
mw inject backend
mw inject frontend

# Check workspace health
mw status
```

---

## CLI Command Reference

| Command | Description |
|:---|:---|
| `mw add <name> <path>` | Register a local repository and create its scope symlink |
| `mw remove <name>` | Unregister a repository and clean up associated symlinks |
| `mw list` | Display all registered repos with their visibility and injection status |
| `mw status` | Inspect workspace health, active links, and broken paths |
| `mw show <name>` | Restore a hidden repo to the workspace scope (`repos/<name>`) |
| `mw hide <name>` | Temporarily remove a repo from the workspace scope |
| `mw inject <name>` | Create symlinks inside target repo pointing to shared AI configs |
| `mw eject <name>` | Remove injected symlinks from target repo |
| `mw inject-all` | Inject shared configs into all member repos |
| `mw eject-all` | Remove injected configs from all member repos |
| `mw sync` | Reconcile and rebuild all symlinks from `workspace.yaml` (idempotent) |

---

## Manifest Format (`workspace.yaml`)

All registered repositories are tracked in `workspace.yaml`:

```yaml
version: 1

repos:
  backend-api:
    path: /Users/admin/code/backend-api
    scope: visible
    inject: true
  web-app:
    path: /Users/admin/code/web-app
    scope: visible
    inject: true
  legacy-service:
    path: /Users/admin/code/legacy-service
    scope: hidden
    inject: false
```

---

## Repository Structure

```
meta-repo/
├── workspace.yaml                  # Repo registry & configuration
├── mw                              # CLI script (zero dependencies)
├── mw.sh                           # Shortcut symlink to mw
├── AGENTS.md                       # Universal AI coding guidelines
├── .github/
│   └── copilot-instructions.md     # GitHub Copilot rules
├── toolkit/                        # Shared prompts, scripts, templates
│   ├── prompts/
│   ├── scripts/
│   └── templates/
├── repos/                          # In-scope member repos (gitignored symlinks)
└── README.md
```

---

## Extending Injected Files

To inject additional AI configuration files across your repos (e.g. `.cursorrules`, `.claude/`), customize `INJECT_ITEMS` in `mw`:

```sh
INJECT_ITEMS="AGENTS.md:file
.github/copilot-instructions.md:file
.cursorrules:file"
```
Existing non-symlink files in member repositories are never overwritten.
