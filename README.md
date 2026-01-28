# Claude Cortex

A library of coding convention rules for Claude Code. Use as a git submodule to maintain consistent AI-assisted development standards.

## Usage

### As a Submodule (Recommended)

Add to your `~/.claude` or project:

```bash
cd ~/.claude  # or your project
git submodule add https://github.com/dharnnie/claude-cortex.git rules
```

Reference rules in your `CLAUDE.md`:

```markdown
## Rules Reference

### General
- @rules/general/contributing.md
- @rules/general/security.md

### Go
- @rules/golang/project-structure.md
- @rules/golang/error-handling.md
- @rules/golang/testing.md
```

### Update Rules

```bash
git submodule update --remote rules
git add rules
git commit -m "chore: update rules"
```

## Available Rules

### General (All Languages)

| File | Description |
|------|-------------|
| `general/contributing.md` | Git workflow, branches, commits, PRs, code review |
| `general/security.md` | Security checklist, input validation, secrets management |

### Go

| File | Description |
|------|-------------|
| `golang/project-structure.md` | Package design, `cmd/`, `internal/`, `pkg/` layout |
| `golang/error-handling.md` | Wrapping errors, sentinel errors, custom types |
| `golang/testing.md` | Table-driven tests, mocks, test helpers |
| `golang/concurrency.md` | Context, goroutines, channels, sync primitives |
| `golang/style.md` | Naming, formatting, idioms |
| `golang/dependencies.md` | Stdlib first, when to add deps |

### Ruby / Rails

| File | Description |
|------|-------------|
| `ruby/models.md` | Model conventions, migrations, associations |
| `ruby/services.md` | Service objects, query objects, form objects |
| `ruby/testing.md` | RSpec, FactoryBot, request specs |
| `ruby/api.md` | API design, serializers, versioning |
| `ruby/performance.md` | N+1 prevention, caching, background jobs |
| `ruby/security.md` | Authentication, authorization, SQL injection |
| `ruby/contributing.md` | Ruby-specific workflow, CI |

## Quick Start with Starter

For a complete `~/.claude` setup including notifications, see `starter/`:

```bash
cd starter
./install.sh
```

This creates `~/.claude` with:
- `CLAUDE.md` - Global preferences template
- `settings.json` - Notification hooks
- `rules/` - This repo as a submodule

See `starter/README.md` for details.

## Structure

```
claude-cortex/
├── README.md
├── general/
│   ├── contributing.md
│   └── security.md
├── golang/
│   ├── concurrency.md
│   ├── dependencies.md
│   ├── error-handling.md
│   ├── project-structure.md
│   ├── style.md
│   └── testing.md
├── ruby/
│   ├── api.md
│   ├── contributing.md
│   ├── models.md
│   ├── performance.md
│   ├── security.md
│   ├── services.md
│   └── testing.md
└── starter/
    ├── README.md
    ├── CLAUDE.md.example
    ├── settings.json.example
    ├── .gitignore.example
    └── install.sh
```

## Adding Rules

### New Language

```bash
mkdir -p typescript
```

Create rule files with optional `paths:` frontmatter:

```markdown
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Conventions

...
```

### Per-Project Rules

Add project-specific rules in your project's `.claude/rules/` directory. Project rules take precedence over global rules.

## License

MIT - Fork and customize for your own use.
