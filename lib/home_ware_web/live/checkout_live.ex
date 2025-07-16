defmodule HomeWareWeb.CheckoutLive do
  use HomeWareWeb, :live_view

  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  alias HomeWare.CartItems
  alias HomeWare.Addresses

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)

    # Remove out-of-stock items from the cart
    {available_items, out_of_stock_items} =
      Enum.split_with(cart_items, fn item ->
        # Check variant availability if item has a variant, otherwise check product availability
        if item.product_variant do
          item.product_variant.available?
        else
          item.product.available?
        end
      end)

    Enum.each(out_of_stock_items, fn item ->
      CartItems.delete_cart_item(item)
    end)

    # Show notification if items were removed
    socket =
      if length(out_of_stock_items) > 0 do
        removed_count = length(out_of_stock_items)

        removed_names =
          Enum.map_join(out_of_stock_items, ", ", fn item ->
            variant_name =
              if item.product_variant, do: " (#{item.product_variant.option_name})", else: ""

            "#{item.product.name}#{variant_name}"
          end)

        socket
        |> put_flash(
          :warning,
          "#{removed_count} item(s) removed from cart: #{removed_names} - no longer available"
        )
      else
        socket
      end

    addresses = Addresses.list_user_addresses(user.id)

    total = calculate_subtotal(available_items)
    shipping = calculate_shipping(available_items)
    total_plus_shipping = Decimal.add(total, shipping)
    tax = calculate_tax(total_plus_shipping)
    grand_total = Decimal.add(total_plus_shipping, tax)

    {:ok,
     assign(socket,
       cart_items: available_items,
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
       order_summary: %{},
       notes: ""
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-white font-sans">
      <!-- Progress Indicator -->
      <div class="max-w-5xl mx-auto pt-8 pb-4">
        <div class="flex items-center justify-center space-x-8">
          <%= for {step, label, icon, active} <- [
            {1, "Cart", "🛒", @step >= 1},
            {2, "Shipping", "🚚", @step >= 2},
            {3, "Payment", "💳", @step >= 3},
            {4, "Review", "📝", @step >= 4}
          ] do %>
            <div class="flex items-center">
              <div class={
                "w-10 h-10 rounded-full flex items-center justify-center text-lg font-bold " <>
                if active, do: "bg-gradient-to-br from-purple-500 to-teal-400 shadow-lg text-black", else: "bg-gray-800 text-gray-400"
              }>
                <%= icon %>
              </div>
              <span class={
                "ml-2 text-base font-semibold tracking-wide uppercase " <>
                if active, do: "text-purple-400", else: "text-gray-500"
              }>
                <%= label %>
              </span>
            </div>
            <%= unless step == 4 do %>
              <div class="w-8 h-1 rounded bg-gradient-to-r from-purple-500 to-red-500 mx-2"></div>
            <% end %>
          <% end %>
        </div>
      </div>

      <div class="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-10 px-4 pb-12">
        <!-- LEFT: Customer Details & Payment -->
        <div class="bg-gray-900 rounded-3xl shadow-2xl p-8 space-y-8">
          <%= if @step == 1 do %>
            <!-- Cart Review -->
            <div>
              <h2 class="text-xl font-bold mb-4 text-purple-400">Review Your Cart</h2>
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
                  <h3 class="mt-2 text-sm font-medium text-gray-300">Your cart is empty</h3>
                  <p class="mt-1 text-sm text-gray-500">Start shopping to add items to your cart.</p>
                  <div class="mt-6">
                    <a
                      href="/products"
                      class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-black bg-gradient-to-r from-purple-500 to-teal-400 hover:from-purple-600 hover:to-teal-500"
                    >
                      Continue Shopping
                    </a>
                  </div>
                </div>
              <% else %>
                <div class="space-y-4">
                  <%= for item <- @cart_items do %>
                    <div class="flex items-center p-4 bg-gray-800 rounded-xl border border-gray-700">
                      <img
                        src={item.product.featured_image || "https://via.placeholder.com/80x80"}
                        alt={item.product.name}
                        class="w-20 h-20 rounded-xl object-cover border-2 border-gray-700 shadow-lg mr-4"
                      />
                      <div class="flex-1">
                        <div class="flex justify-between items-center">
                          <div>
                            <div class="font-semibold text-lg text-white">
                              <a
                                href={~p"/products/#{item.product.id}"}
                                class="hover:text-purple-400 transition-colors"
                              >
                                <%= item.product.name %>
                              </a>
                            </div>
                            <div class="text-sm text-gray-400">
                              <%= item.product.brand %>
                              <%= if item.product_variant do %>
                                | <%= item.product_variant.option_name %> (SKU: <%= item.product_variant.sku %>)
                                <%= unless item.product_variant.available? do %>
                                  <span class="bg-red-600 text-white text-xs font-medium px-2 py-1 rounded ml-2">
                                    Out of Stock
                                  </span>
                                <% end %>
                              <% end %>
                            </div>
                          </div>
                          <div class="text-right">
                            <span class="font-bold text-lg text-teal-400">
                              ₹<%= Number.Delimit.number_to_delimited(
                                Decimal.mult(item.product.selling_price, Decimal.new(item.quantity)),
                                precision: 2
                              ) %>
                            </span>
                          </div>
                        </div>
                        <div class="flex items-center justify-between mt-2">
                          <div class="flex items-center space-x-2">
                            <label class="text-gray-400 text-sm">Qty</label>
                            <div class="flex items-center space-x-1">
                              <button
                                phx-click="decrease_quantity"
                                phx-value-cart-item-id={item.id}
                                type="button"
                                class="w-8 h-8 rounded bg-gray-700 text-white hover:bg-gray-600 flex items-center justify-center"
                                disabled={item.product_variant && !item.product_variant.available?}
                              >
                                -
                              </button>
                              <span class="px-3 py-1 bg-gray-800 text-white rounded min-w-[2rem] text-center">
                                <%= item.quantity %>
                              </span>
                              <button
                                phx-click="increase_quantity"
                                phx-value-cart-item-id={item.id}
                                type="button"
                                class="w-8 h-8 rounded bg-gray-700 text-white hover:bg-gray-600 flex items-center justify-center"
                                disabled={item.product_variant && !item.product_variant.available?}
                              >
                                +
                              </button>
                            </div>
                            <span class="text-gray-500 text-sm">
                              ₹<%= Number.Delimit.number_to_delimited(item.product.selling_price,
                                precision: 2
                              ) %> each
                            </span>
                          </div>
                          <button
                            phx-click="remove_item"
                            phx-value-cart-item-id={item.id}
                            type="button"
                            class="text-red-400 hover:text-red-300 transition-colors p-2 rounded-lg hover:bg-red-500/10"
                            title="Remove item"
                          >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                              />
                            </svg>
                          </button>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
                <div class="mt-8 flex justify-end">
                  <button
                    phx-click="proceed_to_address"
                    class="bg-gradient-to-r from-purple-500 to-teal-400 text-black px-8 py-3 rounded-xl font-bold hover:from-purple-600 hover:to-teal-500 transition-all shadow-lg"
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
              <h2 class="text-xl font-bold mb-4 text-teal-400">Select Addresses</h2>
              <!-- Shipping Address -->
              <div class="mb-8">
                <h3 class="text-lg font-medium text-gray-300 mb-4">Shipping Address</h3>
                <div class="grid grid-cols-1 gap-4">
                  <%= for address <- @addresses do %>
                    <div
                      class={
                        if @selected_shipping_address_id == address.id,
                          do:
                            "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-purple-500 bg-purple-500/10",
                          else:
                            "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-gray-700 bg-gray-800 hover:border-purple-500"
                      }
                      phx-click="select_shipping_address"
                      phx-value-address-id={address.id}
                    >
                      <div class="flex items-start justify-between">
                        <div class="flex-1">
                          <p class="font-medium text-white">
                            <%= address.first_name %> <%= address.last_name %>
                          </p>
                          <p class="text-sm text-gray-400"><%= address.address_line_1 %></p>
                          <%= if address.address_line_2 && address.address_line_2 != "" do %>
                            <p class="text-sm text-gray-400"><%= address.address_line_2 %></p>
                          <% end %>
                          <p class="text-sm text-gray-400">
                            <%= address.city %>, <%= address.state %> <%= address.postal_code %>
                          </p>
                          <p class="text-sm text-gray-400"><%= address.phone %></p>
                        </div>
                        <div class="ml-4">
                          <%= if @selected_shipping_address_id == address.id do %>
                            <svg
                              class="h-5 w-5 text-purple-400"
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
                  <a href="/addresses/new" class="text-purple-400 hover:text-purple-300 font-medium">
                    + Add New Address
                  </a>
                </div>
              </div>
              <!-- Billing Address -->
              <div class="mb-8">
                <h3 class="text-lg font-medium text-gray-300 mb-4">Billing Address</h3>
                <div class="flex items-center mb-4">
                  <input
                    type="checkbox"
                    id="same_as_shipping"
                    phx-click="toggle_billing_same_as_shipping"
                    class="accent-purple-500 w-5 h-5 rounded focus:ring-2 focus:ring-purple-500/40"
                  />
                  <label for="same_as_shipping" class="ml-2 block text-sm text-gray-300">
                    Same as shipping address
                  </label>
                </div>

                <%= if @selected_shipping_address_id && @selected_billing_address_id != @selected_shipping_address_id do %>
                  <div class="grid grid-cols-1 gap-4">
                    <%= for address <- @addresses do %>
                      <div
                        class={
                          if @selected_billing_address_id == address.id,
                            do:
                              "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-teal-500 bg-teal-500/10",
                            else:
                              "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-gray-700 bg-gray-800 hover:border-teal-500"
                        }
                        phx-click="select_billing_address"
                        phx-value-address-id={address.id}
                      >
                        <div class="flex items-start justify-between">
                          <div class="flex-1">
                            <p class="font-medium text-white">
                              <%= address.first_name %> <%= address.last_name %>
                            </p>
                            <p class="text-sm text-gray-400"><%= address.address_line_1 %></p>
                            <%= if address.address_line_2 && address.address_line_2 != "" do %>
                              <p class="text-sm text-gray-400"><%= address.address_line_2 %></p>
                            <% end %>
                            <p class="text-sm text-gray-400">
                              <%= address.city %>, <%= address.state %> <%= address.postal_code %>
                            </p>
                            <p class="text-sm text-gray-400"><%= address.phone %></p>
                          </div>
                          <div class="ml-4">
                            <%= if @selected_billing_address_id == address.id do %>
                              <svg
                                class="h-5 w-5 text-teal-400"
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
                  class="bg-gray-700 text-gray-300 px-6 py-2 rounded-xl hover:bg-gray-600 transition-colors"
                >
                  Back to Cart
                </button>
                <button
                  phx-click="proceed_to_payment"
                  disabled={!@selected_shipping_address_id}
                  class="bg-gradient-to-r from-purple-500 to-teal-400 text-black px-6 py-2 rounded-xl font-bold hover:from-purple-600 hover:to-teal-500 transition-all disabled:bg-gray-600 disabled:cursor-not-allowed"
                >
                  Continue to Payment
                </button>
              </div>
            </div>
          <% end %>

          <%= if @step == 3 do %>
            <!-- Payment Information -->
            <div>
              <h2 class="text-xl font-bold mb-4 text-red-500">Payment Method</h2>
              <div class="mb-6">
                <div class="flex items-center p-4 bg-gray-800/50 border-2 border-purple-500/30 rounded-xl">
                  <svg
                    class="w-6 h-6 text-purple-400 mr-3"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
                    />
                  </svg>
                  <span class="text-white font-medium">Cash on Delivery</span>
                </div>
              </div>

              <form phx-submit="save_payment" class="space-y-6">
                <div>
                  <label class="block text-gray-400 mb-2">Special handling or delivery notes</label>
                  <textarea
                    name="notes"
                    phx-keyup="update_notes"
                    rows="2"
                    class="w-full rounded-xl bg-black/80 border-2 border-gray-700 focus:border-teal-400 focus:ring-2 focus:ring-teal-400/40 text-white px-4 py-3 text-lg shadow transition-all duration-200 outline-none"
                    placeholder="Any special instructions for delivery..."
                  ></textarea>
                </div>

                <div class="flex justify-between">
                  <button
                    type="button"
                    phx-click="back_to_address"
                    class="bg-gray-700 text-gray-300 px-6 py-2 rounded-xl hover:bg-gray-600 transition-colors"
                  >
                    Back
                  </button>
                </div>
              </form>
            </div>
          <% end %>
        </div>
        <!-- RIGHT: Order Summary -->
        <div class="bg-gray-950 rounded-3xl shadow-2xl p-8 space-y-8">
          <h2 class="text-xl font-bold mb-6 text-purple-400">Order Summary</h2>
          <!-- Promo Code -->
          <div class="flex items-center mt-6">
            <input
              type="text"
              placeholder="Promo code"
              class="flex-1 rounded-xl bg-black/80 border-2 border-gray-700 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/40 text-white px-4 py-3 text-lg shadow transition-all duration-200 outline-none"
            />
            <button class="ml-3 px-5 py-3 rounded-xl bg-gradient-to-r from-purple-500 to-teal-400 text-black font-bold shadow-lg hover:from-purple-600 hover:to-teal-500 transition-all">
              Apply
            </button>
          </div>
          <!-- Totals -->
          <div class="mt-8 space-y-2 text-lg">
            <div class="flex justify-between">
              <span class="text-gray-400">Subtotal</span>
              <span>₹<%= Number.Delimit.number_to_delimited(@total, precision: 2) %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-400">Shipping</span>
              <span>₹<%= Number.Delimit.number_to_delimited(@shipping, precision: 2) %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-400">Tax</span>
              <span>₹<%= Number.Delimit.number_to_delimited(@tax, precision: 2) %></span>
            </div>
            <div class="flex justify-between font-bold text-xl">
              <span class="text-purple-400">Total</span>
              <span>₹<%= Number.Delimit.number_to_delimited(@grand_total, precision: 2) %></span>
            </div>
          </div>
          <!-- Estimated Delivery -->
          <div class="mt-4 text-teal-400 text-sm">
            <span>Estimated delivery: 3-5 business days</span>
          </div>
          <!-- CTA -->
          <button
            phx-click="complete_order"
            disabled={is_nil(@notes) || @notes == ""}
            class={"w-full mt-8 py-4 rounded-2xl font-extrabold text-xl shadow-xl transition-all focus:outline-none focus:ring-4 focus:ring-purple-500/40 #{if is_nil(@notes) || @notes == "", do: "bg-gray-600 text-gray-400 cursor-not-allowed", else: "bg-gradient-to-r from-purple-500 via-red-500 to-teal-400 text-black hover:from-purple-600 hover:via-red-600 hover:to-teal-500 animate-glow"}"}
          >
            <span class="drop-shadow-lg">Complete My Order</span>
          </button>
          <!-- Trust Badges -->
          <div class="flex items-center justify-center space-x-6 mt-8">
            <div class="flex items-center space-x-2">
              <svg class="w-6 h-6 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 11c0-1.104.896-2 2-2s2 .896 2 2-2 2-2 2-2-.896-2-2z"
                /><path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 19c-4.418 0-8-3.582-8-8s3.582-8 8-8 8 3.582 8 8-3.582 8-8 8z"
                />
              </svg>
              <span class="text-xs text-gray-400">Secure Payment</span>
            </div>
            <div class="flex items-center space-x-2">
              <svg class="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3" /><circle
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="2"
                  fill="none"
                />
              </svg>
              <span class="text-xs text-gray-400">18+ Only</span>
            </div>
            <div class="flex items-center space-x-2">
              <svg
                class="w-6 h-6 text-purple-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 4h16v16H4z"
                /><path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 8h8v8H8z"
                />
              </svg>
              <span class="text-xs text-gray-400">Discreet Shipping</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      .input-glow {
        @apply w-full rounded-xl bg-black/80 border-2 border-gray-700 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/40 text-white px-4 py-3 text-lg shadow transition-all duration-200 outline-none;
        box-shadow: 0 0 0 0 transparent;
      }
      .input-glow:focus {
        box-shadow: 0 0 8px 2px #a21caf55, 0 0 0 2px #14b8a6aa;
      }
      .payment-btn {
        @apply w-full py-3 rounded-xl font-bold text-lg bg-gray-800 text-gray-300 border-2 border-gray-700 shadow transition-all duration-200;
      }
      .payment-btn.selected, .payment-btn:focus {
        @apply bg-gradient-to-r from-purple-500 to-teal-400 text-black border-purple-500 shadow-lg;
        box-shadow: 0 0 12px 2px #a21caf88, 0 0 0 2px #14b8a6aa;
      }
      .animate-glow {
        animation: glow 1.5s infinite alternate;
      }
      @keyframes glow {
        from { box-shadow: 0 0 8px 2px #a21caf88, 0 0 0 2px #14b8a6aa; }
        to   { box-shadow: 0 0 24px 6px #a21cafcc, 0 0 0 4px #14b8a6cc; }
      }
    </style>
    """
  end

  @impl true
  def handle_event("test_event", _params, socket) do
    IO.inspect("TEST EVENT RECEIVED!")
    {:noreply, socket}
  end

  @impl true
  def handle_event("increase_quantity", %{"cart-item-id" => cart_item_id}, socket) do
    IO.inspect("INCREASE QUANTITY for cart item: #{cart_item_id}")

    cart_item = CartItems.get_cart_item!(cart_item_id)
    new_quantity = cart_item.quantity + 1

    {:ok, _updated_cart_item} =
      CartItems.update_cart_item(cart_item, %{quantity: new_quantity})

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
  def handle_event("decrease_quantity", %{"cart-item-id" => cart_item_id}, socket) do
    IO.inspect("DECREASE QUANTITY for cart item: #{cart_item_id}")

    cart_item = CartItems.get_cart_item!(cart_item_id)
    new_quantity = max(1, cart_item.quantity - 1)

    {:ok, _updated_cart_item} =
      CartItems.update_cart_item(cart_item, %{quantity: new_quantity})

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
  def handle_event("update_quantity", params, socket) do
    IO.inspect(params, label: "update_quantity params")
    IO.inspect(socket.assigns, label: "socket assigns before update")

    case params do
      %{"value" => quantity, "cart-item-id" => cart_item_id} ->
        IO.inspect("Processing quantity update: #{quantity} for cart item: #{cart_item_id}")

        cart_item = CartItems.get_cart_item!(cart_item_id)
        IO.inspect(cart_item, label: "Original cart item")

        {:ok, updated_cart_item} =
          CartItems.update_cart_item(cart_item, %{quantity: String.to_integer(quantity)})

        IO.inspect(updated_cart_item, label: "Updated cart item")

        user = socket.assigns.current_user
        cart_items = CartItems.list_user_cart_items(user.id)
        total = calculate_subtotal(cart_items)
        shipping = calculate_shipping(cart_items)
        total_plus_shipping = Decimal.add(total, shipping)
        tax = calculate_tax(total_plus_shipping)
        grand_total = Decimal.add(total_plus_shipping, tax)

        IO.inspect(cart_items, label: "Updated cart items")
        IO.inspect(total, label: "New total")

        {:noreply,
         assign(socket,
           cart_items: cart_items,
           total: total,
           shipping: shipping,
           tax: tax,
           grand_total: grand_total,
           cart_count: CartItems.get_user_cart_count(user.id)
         )}

      _ ->
        IO.inspect(params, label: "Unexpected params format")
        {:noreply, socket}
    end
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

  @impl true
  def handle_event("update_notes", %{"value" => notes}, socket) do
    {:noreply, assign(socket, notes: notes)}
  end

  defp generate_order_number do
    today = Date.utc_today()

    day_month =
      String.pad_leading(Integer.to_string(today.day), 2, "0") <>
        String.pad_leading(Integer.to_string(today.month), 2, "0")

    random_number = :crypto.strong_rand_bytes(4) |> Base.encode16() |> binary_part(0, 8)
    "VIBE-#{day_month}-#{random_number}"
  end

  @impl true
  def handle_event("complete_order", _params, socket) do
    user = socket.assigns.current_user
    cart_items = socket.assigns.cart_items
    shipping_address_id = socket.assigns.selected_shipping_address_id
    billing_address_id = socket.assigns.selected_billing_address_id
    notes = socket.assigns[:notes] || ""

    # Get the actual address objects
    shipping_address =
      Enum.find(socket.assigns.addresses, fn addr -> addr.id == shipping_address_id end)

    billing_address =
      Enum.find(socket.assigns.addresses, fn addr -> addr.id == billing_address_id end)

    # Generate order number
    order_number = generate_order_number()

    # Create the order
    order_params = %{
      user_id: user.id,
      shipping_address_id: shipping_address.id,
      billing_address_id: billing_address.id,
      order_number: order_number,
      subtotal: socket.assigns.total,
      total_amount: socket.assigns.grand_total,
      payment_method: "cash_on_delivery",
      status: "pending",
      notes: notes
    }

    case HomeWare.Orders.create_order(order_params) do
      {:ok, order} ->
        # Create order items from cart items
        Enum.each(cart_items, fn cart_item ->
          HomeWare.Orders.create_order_item(%{
            order_id: order.id,
            product_id: cart_item.product_id,
            product_variant_id: cart_item.product_variant_id,
            quantity: cart_item.quantity,
            unit_price: cart_item.product.selling_price,
            total_price: Decimal.mult(cart_item.product.selling_price, cart_item.quantity)
          })
        end)

        # Clear the cart
        HomeWare.CartItems.clear_user_cart(user.id)

        {:noreply,
         socket
         |> put_flash(:info, "Order placed successfully!")
         |> push_navigate(to: "/orders")}

      {:error, reason} ->
        Logger.error("Error creating order: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Could not place order. Please try again.")}
    end
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
