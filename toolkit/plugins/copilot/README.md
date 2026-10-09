# GitHub Copilot Plugin for Repo Nexus

A built-in Repo Nexus plugin providing bidirectional alignment and operational prompt/skill mirroring for GitHub Copilot.

## Capabilities

1. **Prompts Mirroring**: Standardized Repo Nexus prompts (`rnex-feature`, `rnex-audit`, etc.) and active plugins' prompts/workflows are synchronized into `.github/prompts/*.prompt.md` with YAML frontmatter.
2. **Agent Skills**: Prompts, active plugin skills, and agent bundles are mirrored into `.github/skills/<name>/SKILL.md` for GitHub Copilot Agent mode.
3. **Custom Agents**: Active plugins' agents are mirrored into `.github/agents/*.agent.md`.
4. **Instructions Integration**: Active plugins' rules/instructions and Repo Nexus routing instructions are synthesized into `.github/copilot-instructions.md`.

## Usage

Enable the plugin across the workspace:
```bash
rnex plugin enable copilot
```

Or configure options in `rnex.yaml` or `.local.rnex.yaml`:
```yaml
plugins:
  copilot:
    prompts: true
    skills: true
    instructions: true
    agents: true
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `prompts` | boolean | `true` | Mirror prompts to `.github/prompts/*.prompt.md` |
| `skills` | boolean | `true` | Mirror skills to `.github/skills/<name>/SKILL.md` |
| `instructions` | boolean | `true` | Mirror guidelines to `.github/copilot-instructions.md` |
| `agents` | boolean | `true` | Mirror custom agents to `.github/agents/*.agent.md` |
| `enabled` | boolean | `true` | Set to `false` in `.local.rnex.yaml` to override team config |
