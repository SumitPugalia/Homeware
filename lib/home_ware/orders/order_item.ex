defmodule HomeWare.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_items" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :total_price, :decimal
    field :product_name, :string
    field :product_sku, :string

    belongs_to :order, HomeWare.Orders.Order
    belongs_to :product, HomeWare.Products.Product

    timestamps()
  end

  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :unit_price, :total_price, :product_name, :product_sku, :order_id, :product_id])
    |> validate_required([:quantity, :unit_price, :total_price, :product_name, :order_id, :product_id])
  end
end
