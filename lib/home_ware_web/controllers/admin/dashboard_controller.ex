defmodule HomeWareWeb.Admin.DashboardController do
  use HomeWareWeb, :controller

  alias HomeWare.Orders
  alias HomeWare.Products

  def index(conn, _params) do
    # Order stats
    total_orders = Orders.count_orders()
    active_orders = Orders.count_orders_by_status("active")
    completed_orders = Orders.count_orders_by_status("completed")
    return_orders = Orders.count_orders_by_status("returned")

    # Best sellers (top 3 products by sales count)
    best_sellers = Products.top_selling_products(3)

    # Recent orders (last 6)
    recent_orders = Orders.list_recent_orders(6)

    # Sale graph data (monthly sales for last year)
    sale_graph_data = Orders.monthly_sales_data(12)

    render(conn, "index.html",
      total_orders: total_orders,
      active_orders: active_orders,
      completed_orders: completed_orders,
      return_orders: return_orders,
      best_sellers: best_sellers,
      recent_orders: recent_orders,
      sale_graph_data: sale_graph_data
    )
  end
end
