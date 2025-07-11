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
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
        <div class="flex space-x-4">
          <a
            href={~p"/admin/products"}
            class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
          >
            Manage Products
          </a>
          <button
            phx-click="refresh_stats"
            class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
          >
            Refresh Stats
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-gray-700">Total Products</h3>
          <p class="text-3xl font-bold text-blue-600"><%= @total_products %></p>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-gray-700">Total Users</h3>
          <p class="text-3xl font-bold text-green-600"><%= @total_users %></p>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-gray-700">Total Orders</h3>
          <p class="text-3xl font-bold text-purple-600"><%= @total_orders %></p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-xl font-semibold text-gray-900 mb-4">Recent Orders</h3>
          <%= if Enum.empty?(@recent_orders) do %>
            <p class="text-gray-500">No recent orders</p>
          <% else %>
            <div class="space-y-3">
              <%= for order <- @recent_orders do %>
                <div class="border-b border-gray-200 pb-3">
                  <p class="font-medium">Order #<%= order.id %></p>
                  <p class="text-sm text-gray-600"><%= order.status %></p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-xl font-semibold text-gray-900 mb-4">Top Products</h3>
          <%= if Enum.empty?(@top_products) do %>
            <p class="text-gray-500">No products available</p>
          <% else %>
            <div class="space-y-3">
              <%= for product <- @top_products do %>
                <div class="border-b border-gray-200 pb-3">
                  <p class="font-medium"><%= product.name %></p>
                  <p class="text-sm text-gray-600">$<%= product.price %></p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
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
