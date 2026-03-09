# marlon-claude-plugin

Personal Claude Code plugin with custom agents, skills, commands, and hooks.

## Installation

### Linux / macOS
```bash
./install.sh
```

### Windows
```cmd
install.cmd
```

This registers the `plugin/` directory path in `~/.claude/plugins/installed_plugins.json`. No symlink needed — Claude Code reads directly from the repo. Restart Claude Code after installing.

## Uninstall

Remove the entry from `installed_plugins.json`:
```bash
# Remove "marlon-claude-plugin" from ~/.claude/plugins/installed_plugins.json
```

## Structure

| Path | Purpose |
|------|---------|
| `plugin/` | The plugin itself — everything Claude Code loads |
| `plugin/.claude-plugin/plugin.json` | Plugin metadata |
| `plugin/agents/` | Agent definitions (`.md`) |
| `plugin/skills/` | Skill modules (each a folder with `SKILL.md`) |
| `plugin/commands/` | Slash commands (`.md`) |
| `plugin/hooks/hooks.json` | Hook configuration |
| `data/` | Reference/inspiration material (not shipped) |

## Adding Content

**Agent:** Create `plugin/agents/my-agent.md` with YAML frontmatter (`name`, `description`, `model`).

**Skill:** Create `plugin/skills/my-skill/SKILL.md` with YAML frontmatter (`name`, `description`).

**Command:** Create `plugin/commands/my-command.md` with YAML frontmatter (`description`).

**Hook:** Add entries to `plugin/hooks/hooks.json` under the appropriate event type.

See `CLAUDE.md` for detailed format documentation.
