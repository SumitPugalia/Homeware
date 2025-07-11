defmodule HomeWareWeb.OrderController do
  use HomeWareWeb, :controller

  alias HomeWare.Orders

  def index(conn, _params) do
    user = conn.assigns.current_user
    orders = Orders.list_user_orders(user.id)
    render(conn, :index, orders: orders)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    order = Orders.get_user_order!(user.id, id)
    render(conn, :show, order: order)
  end
end
