defmodule HomeWareWeb.AdminOrdersLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Orders

  @impl true
  def mount(_params, _session, socket) do
    orders = Orders.list_orders_with_users()

    {:ok,
     assign(socket,
       orders: orders,
       filters: %{},
       sort_by: "created_at",
       page: 1,
       per_page: 20
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex">
              <div class="flex-shrink-0 flex items-center">
                <a href="/" class="text-xl font-bold text-gray-900">HomeWare</a>
              </div>
            </div>
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <a href="/cart" class="relative p-2 text-gray-400 hover:text-gray-500">
                  <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m6 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                    />
                  </svg>
                </a>
              </div>
              <div class="ml-4 flex items-center md:ml-6">
                <%= if @current_user do %>
                  <div class="ml-3 relative">
                    <div class="flex items-center">
                      <span class="text-sm text-gray-700 mr-4">
                        Welcome, <%= @current_user.first_name %>
                      </span>
                      <a href="/profile" class="text-sm text-gray-700 hover:text-gray-900 mr-4">
                        Profile
                      </a>
                      <a href="/orders" class="text-sm text-gray-700 hover:text-gray-900 mr-4">
                        Orders
                      </a>
                      <form action="/users/log_out" method="post" class="inline">
                        <button type="submit" class="text-sm text-gray-700 hover:text-gray-900">
                          Logout
                        </button>
                      </form>
                    </div>
                  </div>
                <% else %>
                  <div class="flex items-center space-x-4">
                    <a href="/users/log_in" class="text-sm text-gray-700 hover:text-gray-900">
                      Sign in
                    </a>
                    <a
                      href="/users/register"
                      class="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700"
                    >
                      Sign up
                    </a>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </nav>
      <!-- Admin Header -->
      <div class="bg-white border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between py-4">
            <h1 class="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
            <nav class="flex space-x-4">
              <a href="/admin/dashboard" class="text-gray-500 hover:text-gray-700">Dashboard</a>
              <a href="/admin/products" class="text-gray-500 hover:text-gray-700">Products</a>
              <a href="/admin/categories" class="text-gray-500 hover:text-gray-700">Categories</a>
              <a href="/admin/orders" class="text-indigo-600 font-medium">Orders</a>
              <a href="/admin/users" class="text-gray-500 hover:text-gray-700">Users</a>
            </nav>
          </div>
        </div>
      </div>
      <!-- Content -->
      <div class="max-w-7xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center mb-8">
          <h2 class="text-3xl font-bold text-gray-900">Orders</h2>
          <div class="flex items-center space-x-4">
            <select
              phx-change="filter_by_status"
              class="rounded-md border-gray-300 py-1 px-2 text-sm focus:border-indigo-500 focus:ring-indigo-500"
            >
              <option value="">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="processing">Processing</option>
              <option value="shipped">Shipped</option>
              <option value="delivered">Delivered</option>
              <option value="cancelled">Cancelled</option>
            </select>
            <select
              phx-change="sort_orders"
              class="rounded-md border-gray-300 py-1 px-2 text-sm focus:border-indigo-500 focus:ring-indigo-500"
            >
              <option value="created_at" selected={@sort_by == "created_at"}>Date Created</option>
              <option value="total_amount" selected={@sort_by == "total_amount"}>Total Amount</option>
              <option value="status" selected={@sort_by == "status"}>Status</option>
            </select>
          </div>
        </div>
        <!-- Orders Table -->
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Order ID
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Customer
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Total
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for order <- @orders do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    #<%= order.order_number %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm text-gray-900">
                      <%= order.user.first_name %> <%= order.user.last_name %>
                    </div>
                    <div class="text-sm text-gray-500">
                      <%= order.user.email %>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <%= Calendar.strftime(order.inserted_at, "%B %d, %Y") %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    $<%= order.total_amount %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={
                      case order.status do
                        "pending" ->
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800"

                        "processing" ->
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800"

                        "shipped" ->
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-800"

                        "delivered" ->
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800"

                        "cancelled" ->
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800"

                        _ ->
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800"
                      end
                    }>
                      <%= String.capitalize(order.status) %>
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <!-- <a
                      href={~p"/admin/orders/#{order.id}"}
                      class="text-indigo-600 hover:text-indigo-900 mr-3"
                    >
                      View
                    </a> -->
                    <button
                      phx-click="update_status"
                      phx-value-id={order.id}
                      class="text-gray-600 hover:text-gray-900"
                    >
                      Update Status
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        <!-- Pagination -->
        <%= if length(@orders) > @per_page do %>
          <div class="mt-8 flex justify-center">
            <nav class="flex items-center space-x-2">
              <%= if @page > 1 do %>
                <a
                  href={~p"/admin/orders?page=#{@page - 1}"}
                  class="px-3 py-2 text-gray-500 hover:text-gray-700"
                >
                  Previous
                </a>
              <% end %>

              <span class="px-3 py-2 text-gray-700">
                Page <%= @page %> of <%= ceil(length(@orders) / @per_page) %>
              </span>

              <%= if @page < ceil(length(@orders) / @per_page) do %>
                <a
                  href={~p"/admin/orders?page=#{@page + 1}"}
                  class="px-3 py-2 text-gray-500 hover:text-gray-700"
                >
                  Next
                </a>
              <% end %>
            </nav>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("filter_by_status", %{"value" => _status}, socket) do
    # TODO: Filter orders by status
    {:noreply, socket}
  end

  @impl true
  def handle_event("sort_orders", %{"value" => sort_by}, socket) do
    # TODO: Sort orders
    {:noreply, assign(socket, sort_by: sort_by)}
  end

  @impl true
  def handle_event("update_status", %{"id" => _order_id}, socket) do
    # TODO: Show status update modal
    {:noreply, socket}
  end
end
