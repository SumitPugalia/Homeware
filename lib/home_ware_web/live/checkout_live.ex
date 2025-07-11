defmodule HomeWareWeb.CheckoutLive do
  use HomeWareWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Get cart items and user from session
    cart_items = []
    total = calculate_total(cart_items)
    shipping = calculate_shipping(cart_items)
    tax = calculate_tax(total + shipping)

    {:ok,
     assign(socket,
       cart_items: cart_items,
       total: total,
       shipping: shipping,
       tax: tax,
       step: 1,
       shipping_address: %{},
       billing_address: %{},
       payment_method: "credit_card"
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
      <!-- Checkout Progress -->
      <div class="bg-white border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-center py-4">
            <div class="flex items-center">
              <div class={if @step >= 1, do: "bg-indigo-600", else: "bg-gray-200"}>
                <span class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white">
                  1
                </span>
              </div>
              <div
                class={if @step >= 1, do: "text-indigo-600", else: "text-gray-400"}
                class="ml-2 text-sm font-medium"
              >
                Shipping
              </div>
            </div>
            <div class="flex items-center ml-8">
              <div class={if @step >= 2, do: "bg-indigo-600", else: "bg-gray-200"}>
                <span class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white">
                  2
                </span>
              </div>
              <div
                class={if @step >= 2, do: "text-indigo-600", else: "text-gray-400"}
                class="ml-2 text-sm font-medium"
              >
                Payment
              </div>
            </div>
            <div class="flex items-center ml-8">
              <div class={if @step >= 3, do: "bg-indigo-600", else: "bg-gray-200"}>
                <span class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white">
                  3
                </span>
              </div>
              <div
                class={if @step >= 3, do: "text-indigo-600", else: "text-gray-400"}
                class="ml-2 text-sm font-medium"
              >
                Review
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Checkout Content -->
      <div class="bg-white">
        <div class="max-w-7xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
          <div class="lg:grid lg:grid-cols-12 lg:gap-x-12 lg:items-start">
            <!-- Main Content -->
            <div class="lg:col-span-8">
              <%= if @step == 1 do %>
                <!-- Shipping Information -->
                <div>
                  <h2 class="text-2xl font-bold text-gray-900 mb-6">Shipping Information</h2>

                  <form phx-submit="save_shipping" class="space-y-6">
                    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                      <div>
                        <label for="first_name" class="block text-sm font-medium text-gray-700">
                          First Name
                        </label>
                        <input
                          type="text"
                          name="first_name"
                          id="first_name"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        />
                      </div>
                      <div>
                        <label for="last_name" class="block text-sm font-medium text-gray-700">
                          Last Name
                        </label>
                        <input
                          type="text"
                          name="last_name"
                          id="last_name"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        />
                      </div>
                    </div>

                    <div>
                      <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
                      <input
                        type="email"
                        name="email"
                        id="email"
                        required
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      />
                    </div>

                    <div>
                      <label for="phone" class="block text-sm font-medium text-gray-700">Phone</label>
                      <input
                        type="tel"
                        name="phone"
                        id="phone"
                        required
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      />
                    </div>

                    <div>
                      <label for="address" class="block text-sm font-medium text-gray-700">
                        Address
                      </label>
                      <input
                        type="text"
                        name="address"
                        id="address"
                        required
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      />
                    </div>

                    <div class="grid grid-cols-1 gap-6 sm:grid-cols-3">
                      <div>
                        <label for="city" class="block text-sm font-medium text-gray-700">City</label>
                        <input
                          type="text"
                          name="city"
                          id="city"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        />
                      </div>
                      <div>
                        <label for="state" class="block text-sm font-medium text-gray-700">
                          State
                        </label>
                        <select
                          name="state"
                          id="state"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        >
                          <option value="">Select State</option>
                          <option value="NY">New York</option>
                          <option value="CA">California</option>
                          <option value="TX">Texas</option>
                          <option value="FL">Florida</option>
                        </select>
                      </div>
                      <div>
                        <label for="zip" class="block text-sm font-medium text-gray-700">
                          ZIP Code
                        </label>
                        <input
                          type="text"
                          name="zip"
                          id="zip"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        />
                      </div>
                    </div>

                    <div class="flex items-center">
                      <input
                        type="checkbox"
                        name="same_as_shipping"
                        id="same_as_shipping"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                      />
                      <label for="same_as_shipping" class="ml-2 block text-sm text-gray-900">
                        Billing address same as shipping
                      </label>
                    </div>

                    <div class="flex justify-end">
                      <button
                        type="submit"
                        class="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700"
                      >
                        Continue to Payment
                      </button>
                    </div>
                  </form>
                </div>
              <% end %>

              <%= if @step == 2 do %>
                <!-- Payment Information -->
                <div>
                  <h2 class="text-2xl font-bold text-gray-900 mb-6">Payment Information</h2>

                  <form phx-submit="save_payment" class="space-y-6">
                    <div>
                      <label for="card_number" class="block text-sm font-medium text-gray-700">
                        Card Number
                      </label>
                      <input
                        type="text"
                        name="card_number"
                        id="card_number"
                        required
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        placeholder="1234 5678 9012 3456"
                      />
                    </div>

                    <div class="grid grid-cols-1 gap-6 sm:grid-cols-3">
                      <div>
                        <label for="expiry" class="block text-sm font-medium text-gray-700">
                          Expiry Date
                        </label>
                        <input
                          type="text"
                          name="expiry"
                          id="expiry"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                          placeholder="MM/YY"
                        />
                      </div>
                      <div>
                        <label for="cvv" class="block text-sm font-medium text-gray-700">CVV</label>
                        <input
                          type="text"
                          name="cvv"
                          id="cvv"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                          placeholder="123"
                        />
                      </div>
                      <div>
                        <label for="name_on_card" class="block text-sm font-medium text-gray-700">
                          Name on Card
                        </label>
                        <input
                          type="text"
                          name="name_on_card"
                          id="name_on_card"
                          required
                          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        />
                      </div>
                    </div>

                    <div class="flex justify-between">
                      <button
                        type="button"
                        phx-click="back_to_shipping"
                        class="bg-gray-300 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-400"
                      >
                        Back
                      </button>
                      <button
                        type="submit"
                        class="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700"
                      >
                        Continue to Review
                      </button>
                    </div>
                  </form>
                </div>
              <% end %>

              <%= if @step == 3 do %>
                <!-- Order Review -->
                <div>
                  <h2 class="text-2xl font-bold text-gray-900 mb-6">Order Review</h2>

                  <div class="space-y-6">
                    <!-- Shipping Address -->
                    <div>
                      <h3 class="text-lg font-medium text-gray-900 mb-2">Shipping Address</h3>
                      <div class="bg-gray-50 rounded-lg p-4">
                        <p class="text-gray-600">John Doe</p>
                        <p class="text-gray-600">123 Main Street</p>
                        <p class="text-gray-600">New York, NY 10001</p>
                        <p class="text-gray-600">john@example.com</p>
                        <p class="text-gray-600">(555) 123-4567</p>
                      </div>
                    </div>
                    <!-- Payment Method -->
                    <div>
                      <h3 class="text-lg font-medium text-gray-900 mb-2">Payment Method</h3>
                      <div class="bg-gray-50 rounded-lg p-4">
                        <p class="text-gray-600">Visa ending in 1234</p>
                        <p class="text-gray-600">Expires 12/25</p>
                      </div>
                    </div>
                    <!-- Order Items -->
                    <div>
                      <h3 class="text-lg font-medium text-gray-900 mb-2">Order Items</h3>
                      <div class="border-t border-gray-200 divide-y divide-gray-200">
                        <%= for item <- @cart_items do %>
                          <div class="py-4 flex">
                            <div class="flex-shrink-0 w-16 h-16">
                              <img
                                src="https://via.placeholder.com/64x64"
                                alt={item.product.name}
                                class="w-full h-full object-center object-cover rounded-md"
                              />
                            </div>
                            <div class="ml-4 flex-1">
                              <h4 class="text-sm font-medium text-gray-900">
                                <%= item.product.name %>
                              </h4>
                              <p class="text-sm text-gray-500">Qty: <%= item.quantity %></p>
                              <p class="text-sm font-medium text-gray-900">
                                $<%= item.product.price * item.quantity %>
                              </p>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>

                    <div class="flex justify-between">
                      <button
                        type="button"
                        phx-click="back_to_payment"
                        class="bg-gray-300 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-400"
                      >
                        Back
                      </button>
                      <button
                        phx-click="place_order"
                        class="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700"
                      >
                        Place Order
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
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
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("save_shipping", _params, socket) do
    {:noreply, assign(socket, step: 2)}
  end

  @impl true
  def handle_event("save_payment", _params, socket) do
    {:noreply, assign(socket, step: 3)}
  end

  @impl true
  def handle_event("back_to_shipping", _params, socket) do
    {:noreply, assign(socket, step: 1)}
  end

  @impl true
  def handle_event("back_to_payment", _params, socket) do
    {:noreply, assign(socket, step: 2)}
  end

  @impl true
  def handle_event("place_order", _params, socket) do
    # TODO: Create order and redirect to confirmation
    {:noreply, redirect(socket, to: ~p"/orders/confirmation")}
  end

  defp calculate_total(cart_items) do
    Enum.reduce(cart_items, 0, fn item, acc ->
      acc + item.product.price * item.quantity
    end)
  end

  defp calculate_shipping(cart_items) do
    # Simple shipping calculation
    if Enum.empty?(cart_items), do: 0, else: 9.99
  end

  defp calculate_tax(subtotal) do
    # Simple tax calculation (8.875% for NY)
    subtotal * 0.08875
  end
end
