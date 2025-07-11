defmodule HomeWareWeb.AdminDashboardLive do
  use HomeWareWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       total_products: 0,
       total_users: 0,
       total_orders: 0,
       recent_orders: [],
       top_products: []
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_stats", _params, socket) do
    # TODO: Implement refresh stats
    {:noreply, socket}
  end
end
