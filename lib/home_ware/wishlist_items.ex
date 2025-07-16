defmodule HomeWare.WishlistItems do
  @moduledoc """
  The WishlistItems context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.WishlistItem
  alias HomeWare.Products

  def list_user_wishlist_items(user_id) do
    WishlistItem
    |> where(user_id: ^user_id)
    |> preload(:product)
    |> Repo.all()
    |> Enum.map(fn wishlist_item ->
      # Set availability for the product
      product_with_availability = Products.set_availability(wishlist_item.product)
      %{wishlist_item | product: product_with_availability}
    end)
  end

  def get_user_wishlist_count(user_id) do
    WishlistItem
    |> where(user_id: ^user_id)
    |> select([wi], count(wi.id))
    |> Repo.one()
    |> case do
      nil -> 0
      count -> count
    end
  end

  def add_to_wishlist(user_id, product_id) do
    %WishlistItem{}
    |> WishlistItem.changeset(%{user_id: user_id, product_id: product_id})
    |> Repo.insert()
  end

  def remove_from_wishlist(user_id, product_id) do
    WishlistItem
    |> where(user_id: ^user_id, product_id: ^product_id)
    |> Repo.delete_all()
    |> case do
      {1, _} -> {:ok, :deleted}
      {0, _} -> {:error, :not_found}
    end
  end

  def is_in_wishlist?(user_id, product_id) do
    WishlistItem
    |> where(user_id: ^user_id, product_id: ^product_id)
    |> Repo.exists?()
  end

  def get_wishlist_item!(id), do: Repo.get!(WishlistItem, id)

  def create_wishlist_item(attrs \\ %{}) do
    %WishlistItem{}
    |> WishlistItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_wishlist_item(%WishlistItem{} = wishlist_item, attrs) do
    wishlist_item
    |> WishlistItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_wishlist_item(%WishlistItem{} = wishlist_item) do
    Repo.delete(wishlist_item)
  end

  def change_wishlist_item(%WishlistItem{} = wishlist_item, attrs \\ %{}) do
    WishlistItem.changeset(wishlist_item, attrs)
  end
end
