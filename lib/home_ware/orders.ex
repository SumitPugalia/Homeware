defmodule HomeWare.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Orders.Order

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
        join: p in assoc(o, :product),
        join: u in assoc(o, :user),
        order_by: [desc: o.inserted_at],
        limit: ^n,
        select: %{
          id: o.id,
          product_name: p.name,
          date: o.inserted_at,
          customer_name: u.first_name,
          status: o.status,
          amount: o.total
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
end
