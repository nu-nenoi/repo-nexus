# Karpathy LLM Wiki Lint & Graph Integrity Workflow

Use this workflow to validate link integrity, update bidirectional backlinks, and detect orphaned pages in `/wiki/`.

---

## 1. Graph Traversal & Validation
1. Verify that all markdown links (`[text](./target.md)`) and frontmatter references (`sources`, `related`, `extends`, `contradicts`) point to existing files on disk.
2. Recompute bidirectional `mentioned_in: []` frontmatter backlinks:
   - If Page A references Page B in `related`, `extends`, or body links, ensure Page B includes Page A in its `mentioned_in` list.
3. Detect orphan pages: any page in `/wiki/` that has no incoming links and is not listed in `wiki/index.md`.

## 2. Master Index Rebuild
1. Inspect all atomic pages in `wiki/`.
2. Reconcile categories and alphabetical links in `wiki/index.md`.
3. Record lint operations in `wiki/_log.md`.
