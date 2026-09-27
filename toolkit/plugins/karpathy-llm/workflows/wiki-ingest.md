# Wiki Ingestion Workflow (`wiki-ingest`)

Universal workflow for decomposing and ingesting raw source materials into atomic Karpathy LLM Wiki pages.

---

## Ingestion Protocol

1. **Intake Discovery:**
   - Scan `/raw/` for source materials (articles, transcripts, documents, research notes, meeting logs) not yet logged in `/wiki/_log.md`.
   - Never ingest partial or in-progress files.

2. **Analyze & Clarify:**
   - Read the raw source fully.
   - If domain boundaries, target audience, or level of detail are ambiguous, ask a focused round of clarifying questions before generating pages.

3. **Decompose Atomically:**
   - Deconstruct the source into atomic markdown pages — **exactly one page per distinct concept, entity, person, organization, system, architectural decision, or contract**.
   - A single source document commonly yields **5 to 25 atomic wiki pages**. Never collapse an entire source document into a single monolithic page.

4. **Frontmatter Schema:**
   Every generated wiki page must begin with the standard typed relation frontmatter:
   ```yaml
   ---
   title: "Descriptive Concept Title"
   tags: [domain, architecture]
   last_updated: YYYY-MM-DD
   # Typed frontmatter relations (paths relative to /wiki/)
   sources: ["raw/filename.ext"]
   related: ["concepts/related-page.md"]
   extends: []
   contradicts: []
   mentioned_in: []   # Leave empty; computed and maintained by wiki-lint
   ---
   ```

5. **Author Atomic Body:**
   - Provide a concise summary and core facts/insights.
   - Include standard Markdown links (`[Label](./target.md)`) where prose naturally benefits.
   - Ground all factual assertions directly in the source material.

6. **Update Navigation Index:**
   - Insert links to all newly created pages into the categorized sections of `/wiki/index.md`.

7. **Update Hot Context Cache:**
   - If `/wiki/hot.md` exists, update its rolling summary with the most critical new concepts (keeping total length around ~500 words).

8. **Append Operation Log:**
   - Add a timestamped entry to `/wiki/_log.md` detailing:
     - Date & time
     - Raw file processed
     - List of atomic pages generated
     - Any flagged follow-ups
