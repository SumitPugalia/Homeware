defmodule HomeWareWeb.CheckoutLive do
  use HomeWareWeb, :live_view

  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  alias HomeWare.CartItems
  alias HomeWare.Addresses

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    addresses = Addresses.list_user_addresses(user.id)

    total = calculate_subtotal(cart_items)
    shipping = calculate_shipping(cart_items)
    total_plus_shipping = Decimal.add(total, shipping)
    tax = calculate_tax(total_plus_shipping)
    grand_total = Decimal.add(total_plus_shipping, tax)

    {:ok,
     assign(socket,
       cart_items: cart_items,
       addresses: addresses,
       total: total,
       shipping: shipping,
       tax: tax,
       grand_total: grand_total,
       cart_count: CartItems.get_user_cart_count(user.id),
       step: 1,
       selected_shipping_address_id: nil,
       selected_billing_address_id: nil,
       payment_method: "credit_card",
       order_summary: %{}
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Checkout Progress -->
      <div class="bg-white border-b border-gray-200">
        <div class="max-w-14xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-center py-4">
            <div class="flex items-center">
              <div class={if @step >= 1, do: "bg-indigo-600", else: "bg-gray-200"}>
                <span class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white">
                  1
                </span>
              </div>
              <div class={
                if @step >= 1,
                  do: "text-indigo-600 ml-2 text-sm font-medium",
                  else: "text-gray-400 ml-2 text-sm font-medium"
              }>
                Cart Review
              </div>
            </div>
            <div class="flex items-center ml-8">
              <div class={if @step >= 2, do: "bg-indigo-600", else: "bg-gray-200"}>
                <span class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white">
                  2
                </span>
              </div>
              <div class={
                if @step >= 2,
                  do: "text-indigo-600 ml-2 text-sm font-medium",
                  else: "text-gray-400 ml-2 text-sm font-medium"
              }>
                Address
              </div>
            </div>
            <div class="flex items-center ml-8">
              <div class={if @step >= 3, do: "bg-indigo-600", else: "bg-gray-200"}>
                <span class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium text-white">
                  3
                </span>
              </div>
              <div class={
                if @step >= 3,
                  do: "text-indigo-600 ml-2 text-sm font-medium",
                  else: "text-gray-400 ml-2 text-sm font-medium"
              }>
                Payment
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Checkout Content -->
      <div class="bg-white">
        <div class="max-w-14xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
          <div class="lg:grid lg:grid-cols-12 lg:gap-x-12 lg:items-start">
            <!-- Main Content -->
            <div class="lg:col-span-8">
              <%= if @step == 1 do %>
                <!-- Cart Review -->
                <div>
                  <h2 class="text-2xl font-bold text-gray-900 mb-6">Review Your Cart</h2>

                  <%= if Enum.empty?(@cart_items) do %>
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
                          d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m8 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                        />
                      </svg>
                      <h3 class="mt-2 text-sm font-medium text-gray-900">Your cart is empty</h3>
                      <p class="mt-1 text-sm text-gray-500">
                        Start shopping to add items to your cart.
                      </p>
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
                    <div class="border-t border-gray-200 divide-y divide-gray-200">
                      <%= for item <- @cart_items do %>
                        <div class="py-6 flex">
                          <div class="flex-shrink-0 w-24 h-24">
                            <img
                              src={item.product.featured_image || "https://via.placeholder.com/96x96"}
                              alt={item.product.name}
                              class="w-full h-full object-center object-cover rounded-md"
                            />
                          </div>
                          <div class="ml-4 flex-1 flex flex-col">
                            <div>
                              <div class="flex justify-between text-base font-medium text-gray-900">
                                <h3>
                                  <a href={~p"/products/#{item.product.id}"}>
                                    <%= item.product.name %>
                                  </a>
                                </h3>
                                <p class="ml-4">
                                  ₹<%= Number.Delimit.number_to_delimited(
                                    Decimal.mult(
                                      item.product.selling_price,
                                      Decimal.new(item.quantity)
                                    ),
                                    precision: 2
                                  ) %>
                                </p>
                              </div>
                              <p class="mt-1 text-sm text-gray-500"><%= item.product.brand %></p>
                              <%= if item.product_variant do %>
                                <p class="mt-1 text-sm text-gray-500">
                                  SKU: <%= item.product_variant.sku %>
                                </p>
                              <% end %>
                            </div>
                            <div class="flex-1 flex items-end justify-between text-sm">
                              <div class="flex items-center space-x-4">
                                <label for="quantity" class="text-gray-500">Qty</label>
                                <select
                                  id="quantity"
                                  phx-change="update_quantity"
                                  phx-value-cart-item-id={item.id}
                                  class="rounded-md border-gray-300 py-1 px-2 text-base leading-5 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                                >
                                  <%= for qty <- 1..10 do %>
                                    <option value={qty} selected={qty == item.quantity}>
                                      <%= qty %>
                                    </option>
                                  <% end %>
                                </select>
                                <span class="text-gray-500">
                                  ₹<%= Number.Delimit.number_to_delimited(item.product.selling_price,
                                    precision: 2
                                  ) %> each
                                </span>
                              </div>
                              <div class="flex">
                                <button
                                  phx-click="remove_item"
                                  phx-value-cart-item-id={item.id}
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

                    <div class="mt-8 flex justify-end">
                      <button
                        phx-click="proceed_to_address"
                        class="bg-indigo-600 text-white px-6 py-3 rounded-md hover:bg-indigo-700 font-medium"
                      >
                        Continue to Address Selection
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%= if @step == 2 do %>
                <!-- Address Selection -->
                <div>
                  <h2 class="text-2xl font-bold text-gray-900 mb-6">Select Addresses</h2>
                  <!-- Shipping Address -->
                  <div class="mb-8">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Shipping Address</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                      <%= for address <- @addresses do %>
                        <div
                          class="border rounded-lg p-4 cursor-pointer hover:border-indigo-500 transition-colors"
                          class={
                            if @selected_shipping_address_id == address.id,
                              do: "border-indigo-500 bg-indigo-50",
                              else: "border-gray-300"
                          }
                          phx-click="select_shipping_address"
                          phx-value-address-id={address.id}
                        >
                          <div class="flex items-start justify-between">
                            <div class="flex-1">
                              <p class="font-medium text-gray-900">
                                <%= address.first_name %> <%= address.last_name %>
                              </p>
                              <p class="text-sm text-gray-600"><%= address.address_line_1 %></p>
                              <%= if address.address_line_2 && address.address_line_2 != "" do %>
                                <p class="text-sm text-gray-600"><%= address.address_line_2 %></p>
                              <% end %>
                              <p class="text-sm text-gray-600">
                                <%= address.city %>, <%= address.state %> <%= address.postal_code %>
                              </p>
                              <p class="text-sm text-gray-600"><%= address.phone %></p>
                            </div>
                            <div class="ml-4">
                              <%= if @selected_shipping_address_id == address.id do %>
                                <svg
                                  class="h-5 w-5 text-indigo-600"
                                  fill="currentColor"
                                  viewBox="0 0 20 20"
                                >
                                  <path
                                    fill-rule="evenodd"
                                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                    clip-rule="evenodd"
                                  />
                                </svg>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>

                    <div class="mt-4">
                      <a
                        href="/addresses/new"
                        class="text-indigo-600 hover:text-indigo-500 font-medium"
                      >
                        + Add New Address
                      </a>
                    </div>
                  </div>
                  <!-- Billing Address -->
                  <div class="mb-8">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Billing Address</h3>
                    <div class="flex items-center mb-4">
                      <input
                        type="checkbox"
                        id="same_as_shipping"
                        phx-click="toggle_billing_same_as_shipping"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                      />
                      <label for="same_as_shipping" class="ml-2 block text-sm text-gray-900">
                        Same as shipping address
                      </label>
                    </div>

                    <%= if @selected_shipping_address_id && @selected_billing_address_id != @selected_shipping_address_id do %>
                      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <%= for address <- @addresses do %>
                          <div
                            class="border rounded-lg p-4 cursor-pointer hover:border-indigo-500 transition-colors"
                            class={
                              if @selected_billing_address_id == address.id,
                                do: "border-indigo-500 bg-indigo-50",
                                else: "border-gray-300"
                            }
                            phx-click="select_billing_address"
                            phx-value-address-id={address.id}
                          >
                            <div class="flex items-start justify-between">
                              <div class="flex-1">
                                <p class="font-medium text-gray-900">
                                  <%= address.first_name %> <%= address.last_name %>
                                </p>
                                <p class="text-sm text-gray-600"><%= address.address_line_1 %></p>
                                <%= if address.address_line_2 && address.address_line_2 != "" do %>
                                  <p class="text-sm text-gray-600"><%= address.address_line_2 %></p>
                                <% end %>
                                <p class="text-sm text-gray-600">
                                  <%= address.city %>, <%= address.state %> <%= address.postal_code %>
                                </p>
                                <p class="text-sm text-gray-600"><%= address.phone %></p>
                              </div>
                              <div class="ml-4">
                                <%= if @selected_billing_address_id == address.id do %>
                                  <svg
                                    class="h-5 w-5 text-indigo-600"
                                    fill="currentColor"
                                    viewBox="0 0 20 20"
                                  >
                                    <path
                                      fill-rule="evenodd"
                                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                      clip-rule="evenodd"
                                    />
                                  </svg>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>

                  <div class="flex justify-between">
                    <button
                      type="button"
                      phx-click="back_to_cart"
                      class="bg-gray-300 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-400"
                    >
                      Back to Cart
                    </button>
                    <button
                      phx-click="proceed_to_payment"
                      disabled={!@selected_shipping_address_id}
                      class="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                    >
                      Continue to Payment
                    </button>
                  </div>
                </div>
              <% end %>

              <%= if @step == 3 do %>
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
                        phx-click="back_to_address"
                        class="bg-gray-300 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-400"
                      >
                        Back
                      </button>
                      <button
                        type="submit"
                        class="bg-indigo-600 text-white px-6 py-2 rounded-md hover:bg-indigo-700"
                      >
                        Place Order
                      </button>
                    </div>
                  </form>
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
                    <dd class="text-sm font-medium text-gray-900">
                      ₹<%= Number.Delimit.number_to_delimited(@total, precision: 2) %>
                    </dd>
                  </div>
                  <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                    <dt class="text-sm text-gray-600">Shipping</dt>
                    <dd class="text-sm font-medium text-gray-900">
                      ₹<%= Number.Delimit.number_to_delimited(@shipping, precision: 2) %>
                    </dd>
                  </div>
                  <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                    <dt class="text-sm text-gray-600">Tax</dt>
                    <dd class="text-sm font-medium text-gray-900">
                      ₹<%= Number.Delimit.number_to_delimited(@tax, precision: 2) %>
                    </dd>
                  </div>
                  <div class="flex items-center justify-between border-t border-gray-200 pt-4">
                    <dt class="text-base font-medium text-gray-900">Total</dt>
                    <dd class="text-base font-medium text-gray-900">
                      ₹<%= Number.Delimit.number_to_delimited(@grand_total, precision: 2) %>
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
  def handle_event(
        "update_quantity",
        %{"value" => quantity, "cart-item-id" => cart_item_id},
        socket
      ) do
    cart_item = CartItems.get_cart_item!(cart_item_id)

    {:ok, _updated_cart_item} =
      CartItems.update_cart_item(cart_item, %{quantity: String.to_integer(quantity)})

    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    total = calculate_subtotal(cart_items)
    shipping = calculate_shipping(cart_items)
    total_plus_shipping = Decimal.add(total, shipping)
    tax = calculate_tax(total_plus_shipping)
    grand_total = Decimal.add(total_plus_shipping, tax)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: total,
       shipping: shipping,
       tax: tax,
       grand_total: grand_total,
       cart_count: CartItems.get_user_cart_count(user.id)
     )}
  end

  @impl true
  def handle_event("remove_item", %{"cart-item-id" => cart_item_id}, socket) do
    cart_item = CartItems.get_cart_item!(cart_item_id)
    CartItems.delete_cart_item(cart_item)

    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    total = calculate_subtotal(cart_items)
    shipping = calculate_shipping(cart_items)
    total_plus_shipping = Decimal.add(total, shipping)
    tax = calculate_tax(total_plus_shipping)
    grand_total = Decimal.add(total_plus_shipping, tax)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: total,
       shipping: shipping,
       tax: tax,
       grand_total: grand_total,
       cart_count: CartItems.get_user_cart_count(user.id)
     )}
  end

  @impl true
  def handle_event("proceed_to_address", _params, socket) do
    {:noreply, assign(socket, step: 2)}
  end

  @impl true
  def handle_event("select_shipping_address", %{"address-id" => address_id}, socket) do
    {:noreply, assign(socket, selected_shipping_address_id: address_id)}
  end

  @impl true
  def handle_event("select_billing_address", %{"address-id" => address_id}, socket) do
    {:noreply, assign(socket, selected_billing_address_id: address_id)}
  end

  @impl true
  def handle_event("toggle_billing_same_as_shipping", _params, socket) do
    billing_address_id =
      if socket.assigns.selected_billing_address_id == socket.assigns.selected_shipping_address_id do
        nil
      else
        socket.assigns.selected_shipping_address_id
      end

    {:noreply, assign(socket, selected_billing_address_id: billing_address_id)}
  end

  @impl true
  def handle_event("back_to_cart", _params, socket) do
    {:noreply, assign(socket, step: 1)}
  end

  @impl true
  def handle_event("proceed_to_payment", _params, socket) do
    {:noreply, assign(socket, step: 3)}
  end

  @impl true
  def handle_event("back_to_address", _params, socket) do
    {:noreply, assign(socket, step: 2)}
  end

  @impl true
  def handle_event("save_payment", _params, socket) do
    # TODO: Process payment and create order
    {:noreply, redirect(socket, to: ~p"/orders/confirmation")}
  end

  defp calculate_subtotal(cart_items) do
    Enum.reduce(cart_items, Decimal.new(0), fn item, acc ->
      Decimal.add(acc, Decimal.mult(item.product.selling_price, Decimal.new(item.quantity)))
    end)
  end

  defp calculate_shipping(cart_items) do
    # Simple shipping calculation
    if Enum.empty?(cart_items), do: Decimal.new(0), else: Decimal.new("9.99")
  end

  defp calculate_tax(subtotal) do
    # Simple tax calculation (8.875% for NY)
    Decimal.mult(subtotal, Decimal.new("0.08875"))
  end
end
