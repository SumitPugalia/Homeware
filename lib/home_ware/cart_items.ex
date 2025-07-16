defmodule HomeWare.CartItems do
  @moduledoc """
  The CartItems context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.CartItem
  alias HomeWare.Products.Product
  alias HomeWare.Products.ProductVariant

  def list_user_cart_items(user_id) do
    CartItem
    |> where(user_id: ^user_id)
    |> preload(:product)
    |> preload(:product_variant)
    |> Repo.all()
    |> Enum.map(fn cart_item ->
      # Set availability for the product
      product_with_availability = HomeWare.Products.set_availability(cart_item.product)

      # Set availability for the variant if it exists
      variant_with_availability =
        if cart_item.product_variant do
          HomeWare.Products.ProductVariant.set_availability(cart_item.product_variant)
        else
          nil
        end

      %{
        cart_item
        | product: product_with_availability,
          product_variant: variant_with_availability
      }
    end)
  end

  def get_user_cart_count(user_id) do
    CartItem
    |> where(user_id: ^user_id)
    |> select([ci], sum(ci.quantity))
    |> Repo.one()
    |> case do
      nil -> 0
      count -> count
    end
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

  @doc """
  Adds a product (with optional variant) to the user's cart. If a cart item for the same user/product/variant exists, increments quantity.
  """
  def add_to_cart(user_id, product_id, variant_id, quantity)
      when is_binary(user_id) and is_binary(product_id) do
    base_query =
      from ci in CartItem,
        where: ci.user_id == ^user_id and ci.product_id == ^product_id

    query = maybe_variant_id_filter(base_query, variant_id)

    with cart_item <- Repo.one(query),
         {:product, _product} <- {:product, Repo.get(Product, product_id)},
         {:variant, _variant} <-
           {:variant, if(variant_id, do: Repo.get(ProductVariant, variant_id), else: nil)} do
      cond do
        is_nil(cart_item) ->
          create_cart_item(%{
            user_id: user_id,
            product_id: product_id,
            product_variant_id: variant_id,
            quantity: quantity
          })

        true ->
          new_quantity = cart_item.quantity + quantity
          update_cart_item(cart_item, %{quantity: new_quantity})
      end
    else
      {:product, nil} ->
        {:error, :product_not_found}

      {:variant, nil} when not is_nil(variant_id) ->
        {:error, :variant_not_found}
    end
  end

  defp maybe_variant_id_filter(query, nil), do: query

  defp maybe_variant_id_filter(query, variant_id) do
    query |> where([ci], ci.product_variant_id == ^variant_id)
  end

  @doc """
  Gets the total quantity of all items in a user's cart.
  """
  def get_user_cart_total_quantity(user_id) do
    CartItem
    |> where(user_id: ^user_id)
    |> select([ci], sum(ci.quantity))
    |> Repo.one() || 0
  end
end
