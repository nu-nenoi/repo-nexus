# Karpathy LLM Wiki Lint & Graph Maintenance (`wiki-lint`)

Periodic maintenance workflow to preserve wiki graph integrity, validate typed relations, and recompute bidirectional links.

## Protocol
1. Verify all frontmatter relation paths (`sources`, `related`, `extends`, `contradicts`) resolve to existing files.
2. Recompute `mentioned_in` backlinks for every page across the entire wiki graph.
3. Find orphaned pages not reachable from `wiki/index.md` or any `mentioned_in` link, and index them.
4. Detect duplicate/overlapping pages and check for factual contradictions.
5. Identify knowledge gaps and append audit results to `wiki/_log.md`.
