# Claude Cortex

A curated library of coding convention **rules** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Rules are markdown documents that live in `.claude/rules/`. Claude reads them for guidance on style, patterns, and project conventions when working in your codebase. Rules are not executable — they carry no logic and perform no actions.

> **Rules vs Skills:** In the Claude Code ecosystem, *rules* provide passive context (conventions, guidelines, constraints), while *skills* are executable slash commands (`/commit`, `/review-pr`) that perform actions with tool access. This project provides **rules only**.

**What this is:**
- A library of opinionated, language-organized convention documents
- Installable via a single `curl` command with automatic language detection
- Safely updatable while preserving your local edits

**What this is not:**
- Not a Claude Code plugin, extension, or runtime dependency
- Not executable skills or slash commands
- Not a replacement for project-specific rules you write yourself

## Quick Start

From your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash
```

This will:
1. Detect your project's languages (via `go.mod`, `Gemfile`, `package.json`, etc.)
2. Copy only the relevant rule files into `.claude/rules/`
3. Generate a `CLAUDE.md` referencing the installed rules
4. Write checksums so future updates can preserve your local edits

## How Selective Loading Works

Claude Cortex keeps Claude's context focused through two layers of filtering.

### At install time

The installer detects languages from marker files in your project root and copies only matching rule sets:

| Marker file | Language | Rules installed |
|---|---|---|
| `go.mod`, `go.sum` | Go | `golang/` |
| `Gemfile`, `Rakefile`, `.ruby-version` | Ruby | `ruby/` |
| `package.json` | JavaScript | `javascript/` |
| `tsconfig.json` | TypeScript | `typescript/` |
| `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` | Python | `python/` |
| `Cargo.toml` | Rust | `rust/` |
| `pom.xml`, `build.gradle` | Java | `java/` |

Rules in `general/` are always installed regardless of language.

### At runtime

Rule files can declare which file patterns they apply to using `paths:` YAML frontmatter:

```markdown
---
paths:
  - "**/*.go"
---

# Go Style Guide
...
```

When a rule has `paths:` frontmatter, Claude Code loads it **only** when you are working on files matching those patterns. A Go style rule won't load when you're editing a Dockerfile.

Rules without `paths:` frontmatter (like `general/contributing.md`) load for all files.

### Result

A Go project installs only `general/` and `golang/` rules. Within those, Go-specific rules activate only when editing `.go` files. Claude's context stays small, relevant, and fast.

## Available Rules

### General (all projects)

| File | Description | Paths |
|---|---|---|
| `general/contributing.md` | Git workflow, branches, commits, PRs, code review | all files |
| `general/security.md` | Security checklist, input validation, secrets management | all files |

### Go

| File | Description | Paths |
|---|---|---|
| `golang/style.md` | Naming, formatting, idioms | `**/*.go` |
| `golang/error-handling.md` | Wrapping errors, sentinel errors, custom types | `**/*.go` |
| `golang/testing.md` | Table-driven tests, mocks, test helpers | `**/*.go`, `**/*_test.go` |
| `golang/concurrency.md` | Context, goroutines, channels, sync primitives | `**/*.go` |
| `golang/project-structure.md` | Package design, `cmd/`, `internal/`, `pkg/` layout | `**/*.go`, `go.mod`, `go.sum` |
| `golang/dependencies.md` | Stdlib first, when to add deps | `**/*.go`, `go.mod`, `go.sum` |

### Ruby / Rails

| File | Description | Paths |
|---|---|---|
| `ruby/models.md` | Model conventions, migrations, associations | `**/*.rb`, `**/db/migrate/**`, `**/db/schema.rb` |
| `ruby/services.md` | Service objects, query objects, form objects | `**/*.rb` |
| `ruby/testing.md` | RSpec, FactoryBot, request specs | `**/*.rb`, `**/*_spec.rb`, `**/spec/**` |
| `ruby/api.md` | API design, serializers, versioning | `**/*.rb` |
| `ruby/performance.md` | N+1 prevention, caching, background jobs | `**/*.rb` |
| `ruby/security.md` | Authentication, authorization, SQL injection | `**/*.rb`, `**/config/**` |
| `ruby/contributing.md` | Ruby-specific workflow, CI | `**/*.rb`, `Gemfile`, `Rakefile` |

## Installation Options

### Preview before installing

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --dry-run
```

