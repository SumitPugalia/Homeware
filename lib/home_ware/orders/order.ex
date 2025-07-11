defmodule HomeWare.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending paid shipped delivered cancelled)a

  schema "orders" do
    field :order_number, :string
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :subtotal, :decimal
    field :tax_amount, :decimal
    field :shipping_amount, :decimal
    field :discount_amount, :decimal
    field :total_amount, :decimal
    field :currency, :string, default: "USD"
    field :notes, :string
    field :tracking_number, :string
    field :shipped_at, :naive_datetime
    field :delivered_at, :naive_datetime
    field :cancelled_at, :naive_datetime
    field :cancellation_reason, :string

    belongs_to :user, HomeWare.Accounts.User
    belongs_to :shipping_address, HomeWare.Address
    belongs_to :billing_address, HomeWare.Address
    has_many :order_items, HomeWare.Orders.OrderItem
    has_many :product_reviews, HomeWare.ProductReview

    timestamps(type: :utc_datetime)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :order_number,
      :status,
      :subtotal,
      :tax_amount,
      :shipping_amount,
      :discount_amount,
      :total_amount,
      :currency,
      :notes,
      :tracking_number,
      :shipped_at,
      :delivered_at,
      :cancelled_at,
      :cancellation_reason,
      :user_id,
      :shipping_address_id,
      :billing_address_id
    ])
    |> validate_required([
      :order_number,
      :status,
      :subtotal,
      :total_amount,
      :currency,
      :user_id,
      :shipping_address_id,
      :billing_address_id
    ])
    |> unique_constraint(:order_number)
    |> validate_inclusion(:status, @statuses)
  end
end
