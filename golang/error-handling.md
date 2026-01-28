---
paths:
  - "**/*.go"
---

# Go Error Handling

## Core Principles

1. **Always handle errors.** Never ignore them with `_`.
2. **Add context when wrapping.** Say what operation failed.
3. **Handle errors once.** Either handle it or return it, not both.
4. **Errors are values.** Use them, don't panic.

## The Basics

```go
// BAD - ignoring error
data, _ := ioutil.ReadFile("config.json")

// BAD - no context
if err != nil {
    return err
}

// GOOD - wrap with context
data, err := os.ReadFile("config.json")
if err != nil {
    return fmt.Errorf("read config: %w", err)
}
```

## Wrapping Errors

Use `fmt.Errorf` with `%w` to wrap errors. This preserves the error chain.

```go
func LoadUser(id string) (*User, error) {
    row := db.QueryRow("SELECT * FROM users WHERE id = $1", id)

    var u User
    if err := row.Scan(&u.ID, &u.Name, &u.Email); err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("scan user %s: %w", id, err)
    }

    return &u, nil
}
```

**Context format:** `"<operation>: %w"` or `"<operation> <detail>: %w"`

```go
// Good context messages
fmt.Errorf("connect to database: %w", err)
fmt.Errorf("parse config file %s: %w", path, err)
fmt.Errorf("create user %s: %w", email, err)
```

## Sentinel Errors

Define package-level errors for conditions callers need to check.

```go
package user

import "errors"

var (
    ErrNotFound      = errors.New("user not found")
    ErrAlreadyExists = errors.New("user already exists")
    ErrInvalidEmail  = errors.New("invalid email format")
)
```

**Callers check with `errors.Is`:**

```go
user, err := userService.Get(id)
if errors.Is(err, user.ErrNotFound) {
    return c.JSON(404, map[string]string{"error": "user not found"})
}
if err != nil {
    return fmt.Errorf("get user: %w", err)
}
```

## Custom Error Types

Use when you need to carry additional data.

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("%s: %s", e.Field, e.Message)
}

// Usage
func ValidateUser(u *User) error {
    if u.Email == "" {
        return &ValidationError{Field: "email", Message: "required"}
    }
    return nil
}

// Caller extracts details with errors.As
var valErr *ValidationError
if errors.As(err, &valErr) {
    log.Printf("validation failed on field: %s", valErr.Field)
}
```

## Error Handling in HTTP Handlers

Handle errors at the boundary. Log internal details, return safe messages.

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")

    user, err := h.service.Get(r.Context(), id)
    if errors.Is(err, service.ErrNotFound) {
        http.Error(w, "user not found", http.StatusNotFound)
        return
    }
    if err != nil {
        h.logger.Error("get user failed", "id", id, "error", err)
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(user)
}
```

## Don't

```go
// DON'T panic for expected errors
if err != nil {
    panic(err)  // Only for truly unrecoverable programmer errors
}

// DON'T log and return (handles error twice)
if err != nil {
    log.Printf("error: %v", err)
    return err  // Caller might also log it
}

// DON'T use string matching
if err.Error() == "user not found" {  // Fragile
    // ...
}

// DON'T wrap with %v (loses error chain)
return fmt.Errorf("failed: %v", err)  // Use %w
```

## Error Handling Patterns

**Early return (guard clauses):**

```go
func Process(data []byte) error {
    if len(data) == 0 {
        return errors.New("empty data")
    }

    parsed, err := parse(data)
    if err != nil {
        return fmt.Errorf("parse: %w", err)
    }

    if err := validate(parsed); err != nil {
        return fmt.Errorf("validate: %w", err)
    }

    return save(parsed)
}
```

**Deferred cleanup with error capture:**

```go
func WriteFile(path string, data []byte) (err error) {
    f, err := os.Create(path)
    if err != nil {
        return fmt.Errorf("create file: %w", err)
    }
    defer func() {
        if cerr := f.Close(); cerr != nil && err == nil {
            err = fmt.Errorf("close file: %w", cerr)
        }
    }()

    if _, err := f.Write(data); err != nil {
        return fmt.Errorf("write: %w", err)
    }

    return nil
}
```
