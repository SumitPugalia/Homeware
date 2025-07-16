defmodule HomeWareWeb.OrderController do
  use HomeWareWeb, :controller

  alias HomeWare.Orders

  def index(conn, _params) do
    user = conn.assigns.current_user
    orders = Orders.list_user_orders(user.id)

    # Preload order items for each order to get item count
    orders_with_items =
      Enum.map(orders, fn order ->
        order_with_items = Orders.get_order_with_details!(order.id)
        item_count = length(order_with_items.order_items)
        Map.put(order_with_items, :item_count, item_count)
      end)

    render(conn, :index, orders: orders_with_items)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    try do
      order = Orders.get_user_order!(user.id, id)
      order_with_details = Orders.get_order_with_details!(order.id)
      render(conn, :show, order: order_with_details)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Order not found")
        |> redirect(to: ~p"/orders")
    end
  end
end