### Overwrite existing CLAUDE.md

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --force
```

Backs up the existing file to `CLAUDE.md.bak` before overwriting.

### Install globally

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --global
```

Installs to `~/.claude/rules/` instead of the current project. See [Global vs Project-Level Installation](#global-vs-project-level-installation).

### Use your fork

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/claude-cortex/main/install.sh | bash -s -- \
  --repo https://github.com/YOUR_ORG/claude-cortex.git
```

### All flags

| Flag | Description |
|---|---|
| `--dry-run` | Preview without writing files |
| `--force` | Overwrite CLAUDE.md (backs up existing) |
| `--update` | Pull upstream changes, preserve local edits |
| `--global` | Install to `~/.claude` |
| `--repo URL` | Use a custom repo URL |
| `--help` | Show usage |

## Updating Rules

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --update
```

### How updates work

The installer tracks SHA-256 checksums of every rule file at install time (stored in `.claude/rules/.checksums`).

On `--update`:
1. Files **you have not modified** are updated to the latest upstream version
2. Files **you have modified locally** are skipped — your edits are preserved
3. New rule files from upstream are added
4. CLAUDE.md is regenerated if it was not manually edited

### Force-updating modified files

To replace locally modified files with upstream versions:

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --update --force
```

This backs up modified files to `.bak` before overwriting.

## Global vs Project-Level Installation

### Project-level (default)

```
your-project/
├── CLAUDE.md
└── .claude/
    └── rules/
        ├── .checksums
        ├── general/
        └── golang/
```

Rules apply only to this project. Commit `.claude/rules/` to share conventions with your team.

**Use when:** you want consistent conventions across all contributors on a specific project.

### Global

```
~/.claude/
├── CLAUDE.md
├── settings.json
└── rules/
    ├── general/
    └── golang/
```

Rules apply as defaults across all your projects.

**Use when:** you want personal baseline conventions that apply everywhere.

### Precedence

Project-level rules override global rules. If the same rule file exists in both locations, Claude uses the project version. This means you can:

1. Install a broad set of conventions globally
2. Override specific rules per project as needed
3. Add project-only rules that don't exist globally

## Customization

### Adding project-specific rules

Create rule files directly in `.claude/rules/`:

```markdown
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# Our TypeScript Conventions

...
```

These are your own rules — the installer will not touch files it didn't create.

### Editing installed rules

Modify any installed rule file in `.claude/rules/`. The `--update` flag detects your changes via checksum and skips those files.

### Forking for your team

1. Fork the repo
2. Modify or add rules
3. Install from your fork:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/claude-cortex/main/install.sh | bash -s -- \
  --repo https://github.com/YOUR_ORG/claude-cortex.git
```

Your team members use the same command. Updates pull from your fork.

### Regenerating CLAUDE.md

If you add a new language to your project after initial installation, re-run with `--force` to re-detect languages and regenerate CLAUDE.md:

```bash
curl -fsSL https://raw.githubusercontent.com/dharnnie/claude-cortex/main/install.sh | bash -s -- --force
```

## Contributing

### Adding a new language

1. Create a directory matching the language (e.g., `typescript/`)
2. Add rule files with `paths:` frontmatter
3. Add the language's marker files to the `LANG_MARKERS` array in `install.sh`
4. Update the Available Rules table in this README

### Rule file conventions

- One concept per file (e.g., `testing.md`, `error-handling.md`)
- Start with a `# Heading` that describes the rule set
- Use `paths:` frontmatter to scope rules to relevant file types
- Include concrete code examples, not just prose
- Keep files focused — split large topics into multiple files

### Repository structure

```
claude-cortex/
├── install.sh        # Curl-fetchable installer
├── setup.sh          # CLAUDE.md regeneration helper
├── general/          # Language-agnostic rules (always installed)
├── golang/           # Go rules (installed when go.mod detected)
├── ruby/             # Ruby rules (installed when Gemfile detected)
└── starter/          # Global ~/.claude setup templates
```

## License

MIT
