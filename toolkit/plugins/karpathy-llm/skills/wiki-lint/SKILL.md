---
name: wiki-lint
description: Autonomous link validation, backlink recalculation, and graph repair for Karpathy LLM Wiki.
---

# Karpathy LLM Wiki Lint Skill

Use this skill when auditing and maintaining knowledge graph integrity across `/wiki/`.

## Key Steps
- Validate all relation filepaths exist.
- Recalculate and update `mentioned_in` backlinks.
- Check for orphan pages and update `wiki/index.md`.
- Flag contradictions and record maintenance in `wiki/_log.md`.
