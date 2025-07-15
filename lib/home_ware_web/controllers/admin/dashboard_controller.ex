defmodule HomeWareWeb.Admin.DashboardController do
  use HomeWareWeb, :admin_controller

  alias HomeWare.Orders
  alias HomeWare.Products

  def index(conn, _params) do
    # Product stats
    total_products = Products.count_products()

    # Order stats
    total_orders = Orders.count_orders()
    active_orders = Orders.count_orders_by_status(:pending)
    completed_orders = Orders.count_orders_by_status(:delivered)
    return_orders = Orders.count_orders_by_status(:cancelled)

    # Customer stats (stub for now)
    total_customers = 0
    total_revenue = 0

    # Best sellers (top 3 products by sales count)
    best_sellers = Products.top_selling_products(3)

    # Recent orders (last 6)
    recent_orders = Orders.list_recent_orders(6)

    # Sale graph data (monthly sales for last year)
    sale_graph_data = Orders.monthly_sales_data(12)

    render(conn, "index.html",
      total_products: total_products,
      total_orders: total_orders,
      total_customers: total_customers,
      total_revenue: total_revenue,
      active_orders: active_orders,
      completed_orders: completed_orders,
      return_orders: return_orders,
      best_sellers: best_sellers,
      recent_orders: recent_orders,
      sale_graph_data: sale_graph_data,
      current_path: conn.request_path
    )
  end
end
