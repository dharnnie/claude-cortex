# Contributing Guidelines

## Git Workflow

### Branch Naming

```bash
# Feature branches
feature/add-user-authentication
feature/wallet-transactions

# Bug fixes
fix/order-validation-error
fix/null-pointer-in-payments

# Refactoring
refactor/extract-payment-service
refactor/optimize-queries

# Chores (dependencies, CI, docs)
chore/update-rails-8
chore/add-ci-workflow
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format
<type>(<scope>): <description>

# Types
feat:     New feature
fix:      Bug fix
refactor: Code change (no new feature or fix)
test:     Adding/updating tests
docs:     Documentation only
chore:    Maintenance (deps, CI, configs)
perf:     Performance improvement

# Examples
feat(wallets): add balance transfer endpoint
fix(orders): validate quantity before save
refactor(auth): extract token service
test(users): add registration edge cases
chore(deps): bump rails to 8.0.1
```

### Commit Best Practices

- Write in imperative mood: "add feature" not "added feature"
- Keep subject line under 72 characters
- One logical change per commit
- Never commit broken code to main

## Pull Requests

### Before Opening PR

```bash
# 1. Ensure tests pass
bin/rspec

# 2. Run linter and fix issues
bin/rubocop -a

# 3. Check for security issues
bin/brakeman -q

# 4. Rebase on latest main
git fetch origin
git rebase origin/main
```

### PR Requirements

- Descriptive title following commit message format
- Description explaining **what** and **why**
- Link to related issue if applicable
- All CI checks passing
- Test coverage for new code
- No commented-out code
- No debug statements (puts, debugger, binding.pry)

### PR Template

```markdown
## What
Brief description of changes.

## Why
Context and motivation.

## How
Implementation approach (if non-obvious).

## Testing
- [ ] Added/updated unit tests
- [ ] Added/updated request specs (for API changes)
- [ ] Manually tested locally

## Checklist
- [ ] Tests pass (`bin/rspec`)
- [ ] Linter passes (`bin/rubocop`)
- [ ] No N+1 queries introduced
- [ ] Migrations are reversible
- [ ] Secrets not committed
```

## Code Review

### Reviewer Checklist

- [ ] Code follows project conventions
- [ ] Tests cover happy path and edge cases
- [ ] No security vulnerabilities (SQL injection, mass assignment)
- [ ] Queries scoped to current user where applicable
- [ ] No N+1 queries
- [ ] Database indexes for new foreign keys
- [ ] Error handling is appropriate
- [ ] No over-engineering

### Review Etiquette

- Be constructive and specific
- Explain the "why" behind suggestions
- Approve when changes are minor
- Use conventional comments:
  ```
  nit: minor style suggestion
  suggestion: optional improvement
  question: seeking clarification
  issue: must be addressed
  ```

## Database Changes

### Migration Checklist

- [ ] Add indexes for foreign keys
- [ ] Add indexes for columns in WHERE/ORDER BY
- [ ] Use `null: false` where appropriate
- [ ] Provide default values when sensible
- [ ] Migration is reversible (`change` or `up/down`)
- [ ] Large tables: use `disable_ddl_transaction!` if needed

### Safe Migrations

```ruby
# Add column with default (safe in Rails 8+)
add_column :users, :active, :boolean, default: true, null: false

# Add index concurrently for large tables
disable_ddl_transaction!

def change
  add_index :orders, :status, algorithm: :concurrently
end
```

## Planning Before Implementation

**Think before coding.** For non-trivial features, always plan before implementing.

### When to Plan

Plan for:
- New features touching multiple files
- Architectural decisions (new patterns, libraries, integrations)
- Complex refactors
- Unclear requirements that need exploration
- Any change where the approach isn't obvious

Skip planning for:
- Single-file bug fixes
- Typo corrections
- Simple, well-defined changes

### Plan Structure

A good plan includes:

```markdown
## Goal
What we're trying to achieve

## Approach
High-level strategy

## Files to Change
- path/to/file.rb - What changes and why
- path/to/another.rb - What changes and why

## New Files (if any)
- path/to/new_file.rb - Purpose

## Dependencies
- External gems or services needed
- Migration requirements

## Testing Strategy
- What to test and how

## Risks & Considerations
- Edge cases
- Performance implications
- Security concerns
```

## Feature Development Flow

1. Create feature branch from latest `main`
2. **Plan** (for non-trivial features)
3. **Write failing test** for the feature
4. **Implement** the feature
5. **Refactor** if needed
6. **Run full test suite** (`bin/rspec`)
7. **Run linter** (`bin/rubocop -a`)
8. **Push and open PR**
9. **Address review feedback**
10. **Squash and merge** when approved

## Hotfix Flow

1. Branch from `main`: `fix/critical-bug-name`
2. Fix with minimal changes
3. Add regression test
4. Fast-track review
5. Merge and deploy

## CI Requirements

All PRs must pass:
- `bin/rspec` - Test suite
- `bin/rubocop` - Code style
- `bin/brakeman` - Security scan
- `bundle audit` - Dependency vulnerabilities
