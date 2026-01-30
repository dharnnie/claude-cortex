# Claude Cortex

A library of coding convention rules for Claude Code. Install with a single command to maintain consistent AI-assisted development standards.

## Quick Start

From your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash
```

This will:
1. Detect your project's languages (via `go.mod`, `Gemfile`, `package.json`, etc.)
2. Copy relevant rule files into `.claude/rules/`
3. Generate a `CLAUDE.md` referencing the installed rules

### Update Rules

Pull upstream changes without losing local edits:

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --update
```

Files you've modified locally are preserved — only unmodified files are updated.

### More Options

```bash
# Preview without writing any files
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --dry-run

# Overwrite CLAUDE.md even if it exists
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --force

# Install globally to ~/.claude
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --global

# Use your fork
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-cortex/main/install.sh | bash -s -- --repo https://github.com/YOUR_USERNAME/claude-cortex.git
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

## How It Works

The installer clones the repo to a temp directory, copies the relevant `.md` rule files into your project's `.claude/rules/` directory, and generates a `CLAUDE.md` at the project root. A `.checksums` file tracks original file hashes so `--update` can detect which files you've modified locally.

### What Gets Installed

```
your-project/
├── CLAUDE.md                          # Generated index of rules
└── .claude/
    └── rules/
        ├── .checksums                 # Tracks original hashes for safe updates
        ├── general/
        │   ├── contributing.md
        │   └── security.md
        └── golang/                    # Only if go.mod detected
            ├── project-structure.md
            ├── error-handling.md
            └── ...
```

### Regenerating CLAUDE.md

If you add a new language to your project and want to re-detect:

```bash
/path/to/claude-cortex/setup.sh --force
```

`setup.sh` regenerates `CLAUDE.md` from the already-installed rules.

## Manual / Advanced Setup

### As a Git Submodule

If you prefer managing rules as a submodule:

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
```

Update with:

```bash
git submodule update --remote rules
git add rules
git commit -m "chore: update rules"
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

## Structure

```
claude-cortex/
├── README.md
├── install.sh
├── setup.sh
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

## License

MIT - Fork and customize for your own use.
