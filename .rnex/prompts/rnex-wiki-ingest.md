# Karpathy LLM Wiki Ingestion Workflow

Use this workflow to ingest source documents from `/raw/` into atomic, interconnected markdown pages in `/wiki/`.

---

## 1. Intake Scanning
1. Check `/raw/` for source materials (specs, notes, articles, PRDs) not yet recorded in `wiki/_log.md`.
2. Inspect `wiki/index.md` and `wiki/hot.md` to understand existing concept groupings and naming conventions.

## 2. Atomic Decomposition
1. Do NOT collapse an entire source document into a single wiki page.
2. Decompose into atomic concepts, entities, architectural patterns, and design decisions (typically 3–15 atomic pages per source).
3. Every page MUST include the required YAML frontmatter:
   ```yaml
   ---
   title: "Descriptive Concept Title"
   tags: [relevant, tags]
   last_updated: YYYY-MM-DD
   sources: [raw/source-doc.md]
   related: [wiki/related-page.md]
   extends: []
   contradicts: []
   mentioned_in: []
   ---
   ```

## 3. Index & Log Update
1. Update `wiki/index.md` to categorize links to each newly created page.
2. Update `wiki/hot.md` if high-priority architectural orientation changed.
3. Append an entry to `wiki/_log.md` with timestamp, source ingested, and list of generated pages.
