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
  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

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
    <div class="min-h-screen bg-brand-neutral-50 py-8">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-3xl md:text-4xl font-bold text-text-primary mb-4">
            Product <span class="text-brand-primary">Catalog</span>
          </h1>
          <p class="text-text-secondary text-lg">
            Discover our curated collection of premium lifestyle products
          </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <!-- Filters Sidebar -->
          <div class="lg:col-span-1">
            <div class="bg-white rounded-lg shadow-card border border-brand-neutral-200 p-6 sticky top-24">
              <h2 class="text-xl font-bold text-text-primary mb-6">Filters</h2>

              <form id="filter-form" phx-change="filter" class="space-y-6">
                <!-- Category Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Category
                  </label>
                  <div class="relative">
                    <select
                      name="category"
                      class="w-full px-4 py-3 bg-white border border-brand-neutral-300 rounded-md text-text-primary text-sm transition-all duration-200 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 focus:outline-none"
                    >
                      <option value="">All Categories</option>
                      <%= for category <- @categories do %>
                        <option value={category.id} selected={@filters[:category] == category.id}>
                          <%= category.name %>
                        </option>
                      <% end %>
                    </select>
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                      <svg
                        class="w-4 h-4 text-brand-neutral-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 9l-7 7-7-7"
                        />
                      </svg>
                    </div>
                  </div>
                </div>
                <!-- Brand Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Brand
                  </label>
                  <div class="relative">
                    <select
                      name="brand"
                      class="w-full px-4 py-3 bg-white border border-brand-neutral-300 rounded-md text-text-primary text-sm transition-all duration-200 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 focus:outline-none"
                    >
                      <option value="">All Brands</option>
                      <%= for brand <- @brands do %>
                        <option value={brand} selected={@filters[:brand] == brand}>
                          <%= brand %>
                        </option>
                      <% end %>
                    </select>
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                      <svg
                        class="w-4 h-4 text-brand-neutral-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 9l-7 7-7-7"
                        />
                      </svg>
                    </div>
                  </div>
                </div>
                <!-- Min Price Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Min Price
                  </label>
                  <div class="relative">
                    <input
                      type="number"
                      name="min_price"
                      value={@filters[:min_price] || ""}
                      placeholder="₹0"
                      class="w-full pl-8 pr-4 py-3 bg-white border border-brand-neutral-300 rounded-md text-text-primary text-sm transition-all duration-200 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 focus:outline-none"
                    />
                    <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                      <span class="text-brand-neutral-400 text-sm">₹</span>
                    </div>
                  </div>
                </div>
                <!-- Max Price Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Max Price
                  </label>
                  <div class="relative">
                    <input
                      type="number"
                      name="max_price"
                      value={@filters[:max_price] || ""}
                      placeholder="₹∞"
                      class="w-full pl-8 pr-4 py-3 bg-white border border-brand-neutral-300 rounded-md text-text-primary text-sm transition-all duration-200 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 focus:outline-none"
                    />
                    <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                      <span class="text-brand-neutral-400 text-sm">₹</span>
                    </div>
                  </div>
                </div>
                <!-- Action Buttons -->
                <div class="flex items-center justify-between pt-4 border-t border-brand-neutral-200">
                  <button
                    type="submit"
                    class="bg-brand-primary hover:bg-brand-primary-hover text-white px-4 py-2 rounded-md font-medium transition-colors duration-200"
                  >
                    <div class="flex items-center space-x-2">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.207A1 1 0 013 6.5V4z"
                        />
                      </svg>
                      <span class="text-sm">Apply</span>
                    </div>
                  </button>
                  <button
                    type="button"
                    phx-click="reset_filters"
                    class="text-brand-neutral-400 hover:text-brand-primary transition-colors text-sm font-medium"
                  >
                    Reset
                  </button>
                </div>
              </form>
              <!-- Active Filters Display -->
              <%= if @filters[:category] || @filters[:brand] || @filters[:min_price] || @filters[:max_price] do %>
                <div class="mt-6 pt-4 border-t border-brand-neutral-200">
                  <span class="text-xs text-brand-neutral-500 font-medium">Active filters:</span>
                  <div class="flex flex-wrap gap-2 mt-2">
                    <%= if @filters[:category] do %>
                      <span class="px-3 py-1 bg-brand-primary/10 text-brand-primary text-xs rounded-full border border-brand-primary/20">
                        Category
                      </span>
                    <% end %>
                    <%= if @filters[:brand] do %>
                      <span class="px-3 py-1 bg-brand-accent/10 text-brand-accent text-xs rounded-full border border-brand-accent/20">
                        Brand
                      </span>
                    <% end %>
                    <%= if @filters[:min_price] || @filters[:max_price] do %>
                      <span class="px-3 py-1 bg-brand-neutral-200 text-brand-neutral-700 text-xs rounded-full border border-brand-neutral-300">
                        Price
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          <!-- Products Grid -->
          <div class="lg:col-span-3">
            <div class="mb-6 flex items-center justify-between">
              <p class="text-text-secondary text-sm">
                Showing <%= length(@products) %> of <%= @total_count %> products
              </p>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6">
              <%= for product <- @products do %>
                <div
                  class="group bg-white rounded-lg shadow-card border border-brand-neutral-200 overflow-hidden hover:shadow-modal transition-all duration-300 transform hover:-translate-y-1 cursor-pointer"
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
                      class="px-4 py-2 text-brand-neutral-400 hover:text-brand-primary transition-colors text-sm font-medium"
                    >
                      Previous
                    </a>
                  <% end %>

                  <span class="px-4 py-2 text-text-secondary text-sm">
                    Page <%= @page %> of <%= ceil(@total_count / @per_page) %>
                  </span>

                  <%= if @page < ceil(@total_count / @per_page) do %>
                    <a
                      href={~p"/products?page=#{@page + 1}"}
                      class="px-4 py-2 text-brand-neutral-400 hover:text-brand-primary transition-colors text-sm font-medium"
                    >
                      Next
                    </a>
                  <% end %>
                </nav>
              </div>
            <% end %>
          </div>
        </div>
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
