---
paths:
  - "**/*.go"
---

# Go Style Guide

## Formatting

Run `gofmt` or `goimports` on every save. Non-negotiable.

```bash
gofmt -w .
goimports -w .  # Also manages imports
```

## Naming

**Packages:** lowercase, single word, no underscores.

```go
package user      // Good
package userauth  // Good
package user_auth // Bad
package userAuth  // Bad
```

**Variables:** short, contextual. Longer scope = longer name.

```go
// Short scope - short names
for i, v := range items { }
if err != nil { return err }

// Longer scope - descriptive names
userRepository := postgres.NewUserRepository(db)
maxRetryAttempts := 3
```

**Common abbreviations:**

| Short | Meaning |
|-------|---------|
| `ctx` | context.Context |
| `err` | error |
| `db`  | database |
| `tx`  | transaction |
| `req` | request |
| `resp`| response |
| `cfg` | config |
| `srv` | server |
| `msg` | message |
| `buf` | buffer |
| `i, j, k` | loop indices |
| `n`   | count |
| `ok`  | boolean (comma-ok idiom) |

**Receivers:** one or two letters, consistent across methods.

```go
func (u *User) FullName() string { }   // Good
func (user *User) FullName() string { } // Verbose but acceptable
func (this *User) FullName() string { } // Bad - not Go style
```

**Interfaces:** verb + "er" suffix for single-method interfaces.

```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type Stringer interface { String() string }

// Multi-method: describe the capability
type UserRepository interface {
    Get(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, u *User) error
}
```

**Exported names:** clear without package prefix.

```go
// Package user
type User struct { }     // user.User - Good
type UserStruct struct { } // user.UserStruct - Redundant

// Package http
type Client struct { }   // http.Client - Good
type HTTPClient struct { } // http.HTTPClient - Redundant
```

## Function Signatures

**Context first, options last.**

```go
func CreateUser(ctx context.Context, name string, opts ...Option) (*User, error)
```

**Return errors last.**

```go
func (s *Service) Get(ctx context.Context, id string) (*User, error)
```

**Accept interfaces, return concrete types.**

```go
// Accept interface - flexible for callers
func Process(r io.Reader) error

// Return concrete - callers know what they get
func NewBuffer() *bytes.Buffer
```

## Comments

**Package comments:** one sentence starting with "Package".

```go
// Package user provides user management functionality.
package user
```

**Exported symbols:** one sentence starting with the name.

```go
// ErrNotFound is returned when a user cannot be found.
var ErrNotFound = errors.New("user not found")

// User represents a registered user in the system.
type User struct { }

// FullName returns the user's full name.
func (u *User) FullName() string { }
```

**Don't comment obvious code.**

```go
// BAD - states the obvious
// Increment counter by 1
counter++

// GOOD - explains why
// Rate limit: allow max 100 requests per minute
if counter > 100 {
    return ErrRateLimited
}
```

## Struct Field Order

1. Exported fields first
2. Grouped by purpose
3. Most important first

```go
type Server struct {
    // Configuration
    Addr    string
    Handler http.Handler

    // Internal state
    mu       sync.Mutex
    started  bool
    shutdown chan struct{}
}
```

## Imports

Grouped and sorted by `goimports`:

```go
import (
    // Standard library
    "context"
    "fmt"
    "net/http"

    // Third-party
    "github.com/gorilla/mux"
    "go.uber.org/zap"

    // Internal
    "myapp/internal/config"
    "myapp/internal/user"
)
```

## Constants

```go
// Related constants in a block
const (
    StatusPending   = "pending"
    StatusActive    = "active"
    StatusInactive  = "inactive"
)

// iota for sequential values
const (
    Sunday = iota  // 0
    Monday         // 1
    Tuesday        // 2
)

// iota with expressions
const (
    KB = 1 << (10 * iota)  // 1024
    MB                      // 1048576
    GB                      // 1073741824
)
```

## Zero Values

Leverage zero values - they're part of Go's design.

```go
// Zero value is useful
var buf bytes.Buffer  // Ready to use, no make() needed
buf.WriteString("hello")

var mu sync.Mutex  // Ready to use
mu.Lock()

// Struct with useful zero values
type Config struct {
    Timeout time.Duration  // Zero means "use default"
    Retries int            // Zero means "no retries"
}

func (c *Config) timeout() time.Duration {
    if c.Timeout == 0 {
        return 30 * time.Second  // Default
    }
    return c.Timeout
}
```

## Avoid

```go
// Avoid naked returns (unclear what's returned)
func split(sum int) (x, y int) {
    x = sum * 4 / 9
    y = sum - x
    return  // Bad - what's returned?
}

// Avoid init() for business logic
func init() {
    db = connectDB()  // Bad - hidden side effect
}

// Avoid package-level variables
var globalDB *sql.DB  // Bad - hidden dependency

// Avoid else after return
if err != nil {
    return err
}
// Continue here, no else needed

// Avoid stuttering
user.UserID       // Bad
user.ID           // Good

config.ConfigPath // Bad
config.Path       // Good
```
