defmodule HomeWare.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :total_price, :decimal
    field :notes, :string

    belongs_to :user, HomeWare.Accounts.User
    belongs_to :product, HomeWare.Products.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :unit_price, :total_price, :notes, :user_id, :product_id])
    |> validate_required([:quantity, :unit_price, :total_price, :user_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price, greater_than: 0)
    |> validate_number(:total_price, greater_than: 0)
  end
end
