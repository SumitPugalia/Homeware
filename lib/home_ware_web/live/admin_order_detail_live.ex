defmodule HomeWareWeb.AdminOrderDetailLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Orders
  alias HomeWare.Categories

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order_with_details!(id)
    categories = Categories.list_categories()

    sidebar_categories =
      Enum.map(categories, fn cat -> %{name: cat.name, count: Map.get(cat, :product_count, 0)} end)

    {:ok,
     assign(socket,
       order: order,
       sidebar_categories: sidebar_categories
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <.admin_sidebar current="orders" categories={@sidebar_categories} />
      <main class="flex-1 bg-[#f9f9f9] p-8">
        <!-- Header & Breadcrumbs -->
        <div class="mb-6">
          <h1 class="text-xl font-bold text-gray-900">Orders Details</h1>
          <p class="text-xs text-gray-500">Home &gt; Order List &gt; Order Details</p>
        </div>
        <!-- Order Summary Card -->
        <div class="bg-white rounded-lg shadow p-6 mb-6">
          <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div class="flex items-center gap-4">
              <span class="font-semibold text-gray-700">
                Orders ID: <span class="text-black">#<%= @order.order_number %></span>
              </span>
              <span class={[
                "text-xs px-2 py-1 rounded font-semibold ml-2",
                case @order.status do
                  :pending -> "bg-yellow-100 text-yellow-800"
                  :delivered -> "bg-green-100 text-green-800"
                  :cancelled -> "bg-red-100 text-red-800"
                  _ -> "bg-gray-100 text-gray-800"
                end
              ]}>
                <%= Phoenix.Naming.humanize(@order.status) %>
              </span>
            </div>
            <div class="flex items-center gap-4">
              <div class="flex items-center gap-2 text-gray-500 text-xs">
                <span class="material-icons text-base">calendar_today</span>
                <span><%= Calendar.strftime(@order.inserted_at, "%b %d, %Y") %></span>
                <span>-</span>
                <span><%= Calendar.strftime(@order.updated_at, "%b %d, %Y") %></span>
              </div>
              <select class="border rounded px-2 py-1 text-xs">
                <option>Change Status</option>
                <option value="pending">Pending</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
              <button class="border rounded px-2 py-1 text-xs flex items-center gap-1">
                <span class="material-icons text-base">print</span>
              </button>
              <button class="bg-[#0a3d62] text-white rounded px-4 py-1 text-xs">Save</button>
            </div>
          </div>
        </div>
        <!-- Info Cards Row -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <!-- Customer -->
          <div class="bg-white rounded shadow p-4 flex-1">
            <div class="flex items-center gap-2 mb-2">
              <span class="material-icons text-base">person</span><span class="font-semibold text-xs">Customer</span>
            </div>
            <div class="text-xs text-gray-700">
              Full Name: <%= @order.user.first_name %> <%= @order.user.last_name %>
            </div>
            <div class="text-xs text-gray-700">Email: <%= @order.user.email %></div>
            <div class="text-xs text-gray-700">
              Phone: <%= @order.shipping_address && @order.shipping_address.phone %>
            </div>
            <button class="mt-2 w-full bg-[#0a3d62] text-white rounded text-xs py-1">
              View profile
            </button>
          </div>
          <!-- Order Info -->
          <div class="bg-white rounded shadow p-4 flex-1">
            <div class="flex items-center gap-2 mb-2">
              <span class="material-icons text-base">info</span><span class="font-semibold text-xs">Order Info</span>
            </div>
            <div class="text-xs text-gray-700">Shipping: Next express</div>
            <div class="text-xs text-gray-700">Payment Method: Paypal</div>
            <div class="text-xs text-gray-700">
              Status: <%= Phoenix.Naming.humanize(@order.status) %>
            </div>
            <button class="mt-2 w-full bg-gray-200 text-gray-700 rounded text-xs py-1">
              Download info
            </button>
          </div>
          <!-- Deliver To -->
          <div class="bg-white rounded shadow p-4 flex-1">
            <div class="flex items-center gap-2 mb-2">
              <span class="material-icons text-base">local_shipping</span><span class="font-semibold text-xs">Deliver to</span>
            </div>
            <div class="text-xs text-gray-700">
              Address: <%= @order.shipping_address &&
                [
                  @order.shipping_address.address_line_1,
                  @order.shipping_address.city,
                  @order.shipping_address.state,
                  @order.shipping_address.country
                ]
                |> Enum.reject(&is_nil/1)
                |> Enum.join(", ") %>
            </div>
            <button class="mt-2 w-full bg-[#0a3d62] text-white rounded text-xs py-1">
              View profile
            </button>
          </div>
          <!-- Payment Info -->
          <div class="bg-white rounded shadow p-4 flex-1">
            <div class="flex items-center gap-2 mb-2">
              <span class="material-icons text-base">credit_card</span><span class="font-semibold text-xs">Payment Info</span>
            </div>
            <div class="text-xs text-gray-700">Master Card **** **** 6557</div>
            <div class="text-xs text-gray-700">
              Name: <%= @order.user.first_name %> <%= @order.user.last_name %>
            </div>
            <div class="text-xs text-gray-700">
              Phone: <%= @order.shipping_address && @order.shipping_address.phone %>
            </div>
          </div>
        </div>
        <!-- Note & Payment Info Row -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div class="bg-white rounded shadow p-4 md:col-span-1">
            <div class="font-semibold text-xs mb-2">Note</div>
            <textarea class="w-full border rounded p-2 text-xs" rows="3" placeholder="Type some notes"><%= @order.notes %></textarea>
          </div>
        </div>
        <!-- Products Table -->
        <div class="bg-white rounded-lg shadow p-6 mb-6">
          <div class="font-bold text-base mb-2">Products</div>
          <table class="min-w-full text-xs">
            <thead>
              <tr class="border-b">
                <th class="py-2 text-left font-semibold">Product Name</th>
                <th class="py-2 text-left font-semibold">Order ID</th>
                <th class="py-2 text-left font-semibold">Quantity</th>
                <th class="py-2 text-left font-semibold">Total</th>
              </tr>
            </thead>
            <tbody>
              <%= for item <- @order.order_items do %>
                <tr class="border-b">
                  <td class="py-2 flex items-center gap-2">
                    <div class="w-6 h-6 bg-gray-200 rounded"></div>
                    <span><%= item.product && item.product.name %></span>
                  </td>
                  <td class="py-2">#<%= @order.order_number %></td>
                  <td class="py-2"><%= item.quantity %></td>
                  <td class="py-2">₹<%= item.total_price %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        <!-- Order Summary -->
        <div class="flex flex-col items-end">
          <div class="bg-white rounded-lg shadow p-6 w-full max-w-xs">
            <div class="flex justify-between text-xs mb-2">
              <span>Subtotal</span><span>₹<%= @order.subtotal %></span>
            </div>
            <div class="flex justify-between text-xs mb-2">
              <span>Tax (20%)</span><span>₹<%= @order.tax_amount %></span>
            </div>
            <div class="flex justify-between text-xs mb-2">
              <span>Discount</span><span>₹<%= @order.discount_amount %></span>
            </div>
            <div class="flex justify-between text-xs mb-2">
              <span>Shipping Rate</span><span>₹<%= @order.shipping_amount %></span>
            </div>
            <div class="flex justify-between text-base font-bold mt-4">
              <span>Total</span><span>₹<%= @order.total_amount %></span>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end
end
