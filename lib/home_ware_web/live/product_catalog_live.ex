defmodule HomeWareWeb.ProductCatalogLive do
  use HomeWareWeb, :live_view
  import Ecto.Query

  alias HomeWare.Repo
  alias HomeWare.Products.Product
  alias HomeWare.Categories.Category
  alias HomeWare.CartItems

  # Product catalog should be publicly accessible
  # on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  @impl true
  def mount(params, session, socket) do
    # Assign current_user for layout compatibility (can be nil for unauthenticated users)
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)

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

    {:ok,
     assign(socket,
       page: 1,
       per_page: 9,
       filters: filters,
       products: products,
       total_count: length(products),
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
                    class="w-full px-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
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
                    class="w-full px-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
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
              <div class="relative overflow-hidden rounded-xl mb-4">
                <img
                  src={product.featured_image}
                  class="w-full h-64 object-cover rounded-xl group-hover:scale-110 transition-transform duration-700"
                  alt={product.name}
                />
                <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                </div>
                <%= if product.is_featured do %>
                  <div class="absolute top-4 right-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-3 py-1.5 rounded-full text-xs font-bold shadow-lg">
                    Featured
                  </div>
                <% end %>
              </div>
              <h3 class="text-xl font-bold mb-2 text-white group-hover:text-purple-400 transition-colors">
                <%= product.name %>
              </h3>
              <p class="text-gray-400 text-sm mb-4 line-clamp-2">
                <%= product.description %>
              </p>
              <div class="flex items-center justify-between gap-4">
                <div class="flex items-center space-x-2">
                  <span class="text-gray-400 line-through text-sm">
                    ₹<%= Number.Delimit.number_to_delimited(product.price, precision: 2) %>
                  </span>
                  <span class="text-2xl font-bold text-purple-400">
                    ₹<%= Number.Delimit.number_to_delimited(product.selling_price, precision: 2) %>
                  </span>
                </div>
                <button
                  phx-click="add_to_cart"
                  phx-value-product-id={product.id}
                  phx-stop-propagation
                  class="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-3 py-1.5 rounded-full text-sm font-medium hover:from-purple-600 hover:to-pink-600 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-purple-500/25"
                >
                  +
                </button>
              </div>
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
        IO.inspect(user.id)
        IO.inspect(product_id)
        CartItems.add_to_cart(user.id, product_id, nil, 1)
        {:noreply, put_flash(socket, :info, "Added to cart!")}
    end
  end

  @impl true
  def handle_event("navigate_to_product", %{"product-id" => product_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/products/#{product_id}")}
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
    query = Product |> preload(:category)

    query
    |> apply_category_filter(filters[:category])
    |> apply_brand_filter(filters[:brand])
    |> apply_price_filters(filters[:min_price], filters[:max_price])
    |> Repo.all()
  end

  # Apply category filter
  defp apply_category_filter(query, nil), do: query
  defp apply_category_filter(query, ""), do: query

  defp apply_category_filter(query, category_id) do
    query |> where([p], p.category_id == ^category_id)
  end

  # Apply brand filter
  defp apply_brand_filter(query, nil), do: query
  defp apply_brand_filter(query, ""), do: query

  defp apply_brand_filter(query, brand) do
    search_pattern = "%#{brand}%"
    query |> where([p], ilike(p.brand, ^search_pattern))
  end

  # Apply price filters
  defp apply_price_filters(query, nil, nil), do: query

  defp apply_price_filters(query, min_price, nil) when is_binary(min_price) and min_price != "" do
    case Integer.parse(min_price) do
      {price, _} ->
        query |> where([p], p.selling_price >= ^price)

      :error ->
        query
    end
  end

  defp apply_price_filters(query, nil, max_price) when is_binary(max_price) and max_price != "" do
    case Integer.parse(max_price) do
      {price, _} ->
        query |> where([p], p.selling_price <= ^price)

      :error ->
        query
    end
  end

  defp apply_price_filters(query, min_price, max_price)
       when is_binary(min_price) and is_binary(max_price) do
    query
    |> apply_price_filters(min_price, nil)
    |> apply_price_filters(nil, max_price)
  end

  defp apply_price_filters(query, _, _), do: query

  # Helper function to get unique brands from products
  defp get_brands() do
    Repo.all(from p in Product, distinct: true, select: p.brand)
  end

  defp get_user_from_session(session) do
    token = session["user_token"]

    case token do
      nil ->
        nil

      token ->
        case HomeWare.Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> user
          {:error, _reason} -> nil
        end
    end
  end
end
