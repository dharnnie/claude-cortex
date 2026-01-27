# Service Objects

**Location:** `app/services/`

## When to Use

- Business logic spanning multiple models
- Complex operations with transactions
- External API integrations
- Anything beyond simple CRUD

## Standard Pattern

```ruby
# app/services/orders/create_service.rb

module Orders
  class CreateService
    include Callable  # Adds .call class method

    def initialize(params, user)
      @params = params
      @user = user
    end

    def call
      order = build_order

      ActiveRecord::Base.transaction do
        apply_pricing(order)
        reserve_inventory(order)
        order.save!
      end

      Result.success(order: order)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(order: e.record, errors: e.record.errors)
    rescue InventoryError => e
      Result.failure(errors: [e.message])
    end

    private

    attr_reader :params, :user

    def build_order
      Order.new(params.merge(user: user, status: :pending))
    end

    def apply_pricing(order)
      # pricing logic
    end

    def reserve_inventory(order)
      # inventory logic
    end
  end
end
```

## Callable Concern

```ruby
# app/models/concerns/callable.rb

module Callable
  extend ActiveSupport::Concern

  class_methods do
    def call(...)
      new(...).call
    end
  end
end
```

## Result Object

```ruby
# app/services/result.rb

class Result
  attr_reader :data, :errors

  def initialize(success:, data: {}, errors: [])
    @success = success
    @data = data
    @errors = errors
  end

  def success? = @success
  def failure? = !@success

  def self.success(data = {})
    new(success: true, data: data)
  end

  def self.failure(errors: [], **data)
    new(success: false, data: data, errors: Array(errors))
  end

  def method_missing(name, *)
    data.key?(name) ? data[name] : super
  end

  def respond_to_missing?(name, *)
    data.key?(name) || super
  end
end
```

## Controller Usage

```ruby
class OrdersController < ApplicationController
  def create
    result = Orders::CreateService.call(order_params, current_user)

    if result.success?
      redirect_to result.order, notice: "Order created"
    else
      @order = result.order
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Query Objects

**Location:** `app/queries/`

```ruby
# app/queries/orders/filtered_query.rb

module Orders
  class FilteredQuery
    def initialize(relation = Order.all)
      @relation = relation
    end

    def call(filters)
      @relation
        .then { |r| by_status(r, filters[:status]) }
        .then { |r| by_date_range(r, filters[:from], filters[:to]) }
        .then { |r| sorted(r, filters[:sort]) }
    end

    private

    def by_status(relation, status)
      return relation if status.blank?
      relation.where(status: status)
    end

    def by_date_range(relation, from, to)
      return relation if from.blank? && to.blank?
      relation.where(created_at: from..to)
    end

    def sorted(relation, sort)
      return relation.recent if sort.blank?
      relation.order(sort)
    end
  end
end
```

## Form Objects

**Location:** `app/forms/`

```ruby
# app/forms/registration_form.rb

class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :company_name, :string

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :password, presence: true, length: { minimum: 12 }
  validates :company_name, presence: true

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      company = Company.create!(name: company_name)
      User.create!(email: email, password: password, company: company)
    end
  end
end
```
