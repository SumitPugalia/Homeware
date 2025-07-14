defmodule HomeWareWeb.AdminOrdersLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Orders
  alias HomeWare.Categories

  @impl true
  def mount(_params, _session, socket) do
    categories = Categories.list_categories()

    sidebar_categories =
      Enum.map(categories, fn cat -> %{name: cat.name, count: Map.get(cat, :product_count, 0)} end)

    orders = Orders.list_orders_with_users()

    {:ok,
     assign(socket,
       orders: orders,
       filters: %{},
       sort_by: "created_at",
       page: 1,
       per_page: 20,
       sidebar_categories: sidebar_categories
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <.admin_sidebar current="orders" categories={@sidebar_categories} />
      <main class="flex-1 bg-[#f9f9f9] p-8">
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
                    <div class="text-sm text-gray-500"><%= order.user.email %></div>
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
        <!-- Pagination (unchanged) -->
        <%= if length(@orders) > @per_page do %>
          <div class="mt-8 flex justify-center">
            <nav class="flex items-center space-x-2">
              <%= if @page > 1 do %>
                <a href="#" class="px-3 py-2 text-gray-500 hover:text-gray-700">
                  Previous
                </a>
              <% end %>
              <span class="px-3 py-2 text-gray-700">
                Page <%= @page %> of <%= ceil(length(@orders) / @per_page) %>
              </span>
              <%= if @page < ceil(length(@orders) / @per_page) do %>
                <a href="#" class="px-3 py-2 text-gray-500 hover:text-gray-700">
                  Next
                </a>
              <% end %>
            </nav>
          </div>
        <% end %>
      </main>
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
