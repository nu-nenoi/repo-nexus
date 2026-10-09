# Karpathy LLM Wiki Ingestion Workflow (`wiki-ingest`)

Autonomous workflow for decomposing and ingesting raw source documents from `raw/` into atomic Karpathy LLM Wiki pages.

## Protocol
1. Scan `raw/` for uningested documents not yet recorded in `wiki/_log.md`.
2. Read source materials completely; preserve original files in `raw/` unmodified.
3. Decompose each source document into atomic wiki pages in `wiki/` (5–25 pages per source).
4. For every page, write required YAML frontmatter with typed relations (`sources`, `related`, `extends`, `contradicts`, `mentioned_in`).
5. Update `wiki/index.md` and append an entry to `wiki/_log.md`.
