# Wiki Lint & Maintenance Workflow (`wiki-lint`)

Periodic health check and maintenance workflow to preserve wiki graph integrity, validate typed relations, recompute bidirectional links, resolve knowledge gaps, and rebuild indexes.

---

## Lint & Maintenance Protocol

1. **Verify Relation Paths:**
   - For every page, verify that all paths in frontmatter relation fields (`related`, `extends`, `contradicts`, `sources`) resolve to existing files.
   - Fix or flag broken paths.

2. **Recompute `mentioned_in`:**
   - Recompute `mentioned_in` for every page by scanning all other pages' relation fields and inline links.
   - Update the field in frontmatter.

3. **Find Orphaned Pages:**
   - Detect pages not reachable from `index.md` or any `mentioned_in` field.
   - Add them to the index in their appropriate category.

4. **Detect Duplicate or Overlapping Pages:**
   - Detect duplicate or heavily overlapping pages.
   - Consolidate and update relations across the wiki graph.

5. **Check Factual Inconsistencies:**
   - Check for factual inconsistencies between pages in `contradicts` relations or covering the same topic.
   - Clarify or resolve contradictions.

6. **Identify Knowledge Gaps:**
   - Identify knowledge gaps: concepts referenced in relation fields or prose but lacking their own atomic page.
   - Create stub pages or flag for future ingest.

7. **Suggest Source Candidates:**
   - Suggest source candidates from `/raw/` or external searches to fill identified knowledge gaps.

8. **Rebuild Navigation Index:**
   - Rebuild `/wiki/index.md` to reflect the current set of pages and categories accurately.

9. **Update Hot Cache:**
   - Update `/wiki/hot.md` if it exists, refreshing the rolling ~500-word orientation context.

10. **Append Operation Log:**
    - Append a lint summary to `/wiki/_log.md` detailing:
      - Broken links fixed or flagged
      - `mentioned_in` updates
      - Orphans and duplicates resolved
      - Gaps identified or stubbed
