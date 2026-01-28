---
paths:
  - "**/*.go"
  - "go.mod"
  - "go.sum"
---

# Go Dependencies

## Philosophy

**Standard library first.** Go's stdlib is excellent. Don't add dependencies for things it handles well.

## Standard Library Strengths

Use stdlib for:

| Need | Use |
|------|-----|
| HTTP server/client | `net/http` |
| JSON | `encoding/json` |
| Logging | `log/slog` (Go 1.21+) |
| Testing | `testing` |
| Time | `time` |
| Strings/bytes | `strings`, `bytes` |
| I/O | `io`, `bufio` |
| File system | `os`, `io/fs` |
| Templates | `text/template`, `html/template` |
| CLI flags | `flag` |
| SQL | `database/sql` |
| Context | `context` |
| Sync primitives | `sync` |
| Crypto | `crypto/*` |

## When to Add Dependencies

Add a dependency when:
1. **It solves a complex problem well** (e.g., postgres driver)
2. **Stdlib doesn't cover it** (e.g., UUID generation)
3. **Significant effort to reimplement** (e.g., JWT validation)

**Don't add dependencies for:**
- "Nicer" APIs (stdlib is fine)
- Trivial utilities
- Test assertions (stdlib `testing` works)

## Recommended Libraries

**Only when needed:**

| Need | Library |
|------|---------|
| PostgreSQL driver | `github.com/jackc/pgx/v5` |
| MySQL driver | `github.com/go-sql-driver/mysql` |
| Router (if needed) | `github.com/go-chi/chi/v5` |
| UUID | `github.com/google/uuid` |
| Env config | `github.com/kelseyhightower/envconfig` |
| Migrations | `github.com/golang-migrate/migrate/v4` |
| Structured logging | `log/slog` (stdlib) or `go.uber.org/zap` |
| Testing diffs | `github.com/google/go-cmp/cmp` |
| Mocking (if needed) | `go.uber.org/mock` |
| gRPC | `google.golang.org/grpc` |
| Protobuf | `google.golang.org/protobuf` |
| Concurrent helpers | `golang.org/x/sync/errgroup` |

## go.mod Hygiene

```bash
# Add dependency
go get github.com/google/uuid

# Update all dependencies
go get -u ./...

# Update specific dependency
go get -u github.com/google/uuid

# Remove unused dependencies
go mod tidy

# Verify checksums
go mod verify

# See why a dependency exists
go mod why github.com/some/dep
```

## Vendoring

Consider vendoring for:
- Reproducible builds
- Air-gapped environments
- CI/CD reliability

```bash
go mod vendor
go build -mod=vendor ./...
```

## Security

```bash
# Check for vulnerabilities
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Run in CI
govulncheck -json ./... | jq .
```

## Version Pinning

In `go.mod`, versions are pinned automatically. Don't manually edit versions unless necessary.

```go
module myapp

go 1.22

require (
    github.com/google/uuid v1.6.0
    github.com/jackc/pgx/v5 v5.5.0
)
```

## Red Flags

Avoid libraries that:
- Haven't been updated in 2+ years (abandoned)
- Have many open security issues
- Pull in excessive transitive dependencies
- Require `replace` directives to work
- Use `unsafe` without good reason

## Check Before Adding

```bash
# See what you're pulling in
go mod graph | grep newdep

# Check transitive dependencies
go list -m all | wc -l  # Total dependency count
```
