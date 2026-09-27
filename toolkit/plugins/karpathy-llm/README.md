# Karpathy LLM Plugin for Repo Nexus

The **`karpathy-llm`** plugin packages Andrej Karpathy's agent behavioral principles, multi-repo context engineering standards, and the autonomous **Karpathy LLM Wiki** knowledge architecture for AI coding assistants (Cursor, Claude Code, GitHub Copilot, Antigravity, Windsurf).

No external vector databases, embedding pipelines, or MCP servers required — just markdown files with structured YAML frontmatter navigated natively by AI agents.

---

## What It Provides

### 1. The 4 Cardinal Principles for Coding Agents (`rules/KARPATHY_RULES.md`)
* **Think Before Coding:** Explicit assumptions, problem formulation, and trade-off evaluation before writing code.
* **Simplicity First:** Minimal abstractions, readable implementations, and zero boilerplate bloat.
* **Surgical Changes:** Minimal blast radius, preserved comments/docstrings, and tightly focused diffs.
* **Goal-Driven Execution:** Upfront verification criteria, automated tests, and rigorous diff review.

### 2. Multi-Repo Context Engineering & Autonomy
* Guidelines tailored for Repo Nexus workspaces respecting member repository autonomy and symlink write-through semantics.

### 3. Complete Karpathy LLM Wiki Architecture
* **`/raw/` Intake Directory:** Append-only directory where unmodified source material (articles, transcripts, docs, meeting notes) is deposited.
* **`/wiki/` Curated Knowledge Base:** Interlinked atomic markdown pages, each with typed frontmatter relations (`sources`, `related`, `extends`, `contradicts`, `mentioned_in`).
* **`/wiki/index.md` Control & Navigation Index:** Master categorized catalog containing `lint_trigger: enabled|disabled` to control autonomous maintenance.
* **`/wiki/hot.md` Rolling Context Cache:** High-density ~500-word orientation summary for rapid agent onboarding without full wiki scans.
* **`/wiki/_log.md` Audit Trail:** Append-only log recording every ingest and lint operation.

### 4. Autonomous Lint Trigger Script (`scripts/wiki-lint-trigger.sh`)
* A lightweight POSIX script checking `lint_trigger: enabled` and a session counter (`wiki/.lint_trigger_counter`).
* Alerts agents with `[WIKI MAINTENANCE DUE]` on session 1 and every 15 sessions.

### 5. Standardized Agent Workflows (`workflows/`)
* **`wiki-ingest.md`:** Step-by-step instructions to decompose raw source documents into 5–25 atomic wiki pages with frontmatter relations.
* **`wiki-lint.md`:** Integrity audit protocol to validate paths, recompute `mentioned_in`, eliminate orphans, merge duplicates, and highlight knowledge gaps.

---

## Directory Layout Scaffolding

When enabled, the plugin scaffolds:

```text
my-workspace/
├── raw/
│   └── .gitkeep                     # Intake for unmodified source documents
├── wiki/
│   ├── index.md                     # Master catalog + lint_trigger toggle
│   ├── hot.md                       # Rolling ~500-word quick-orient context
│   └── _log.md                      # Ingestion & lint audit history
├── scripts/
│   └── wiki-lint-trigger.sh         # Executable session counter & lint alert
├── .agents/rules/
│   └── KARPATHY_RULES.md            # Cardinal principles & wiki rules (auto-symlinked)
├── .agent/workflows/
│   ├── wiki-ingest.md               # Decomposition & ingestion workflow
│   └── wiki-lint.md                 # Graph validation & maintenance workflow
└── docs/
    └── wiki-page.template.md        # Atomic page template with typed relations
```

---

## Enabling in Repo Nexus

### Option 1: Via CLI (Recommended)

```bash
rnex plugin enable karpathy-llm
```

This command:
1. Adds `karpathy-llm` to `rnex.yaml`.
2. Initializes `/raw/`, `/wiki/`, `scripts/wiki-lint-trigger.sh`, and workflows if they don't already exist.
3. Symlinks `KARPATHY_RULES.md` and workflows into `.agents/rules/` and all registered member repositories via `rnex sync`.

### Option 2: Declarative in `rnex.yaml`

Add `karpathy-llm` to `plugins:` in `rnex.yaml`:

```yaml
plugins:
  - karpathy-llm
```

Then synchronize:

```bash
rnex sync
```

---

## Everyday Operation & Cadence

1. **Intake:** Drop research papers, meeting notes, or PRDs into `/raw/`.
2. **Ingest:** Instruct your AI assistant: *"Run wiki-ingest on raw/filename.md"*.
3. **Session Cadence:** After sessions where repository files were edited, run `scripts/wiki-lint-trigger.sh`.
4. **Maintenance:** If prompted by `[WIKI MAINTENANCE DUE]`, instruct the assistant: *"Run wiki-lint"*.
5. **Toggle Automation:** Edit `lint_trigger: enabled` or `lint_trigger: disabled` in `/wiki/index.md` anytime.

---

## Disabling

```bash
rnex plugin disable karpathy-llm
```

Safely unlinks plugin assets from member repositories and removes the entry from `rnex.yaml`. Your curated `/wiki/` and `/raw/` data remain completely untouched on disk.
