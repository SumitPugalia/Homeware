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
    with {:ok, product} <- get_product(product_id),
         {:ok, final_variant_id} <- select_variant_if_needed(product, variant_id),
         {:ok, _variant} <- validate_variant(final_variant_id),
         {:ok, cart_item} <-
           find_or_create_cart_item(user_id, product_id, final_variant_id, quantity) do
      {:ok, cart_item}
    else
      {:error, :product_not_found} ->
        {:error, :product_not_found}

      {:error, :variant_not_found} ->
        {:error, :variant_not_found}

      {:error, :no_available_variants} ->
        {:error, :no_available_variants}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper functions for the with clause
  defp get_product(product_id) do
    case Repo.get(Product, product_id) do
      nil -> {:error, :product_not_found}
      product -> {:ok, product}
    end
  end

  defp select_variant_if_needed(_product, variant_id) when not is_nil(variant_id) do
    {:ok, variant_id}
  end

  defp select_variant_if_needed(product, nil) do
    variants = HomeWare.Products.list_product_variants(product.id)
    available_variants = Enum.filter(variants, & &1.available?)

    case available_variants do
      [] -> {:ok, nil}
      variants -> {:ok, Enum.random(variants).id}
    end
  end

  defp validate_variant(nil), do: {:ok, nil}

  defp validate_variant(variant_id) do
    case Repo.get(ProductVariant, variant_id) do
      nil -> {:error, :variant_not_found}
      variant -> {:ok, variant}
    end
  end

  defp find_or_create_cart_item(user_id, product_id, variant_id, quantity) do
    base_query =
      from ci in CartItem,
        where: ci.user_id == ^user_id and ci.product_id == ^product_id

    query = maybe_variant_id_filter(base_query, variant_id)
    cart_items = Repo.all(query)

    cart_item =
      if is_nil(variant_id) do
        # Find cart item without variant (product_variant_id is nil)
        List.first(cart_items)
      else
        # Find cart item with specific variant
        Enum.find(cart_items, fn item -> item.product_variant_id == variant_id end)
      end

    case cart_item do
      nil ->
        # Create new cart item
        create_cart_item(%{
          user_id: user_id,
          product_id: product_id,
          product_variant_id: variant_id,
          quantity: quantity
        })

      existing_item ->
        # Update existing cart item quantity
        new_quantity = existing_item.quantity + quantity
        update_cart_item(existing_item, %{quantity: new_quantity})
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
