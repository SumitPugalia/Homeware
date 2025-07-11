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
end
