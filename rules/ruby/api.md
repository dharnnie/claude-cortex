# API Design

## Controller Structure

```ruby
# app/controllers/api/v1/orders_controller.rb

module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate!
      before_action :set_order, only: [:show, :update, :destroy]

      def index
        orders = Orders::FilteredQuery.new(current_user.orders)
          .call(filter_params)
          .page(params[:page])
          .per(25)

        render json: OrderSerializer.new(orders, meta: pagination(orders))
      end

      def show
        render json: OrderSerializer.new(@order, include: [:line_items])
      end

      def create
        result = Orders::CreateService.call(order_params, current_user)

        if result.success?
          render json: OrderSerializer.new(result.order), status: :created
        else
          render_errors(result.errors)
        end
      end

      private

      def set_order
        @order = current_user.orders.find(params[:id])
      end

      def order_params
        params.require(:order).permit(:address_id, items: [:product_id, :qty])
      end

      def filter_params
        params.permit(:status, :from, :to, :sort)
      end
    end
  end
end
```

## Base Controller

```ruby
# app/controllers/api/v1/base_controller.rb

module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Backend

      skip_before_action :verify_authenticity_token
      before_action :set_default_format

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def set_default_format
        request.format = :json
      end

      def render_errors(errors, status: :unprocessable_entity)
        render json: { errors: Array(errors) }, status: status
      end

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def pagination(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
```

## Serializers (jsonapi-serializer)

```ruby
# app/serializers/order_serializer.rb

class OrderSerializer
  include JSONAPI::Serializer

  attributes :status, :total_cents, :placed_at

  attribute :total_formatted do |order|
    "$#{(order.total_cents / 100.0).round(2)}"
  end

  belongs_to :user
  has_many :line_items

  meta do |order|
    { cancelable: order.cancelable? }
  end
end
```

## Response Format

```json
{
  "data": {
    "id": "123",
    "type": "order",
    "attributes": {
      "status": "pending",
      "total_cents": 5000,
      "total_formatted": "$50.00"
    },
    "relationships": {
      "user": { "data": { "id": "1", "type": "user" } }
    }
  },
  "meta": {
    "cancelable": true
  }
}
```

## Error Response Format

```json
{
  "errors": [
    {
      "field": "email",
      "message": "has already been taken"
    }
  ]
}
```

## Versioning

- Use path versioning: `/api/v1/`, `/api/v2/`
- Keep controllers in versioned modules
- Deprecate old versions gradually

## Pagination

Always paginate collections:

```ruby
# Using Pagy (recommended)
pagy, orders = pagy(Order.all, items: 25)

# Using Kaminari
Order.page(params[:page]).per(25)
```

## Rate Limiting

```ruby
# config/initializers/rack_attack.rb

Rack::Attack.throttle("api/ip", limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api/")
end
```
