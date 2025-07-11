defmodule HomeWare.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "order_items" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :total_price, :decimal
    field :notes, :string

    belongs_to :order, HomeWare.Orders.Order
    belongs_to :product, HomeWare.Products.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :unit_price, :total_price, :notes, :order_id, :product_id])
    |> validate_required([:quantity, :unit_price, :total_price, :order_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than: 0)
    |> validate_number(:total_price, greater_than: 0)
  end
end
