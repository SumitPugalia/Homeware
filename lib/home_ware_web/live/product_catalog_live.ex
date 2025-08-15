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
      |> maybe_add_filter(:new_products, params["new_products"])

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
    <div class="min-h-screen bg-brand-neutral-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-text-primary mb-2">Product Catalog</h1>
          <p class="text-text-secondary">
            Discover our collection of premium home and lifestyle products
          </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <!-- Filters Sidebar -->
          <div class="lg:col-span-1">
            <div class="bg-white rounded-xl shadow-sm border border-brand-neutral-200 p-6 sticky top-8">
              <h2 class="text-xl font-bold text-text-primary mb-6">Filters</h2>

              <form id="filter-form" phx-change="filter" class="space-y-6">
                <!-- Category Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Category
                  </label>
                  <.modern_dropdown
                    name="category"
                    label=""
                    options={[{"All Categories", ""} | Enum.map(@categories, &{&1.name, &1.id})]}
                    value={@filters[:category]}
                    placeholder="All Categories"
                  />
                </div>
                <!-- Brand Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Brand
                  </label>
                  <.modern_dropdown
                    name="brand"
                    label=""
                    options={[{"All Brands", ""} | Enum.map(@brands, &{&1, &1})]}
                    value={@filters[:brand]}
                    placeholder="All Brands"
                  />
                </div>
                <!-- New Products Filter -->
                <div class="space-y-2">
                  <label class="block text-sm font-semibold text-text-primary">
                    Product Type
                  </label>
                  <.modern_dropdown
                    name="new_products"
                    label=""
                    options={[
                      {"All Products", ""},
                      {"New Arrivals", "new"},
                      {"Featured", "featured"},
                      {"Bestsellers", "bestsellers"}
                    ]}
                    value={@filters[:new_products]}
                    placeholder="All Products"
                  />
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
                      class="w-full pl-8 pr-4 py-3 bg-white border border-brand-neutral-300 rounded-lg text-text-primary text-sm transition-all duration-200 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 focus:outline-none"
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
                      class="w-full pl-8 pr-4 py-3 bg-white border border-brand-neutral-300 rounded-lg text-text-primary text-sm transition-all duration-200 focus:border-brand-primary focus:ring-2 focus:ring-brand-primary/20 focus:outline-none"
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
                    class="bg-brand-primary hover:bg-brand-primary-hover text-white px-4 py-2 rounded-lg font-medium transition-colors duration-200"
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
            </div>
          </div>
          <!-- Product Grid -->
          <div class="lg:col-span-3">
            <!-- Sort Options -->
            <div class="flex justify-between items-center mb-6">
              <div class="flex items-center space-x-4">
                <label class="text-sm font-medium text-text-primary">Sort by:</label>
                <.modern_dropdown
                  name="sort"
                  label=""
                  options={[
                    {"Newest First", "newest"},
                    {"Oldest First", "oldest"},
                    {"Price: Low to High", "price_low"},
                    {"Price: High to Low", "price_high"},
                    {"Name: A to Z", "name_asc"},
                    {"Name: Z to A", "name_desc"}
                  ]}
                  value="newest"
                  placeholder="Newest First"
                />
              </div>
              <div class="text-sm text-text-secondary">
                <%= @total_count %> products found
              </div>
            </div>
            <!-- Products Grid -->
            <%= if Enum.empty?(@products) do %>
              <div class="text-center py-12">
                <div class="w-16 h-16 bg-brand-neutral-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg
                    class="w-8 h-8 text-brand-neutral-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"
                    />
                  </svg>
                </div>
                <h3 class="text-lg font-semibold text-text-primary mb-2">No products found</h3>
                <p class="text-text-secondary">
                  Try adjusting your filters to find what you're looking for.
                </p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <%= for product <- @products do %>
                  <%= product_card(%{product: product, current_user: @current_user}) %>
                <% end %>
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
          "max_price" => max_price,
          "new_products" => new_products
        },
        socket
      ) do
    filters =
      %{}
      |> maybe_add_filter(:category, category)
      |> maybe_add_filter(:brand, brand)
      |> maybe_add_filter(:min_price, min_price)
      |> maybe_add_filter(:max_price, max_price)
      |> maybe_add_filter(:new_products, new_products)

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
      |> maybe_add_filter(:new_products, params["new_products"])

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
      max_price: parse_price(filters[:max_price]),
      new_products: filters[:new_products]
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
