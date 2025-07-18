defmodule HomeWareWeb.ProductCatalogLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.NavCountsLive, :default}
  import Ecto.Query

  alias HomeWare.Repo
  alias HomeWare.Products.Product
  alias HomeWare.Categories.Category
  alias HomeWare.CartItems
  alias HomeWare.WishlistItems
  alias HomeWareWeb.SessionUtils

  # Import components
  import HomeWareWeb.ProductCard, only: [product_card: 1]

  # Product catalog should be publicly accessible
  # on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  @impl true
  def mount(params, session, socket) do
    # Assign current_user for layout compatibility (can be nil for unauthenticated users)
    socket = SessionUtils.assign_current_user(socket, session)

    categories = Repo.all(Category)

    # Get initial filters from URL params
    filters =
      %{}
      |> maybe_add_filter(:category, params["category"])
      |> maybe_add_filter(:brand, params["brand"])
      |> maybe_add_filter(:min_price, params["min_price"])
      |> maybe_add_filter(:max_price, params["max_price"])

    # Get filtered products
    products = get_filtered_products(filters)

    # Add wishlist status to products if user is authenticated
    products_with_wishlist_status =
      if socket.assigns.current_user do
        Enum.map(products, fn product ->
          is_in_wishlist =
            WishlistItems.is_in_wishlist?(socket.assigns.current_user.id, product.id)

          Map.put(product, :is_in_wishlist, is_in_wishlist)
        end)
      else
        Enum.map(products, fn product -> Map.put(product, :is_in_wishlist, false) end)
      end

    {:ok,
     assign(socket,
       page: 1,
       per_page: 9,
       filters: filters,
       products: products_with_wishlist_status,
       total_count: length(products_with_wishlist_status),
       categories: categories,
       brands: get_brands()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <div class="container mx-auto px-4 py-8">
        <!-- Modern Filter Section -->
        <div class="mb-12">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-2xl font-bold text-white">Filters</h2>
          </div>

          <form
            phx-submit="filter"
            id="filter-form"
            class="bg-gradient-to-br from-gray-800 to-gray-900 p-8 rounded-3xl shadow-2xl border border-gray-700"
          >
            <!-- Filter Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
              <!-- Category Filter -->
              <div class="space-y-3">
                <label class="block text-sm font-semibold text-gray-300 uppercase tracking-wide">
                  Category
                </label>
                <div class="relative group">
                  <select
                    name="category"
                    class="w-full px-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
                  >
                    <option value="">All Categories</option>
                    <%= for category <- @categories do %>
                      <option value={category.id} selected={@filters[:category] == category.id}>
                        <%= category.name %>
                      </option>
                    <% end %>
                  </select>
                  <div class="absolute inset-y-0 right-0 flex items-center pr-4 pointer-events-none">
                    <svg
                      class="w-5 h-5 text-gray-400 group-hover:text-gray-300 transition-colors"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 9l-7 7-7-7"
                      >
                      </path>
                    </svg>
                  </div>
                </div>
              </div>
              <!-- Brand Filter -->
              <div class="space-y-3">
                <label class="block text-sm font-semibold text-gray-300 uppercase tracking-wide">
                  Brand
                </label>
                <div class="relative group">
                  <select
                    name="brand"
                    class="w-full px-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
                  >
                    <option value="">All Brands</option>
                    <%= for brand <- @brands do %>
                      <option value={brand} selected={@filters[:brand] == brand}><%= brand %></option>
                    <% end %>
                  </select>
                  <div class="absolute inset-y-0 right-0 flex items-center pr-4 pointer-events-none">
                    <svg
                      class="w-5 h-5 text-gray-400 group-hover:text-gray-300 transition-colors"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 9l-7 7-7-7"
                      >
                      </path>
                    </svg>
                  </div>
                </div>
              </div>
              <!-- Min Price Filter -->
              <div class="space-y-3">
                <label class="block text-sm font-semibold text-gray-300 uppercase tracking-wide">
                  Min Price
                </label>
                <div class="relative group">
                  <input
                    type="number"
                    name="min_price"
                    value={@filters[:min_price] || ""}
                    placeholder="₹0"
                    class="w-full pl-8 pr-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
                  />
                  <div class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
                    <span class="text-gray-400 text-sm">₹</span>
                  </div>
                </div>
              </div>
              <!-- Max Price Filter -->
              <div class="space-y-3">
                <label class="block text-sm font-semibold text-gray-300 uppercase tracking-wide">
                  Max Price
                </label>
                <div class="relative group">
                  <input
                    type="number"
                    name="max_price"
                    value={@filters[:max_price] || ""}
                    placeholder="₹∞"
                    class="w-full pl-8 pr-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
                  />
                  <div class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
                    <span class="text-gray-400 text-sm">₹</span>
                  </div>
                </div>
              </div>
            </div>
            <!-- Action Buttons -->
            <div class="flex items-center justify-between mt-8 pt-6 border-t border-gray-700">
              <div class="flex items-center space-x-4">
                <button
                  type="submit"
                  class="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-8 py-3 rounded-2xl font-semibold hover:from-purple-600 hover:to-pink-600 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-purple-500/25"
                >
                  <div class="flex items-center space-x-2">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.207A1 1 0 013 6.5V4z"
                      >
                      </path>
                    </svg>
                    <span>Apply Filters</span>
                  </div>
                </button>
                <button
                  type="button"
                  phx-click="reset_filters"
                  class="text-gray-400 hover:text-white transition-colors font-medium"
                >
                  Reset
                </button>
              </div>
              <!-- Active Filters Display -->
              <div class="flex items-center space-x-2">
                <%= if @filters[:category] || @filters[:brand] || @filters[:min_price] || @filters[:max_price] do %>
                  <span class="text-sm text-gray-400">Active filters:</span>
                  <div class="flex items-center space-x-2">
                    <%= if @filters[:category] do %>
                      <span class="px-3 py-1 bg-purple-500/20 text-purple-300 text-xs rounded-full border border-purple-500/30">
                        Category
                      </span>
                    <% end %>
                    <%= if @filters[:brand] do %>
                      <span class="px-3 py-1 bg-pink-500/20 text-pink-300 text-xs rounded-full border border-pink-500/30">
                        Brand
                      </span>
                    <% end %>
                    <%= if @filters[:min_price] || @filters[:max_price] do %>
                      <span class="px-3 py-1 bg-teal-500/20 text-teal-300 text-xs rounded-full border border-teal-500/30">
                        Price
                      </span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </form>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
          <%= for product <- @products do %>
            <div
              class="group relative bg-gray-800 rounded-2xl p-6 hover:bg-gray-700 transition-all duration-500 transform hover:-translate-y-2 cursor-pointer"
              data-product-id={product.id}
              phx-click="navigate_to_product"
              phx-value-product-id={product.id}
            >
              <.product_card product={product} />
            </div>
          <% end %>
        </div>

        <%= if @total_count > 0 do %>
          <div class="mt-8 flex justify-center">
            <nav class="flex items-center space-x-2">
              <%= if @page > 1 do %>
                <a
                  href={~p"/products?page=#{@page - 1}"}
                  class="px-3 py-2 text-gray-500 hover:text-gray-700"
                >
                  Previous
                </a>
              <% end %>

              <span class="px-3 py-2 text-gray-700">
                Page <%= @page %> of <%= ceil(@total_count / @per_page) %>
              </span>

              <%= if @page < ceil(@total_count / @per_page) do %>
                <a
                  href={~p"/products?page=#{@page + 1}"}
                  class="px-3 py-2 text-gray-500 hover:text-gray-700"
                >
                  Next
                </a>
              <% end %>
            </nav>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    page = String.to_integer(page)
    {:noreply, assign(socket, page: page)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "filter",
        %{
          "category" => category,
          "brand" => brand,
          "min_price" => min_price,
          "max_price" => max_price
        },
        socket
      ) do
    filters =
      %{}
      |> maybe_add_filter(:category, category)
      |> maybe_add_filter(:brand, brand)
      |> maybe_add_filter(:min_price, min_price)
      |> maybe_add_filter(:max_price, max_price)

    products = get_filtered_products(filters)
    brands = get_brands()

    {:noreply,
     assign(socket,
       filters: filters,
       products: products,
       total_count: length(products),
       brands: brands,
       page: 1
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters =
      %{}
      |> maybe_add_filter(:category, params["category"])
      |> maybe_add_filter(:brand, params["brand"])
      |> maybe_add_filter(:min_price, params["min_price"])
      |> maybe_add_filter(:max_price, params["max_price"])

    products = get_filtered_products(filters)
    brands = get_brands()

    {:noreply,
     assign(socket,
       filters: filters,
       products: products,
       total_count: length(products),
       brands: brands,
       page: 1
     )}
  end

  @impl true
  def handle_event("add_to_cart", %{"product-id" => product_id}, socket) do
    user = Map.get(socket.assigns, :current_user)

    cond do
      is_nil(user) ->
        {:noreply,
         socket
         |> put_flash(:error, "You must be logged in to add items to your cart.")
         |> push_navigate(to: "/users/log_in")}

      true ->
        # Check if product exists and is available
        product = HomeWare.Products.get_product!(product_id)

        if product.available? do
          case CartItems.add_to_cart(user.id, product_id, nil, 1) do
            {:ok, _cart_item} ->
              {:noreply, put_flash(socket, :info, "Added to cart!")}

            {:error, _reason} ->
              {:noreply, put_flash(socket, :error, "Failed to add item to cart.")}
          end
        else
          {:noreply, put_flash(socket, :error, "This product is currently out of stock.")}
        end
    end
  end

  @impl true
  def handle_event("navigate_to_product", %{"product-id" => product_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/products/#{product_id}")}
  end

  @impl true
  def handle_event("add_to_wishlist", %{"product-id" => product_id}, socket) do
    user = Map.get(socket.assigns, :current_user)

    cond do
      is_nil(user) ->
        {:noreply,
         socket
         |> put_flash(:error, "You must be logged in to add items to your wishlist.")
         |> push_navigate(to: "/users/log_in")}

      true ->
        case WishlistItems.add_to_wishlist(user.id, product_id) do
          {:ok, _wishlist_item} ->
            # Update the product's wishlist status in the current list
            updated_products =
              Enum.map(socket.assigns.products, fn product ->
                if product.id == product_id do
                  Map.put(product, :is_in_wishlist, true)
                else
                  product
                end
              end)

            {:noreply,
             socket
             |> assign(products: updated_products)
             |> put_flash(:info, "Added to wishlist!")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to add item to wishlist.")}
        end
    end
  end

  @impl true
  def handle_event("remove_from_wishlist", %{"product-id" => product_id}, socket) do
    user = Map.get(socket.assigns, :current_user)

    cond do
      is_nil(user) ->
        {:noreply, put_flash(socket, :error, "You must be logged in to manage your wishlist.")}

      true ->
        case WishlistItems.remove_from_wishlist(user.id, product_id) do
          {:ok, :deleted} ->
            # Update the product's wishlist status in the current list
            updated_products =
              Enum.map(socket.assigns.products, fn product ->
                if product.id == product_id do
                  Map.put(product, :is_in_wishlist, false)
                else
                  product
                end
              end)

            {:noreply,
             socket
             |> assign(products: updated_products)
             |> put_flash(:info, "Removed from wishlist!")}

          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Item not found in wishlist.")}
        end
    end
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    products = get_filtered_products(%{})
    brands = get_brands()

    {:noreply,
     assign(socket,
       filters: %{},
       products: products,
       total_count: length(products),
       brands: brands,
       page: 1
     )}
  end

  @impl true
  def handle_event("reset_filters", _params, socket) do
    products = get_filtered_products(%{})
    brands = get_brands()

    {:noreply,
     assign(socket,
       filters: %{},
       products: products,
       total_count: length(products),
       brands: brands,
       page: 1
     )}
  end

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, _key, ""), do: filters

  defp maybe_add_filter(filters, key, value) when is_binary(value) and value != "",
    do: Map.put(filters, key, value)

  defp maybe_add_filter(filters, key, value) when is_integer(value),
    do: Map.put(filters, key, value)

  defp maybe_add_filter(filters, _key, _value), do: filters

  # Helper function to get filtered products
  defp get_filtered_products(filters) do
    # Map filter parameters to match Products context expectations
    mapped_filters = %{
      category_id: filters[:category],
      brand: filters[:brand],
      min_price: parse_price(filters[:min_price]),
      max_price: parse_price(filters[:max_price])
    }

    # Use the Products context to ensure availability is set
    HomeWare.Products.list_products_with_filters(mapped_filters)
  end

  defp parse_price(nil), do: nil
  defp parse_price(""), do: nil

  defp parse_price(price) when is_binary(price) do
    case Integer.parse(price) do
      {price_int, _} -> price_int
      :error -> nil
    end
  end

  defp parse_price(price) when is_integer(price), do: price
  defp parse_price(_), do: nil

  # Helper function to get unique brands from products
  defp get_brands() do
    Repo.all(from p in Product, distinct: true, select: p.brand)
  end
end
