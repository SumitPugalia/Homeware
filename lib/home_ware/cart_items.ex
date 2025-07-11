defmodule HomeWare.CartItems do
  @moduledoc """
  The CartItems context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.CartItem

  def list_user_cart_items(user_id) do
    CartItem
    |> where(user_id: ^user_id)
    |> preload(:product)
    |> Repo.all()
  end

  def get_cart_item!(id), do: Repo.get!(CartItem, id)

  def create_cart_item(attrs \\ %{}) do
    %CartItem{}
    |> CartItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_cart_item(%CartItem{} = cart_item, attrs) do
    cart_item
    |> CartItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_cart_item(%CartItem{} = cart_item) do
    Repo.delete(cart_item)
  end

  def change_cart_item(%CartItem{} = cart_item, attrs \\ %{}) do
    CartItem.changeset(cart_item, attrs)
  end

  def clear_user_cart(user_id) do
    CartItem
    |> where(user_id: ^user_id)
    |> Repo.delete_all()
  end
end
