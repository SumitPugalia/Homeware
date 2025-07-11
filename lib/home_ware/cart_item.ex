defmodule HomeWare.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1
    field :session_id, :string

    belongs_to :user, HomeWare.Accounts.User
    belongs_to :product, HomeWare.Products.Product

    timestamps()
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :session_id, :user_id, :product_id])
    |> validate_required([:quantity, :session_id, :product_id])
  end
end
