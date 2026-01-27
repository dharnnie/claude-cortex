# Claude Code Dotfiles

Personal Claude Code configuration for consistent AI-assisted development across all projects.

## Quick Start

### New Machine Setup

```bash
# Clone the repo
git clone git@github.com:YOUR_USERNAME/claude-code-dotfiles.git ~/engineering/gen-ai/claude-code-dotfiles

# Symlink to ~/.claude
rm -rf ~/.claude
ln -s ~/engineering/gen-ai/claude-code-dotfiles ~/.claude

# Verify
ls -la ~/.claude
```

### Install Dependencies (macOS)

```bash
# For notifications
brew install terminal-notifier
```

## What's Included

### Notifications (`settings.json`)

System notifications when Claude needs attention:
- **Permission prompts** - When Claude needs approval to run a command
- **Idle prompts** - When Claude has been waiting 60+ seconds for input

Uses Submarine sound (plays 5x) via `terminal-notifier`.

### Global Preferences (`CLAUDE.md`)

Personal coding standards and workflow preferences that apply to all projects.

### Rules

Modular rule files that provide language-specific guidance:

```
rules/
├── general/
│   ├── contributing.md    # Git workflow, PRs, conventional commits
│   └── security.md        # Security checklist (all languages)
├── golang/
│   ├── project-structure.md   # cmd/, internal/, pkg/ layout
│   ├── error-handling.md      # Wrapping, sentinel errors, patterns
│   ├── testing.md             # Table-driven tests, mocks
│   ├── concurrency.md         # Context, channels, sync primitives
│   ├── style.md               # Naming, formatting, idioms
│   └── dependencies.md        # Stdlib first, when to add deps
└── ruby/
    ├── models.md              # Model conventions, migrations
    ├── services.md            # Service objects, query objects
    ├── testing.md             # RSpec, factories, request specs
    ├── api.md                 # API design, serializers
    ├── performance.md         # N+1, caching, background jobs
    ├── security.md            # Auth, SQL injection prevention
    └── contributing.md        # Ruby-specific workflow, CI
```

Rules use `paths:` frontmatter to apply only to relevant files:

```yaml
---
paths:
  - "**/*.go"
---
```

## How It Works

```
~/.claude/                      ← Symlinked to this repo
├── settings.json               ← Notifications, permissions
├── CLAUDE.md                   ← Global preferences
└── rules/                      ← Language-specific rules
    ├── general/                ← All languages
    ├── golang/                 ← Go projects
    └── ruby/                   ← Ruby projects

your-project/.claude/           ← Project-specific (optional)
├── settings.json               ← Project overrides
└── rules/                      ← Project-specific rules
```

**Precedence:** Project-level settings override user-level (global) settings.

## Adding New Languages

1. Create a directory: `rules/<language>/`
2. Add rule files with `paths:` frontmatter
3. Update `CLAUDE.md` to reference new rules

Example for TypeScript:

```bash
mkdir -p rules/typescript
```

```markdown
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Conventions

- Use strict mode
- Prefer interfaces over types
- ...
```

## Customization

### Change Notification Sound

Edit `settings.json` and replace `Submarine` with another macOS sound:
- `Glass`, `Ping`, `Pop`, `Purr`, `Funk`, `Hero`, `Morse`, `Sosumi`, `Tink`

### Add Permissions

```json
{
  "permissions": {
    "allow": [
      "Bash(go test ./...)",
      "Bash(make *)"
    ]
  }
}
```

## Files Not Committed

These are gitignored (machine-specific runtime data):
- `cache/`
- `projects/`
- `todos/`
- `history.jsonl`
- `settings.local.json`

## License

Personal configuration - fork and customize for your own use.
