defmodule HomeWareWeb.ProductCard do
  use HomeWareWeb, :verified_routes

  @moduledoc """
  Reusable product card component for displaying products in catalogs and wishlists.
  """

  use Phoenix.Component
  alias HomeWareWeb.Formatters

  @doc """
  Renders a product card with consistent styling and functionality.
  """
  def product_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-card border border-brand-neutral-200 overflow-hidden group hover:shadow-modal transition-all duration-300 transform hover:-translate-y-1">
      <!-- Product Image -->
      <div class="relative">
        <img
          src={@product.featured_image || "https://via.placeholder.com/300x200"}
          alt={@product.name}
          class="w-full h-48 object-cover group-hover:scale-105 transition-transform duration-300"
        />
        <!-- Availability Badge -->
        <div class="absolute top-3 left-3">
          <span class={get_availability_class(@product.available?)}>
            <%= Formatters.format_availability_status(
              @product.available?,
              @product.inventory_quantity
            ) %>
          </span>
        </div>
        <!-- Wishlist Button -->
        <button
          phx-click={
            if Map.get(@product, :is_in_wishlist, false),
              do: "remove_from_wishlist",
              else: "add_to_wishlist"
          }
          phx-value-product-id={@product.id}
          phx-stop-propagation
          class={get_wishlist_button_class(@product)}
          title={
            if Map.get(@product, :is_in_wishlist, false),
              do: "Remove from wishlist",
              else: "Add to wishlist"
          }
          aria-label={
            if Map.get(@product, :is_in_wishlist, false),
              do: "Remove from wishlist",
              else: "Add to wishlist"
          }
        >
          <svg
            class={get_wishlist_icon_class(@product)}
            fill={if Map.get(@product, :is_in_wishlist, false), do: "currentColor", else: "none"}
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
            />
          </svg>
        </button>
        <!-- Out of Stock Overlay -->
        <%= if !@product.available? do %>
          <div class="absolute inset-0 bg-brand-neutral-900/50 flex items-center justify-center">
            <div class="text-center">
              <svg
                class="w-8 h-8 text-white mx-auto mb-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                />
              </svg>
              <span class="text-white font-medium text-sm">Out of Stock</span>
            </div>
          </div>
        <% end %>
      </div>
      <!-- Product Info -->
      <div class="p-4">
        <h3 class="text-lg font-semibold mb-2 text-text-primary group-hover:text-brand-primary transition-colors line-clamp-1">
          <a href={~p"/products/#{@product.id}"} class="hover:text-brand-primary">
            <%= @product.name %>
          </a>
        </h3>

        <p class="text-text-secondary text-sm mb-4 line-clamp-2">
          <%= @product.description %>
        </p>

        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center space-x-2">
            <span class="text-brand-neutral-400 line-through text-sm">
              <%= Formatters.format_currency(@product.price) %>
            </span>
            <span class="text-xl font-bold text-brand-primary">
              <%= Formatters.format_currency(@product.selling_price) %>
            </span>
          </div>

          <%= if @product.available? do %>
            <button
              phx-click="add_to_cart"
              phx-value-product-id={@product.id}
              phx-stop-propagation
              class="bg-brand-primary hover:bg-brand-primary-hover text-white p-2 rounded-md transition-colors duration-200 shadow-sm hover:shadow-md"
              aria-label="Add to cart"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
            </button>
          <% else %>
            <button
              disabled
              class="bg-brand-neutral-200 text-brand-neutral-400 p-2 rounded-md cursor-not-allowed"
              aria-label="Out of stock"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Private helper functions

  defp get_availability_class(available?) do
    case available? do
      true ->
        "bg-green-100 text-green-800 text-xs font-medium px-3 py-1 rounded-full border border-green-200"

      false ->
        "bg-red-100 text-red-800 text-xs font-medium px-3 py-1 rounded-full border border-red-200"
    end
  end

  defp get_wishlist_button_class(product) do
    base_class =
      "absolute top-3 right-3 w-8 h-8 flex items-center justify-center rounded-full shadow-sm transition-all duration-200"

    if Map.get(product, :is_in_wishlist, false) do
      "#{base_class} bg-brand-accent hover:bg-brand-accent/80"
    else
      "#{base_class} bg-white/90 hover:bg-white border border-brand-neutral-200"
    end
  end

  defp get_wishlist_icon_class(product) do
    base_class = "w-4 h-4"

    if Map.get(product, :is_in_wishlist, false) do
      "#{base_class} text-white"
    else
      "#{base_class} text-brand-neutral-400"
    end
  end
end
