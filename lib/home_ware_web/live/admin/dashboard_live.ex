defmodule HomeWareWeb.Admin.DashboardLive do
  use Phoenix.LiveView,
    layout: {HomeWareWeb.Layouts, :admin}

  use HomeWareWeb, :verified_routes

  alias HomeWare.Orders
  alias HomeWare.Products
  alias HomeWare.Accounts

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    token = session["user_token"]
    user = HomeWare.Accounts.get_user_by_session_token(token)

    if connected?(socket) do
      # Set up periodic updates every 30 seconds
      :timer.send_interval(30_000, self(), :update_stats)
    end

    {:ok,
     socket
     |> assign(:current_user, user)
     |> assign(:theme, "light")
     |> assign_stats()}
  end

  @impl Phoenix.LiveView
  def handle_info(:update_stats, socket) do
    {:noreply, assign_stats(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("refresh", _params, socket) do
    {:noreply, assign_stats(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_theme", _params, socket) do
    new_theme = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, :theme, new_theme)}
  end

  defp assign_stats(socket) do
    # Product stats
    total_products = Products.count_products()

    # Order stats
    total_orders = Orders.count_orders()
    active_orders = Orders.count_orders_by_status(:pending)
    completed_orders = Orders.count_orders_by_status(:delivered)
    return_orders = Orders.count_orders_by_status(:cancelled)

    # Customer stats
    total_customers = Accounts.count_customers()
    total_revenue = Orders.calculate_total_revenue()

    # Best sellers (top 3 products by sales count)
    best_sellers = Products.top_selling_products(3)

    # Recent orders (last 6)
    recent_orders = Orders.list_recent_orders(6)

    # Monthly sales data for chart
    monthly_sales = Orders.monthly_sales_data(6)

    socket
    |> assign(:total_products, total_products)
    |> assign(:total_orders, total_orders)
    |> assign(:active_orders, active_orders)
    |> assign(:completed_orders, completed_orders)
    |> assign(:return_orders, return_orders)
    |> assign(:total_customers, total_customers)
    |> assign(:total_revenue, total_revenue)
    |> assign(:best_sellers, best_sellers)
    |> assign(:recent_orders, recent_orders)
    |> assign(:monthly_sales, monthly_sales)
    |> assign(:page_title, "Admin Dashboard")
  end
end
