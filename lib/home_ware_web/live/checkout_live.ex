defmodule HomeWareWeb.CheckoutLive do
  use HomeWareWeb, :live_view

  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}
  on_mount {HomeWareWeb.NavCountsLive, :default}

  alias HomeWare.CartItems
  alias HomeWare.Addresses
  alias HomeWare.Orders
  alias HomeWareWeb.SessionUtils

  # Import components
  import HomeWareWeb.CartItem, only: [cart_item: 1]

  require Logger

  @impl true
  def mount(_params, session, socket) do
    socket = SessionUtils.assign_current_user(socket, session)
    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)

    # Remove out-of-stock items from the cart
    {available_items, out_of_stock_items} = Orders.filter_available_items(cart_items)

    Enum.each(out_of_stock_items, fn item ->
      CartItems.delete_cart_item(item)
    end)

    # Show notification if items were removed
    socket =
      if message = Orders.format_removed_items_message(out_of_stock_items) do
        put_flash(socket, :warning, message)
      else
        socket
      end

    addresses = Addresses.list_user_addresses(user.id)
    totals = Orders.calculate_order_totals(available_items)

    {:ok,
     assign(socket,
       cart_items: available_items,
       addresses: addresses,
       total: totals.subtotal,
       shipping: totals.shipping,
       tax: totals.tax,
       grand_total: totals.grand_total,
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
    <div class="min-h-screen bg-gradient-to-br from-brand-neutral-50 to-white">
      <!-- Header -->
      <div class="bg-white shadow-sm border-b border-brand-neutral-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <a href="/" class="text-2xl font-bold text-brand-primary">HomeWare</a>
              <span class="text-brand-neutral-400">/</span>
              <span class="text-text-primary font-medium">Checkout</span>
            </div>
            <div class="text-sm text-text-secondary">
              Secure checkout powered by HomeWare
            </div>
          </div>
        </div>
      </div>
      <!-- Progress Indicator -->
      <div class="bg-white border-b border-brand-neutral-200">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div class="flex items-center justify-center space-x-8">
            <%= for {step, label, icon, active, completed} <- [
              {1, "Cart", "🛒", @step == 1, @step > 1},
              {2, "Shipping", "🚚", @step == 2, @step > 2},
              {3, "Payment", "💳", @step == 3, @step > 3},
              {4, "Review", "✅", @step == 4, @step > 4}
            ] do %>
              <div class="flex items-center">
                <div class={
                  "w-12 h-12 rounded-full flex items-center justify-center text-lg font-bold transition-all duration-300 " <>
                  cond do
                    completed -> "bg-brand-accent text-white shadow-md"
                    active -> "bg-brand-primary text-white shadow-lg"
                    true -> "bg-brand-neutral-100 text-brand-neutral-400"
                  end
                }>
                  <%= if completed do %>
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  <% else %>
                    <%= icon %>
                  <% end %>
                </div>
                <span class={
                  "ml-3 text-sm font-semibold tracking-wide uppercase transition-colors duration-300 " <>
                  cond do
                    completed -> "text-brand-accent"
                    active -> "text-brand-primary"
                    true -> "text-brand-neutral-400"
                  end
                }>
                  <%= label %>
                </span>
              </div>
              <%= unless step == 4 do %>
                <div class={
                  "w-12 h-1 rounded-full transition-all duration-300 #{if completed, do: "bg-brand-accent", else: "bg-brand-neutral-200"}"
                }>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
          <!-- LEFT: Main Content -->
          <div class="xl:col-span-2 space-y-8">
            <%= if @step == 1 do %>
              <!-- Cart Review -->
              <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 overflow-hidden">
                <div class="px-6 py-4 bg-gradient-to-r from-brand-primary/5 to-brand-accent/5 border-b border-brand-neutral-200">
                  <h2 class="text-xl font-bold text-text-primary">Review Your Cart</h2>
                  <p class="text-text-secondary text-sm mt-1">Review your items before proceeding</p>
                </div>
                <%= if Enum.empty?(@cart_items) do %>
                  <div class="text-center py-16 px-6">
                    <div class="w-20 h-20 bg-brand-neutral-100 rounded-full flex items-center justify-center mx-auto mb-6">
                      <svg
                        class="w-10 h-10 text-brand-neutral-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m8 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                        />
                      </svg>
                    </div>
                    <h3 class="text-xl font-semibold text-text-primary mb-3">Your cart is empty</h3>
                    <p class="text-text-secondary mb-8">Start shopping to add items to your cart.</p>
                    <a
                      href="/products"
                      class="inline-flex items-center px-8 py-3 bg-brand-primary hover:bg-brand-primary-hover text-white font-semibold rounded-lg transition-all duration-200 shadow-sm hover:shadow-md"
                    >
                      Continue Shopping
                    </a>
                  </div>
                <% else %>
                  <div class="divide-y divide-brand-neutral-200">
                    <%= for item <- @cart_items do %>
                      <div class="p-6">
                        <.cart_item item={item} />
                      </div>
                    <% end %>
                  </div>
                  <div class="px-6 py-4 bg-brand-neutral-50 border-t border-brand-neutral-200">
                    <button
                      phx-click="proceed_to_address"
                      class="w-full bg-brand-primary hover:bg-brand-primary-hover text-white py-4 rounded-lg font-semibold text-lg transition-all duration-200 shadow-sm hover:shadow-md"
                    >
                      Continue to Address Selection
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>

            <%= if @step == 2 do %>
              <!-- Address Selection -->
              <div class="space-y-8">
                <!-- Shipping Address -->
                <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 overflow-hidden">
                  <div class="px-6 py-4 bg-gradient-to-r from-brand-primary/5 to-brand-accent/5 border-b border-brand-neutral-200">
                    <h2 class="text-xl font-bold text-text-primary">Shipping Address</h2>
                    <p class="text-text-secondary text-sm mt-1">
                      Where should we deliver your order?
                    </p>
                  </div>
                  <div class="p-6">
                    <div class="grid grid-cols-1 gap-4">
                      <%= for address <- @addresses do %>
                        <div
                          class={
                            if @selected_shipping_address_id == address.id,
                              do:
                                "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-brand-primary bg-brand-primary/5 shadow-sm",
                              else:
                                "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-brand-neutral-200 bg-white hover:border-brand-neutral-300 hover:shadow-sm"
                          }
                          phx-click="select_shipping_address"
                          phx-value-address-id={address.id}
                        >
                          <div class="flex items-start justify-between">
                            <div class="flex-1">
                              <div class="flex items-center space-x-3 mb-2">
                                <div class="w-8 h-8 bg-brand-primary/10 rounded-full flex items-center justify-center">
                                  <svg
                                    class="w-4 h-4 text-brand-primary"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                  >
                                    <path
                                      stroke-linecap="round"
                                      stroke-linejoin="round"
                                      stroke-width="2"
                                      d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                                    />
                                    <path
                                      stroke-linecap="round"
                                      stroke-linejoin="round"
                                      stroke-width="2"
                                      d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                                    />
                                  </svg>
                                </div>
                                <p class="font-semibold text-text-primary">
                                  <%= address.first_name %> <%= address.last_name %>
                                </p>
                              </div>
                              <p class="text-text-secondary text-sm"><%= address.address_line_1 %></p>
                              <%= if address.address_line_2 && address.address_line_2 != "" do %>
                                <p class="text-text-secondary text-sm">
                                  <%= address.address_line_2 %>
                                </p>
                              <% end %>
                              <p class="text-text-secondary text-sm">
                                <%= address.city %>, <%= address.state %> <%= address.postal_code %>
                              </p>
                              <p class="text-text-secondary text-sm"><%= address.phone %></p>
                            </div>
                            <div class="ml-4">
                              <%= if @selected_shipping_address_id == address.id do %>
                                <div class="w-6 h-6 bg-brand-primary rounded-full flex items-center justify-center">
                                  <svg
                                    class="w-4 h-4 text-white"
                                    fill="currentColor"
                                    viewBox="0 0 20 20"
                                  >
                                    <path
                                      fill-rule="evenodd"
                                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                      clip-rule="evenodd"
                                    />
                                  </svg>
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                    <div class="mt-6">
                      <a
                        href="/addresses/new"
                        class="inline-flex items-center text-brand-primary hover:text-brand-primary-hover font-medium text-sm"
                      >
                        <svg
                          class="w-4 h-4 mr-2"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                          />
                        </svg>
                        Add New Address
                      </a>
                    </div>
                  </div>
                </div>
                <!-- Billing Address -->
                <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 overflow-hidden">
                  <div class="px-6 py-4 bg-gradient-to-r from-brand-accent/5 to-brand-primary/5 border-b border-brand-neutral-200">
                    <h2 class="text-xl font-bold text-text-primary">Billing Address</h2>
                    <p class="text-text-secondary text-sm mt-1">Where should we send your invoice?</p>
                  </div>
                  <div class="p-6">
                    <div class="flex items-center mb-6 p-4 bg-brand-neutral-50 rounded-lg border border-brand-neutral-200">
                      <input
                        type="checkbox"
                        id="same_as_shipping"
                        phx-click="toggle_billing_same_as_shipping"
                        class="accent-brand-primary w-5 h-5 rounded focus:ring-2 focus:ring-brand-primary/20"
                      />
                      <label for="same_as_shipping" class="ml-3 block text-text-primary font-medium">
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
                                  "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-brand-accent bg-brand-accent/5 shadow-sm",
                                else:
                                  "border-2 rounded-xl p-4 cursor-pointer transition-all duration-200 border-brand-neutral-200 bg-white hover:border-brand-neutral-300 hover:shadow-sm"
                            }
                            phx-click="select_billing_address"
                            phx-value-address-id={address.id}
                          >
                            <div class="flex items-start justify-between">
                              <div class="flex-1">
                                <div class="flex items-center space-x-3 mb-2">
                                  <div class="w-8 h-8 bg-brand-accent/10 rounded-full flex items-center justify-center">
                                    <svg
                                      class="w-4 h-4 text-brand-accent"
                                      fill="none"
                                      stroke="currentColor"
                                      viewBox="0 0 24 24"
                                    >
                                      <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                                      />
                                    </svg>
                                  </div>
                                  <p class="font-semibold text-text-primary">
                                    <%= address.first_name %> <%= address.last_name %>
                                  </p>
                                </div>
                                <p class="text-text-secondary text-sm">
                                  <%= address.address_line_1 %>
                                </p>
                                <%= if address.address_line_2 && address.address_line_2 != "" do %>
                                  <p class="text-text-secondary text-sm">
                                    <%= address.address_line_2 %>
                                  </p>
                                <% end %>
                                <p class="text-text-secondary text-sm">
                                  <%= address.city %>, <%= address.state %> <%= address.postal_code %>
                                </p>
                                <p class="text-text-secondary text-sm"><%= address.phone %></p>
                              </div>
                              <div class="ml-4">
                                <%= if @selected_billing_address_id == address.id do %>
                                  <div class="w-6 h-6 bg-brand-accent rounded-full flex items-center justify-center">
                                    <svg
                                      class="w-4 h-4 text-white"
                                      fill="currentColor"
                                      viewBox="0 0 20 20"
                                    >
                                      <path
                                        fill-rule="evenodd"
                                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                        clip-rule="evenodd"
                                      />
                                    </svg>
                                  </div>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
                <!-- Navigation -->
                <div class="flex justify-between items-center">
                  <button
                    type="button"
                    phx-click="back_to_cart"
                    class="inline-flex items-center px-6 py-3 bg-brand-neutral-100 text-text-primary rounded-lg hover:bg-brand-neutral-200 transition-colors font-medium"
                  >
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 19l-7-7 7-7"
                      />
                    </svg>
                    Back to Cart
                  </button>
                  <button
                    phx-click="proceed_to_payment"
                    disabled={!@selected_shipping_address_id}
                    class="inline-flex items-center px-8 py-3 bg-brand-primary hover:bg-brand-primary-hover text-white rounded-lg font-semibold transition-colors disabled:bg-brand-neutral-200 disabled:text-brand-neutral-400 disabled:cursor-not-allowed"
                  >
                    Continue to Payment
                    <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            <% end %>

            <%= if @step == 3 do %>
              <!-- Payment Information -->
              <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 overflow-hidden">
                <div class="px-6 py-4 bg-gradient-to-r from-brand-primary/5 to-brand-accent/5 border-b border-brand-neutral-200">
                  <h2 class="text-xl font-bold text-text-primary">Payment Method</h2>
                  <p class="text-text-secondary text-sm mt-1">Choose how you'd like to pay</p>
                </div>
                <div class="p-6 space-y-6">
                  <div class="p-4 bg-brand-neutral-50 rounded-lg border-2 border-brand-primary/20">
                    <div class="flex items-center">
                      <div class="w-10 h-10 bg-brand-primary/10 rounded-full flex items-center justify-center mr-4">
                        <svg
                          class="w-5 h-5 text-brand-primary"
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
                      </div>
                      <div>
                        <span class="text-text-primary font-semibold">Cash on Delivery</span>
                        <p class="text-text-secondary text-sm">Pay when you receive your order</p>
                      </div>
                    </div>
                  </div>

                  <form phx-submit="save_payment" class="space-y-6">
                    <div>
                      <label class="block text-text-primary mb-3 text-sm font-semibold">
                        Special handling or delivery notes
                      </label>
                      <textarea
                        name="notes"
                        phx-keyup="update_notes"
                        rows="4"
                        class="w-full rounded-lg bg-white border border-brand-neutral-300 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 text-text-primary px-4 py-3 text-sm transition-all duration-200 outline-none resize-none placeholder-brand-neutral-400"
                        placeholder="Any special instructions for delivery..."
                      ></textarea>
                    </div>

                    <div class="flex justify-between">
                      <button
                        type="button"
                        phx-click="back_to_address"
                        class="inline-flex items-center px-6 py-3 bg-brand-neutral-100 text-text-primary rounded-lg hover:bg-brand-neutral-200 transition-colors font-medium"
                      >
                        <svg
                          class="w-4 h-4 mr-2"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M15 19l-7-7 7-7"
                          />
                        </svg>
                        Back
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            <% end %>
          </div>
          <!-- RIGHT: Order Summary -->
          <div class="xl:col-span-1">
            <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 sticky top-8">
              <div class="px-6 py-4 bg-gradient-to-r from-brand-primary/5 to-brand-accent/5 border-b border-brand-neutral-200">
                <h2 class="text-xl font-bold text-text-primary">Order Summary</h2>
                <p class="text-text-secondary text-sm mt-1">Review your order details</p>
              </div>

              <div class="p-6 space-y-6">
                <!-- Promo Code -->
                <div class="space-y-3">
                  <label class="block text-sm font-semibold text-text-primary">Promo Code</label>
                  <div class="flex space-x-3">
                    <input
                      type="text"
                      placeholder="Enter code"
                      class="flex-1 rounded-lg bg-white border border-brand-neutral-300 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 text-text-primary px-4 py-3 text-sm transition-all duration-200 outline-none placeholder-brand-neutral-400"
                    />
                    <button class="px-6 py-3 bg-brand-primary hover:bg-brand-primary-hover text-white font-semibold rounded-lg transition-colors text-sm whitespace-nowrap">
                      Apply
                    </button>
                  </div>
                </div>
                <!-- Totals -->
                <div class="space-y-4">
                  <div class="flex justify-between text-sm">
                    <span class="text-text-secondary">Subtotal</span>
                    <span data-testid="subtotal" class="text-text-primary font-medium">
                      ₹<%= Number.Delimit.number_to_delimited(@total, precision: 2) %>
                    </span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-text-secondary">Shipping</span>
                    <span data-testid="shipping" class="text-text-primary font-medium">
                      ₹<%= Number.Delimit.number_to_delimited(@shipping, precision: 2) %>
                    </span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-text-secondary">Tax</span>
                    <span data-testid="tax" class="text-text-primary font-medium">
                      ₹<%= Number.Delimit.number_to_delimited(@tax, precision: 2) %>
                    </span>
                  </div>
                  <div class="border-t border-brand-neutral-200 pt-4">
                    <div class="flex justify-between text-lg font-bold">
                      <span class="text-brand-primary">Total</span>
                      <span data-testid="grand-total" class="text-brand-primary">
                        ₹<%= Number.Delimit.number_to_delimited(@grand_total, precision: 2) %>
                      </span>
                    </div>
                  </div>
                </div>
                <!-- Estimated Delivery -->
                <div class="p-4 bg-brand-accent/10 rounded-lg border border-brand-accent/20">
                  <div class="flex items-center space-x-3">
                    <svg
                      class="w-5 h-5 text-brand-accent"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 8v4l3 3"
                      />
                      <circle
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="2"
                        fill="none"
                      />
                    </svg>
                    <div>
                      <p class="text-brand-accent font-semibold text-sm">Estimated delivery</p>
                      <p class="text-text-secondary text-sm">3-5 business days</p>
                    </div>
                  </div>
                </div>
                <!-- CTA -->
                <button
                  phx-click="complete_order"
                  disabled={is_nil(@notes) || @notes == ""}
                  class={"w-full py-4 rounded-lg font-bold text-lg transition-all focus:outline-none focus:ring-2 focus:ring-brand-primary/20 #{if is_nil(@notes) || @notes == "", do: "bg-brand-neutral-200 text-brand-neutral-400 cursor-not-allowed", else: "bg-brand-primary hover:bg-brand-primary-hover text-white shadow-sm hover:shadow-md"}"}
                >
                  <span>Complete My Order</span>
                </button>
                <!-- Trust Badges -->
                <div class="grid grid-cols-3 gap-4 pt-6 border-t border-brand-neutral-200">
                  <div class="text-center">
                    <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-2">
                      <svg
                        class="w-4 h-4 text-green-600"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                        />
                      </svg>
                    </div>
                    <p class="text-xs text-text-secondary">Secure</p>
                  </div>
                  <div class="text-center">
                    <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-2">
                      <svg
                        class="w-4 h-4 text-blue-600"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 8v4l3 3"
                        />
                        <circle
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="2"
                          fill="none"
                        />
                      </svg>
                    </div>
                    <p class="text-xs text-text-secondary">Fast</p>
                  </div>
                  <div class="text-center">
                    <div class="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-2">
                      <svg
                        class="w-4 h-4 text-purple-600"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M4 4h16v16H4z"
                        />
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 8h8v8H8z"
                        />
                      </svg>
                    </div>
                    <p class="text-xs text-text-secondary">Discreet</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("increase_quantity", %{"cart-item-id" => cart_item_id}, socket) do
    cart_item = CartItems.get_cart_item!(cart_item_id)
    new_quantity = cart_item.quantity + 1

    {:ok, _updated_cart_item} =
      CartItems.update_cart_item(cart_item, %{quantity: new_quantity})

    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    totals = Orders.calculate_order_totals(cart_items)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: totals.subtotal,
       shipping: totals.shipping,
       tax: totals.tax,
       grand_total: totals.grand_total
     )}
  end

  @impl true
  def handle_event("decrease_quantity", %{"cart-item-id" => cart_item_id}, socket) do
    cart_item = CartItems.get_cart_item!(cart_item_id)
    new_quantity = max(1, cart_item.quantity - 1)

    {:ok, _updated_cart_item} =
      CartItems.update_cart_item(cart_item, %{quantity: new_quantity})

    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    totals = Orders.calculate_order_totals(cart_items)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: totals.subtotal,
       shipping: totals.shipping,
       tax: totals.tax,
       grand_total: totals.grand_total
     )}
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
    totals = Orders.calculate_order_totals(cart_items)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: totals.subtotal,
       shipping: totals.shipping,
       tax: totals.tax,
       grand_total: totals.grand_total
     )}
  end

  @impl true
  def handle_event("remove_item", %{"cart-item-id" => cart_item_id}, socket) do
    cart_item = CartItems.get_cart_item!(cart_item_id)
    CartItems.delete_cart_item(cart_item)

    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    totals = Orders.calculate_order_totals(cart_items)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: totals.subtotal,
       shipping: totals.shipping,
       tax: totals.tax,
       grand_total: totals.grand_total
     )}
  end

  @impl true
  def handle_event("remove_from_cart", %{"cart-item-id" => cart_item_id}, socket) do
    cart_item = CartItems.get_cart_item!(cart_item_id)
    CartItems.delete_cart_item(cart_item)

    user = socket.assigns.current_user
    cart_items = CartItems.list_user_cart_items(user.id)
    totals = Orders.calculate_order_totals(cart_items)

    {:noreply,
     assign(socket,
       cart_items: cart_items,
       total: totals.subtotal,
       shipping: totals.shipping,
       tax: totals.tax,
       grand_total: totals.grand_total
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
      if billing_address_id do
        Enum.find(socket.assigns.addresses, fn addr -> addr.id == billing_address_id end)
      else
        nil
      end

    # Validate that required addresses are selected
    cond do
      is_nil(shipping_address) ->
        {:noreply, put_flash(socket, :error, "Please select a shipping address.")}

      is_nil(billing_address) ->
        {:noreply, put_flash(socket, :error, "Please select a billing address.")}

      true ->
        # Generate order number
        order_number = generate_order_number()

        # Create the order
        order_params = %{
          user_id: user.id,
          shipping_address_id: shipping_address.id,
          billing_address_id: billing_address.id,
          order_number: order_number,
          subtotal: socket.assigns.total,
          shipping_amount: socket.assigns.shipping,
          tax_amount: socket.assigns.tax,
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
  end

  defp generate_order_number do
    today = Date.utc_today()

    day_month =
      String.pad_leading(Integer.to_string(today.day), 2, "0") <>
        String.pad_leading(Integer.to_string(today.month), 2, "0")

    random_number = :crypto.strong_rand_bytes(4) |> Base.encode16() |> binary_part(0, 8)
    "VIBE-#{day_month}-#{random_number}"
  end
end
