# Security Checklist

## Authentication

```ruby
# Use has_secure_password or Devise
class User < ApplicationRecord
  has_secure_password

  # Token generation
  def generate_auth_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless User.exists?(auth_token: token)
    end
  end
end
```

## Authorization

```ruby
# Always scope queries to current user

# BAD - allows access to any order
@order = Order.find(params[:id])

# GOOD - scoped to user
@order = current_user.orders.find(params[:id])
```

## Strong Parameters

```ruby
# ALWAYS whitelist params
def order_params
  params.require(:order).permit(:address_id, items: [:product_id, :qty])
end

# NEVER do this
params.permit!
```

## SQL Injection Prevention

```ruby
# BAD - SQL injection vulnerability
User.where("email = '#{params[:email]}'")

# GOOD - parameterized
User.where(email: params[:email])
User.where("email = ?", params[:email])
```

## Mass Assignment

```ruby
# Use attr_readonly for sensitive fields
class User < ApplicationRecord
  attr_readonly :role, :email_verified_at
end
```

## CSRF Protection

```ruby
# Enabled by default in ApplicationController
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# Skip only for API with proper token auth
class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_token!
end
```

## Content Security

```erb
<%# Sanitize user input for HTML output %>
<%= sanitize(user_content) %>

<%# Or use Rails auto-escaping (default) %>
<%= user_content %>  <%# Already escaped %>
```

## Secrets Management

```ruby
# NEVER commit secrets
# Use Rails credentials
Rails.application.credentials.stripe[:secret_key]

# Or environment variables
ENV.fetch("STRIPE_SECRET_KEY")
```

## HTTPS

```ruby
# config/environments/production.rb
config.force_ssl = true
```

## Headers

```ruby
# config/initializers/secure_headers.rb
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
end
```

## Rate Limiting

```ruby
# config/initializers/rack_attack.rb

Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == "/login" && req.post?
end

Rack::Attack.throttle("logins/email", limit: 5, period: 1.minute) do |req|
  if req.path == "/login" && req.post?
    req.params.dig("user", "email")&.downcase
  end
end
```

## Dependency Scanning

```bash
# Run regularly in CI
bundle audit check --update   # Gem vulnerabilities
bin/brakeman                  # Static analysis
```

## Checklist Before Deploy

- [ ] Strong params on all controllers
- [ ] Queries scoped to current user
- [ ] No raw SQL with user input
- [ ] CSRF protection enabled
- [ ] Force SSL in production
- [ ] Secrets in credentials/env only
- [ ] Brakeman passing
- [ ] Bundle audit passing
- [ ] Rate limiting configured
