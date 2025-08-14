defmodule HomeWareWeb.CartItem do
  use HomeWareWeb, :verified_routes

  @moduledoc """
  Reusable cart item component for displaying items in checkout and cart views.
  """

  use Phoenix.Component
  alias HomeWareWeb.Formatters
  import HomeWare.Orders, only: [get_item_price: 1]

  @doc """
  Renders a cart item with consistent styling and functionality.
  """
  def cart_item(assigns) do
    ~H"""
    <div class="flex items-center p-4 bg-white rounded-lg border border-brand-neutral-200 shadow-sm">
      <img
        src={@item.product.featured_image || "https://via.placeholder.com/80x80"}
        alt={@item.product.name}
        class="w-20 h-20 rounded-lg object-cover border border-brand-neutral-200 shadow-sm mr-4"
      />

      <div class="flex-1">
        <div class="flex justify-between items-center">
          <div>
            <div class="font-semibold text-lg text-text-primary">
              <a
                href={~p"/products/#{@item.product.id}"}
                class="hover:text-brand-primary transition-colors"
              >
                <%= @item.product.name %>
              </a>
            </div>

            <div class="text-sm text-text-secondary mt-1">
              <%= @item.product.brand %>
              <%= if @item.product_variant do %>
                | <%= @item.product_variant.option_name %> (SKU: <%= @item.product_variant.sku %>)
                <%= unless @item.product_variant.available? do %>
                  <span class="bg-red-100 text-red-800 text-xs font-medium px-2 py-1 rounded ml-2 border border-red-200">
                    Out of Stock
                  </span>
                <% end %>
              <% end %>
            </div>
          </div>

          <div class="text-right">
            <span class="font-bold text-lg text-brand-primary">
              <%= Formatters.format_currency(
                Decimal.mult(get_item_price(@item), Decimal.new(@item.quantity))
              ) %>
            </span>
          </div>
        </div>

        <div class="flex items-center justify-between mt-4">
          <div class="flex items-center space-x-3">
            <label class="text-text-secondary text-sm font-medium">Qty</label>
            <div class="flex items-center space-x-2">
              <button
                phx-click="decrease_quantity"
                phx-value-cart-item-id={@item.id}
                type="button"
                class="w-8 h-8 rounded-md bg-brand-neutral-100 text-text-primary hover:bg-brand-neutral-200 flex items-center justify-center transition-colors"
                disabled={@item.product_variant && !@item.product_variant.available?}
                aria-label="Decrease quantity"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                </svg>
              </button>
              <span class="px-3 py-1 bg-brand-neutral-50 text-text-primary rounded-md min-w-[2rem] text-center font-medium">
                <%= @item.quantity %>
              </span>
              <button
                phx-click="increase_quantity"
                phx-value-cart-item-id={@item.id}
                type="button"
                class="w-8 h-8 rounded-md bg-brand-neutral-100 text-text-primary hover:bg-brand-neutral-200 flex items-center justify-center transition-colors"
                disabled={@item.product_variant && !@item.product_variant.available?}
                aria-label="Increase quantity"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
              </button>
            </div>
          </div>

          <button
            phx-click="remove_from_cart"
            phx-value-cart-item-id={@item.id}
            type="button"
            class="text-red-500 hover:text-red-600 transition-colors p-1 rounded-md hover:bg-red-50"
            title="Remove item"
            aria-label="Remove item from cart"
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
    """
  end

  @doc """
  Renders a compact cart item for summary views.
  """
  def cart_item_summary(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-3 border-b border-brand-neutral-200 last:border-b-0">
      <div class="flex items-center space-x-3">
        <img
          src={@item.product.featured_image || "https://via.placeholder.com/40x40"}
          alt={@item.product.name}
          class="w-10 h-10 rounded object-cover border border-brand-neutral-200"
        />
        <div>
          <div class="font-medium text-text-primary text-sm">
            <%= @item.product.name %>
          </div>
          <div class="text-text-secondary text-xs mt-1">
            Qty: <%= @item.quantity %>
            <%= if @item.product_variant do %>
              | <%= @item.product_variant.option_name %>
            <% end %>
          </div>
        </div>
      </div>

      <div class="text-right">
        <div class="font-semibold text-brand-primary">
          <%= Formatters.format_currency(
            Decimal.mult(get_item_price(@item), Decimal.new(@item.quantity))
          ) %>
        </div>
      </div>
    </div>
    """
  end
end
