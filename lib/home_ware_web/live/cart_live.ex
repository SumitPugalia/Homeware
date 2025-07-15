defmodule HomeWareWeb.CartLive do
  use HomeWareWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Get cart items from session or database
    cart_items = []
    total = calculate_total(cart_items)

    {:ok,
     assign(socket,
       cart_items: cart_items,
       total: total,
       shipping: 0,
       tax: 0
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow">
        <div class="max-w-14xl mx-auto px-4 sm:px-6 lg:px-8">
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
      <!-- Cart Content -->
      <div class="bg-white">
        <div class="max-w-14xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
          <h1 class="text-3xl font-bold text-gray-900 mb-8">Shopping Cart</h1>

          <%= if Enum.empty?(@cart_items) do %>
            <!-- Empty Cart -->
            <div class="text-center py-12">
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m6 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">Your cart is empty</h3>
              <p class="mt-1 text-sm text-gray-500">Start shopping to add items to your cart.</p>
              <div class="mt-6">
                <a
                  href="/products"
                  class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                >
                  Continue Shopping
                </a>
              </div>
            </div>
          <% else %>
            <div class="lg:grid lg:grid-cols-12 lg:gap-x-12 lg:items-start">
              <!-- Cart Items -->
              <div class="lg:col-span-8">
                <div class="border-t border-gray-200 divide-y divide-gray-200">
                  <%= for item <- @cart_items do %>
                    <div class="py-6 flex">
                      <div class="flex-shrink-0 w-24 h-24">
                        <img
                          src="https://via.placeholder.com/96x96"
                          alt={item.product.name}
                          class="w-full h-full object-center object-cover rounded-md"
                        />
                      </div>

                      <div class="ml-4 flex-1 flex flex-col">
                        <div>
                          <div class="flex justify-between text-base font-medium text-gray-900">
                            <h3>
                              <a href={~p"/products/#{item.product.id}"}><%= item.product.name %></a>
                            </h3>
                            <p class="ml-4">$<%= item.product.price * item.quantity %></p>
                          </div>
                          <p class="mt-1 text-sm text-gray-500"><%= item.product.brand %></p>
                        </div>
                        <div class="flex-1 flex items-end justify-between text-sm">
                          <div class="flex items-center">
                            <label for="quantity" class="mr-2 text-gray-500">Qty</label>
                            <select
                              id="quantity"
                              phx-change="update_quantity"
                              phx-value-product-id={item.product.id}
                              class="rounded-md border-gray-300 py-1 px-2 text-base leading-5 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                            >
                              <%= for qty <- 1..10 do %>
                                <option value={qty} selected={qty == item.quantity}>
                                  <%= qty %>
                                </option>
                              <% end %>
                            </select>
                          </div>

                          <div class="flex">
                            <button
                              phx-click="remove_item"
                              phx-value-product-id={item.product.id}
                              type="button"
                              class="font-medium text-indigo-600 hover:text-indigo-500"
                            >
                              Remove
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
              <!-- Order Summary -->
              <div class="mt-16 lg:mt-0 lg:col-span-4">
                <div class="bg-gray-50 rounded-lg px-4 py-6 sm:p-6 lg:p-8">
                  <h2 class="text-lg font-medium text-gray-900">Order Summary</h2>

                  <dl class="mt-6 space-y-4">
                    <div class="flex items-center justify-between">
                      <dt class="text-sm text-gray-600">Subtotal</dt>
                      <dd class="text-sm font-medium text-gray-900">$<%= @total %></dd>
                    </div>
                    <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                      <dt class="text-sm text-gray-600">Shipping</dt>
                      <dd class="text-sm font-medium text-gray-900">$<%= @shipping %></dd>
                    </div>
                    <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                      <dt class="text-sm text-gray-600">Tax</dt>
                      <dd class="text-sm font-medium text-gray-900">$<%= @tax %></dd>
                    </div>
                    <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                      <dt class="text-base font-medium text-gray-900">Total</dt>
                      <dd class="text-base font-medium text-gray-900">
                        $<%= @total + @shipping + @tax %>
                      </dd>
                    </div>
                  </dl>

                  <div class="mt-6">
                    <a
                      href="/checkout"
                      class="w-full bg-indigo-600 border border-transparent rounded-md shadow-sm py-3 px-4 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Proceed to Checkout
                    </a>
                  </div>

                  <div class="mt-6 flex justify-center text-sm text-center text-gray-500">
                    <p>
                      or
                      <a
                        href="/products"
                        class="text-indigo-600 font-medium text-indigo-500 hover:text-indigo-500"
                      >
                        Continue Shopping
                      </a>
                    </p>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("update_quantity", %{"product-id" => _product_id, "value" => quantity}, socket) do
    _quantity = String.to_integer(quantity)
    # TODO: Update cart item quantity
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_item", %{"product-id" => _product_id}, socket) do
    # TODO: Remove item from cart
    {:noreply, socket}
  end

  defp calculate_total(cart_items) do
    Enum.reduce(cart_items, 0, fn item, acc ->
      acc + item.product.price * item.quantity
    end)
  end
end
