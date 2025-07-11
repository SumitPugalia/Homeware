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
    |> order_by([o], [desc: o.inserted_at])
    |> Repo.all()
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
end
