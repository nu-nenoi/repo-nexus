# Karpathy LLM Wiki Knowledge Architecture

> "A persistent, compounding knowledge base optimized for AI agents." — Andrej Karpathy

This instruction document defines the operational rules, intake lifecycle, and typed relation schema for the Karpathy LLM Wiki (`/wiki/` and `/raw/` directories).

---

## 1. Operating Rules

When working in a workspace with an active Karpathy LLM Wiki:

- **Intake**: All source material (articles, transcripts, docs, notes) goes to `/raw/` unmodified. Never write directly to `/wiki/` without ingesting.
- **Orientation**: Before answering domain questions, read `/wiki/index.md` to find relevant pages, then read only those pages. If `hot.md` exists, read it first as a quick-orient step.
- **Ingestion**: When files appear in `/raw/`, run the `wiki-ingest` workflow (`.rnex/plugins/karpathy-llm/workflows/wiki-ingest.md`). One source document typically produces many atomic pages (commonly 5–25 pages) — do not collapse a source into a single file.
- **Maintenance**: Run the `wiki-lint` workflow (`.rnex/plugins/karpathy-llm/workflows/wiki-lint.md`) to validate paths, update `mentioned_in`, and preserve graph integrity.

---

## 2. Typed Frontmatter Relation Schema

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

**Body Structure:**
- Concise summary of the concept.
- Key facts, definitions, or insights.
- Inline standard Markdown links (`[Label](./path.md)`) where contextually useful in prose.

The relation graph lives in frontmatter, not in prose links. Agents traverse the graph by reading frontmatter fields, not by scanning body text.
