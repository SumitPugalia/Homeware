defmodule HomeWare.WishlistItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "wishlist_items" do
    belongs_to :user, HomeWare.Accounts.User
    belongs_to :product, HomeWare.Products.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(wishlist_item, attrs) do
    wishlist_item
    |> cast(attrs, [:user_id, :product_id])
    |> validate_required([:user_id, :product_id])
    |> unique_constraint([:user_id, :product_id], name: :wishlist_items_user_product_unique_index)
  end
end
