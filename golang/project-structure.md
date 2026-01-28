---
paths:
  - "**/*.go"
  - "go.mod"
  - "go.sum"
---

# Go Project Structure

## Standard Layout

```
project/
├── cmd/                    # Entry points (main packages)
│   └── myapp/
│       └── main.go         # Minimal - parse flags, call run()
├── internal/               # Private packages (not importable)
│   ├── domain/             # Core business types
│   ├── service/            # Business logic
│   ├── repository/         # Data access
│   ├── handler/            # HTTP/gRPC handlers
│   └── config/             # Configuration loading
├── pkg/                    # Public packages (importable by others)
├── api/                    # API definitions (OpenAPI, proto)
├── migrations/             # Database migrations
├── scripts/                # Build/dev scripts
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

## Package Design Principles

**One purpose per package.** A package should do one thing well.

```go
// BAD - mixed concerns
package utils  // What does this do? Everything.

// GOOD - clear purpose
package auth      // Authentication
package invoice   // Invoice generation
package postgres  // PostgreSQL repository
```

**Name by what it provides, not what it contains.**

```go
// BAD
package models
package controllers
package helpers

// GOOD
package user       // User domain
package http       // HTTP transport
package postgres   // PostgreSQL implementation
```

**Avoid package-level state.** No `init()` for business logic, no global variables.

```go
// BAD
var db *sql.DB  // Global state

func init() {
    db, _ = sql.Open(...)  // Hidden initialization
}

// GOOD
type Service struct {
    db *sql.DB
}

func NewService(db *sql.DB) *Service {
    return &Service{db: db}
}
```

## cmd/main.go Pattern

Keep main.go minimal. Its only job: wire dependencies and start the app.

```go
package main

func main() {
    if err := run(); err != nil {
        fmt.Fprintf(os.Stderr, "error: %v\n", err)
        os.Exit(1)
    }
}

func run() error {
    cfg, err := config.Load()
    if err != nil {
        return fmt.Errorf("load config: %w", err)
    }

    db, err := postgres.Connect(cfg.DatabaseURL)
    if err != nil {
        return fmt.Errorf("connect db: %w", err)
    }
    defer db.Close()

    svc := service.New(db)
    srv := handler.NewServer(svc)

    return srv.ListenAndServe(cfg.Port)
}
```

## internal/ vs pkg/

| Directory | When to use |
|-----------|-------------|
| `internal/` | Default choice. Private to this module. |
| `pkg/` | Only if other projects WILL import it. Rare. |

**When in doubt, use `internal/`.** You can always move to `pkg/` later.

## Dependency Injection

Pass dependencies explicitly. No service locators, no DI frameworks.

```go
// Dependencies flow down through constructors
func main() {
    db := postgres.Connect(...)
    cache := redis.Connect(...)

    userRepo := postgres.NewUserRepository(db)
    userCache := redis.NewUserCache(cache)
    userService := service.NewUserService(userRepo, userCache)
    userHandler := handler.NewUserHandler(userService)

    router.Handle("/users", userHandler)
}
```

## File Organization

**One file per major type** in domain packages:

```
internal/user/
├── user.go           # User type, core methods
├── repository.go     # Repository interface
├── service.go        # UserService
└── service_test.go   # Tests
```

**Group by feature, not by layer** when it makes sense:

```
// GOOD for larger apps
internal/
├── user/
│   ├── handler.go
│   ├── service.go
│   └── repository.go
├── order/
│   ├── handler.go
│   ├── service.go
│   └── repository.go
```
