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
chore/update-dependencies
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
feat(auth): add JWT token refresh endpoint
fix(orders): validate quantity before save
refactor(payments): extract stripe service
test(users): add registration edge cases
chore(deps): bump go to 1.22
```

### Commit Best Practices

- Write in imperative mood: "add feature" not "added feature"
- Keep subject line under 72 characters
- One logical change per commit
- Never commit broken code to main

### Worktrees

Use worktrees for parallel work without stashing or switching branches:

```bash
# Create worktree for a feature (from repo root)
git worktree add ../myproject-feature-auth feature/auth

# Create worktree for PR review
git worktree add ../myproject-pr-123 origin/pr-branch

# List active worktrees
git worktree list

# Remove when done
git worktree remove ../myproject-feature-auth
```

**Conventions:**
- Place worktrees as siblings to main repo: `../reponame-purpose`
- Never commit from a worktree you're using for review only
- Clean up worktrees promptly—don't let them accumulate

## Pull Requests

### Before Opening PR

1. Ensure tests pass
2. Run linter and fix issues
3. Check for security issues
4. Rebase on latest main

### PR Requirements

- Descriptive title following commit message format
- Description explaining **what** and **why**
- Link to related issue if applicable
- All CI checks passing
- Test coverage for new code
- No commented-out code
- No debug statements

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
- [ ] Added/updated integration tests (for API changes)
- [ ] Manually tested locally

## Checklist
- [ ] Tests pass
- [ ] Linter passes
- [ ] No secrets committed
```

## Code Review

### Reviewer Checklist

- [ ] Code follows project conventions
- [ ] Tests cover happy path and edge cases
- [ ] No security vulnerabilities
- [ ] No N+1 queries or performance issues
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

## Planning Before Implementation

**Think before coding.** For non-trivial features, always plan before implementing.

### When to Plan

Plan for:
- New features touching multiple files
- Architectural decisions
- Complex refactors
- Unclear requirements

Skip planning for:
- Single-file bug fixes
- Typo corrections
- Simple, well-defined changes

### Plan Structure

```markdown
## Goal
What we're trying to achieve

## Approach
High-level strategy

## Files to Change
- path/to/file - What changes and why

## New Files (if any)
- path/to/new_file - Purpose

## Testing Strategy
- What to test and how

## Risks & Considerations
- Edge cases
- Performance implications
- Security concerns
```

## Feature Development Flow

1. Create feature branch from main
2. Plan (for non-trivial features)
3. Write failing test
4. Implement the feature
5. Refactor if needed
6. Run full test suite
7. Run linter
8. Review before pushing
9. Push and open PR
10. Address review feedback
11. Squash and merge when approved

## Hotfix Flow

1. Branch from main: `fix/critical-bug-name`
2. Fix with minimal changes
3. Add regression test
4. Fast-track review
5. Merge and deploy
