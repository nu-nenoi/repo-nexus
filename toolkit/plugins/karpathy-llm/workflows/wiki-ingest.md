# Wiki Ingestion Workflow (`wiki-ingest`)

Universal workflow for decomposing and ingesting raw source materials into atomic Karpathy LLM Wiki pages.

---

## Ingestion Protocol

1. **Scan Intake:**
   - Scan `/raw/` for source materials (articles, transcripts, documents, research notes, meeting logs) not yet recorded in `/wiki/_log.md`.
   - All source material must reside in `/raw/` unmodified. Never write directly to `/wiki/` without ingesting.

2. **Read & Clarify:**
   - Read each source fully.
   - If scope, domain boundaries, target audience, or level of detail is unclear, ask one round of clarifying questions before proceeding.

3. **Atomic Decomposition:**
   - Decompose each source into atomic wiki pages — **one per distinct concept, person, organization, event, or theme** (or architecture decision/contract).
   - A single source document commonly produces **5–25 pages**. Never collapse an entire source into a single file.
   - Place pages according to workspace wiki organization:
     - **Flat:** directly under `/wiki/` (e.g., `/wiki/<topic>.md`)
     - **Structured:** in categorical subfolders:
       - Research → `concepts/`, `people/`, `organizations/`, `sources/`, `analysis/`
       - Second brain → `projects/`, `people/`, `decisions/`, `logs/`
       - Content archive → `sources/`, `people/`, `tools/`, `concepts/`
       - Codebase → `architecture/`, `decisions/`, `runbooks/`, `people/`

4. **Frontmatter Relations:**
   - For each page, write the required YAML frontmatter with typed relations:
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
   mentioned_in: []     # pages that link to this one (leave empty; maintained by lint)
   ---
   ```
   - **Crucial:** The relation graph lives in frontmatter, not in prose links. Agents traverse the graph by reading frontmatter fields, not by scanning body text.

5. **Author Concise Body:**
   - Write a concise body with summary, key facts, and insights.
   - Add inline standard Markdown links (`[Label](./path.md)`) where contextually useful in prose.

6. **Update Navigation Index:**
   - Update `/wiki/index.md` with links to all new pages in their corresponding categorized sections.

7. **Update Hot Cache:**
   - Update `/wiki/hot.md` if it exists with the rolling ~500-word orientation summary of active context.

8. **Append Operation Log:**
   - Append a timestamped entry to `/wiki/_log.md` detailing:
     - Date & time
     - Raw file processed
     - List of atomic pages generated
     - Any flagged follow-ups or knowledge gaps
