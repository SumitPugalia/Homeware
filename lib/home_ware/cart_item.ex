defmodule HomeWare.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cart_items" do
    field :quantity, :integer
    field :session_id, :string

    belongs_to :user, HomeWare.Accounts.User
    belongs_to :product, HomeWare.Products.Product
    belongs_to :product_variant, HomeWare.Products.ProductVariant

    timestamps(type: :utc_datetime)
  end

  def changeset(cart_item, attrs) do
    cart_item
    |> cast(attrs, [:quantity, :session_id, :user_id, :product_id, :product_variant_id])
    |> validate_required([:quantity, :user_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
  end
end
