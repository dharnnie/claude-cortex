---
paths:
  - "**/*.go"
---

# Go Concurrency

## Core Principles

1. **Don't communicate by sharing memory; share memory by communicating.**
2. **Start goroutines only when you have a clear shutdown plan.**
3. **Use `context.Context` for cancellation and timeouts.**
4. **Run `go test -race` to catch data races.**

## Goroutine Lifecycle

Every goroutine must have a defined way to stop.

```go
// BAD - goroutine leaks forever
func StartWorker() {
    go func() {
        for {
            doWork()  // Never stops
        }
    }()
}

// GOOD - context controls lifecycle
func StartWorker(ctx context.Context) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return
            default:
                doWork()
            }
        }
    }()
}
```

## Context Usage

Pass `context.Context` as the first parameter.

```go
func GetUser(ctx context.Context, id string) (*User, error) {
    // Check if already cancelled
    if err := ctx.Err(); err != nil {
        return nil, err
    }

    // Pass to downstream calls
    row := db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", id)
    // ...
}
```

**Creating contexts:**

```go
// With timeout
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()

// With cancellation
ctx, cancel := context.WithCancel(ctx)
defer cancel()

// With value (sparingly - for request-scoped data only)
ctx = context.WithValue(ctx, requestIDKey, reqID)
```

## Channels

**Use channels for coordination, not data storage.**

```go
// Signal completion (empty struct uses no memory)
done := make(chan struct{})
go func() {
    doWork()
    close(done)  // Signal completion
}()
<-done

// Fan-out work
jobs := make(chan Job, 100)  // Buffered for throughput
for i := 0; i < numWorkers; i++ {
    go worker(jobs)
}

// Collect results
results := make(chan Result)
go func() {
    for _, job := range jobs {
        results <- process(job)
    }
    close(results)
}()
```

**Channel directions in function signatures:**

```go
// Send-only
func producer(out chan<- int) {
    out <- 42
}

// Receive-only
func consumer(in <-chan int) {
    val := <-in
}
```

## sync.WaitGroup

Coordinate multiple goroutines.

```go
func ProcessAll(items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            if err := process(item); err != nil {
                errCh <- err
            }
        }(item)  // Pass item to avoid closure capture bug
    }

    wg.Wait()
    close(errCh)

    // Return first error
    for err := range errCh {
        if err != nil {
            return err
        }
    }
    return nil
}
```

## sync.Mutex

Protect shared state.

```go
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}

func (c *Counter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.value
}

// Use RWMutex when reads are frequent
type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}

func (c *Cache) Set(key string, item Item) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = item
}
```

## sync.Once

Initialize once, safely.

```go
type Client struct {
    once     sync.Once
    conn     *Connection
    connErr  error
}

func (c *Client) getConn() (*Connection, error) {
    c.once.Do(func() {
        c.conn, c.connErr = connect()
    })
    return c.conn, c.connErr
}
```

## errgroup for Concurrent Operations

```go
import "golang.org/x/sync/errgroup"

func FetchAll(ctx context.Context, urls []string) ([]Response, error) {
    g, ctx := errgroup.WithContext(ctx)
    responses := make([]Response, len(urls))

    for i, url := range urls {
        i, url := i, url  // Capture loop variables
        g.Go(func() error {
            resp, err := fetch(ctx, url)
            if err != nil {
                return err
            }
            responses[i] = resp
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }

    return responses, nil
}
```

## Worker Pool Pattern

```go
func WorkerPool(ctx context.Context, jobs <-chan Job, numWorkers int) <-chan Result {
    results := make(chan Result)

    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for {
                select {
                case <-ctx.Done():
                    return
                case job, ok := <-jobs:
                    if !ok {
                        return
                    }
                    results <- process(job)
                }
            }
        }()
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}
```

## Common Mistakes

```go
// BAD - closure captures loop variable
for _, item := range items {
    go func() {
        process(item)  // All goroutines see last item!
    }()
}

// GOOD - pass as parameter
for _, item := range items {
    go func(item Item) {
        process(item)
    }(item)
}

// BAD - reading and writing without sync
go func() { counter++ }()  // Data race
fmt.Println(counter)

// BAD - forgetting to close channels
jobs := make(chan Job)
// ... sender never closes
for job := range jobs {  // Blocks forever
    process(job)
}

// BAD - sending on closed channel (panics)
close(ch)
ch <- value  // panic!
```

## Race Detector

Always run tests with race detector in CI.

```bash
go test -race ./...
go build -race ./cmd/myapp  # For debugging
```
