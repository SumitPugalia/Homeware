defmodule HomeWare.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Orders.Order
  alias Decimal

  def list_user_orders(user_id) do
    Order
    |> where(user_id: ^user_id)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  def list_orders_for_user(user_id, params \\ %{}) do
    page = params["page"] || 1
    per_page = params["per_page"] || 10

    Order
    |> where(user_id: ^user_id)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.paginate(%{page: page, per_page: per_page})
  end

  def get_user_order!(user_id, id) do
    Order
    |> where(user_id: ^user_id, id: ^id)
    |> Repo.one!()
  end

  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def create_order_with_user(user_id, attrs \\ %{}) do
    %Order{}
    |> Order.changeset(Map.put(attrs, :user_id, user_id))
    |> Repo.insert()
  end

  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def create_order_item(attrs \\ %{}) do
    %HomeWare.Orders.OrderItem{}
    |> HomeWare.Orders.OrderItem.changeset(attrs)
    |> Repo.insert()
  end

  def list_orders_with_users do
    Order
    |> preload(:user)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  def get_order_with_details!(id) do
    Order
    |> Repo.get_by!(id: id)
    |> Repo.preload([
      :user,
      :shipping_address,
      :billing_address,
      :product_reviews,
      order_items: [:product]
    ])
  end

  def count_orders do
    alias HomeWare.Orders.Order
    HomeWare.Repo.one(from o in Order, select: count(o.id))
  end

  def count_orders_by_status(status) do
    alias HomeWare.Orders.Order
    HomeWare.Repo.one(from o in Order, where: o.status == ^status, select: count(o.id))
  end

  def list_recent_orders(n) do
    query =
      from o in Order,
        join: u in assoc(o, :user),
        order_by: [desc: o.inserted_at],
        limit: ^n,
        select: %{
          id: o.id,
          # Since orders can have multiple items
          product_name: "Multiple Products",
          date: o.inserted_at,
          customer_name: u.first_name,
          status: o.status,
          amount: o.total_amount
        }

    HomeWare.Repo.all(query)
  end

  def monthly_sales_data(n) do
    alias HomeWare.Orders.Order
    now = Date.utc_today()
    months = Enum.map(0..(n - 1), fn i -> Date.add(now, -30 * i) end)
    # This is a stub, you may want to use fragment for real month grouping
    Enum.map(months, fn date -> {Date.to_string(date), Enum.random(1000..5000)} end)
  end

  @doc """
  Calculates the subtotal for a list of cart items.
  """
  def calculate_subtotal(cart_items) do
    cart_items
    |> Enum.reduce(Decimal.new("0"), fn item, acc ->
      price = get_item_price(item)
      item_total = Decimal.mult(price, Decimal.new(Integer.to_string(item.quantity)))
      Decimal.add(acc, item_total)
    end)
  end

  @doc """
  Calculates shipping cost based on cart items.
  """
  def calculate_shipping(cart_items) do
    # Simple shipping calculation - can be made more sophisticated
    case length(cart_items) do
      0 -> Decimal.new("0")
      # Flat rate shipping
      _ -> Decimal.new("10.00")
    end
  end

  @doc """
  Calculates tax based on subtotal plus shipping.
  """
  def calculate_tax(subtotal_plus_shipping) do
    # 8.875% tax rate
    Decimal.mult(subtotal_plus_shipping, Decimal.new("0.08875"))
  end

  @doc """
  Calculates the complete order totals including subtotal, shipping, tax, and grand total.
  """
  def calculate_order_totals(cart_items) do
    subtotal = calculate_subtotal(cart_items)
    shipping = calculate_shipping(cart_items)
    total_plus_shipping = Decimal.add(subtotal, shipping)
    tax = calculate_tax(total_plus_shipping)
    grand_total = Decimal.add(total_plus_shipping, tax)

    %{
      subtotal: subtotal,
      shipping: shipping,
      tax: tax,
      grand_total: grand_total
    }
  end

  @doc """
  Removes out-of-stock items from cart and returns available items.
  """
  def filter_available_items(cart_items) do
    Enum.split_with(cart_items, fn item ->
      if item.product_variant do
        item.product_variant.available?
      else
        item.product.available?
      end
    end)
  end

  @doc """
  Creates a formatted message for removed out-of-stock items.
  """
  def format_removed_items_message(out_of_stock_items) do
    if length(out_of_stock_items) > 0 do
      removed_count = length(out_of_stock_items)

      removed_names =
        Enum.map_join(out_of_stock_items, ", ", fn item ->
          variant_name =
            if item.product_variant, do: " (#{item.product_variant.option_name})", else: ""

          "#{item.product.name}#{variant_name}"
        end)

      "#{removed_count} item(s) removed from cart: #{removed_names} - no longer available"
    else
      nil
    end
  end

  # Private helper functions

  defp get_item_price(%{product_variant: variant, product: product}) when not is_nil(variant) do
    # If price_override is nil, fall back to product selling_price
    if is_nil(variant.price_override) do
      product.selling_price
    else
      variant.price_override
    end
  end

  defp get_item_price(%{product: product}) do
    product.selling_price
  end
end
