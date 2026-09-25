# Karpathy LLM Plugin for Repo Nexus

The **`karpathy-llm`** plugin packages Andrej Karpathy's widely adopted agent behavioral rules, context engineering standards, and the LLM Wiki pattern for multi-repository development.

---

## What It Provides

1. **The 4 Cardinal Principles for Coding Agents (`rules/KARPATHY_RULES.md`):**
   * **Think Before Coding:** Explicit assumptions, problem formulation, and trade-off evaluation.
   * **Simplicity First:** Minimal abstractions, readable implementations, and zero boilerplate.
   * **Surgical Changes:** Minimal blast radius, preserved comments/docstrings, and focused diffs.
   * **Goal-Driven Execution:** Upfront verification criteria, automated tests, and diff inspection.

2. **Multi-Repo Context Engineering:**
   * Clear guidelines for AI agents (Cursor, Claude Code, GitHub Copilot, Antigravity) respecting member repository autonomy and symlink write-through semantics.

3. **LLM Wiki Pattern Scaffolding (`templates/LLM_WIKI.sample.md`):**
   * A persistent, indexed knowledge base template documenting cross-repo boundaries, contracts, and ADRs so context compounds across developer sessions.

---

## Enabling in Repo Nexus

### Option 1: Via CLI (Recommended)
```bash
rnex plugin enable karpathy-llm
```

### Option 2: Declarative in `rnex.yaml`
Add `karpathy-llm` to the `plugins:` list:
```yaml
plugins:
  - karpathy-llm
```
Then run:
```bash
rnex sync
```

---

## Disabling
```bash
rnex plugin disable karpathy-llm
```
This safely removes the plugin from `rnex.yaml` and cleans up symlinks from member repositories.
