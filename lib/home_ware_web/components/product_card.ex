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
    <div class="bg-gray-800 rounded-2xl shadow-xl overflow-hidden group hover:shadow-2xl transition-all duration-300 transform hover:scale-105 border border-gray-700">
      <!-- Product Image -->
      <div class="relative">
        <img
          src={@product.featured_image || "https://via.placeholder.com/300x200"}
          alt={@product.name}
          class="w-full h-48 object-cover group-hover:opacity-90 transition-opacity duration-300"
        />
        <!-- Availability Badge -->
        <div class="absolute top-2 left-2">
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
          <div class="absolute inset-0 bg-black/50 flex items-center justify-center rounded-xl">
            <div class="text-center">
              <svg
                class="w-12 h-12 text-white mx-auto mb-2"
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
              <span class="text-white font-bold text-lg">Out of Stock</span>
            </div>
          </div>
        <% end %>
      </div>
      <!-- Product Info -->
      <div class="p-6">
        <h3 class="text-xl font-bold mb-2 text-white group-hover:text-purple-400 transition-colors">
          <a href={~p"/products/#{@product.id}"} class="hover:text-purple-400">
            <%= @product.name %>
          </a>
        </h3>

        <p class="text-gray-400 text-sm mb-4 line-clamp-2">
          <%= @product.description %>
        </p>

        <div class="flex items-center justify-between gap-4">
          <div class="flex items-center space-x-2">
            <span class="text-gray-400 line-through text-sm">
              <%= Formatters.format_currency(@product.price) %>
            </span>
            <span class="text-2xl font-bold text-purple-400">
              <%= Formatters.format_currency(@product.selling_price) %>
            </span>
          </div>

          <%= if @product.available? do %>
            <button
              phx-click="add_to_cart"
              phx-value-product-id={@product.id}
              phx-stop-propagation
              class="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-3 py-1.5 rounded-full text-sm font-medium hover:from-purple-600 hover:to-pink-600 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-purple-500/25"
            >
              +
            </button>
          <% else %>
            <button
              disabled
              class="bg-gray-500 text-gray-300 px-3 py-1.5 rounded-full text-sm font-medium cursor-not-allowed"
            >
              +
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
      true -> "bg-green-100 text-green-800 text-xs font-medium px-2 py-1 rounded"
      false -> "bg-red-100 text-red-800 text-xs font-medium px-2 py-1 rounded"
    end
  end

  defp get_wishlist_button_class(product) do
    base_class =
      "absolute top-4 right-4 w-8 h-8 flex items-center justify-center rounded-full shadow-md transition-all duration-300"

    if Map.get(product, :is_in_wishlist, false) do
      "#{base_class} bg-pink-500 hover:bg-pink-600"
    else
      "#{base_class} bg-gray-800/80 hover:bg-gray-700/80"
    end
  end

  defp get_wishlist_icon_class(product) do
    base_class = "w-4 h-4"

    if Map.get(product, :is_in_wishlist, false) do
      "#{base_class} text-white"
    else
      "#{base_class} text-gray-400"
    end
  end
end
