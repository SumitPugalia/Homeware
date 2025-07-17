defmodule HomeWareWeb.Admin.OrderController do
  use HomeWareWeb, :admin_controller
  require Logger

  alias HomeWare.Orders

  @per_page 20

  def index(conn, params) do
    page = params["page"] |> to_int() |> max(1)
    status_filter = params["status"]
    search_query = params["search"]
    start_date = params["start_date"]
    end_date = params["end_date"]

    # Build query with filters
    orders =
      Orders.list_all_orders_with_filters(%{
        page: page,
        per_page: @per_page,
        status: status_filter,
        search: search_query,
        start_date: start_date,
        end_date: end_date
      })

    total_entries =
      Orders.count_all_orders_with_filters(%{
        status: status_filter,
        search: search_query,
        start_date: start_date,
        end_date: end_date
      })

    total_pages = ceil(total_entries / @per_page)

    # Get order statistics
    stats = %{
      total: Orders.count_orders(),
      pending: Orders.count_orders_by_status("pending"),
      paid: Orders.count_orders_by_status("paid"),
      shipped: Orders.count_orders_by_status("shipped"),
      delivered: Orders.count_orders_by_status("delivered"),
      cancelled: Orders.count_orders_by_status("cancelled")
    }

    render(conn, "index.html",
      orders: orders,
      stats: stats,
      page: page,
      total_pages: total_pages,
      total_entries: total_entries,
      per_page: @per_page,
      current_path: conn.request_path,
      status_filter: status_filter,
      search_query: search_query,
      start_date: start_date,
      end_date: end_date
    )
  end

  def show(conn, %{"id" => id}) do
    try do
      order = Orders.get_order_with_details!(id)

      render(conn, "show.html",
        order: order,
        current_path: conn.request_path
      )
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Order not found")
        |> redirect(to: ~p"/admin/orders")
    end
  end

  def update_status(conn, %{"id" => id, "status" => status}) do
    order = Orders.get_order!(id)

    case Orders.update_order(order, %{status: status}) do
      {:ok, _updated_order} ->
        conn
        |> put_flash(:info, "Order status updated to #{status}")
        |> redirect(to: ~p"/admin/orders/#{id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update order status")
        |> redirect(to: ~p"/admin/orders/#{id}")
    end
  end

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 1
    end
  end

  defp to_int(_), do: 1
end
