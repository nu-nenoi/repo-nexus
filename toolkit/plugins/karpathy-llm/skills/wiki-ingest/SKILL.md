---
name: wiki-ingest
description: Autonomous ingestion and atomic decomposition of raw sources into Karpathy LLM Wiki pages.
---

# Karpathy LLM Wiki Ingestion Skill

Use this skill when decomposing raw documents, research notes, meeting logs, or external articles from `raw/` into atomic wiki pages under `wiki/`.

## Key Rules
- Source documents stay untouched in `raw/`.
- Produce 5–25 atomic pages per document (never lump into one large file).
- Include YAML frontmatter with typed relations (`sources`, `related`, `extends`, `contradicts`, `mentioned_in`).
- Record completed ingestion in `wiki/_log.md`.
