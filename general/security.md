# Security Guidelines

## Core Principles

1. **Never trust user input.** Validate and sanitize everything.
2. **Principle of least privilege.** Grant minimum required access.
3. **Defense in depth.** Multiple layers of security.
4. **Fail securely.** Errors should not expose sensitive data.

## Secrets Management

### Never Commit Secrets

```bash
# Add to .gitignore
.env
.env.*
*.pem
*.key
credentials.json
secrets/
```

### Store Secrets Properly

| Environment | Method |
|-------------|--------|
| Local dev | `.env` file (gitignored) |
| CI/CD | Pipeline secrets / vault |
| Production | Secrets manager (AWS SM, Vault, etc.) |

### Rotate Compromised Secrets Immediately

If a secret is ever committed:
1. Rotate the secret immediately
2. Remove from git history (if possible)
3. Audit for unauthorized access
4. Add to `.gitignore`

## Input Validation

### Validate at System Boundaries

```
User Input → [VALIDATE] → Application → [VALIDATE] → Database
External API → [VALIDATE] → Application
```

### Common Validations

- **Length limits** - Prevent DoS via large payloads
- **Type checking** - Ensure expected data types
- **Format validation** - Email, URL, UUID patterns
- **Range checking** - Numbers within expected bounds
- **Allowlists** - Prefer over denylists

## SQL Injection Prevention

### Always Use Parameterized Queries

```go
// BAD - SQL injection vulnerability
query := "SELECT * FROM users WHERE id = " + userID

// GOOD - Parameterized
query := "SELECT * FROM users WHERE id = $1"
db.Query(query, userID)
```

```ruby
# BAD
User.where("email = '#{params[:email]}'")

# GOOD
User.where(email: params[:email])
```

## Authentication

### Password Requirements

- Minimum 12 characters
- No maximum length (within reason)
- Allow all characters
- Check against breached password lists

### Session Security

- Use secure, httpOnly cookies
- Regenerate session ID on login
- Implement session timeout
- Provide logout functionality

### API Authentication

- Use short-lived tokens (JWTs: 15-60 min)
- Implement refresh token rotation
- Validate tokens on every request
- Revoke tokens on logout/password change

## Authorization

### Always Check Permissions

```go
// BAD - No authorization check
func GetOrder(orderID string) *Order {
    return db.FindOrder(orderID)
}

// GOOD - Scoped to user
func GetOrder(userID, orderID string) *Order {
    return db.FindOrderForUser(userID, orderID)
}
```

### Principle of Least Privilege

- Grant minimum required permissions
- Use role-based access control (RBAC)
- Audit permission changes
- Review permissions regularly

## HTTPS/TLS

### Always Use HTTPS in Production

- Redirect HTTP to HTTPS
- Use TLS 1.2+ only
- Enable HSTS header

### Certificate Management

- Use automated certificate renewal (Let's Encrypt)
- Monitor certificate expiration
- Pin certificates in mobile apps (carefully)

## Security Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

## Logging

### Do Log

- Authentication attempts (success/failure)
- Authorization failures
- Input validation failures
- Security-relevant events

### Never Log

- Passwords (even hashed)
- API keys or tokens
- Credit card numbers
- Social security numbers
- Personal health information

### Log Format

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "warn",
  "event": "auth_failure",
  "user_id": "123",
  "ip": "192.168.1.1",
  "reason": "invalid_password"
}
```

## Rate Limiting

Implement rate limiting for:
- Login attempts (5/minute per IP)
- Password reset requests
- API endpoints
- Resource-intensive operations

## Dependency Security

```bash
# Check for vulnerabilities regularly
# Go
govulncheck ./...

# Node
npm audit

# Ruby
bundle audit check --update

# Python
pip-audit
```

## Error Handling

### Don't Expose Internal Details

```go
// BAD - Exposes internal structure
return fmt.Errorf("query failed: %v", err)

// GOOD - Generic message, log details
log.Error("query failed", "error", err, "query", query)
return errors.New("internal error")
```

### Production Error Responses

```json
{
  "error": "An error occurred",
  "request_id": "abc123"
}
```

Never expose:
- Stack traces
- SQL queries
- File paths
- Internal IPs

## Security Checklist

Before deploying:

- [ ] All user input validated
- [ ] Parameterized queries used
- [ ] Authentication implemented correctly
- [ ] Authorization checks on all endpoints
- [ ] HTTPS enforced
- [ ] Security headers set
- [ ] Secrets not in code
- [ ] Dependencies scanned for vulnerabilities
- [ ] Rate limiting configured
- [ ] Logging configured (without secrets)
- [ ] Error messages don't leak details
