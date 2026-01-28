---
paths:
  - "**/*.go"
  - "**/*_test.go"
---

# Go Testing

## Test File Conventions

- Test files: `*_test.go` in the same package
- Test functions: `func TestXxx(t *testing.T)`
- Use `_test` package suffix for black-box testing when needed

```go
// user_test.go - same package (white-box)
package user

// user_test.go - external package (black-box)
package user_test
```

## Table-Driven Tests

The standard pattern for Go tests. Use it.

```go
func TestParseSize(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int64
        wantErr bool
    }{
        {
            name:  "bytes",
            input: "100",
            want:  100,
        },
        {
            name:  "kilobytes",
            input: "10KB",
            want:  10240,
        },
        {
            name:  "megabytes",
            input: "5MB",
            want:  5242880,
        },
        {
            name:    "invalid",
            input:   "abc",
            wantErr: true,
        },
        {
            name:    "empty",
            input:   "",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseSize(tt.input)

            if tt.wantErr {
                if err == nil {
                    t.Error("expected error, got nil")
                }
                return
            }

            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }

            if got != tt.want {
                t.Errorf("got %d, want %d", got, tt.want)
            }
        })
    }
}
```

## Test Naming

```go
// Function: TestFunctionName
func TestParseConfig(t *testing.T)

// Method: TestType_Method
func TestServer_HandleRequest(t *testing.T)

// Subtests describe the scenario
t.Run("returns error when file not found", func(t *testing.T) { ... })
t.Run("parses valid JSON", func(t *testing.T) { ... })
```

## Assertions

Use standard library. Keep it simple.

```go
// Direct comparison
if got != want {
    t.Errorf("got %v, want %v", got, want)
}

// Error checking
if err == nil {
    t.Fatal("expected error")
}

// Deep equality for structs/slices
if !reflect.DeepEqual(got, want) {
    t.Errorf("got %+v, want %+v", got, want)
}

// For better diffs, use cmp package
if diff := cmp.Diff(want, got); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

## Test Helpers

Mark helpers with `t.Helper()` so failures report the correct line.

```go
func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

func createTestUser(t *testing.T, db *sql.DB) *User {
    t.Helper()
    user := &User{Name: "test", Email: "test@example.com"}
    if err := db.Insert(user); err != nil {
        t.Fatalf("create test user: %v", err)
    }
    return user
}
```

## Mocking with Interfaces

Define interfaces where you need them (consumer side), then mock.

```go
// In service package - define interface for what you need
type UserRepository interface {
    Get(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, u *User) error
}

type Service struct {
    repo UserRepository
}

// In test file - create mock
type mockUserRepo struct {
    getUserFunc func(ctx context.Context, id string) (*User, error)
    saveFunc    func(ctx context.Context, u *User) error
}

func (m *mockUserRepo) Get(ctx context.Context, id string) (*User, error) {
    return m.getUserFunc(ctx, id)
}

func (m *mockUserRepo) Save(ctx context.Context, u *User) error {
    return m.saveFunc(ctx, u)
}

// Usage in test
func TestService_GetUser(t *testing.T) {
    wantUser := &User{ID: "123", Name: "Alice"}

    repo := &mockUserRepo{
        getUserFunc: func(ctx context.Context, id string) (*User, error) {
            if id == "123" {
                return wantUser, nil
            }
            return nil, ErrNotFound
        },
    }

    svc := NewService(repo)
    got, err := svc.GetUser(context.Background(), "123")

    assertNoError(t, err)
    assertEqual(t, got.Name, wantUser.Name)
}
```

## TestMain for Setup/Teardown

```go
var testDB *sql.DB

func TestMain(m *testing.M) {
    // Setup
    var err error
    testDB, err = sql.Open("postgres", os.Getenv("TEST_DATABASE_URL"))
    if err != nil {
        log.Fatal(err)
    }

    // Run tests
    code := m.Run()

    // Teardown
    testDB.Close()

    os.Exit(code)
}
```

## HTTP Handler Tests

Use `httptest` package.

```go
func TestHandler_GetUser(t *testing.T) {
    // Setup
    svc := &mockService{...}
    h := NewHandler(svc)

    // Create request
    req := httptest.NewRequest("GET", "/users/123", nil)
    rec := httptest.NewRecorder()

    // Execute
    h.GetUser(rec, req)

    // Assert
    if rec.Code != http.StatusOK {
        t.Errorf("status = %d, want %d", rec.Code, http.StatusOK)
    }

    var got User
    json.NewDecoder(rec.Body).Decode(&got)
    if got.ID != "123" {
        t.Errorf("user ID = %s, want 123", got.ID)
    }
}
```

## Running Tests

```bash
go test ./...                    # All tests
go test ./internal/user          # Specific package
go test -v ./...                 # Verbose output
go test -run TestParseSize ./... # Specific test
go test -race ./...              # Race detector
go test -cover ./...             # Coverage
go test -count=1 ./...           # Disable cache
```

## Benchmarks

```go
func BenchmarkParseSize(b *testing.B) {
    for i := 0; i < b.N; i++ {
        ParseSize("10MB")
    }
}

// Run: go test -bench=. ./...
```

## Don't

```go
// DON'T test private functions directly - test through public API
// DON'T use testify/assert for simple checks - stdlib is fine
// DON'T mock everything - real implementations are often simpler
// DON'T test the standard library - focus on your code
// DON'T write tests that depend on order or global state
```
