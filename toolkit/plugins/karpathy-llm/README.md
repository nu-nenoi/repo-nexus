# Karpathy LLM Plugin for Repo Nexus

The **`karpathy-llm`** plugin packages Andrej Karpathy's agent behavioral principles, multi-repo context engineering standards, and the autonomous **Karpathy LLM Wiki** knowledge architecture for AI coding assistants (Cursor, Claude Code, GitHub Copilot, Antigravity, Windsurf).

No external vector databases, embedding pipelines, or MCP servers required — just interlinked markdown files with structured YAML frontmatter traversed natively by AI agents.

Reference specification: [setup-karpathy-wiki.md](https://github.com/nu-nenoi/ai-toolkit/blob/main/prompts/setup-karpathy-wiki.md) (also available locally in [`toolkit/prompts/setup-karpathy-wiki.md`](../../prompts/setup-karpathy-wiki.md)).

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
* **`/raw/` Intake Directory:** Append-only directory where unmodified source material (articles, transcripts, docs, meeting notes) is deposited. Includes `.gitkeep`.
* **`/wiki/` Curated Knowledge Base:** Interlinked atomic markdown pages, each with typed frontmatter relations (`sources`, `related`, `extends`, `contradicts`, `mentioned_in`).
* **`/wiki/index.md` Control & Navigation Index:** Master categorized catalog containing `lint_trigger: enabled|disabled` to control autonomous maintenance.
* **`/wiki/hot.md` Rolling Context Cache:** High-density ~500-word orientation summary for rapid agent onboarding without full wiki scans (especially for codebase knowledge and second-brain wikis).
* **`/wiki/_log.md` Audit Trail:** Append-only log recording every ingest and lint operation with timestamped details.
* **`/wiki/.lint_trigger_counter` Session Counter:** Machine-local state tracking session activity (ignored in `.gitignore`).

### 4. Autonomous Lint Trigger Script (`scripts/wiki-lint-trigger.sh`)
* Lightweight POSIX script checking `lint_trigger: enabled` and incrementing `wiki/.lint_trigger_counter`.
* Alerts agents with `[WIKI MAINTENANCE DUE]: Pending /raw/ files or wiki health checks detected. Run wiki-lint.` on session 1 and every 15 sessions.

### 5. Standardized Agent Workflows (`workflows/`)
* **`wiki-ingest.md` (8 Steps):** Decomposes raw source documents into 5–25 atomic wiki pages with frontmatter relations.
* **`wiki-lint.md` (10 Steps):** Integrity audit protocol to validate paths, recompute `mentioned_in`, eliminate orphans, merge duplicates, audit inconsistencies, identify gaps, suggest source candidates, and rebuild indexes.

---

## Step 0 — Configuration Interview

When an AI agent or developer sets up the Karpathy LLM Wiki in a repository or workspace, consult the Step 0 configuration questions:

1. **[Q1] Which AI agent instruction file should the wiki rules be written to?**
   - In a **Repo Nexus workspace**: Instructions are maintained in separate instructions files (`.rnex/instructions/karpathy-llm.md` and `.rnex/rules/KARPATHY_RULES.md`). Agents read `rnex.yaml` to detect enabled plugins and read their dedicated instructions files automatically.
   - In a **standalone setup** (outside Repo Nexus):
     - `AGENTS.md` (universal, works across most harnesses)
     - `CLAUDE.md` (Claude Code / Anthropic)
     - `.cursor/rules/wiki.mdc` (Cursor)
     - `.github/copilot-instructions.md` (GitHub Copilot)
     - `GEMINI.md` (Google Gemini / Antigravity)
     - `.windsurfrules` (Windsurf)
     - Other — specify path
     *Append the `## Karpathy Wiki Rules` section to that file while preserving all existing content.*

2. **[Q2] What is this wiki for?**
   - Research / reading list — articles, papers, PDFs on a topic
   - Personal second brain — meetings, notes, business context, personal projects
   - Content archive — transcripts, podcast notes, newsletters
   - Codebase knowledge — architecture decisions, runbooks, team conventions
   - Other (describe briefly)

3. **[Q3] How should the wiki be organized?**
   - **Flat** — all pages at the top level of `/wiki/` (simpler, good default)
   - **Structured** — subfolders by category, chosen based on Q2:
     - Research → `concepts/`, `people/`, `organizations/`, `sources/`, `analysis/`
     - Second brain → `projects/`, `people/`, `decisions/`, `logs/`
     - Content archive → `sources/`, `people/`, `tools/`, `concepts/`
     - Codebase → `architecture/`, `decisions/`, `runbooks/`, `people/`
   - **Agent decides** — infer structure from the first batch of ingested content

4. **[Q4] Enable wiki automation now?**
   - **Yes** — set `lint_trigger: enabled` in `/wiki/index.md` frontmatter
   - **No** — set `lint_trigger: disabled` (can be changed anytime)

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
├── .rnex/
│   ├── instructions/
│   │   └── karpathy-llm.md          # Dedicated plugin instructions (auto-symlinked)
│   ├── rules/
│   │   └── KARPATHY_RULES.md        # Cardinal principles & wiki rules (auto-symlinked)
│   ├── workflows/
│   │   ├── wiki-ingest.md           # 8-step decomposition & ingestion workflow
│   │   └── wiki-lint.md             # 10-step graph validation & maintenance workflow
│   ├── scripts/
│   │   └── wiki-lint-trigger.sh     # Executable session counter & lint alert
│   ├── templates/
│   │   ├── wiki-page.template.md    # Atomic page template with typed relations
│   │   └── LLM_WIKI.sample.md       # Sample wiki walkthrough
│   └── .lint_trigger_counter        # Session counter (gitignored)
└── rnex.yaml                        # Plugin configuration
```

---

## Enabling in Repo Nexus

### Option 1: Via CLI (Recommended)

```bash
rnex plugin enable karpathy-llm
```

This command:
1. Adds `karpathy-llm` to `plugins:` in `rnex.yaml` with default configuration (`lint_trigger_enabled: true`).
2. Copies initial templates (`wiki/index.md`, `wiki/_log.md`, `wiki/hot.md`, `raw/.gitkeep`, `.rnex/templates/wiki-page.template.md`, `.rnex/templates/LLM_WIKI.sample.md`, `.rnex/scripts/wiki-lint-trigger.sh`).
3. Links `KARPATHY_RULES.md` and workflows into `.rnex/rules/` and `.rnex/workflows/`.
4. Ensures `.rnex/.lint_trigger_counter` is added to `.gitignore`.
5. Syncs scope links and AI context files across all registered member repositories via `rnex sync`.

### Option 2: Declarative in `rnex.yaml`

Configure `karpathy-llm` under `plugins:` in `rnex.yaml`:

```yaml
plugins:
  karpathy-llm:
    lint_trigger_enabled: true
```

Then synchronize:

```bash
rnex sync
```

---

## Everyday Operation & Cadence

1. **Intake:** Drop raw research papers, meeting notes, PRDs, or architecture specs into `/raw/` unmodified.
2. **Ingest:** Instruct your AI assistant: *"Run wiki-ingest on raw/source-document.md"*.
3. **Session Cadence:** After sessions where repository files were edited, run `.rnex/scripts/wiki-lint-trigger.sh`.
4. **Maintenance:** If prompted by `[WIKI MAINTENANCE DUE]`, instruct the assistant: *"Run wiki-lint"*.
5. **Toggle Automation:** Edit `lint_trigger: enabled` or `lint_trigger: disabled` in `/wiki/index.md` anytime.

---

## Disabling

```bash
rnex plugin disable karpathy-llm
```

Safely unlinks plugin assets from member repositories and removes the entry from `rnex.yaml`. Your curated `/wiki/` and `/raw/` data remain completely untouched on disk.
