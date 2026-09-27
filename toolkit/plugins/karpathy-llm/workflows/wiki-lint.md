# Wiki Lint & Maintenance Workflow (`wiki-lint`)

Periodic health check and maintenance workflow to preserve wiki graph integrity, validate typed relations, recompute bidirectional links, and resolve knowledge gaps.

---

## Lint & Maintenance Protocol

1. **Verify Relation Paths:**
   - Scan every wiki page under `/wiki/`.
   - Verify that all relative paths specified in `sources`, `related`, `extends`, and `contradicts` resolve to real files on disk.
   - Fix broken links or flag missing files in `/wiki/_log.md`.

2. **Recompute `mentioned_in`:**
   - Scan all pages across the wiki for incoming references (both from frontmatter relation fields and inline prose markdown links).
   - Update each page's `mentioned_in:` frontmatter list to accurately reflect all pages that link to it.

3. **Identify & Link Orphan Pages:**
   - Detect pages that are not linked in `/wiki/index.md` and have an empty `mentioned_in:` list.
   - Add newly discovered orphan pages to their appropriate category in `/wiki/index.md`.

4. **Detect & Consolidate Overlaps:**
   - Identify redundant or duplicate pages that cover identical topics.
   - Consolidate them into a single canonical atomic page and update incoming relations across the wiki.

5. **Audit Inconsistencies & Contradictions:**
   - Review pages tagged with `contradicts:` relations.
   - Ensure competing viewpoints, conflicting architectural decisions, or evolving data models are accurately framed.

6. **Identify Knowledge Gaps:**
   - Find recurring terms, concepts, or entities referenced in prose or relations that do not yet have an atomic page.
   - Create stub pages or flag them as candidates for future ingestion from `/raw/`.

7. **Rebuild Navigation Index:**
   - Re-sort and reconcile `/wiki/index.md` so that all active pages are properly categorized with updated metadata.

8. **Refresh Hot Context Cache:**
   - Prune `/wiki/hot.md` to remove stale context and ensure it remains a crisp ~500-word overview of active domain knowledge.

9. **Log Audit Summary:**
   - Append a timestamped maintenance summary to `/wiki/_log.md` detailing:
     - Dead links fixed
     - `mentioned_in` counts recomputed
     - New stubs or orphans indexed
