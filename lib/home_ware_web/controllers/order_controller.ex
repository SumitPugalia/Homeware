defmodule HomeWareWeb.OrderController do
  use HomeWareWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end

  def show(conn, %{"id" => id}) do
    render(conn, :show, order_id: id)
  end
end
