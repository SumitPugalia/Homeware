defmodule HomeWareWeb.ProductDetailLive do
  use HomeWareWeb, :live_view
  import Ecto.Query

  alias HomeWare.Repo
  alias HomeWare.Products
  alias HomeWare.Products.Product
  alias HomeWare.Categories.Category
  alias Decimal
  alias HomeWare.CartItems
  alias HomeWare.Guardian

  # Product detail pages should be publicly accessible
  # on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  @impl true
  def mount(%{"id" => id}, session, socket) do
    # Assign current_user for layout compatibility (can be nil for unauthenticated users)
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)

    product = Products.get_product_with_variants!(id)
    variants = product.variants || []
    selected_variant_id = if variants != [], do: hd(variants).id, else: nil

    # Get related products from the same category
    related_products =
      from(p in Product,
        where: p.category_id == ^product.category_id and p.id != ^product.id,
        limit: 4
      )
      |> Repo.all()

    {:ok,
     assign(socket,
       product: product,
       variants: variants,
       selected_variant_id: selected_variant_id,
       related_products: related_products,
       quantity: 1
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <div class="container mx-auto px-4 py-8">
        <!-- Breadcrumb -->
        <nav class="mb-8">
          <ol class="flex items-center space-x-2 text-sm text-gray-400">
            <li>
              <a href="/" class="hover:text-purple-400 transition-colors">Home</a>
            </li>
            <li class="flex items-center space-x-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7">
                </path>
              </svg>
              <a href="/products" class="hover:text-purple-400 transition-colors">Products</a>
            </li>
            <li class="flex items-center space-x-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7">
                </path>
              </svg>
              <span class="text-white"><%= @product.name %></span>
            </li>
          </ol>
        </nav>
        <!-- Product Details -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 mb-16">
          <!-- Product Images -->
          <div class="space-y-6">
            <div class="relative overflow-hidden rounded-3xl bg-gray-800">
              <img
                src={@product.featured_image}
                class="w-full h-96 lg:h-[500px] object-cover"
                alt={@product.name}
              />
              <%= if @product.is_featured do %>
                <div class="absolute top-6 right-6 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-4 py-2 rounded-full text-sm font-bold shadow-lg">
                  Featured
                </div>
              <% end %>
            </div>
          </div>
          <!-- Product Info -->
          <div class="space-y-8">
            <div>
              <h1 class="text-4xl font-bold text-white mb-4"><%= @product.name %></h1>
              <p class="text-gray-400 text-lg leading-relaxed mb-6">
                <%= @product.description %>
              </p>
            </div>
            <!-- Price Section -->
            <div class="space-y-4">
              <%= if @variants != [] do %>
                <div class="mb-4">
                  <label class="block text-gray-300 font-semibold mb-2">Select Variant:</label>
                  <select
                    name="variant"
                    id="variant-select"
                    phx-change="select_variant"
                    phx-value-product-id={@product.id}
                    class="w-full px-4 py-3.5 bg-gray-700 border-2 border-gray-600 rounded-2xl text-white text-sm font-medium transition-all duration-300 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 focus:outline-none group-hover:border-gray-500"
                  >
                    <%= for variant <- @variants do %>
                      <option value={variant.id} selected={@selected_variant_id == variant.id}>
                        <%= variant.option_name %> (<%= variant.sku %>) <%= if variant.price_override,
                          do:
                            " - ₹#{Number.Delimit.number_to_delimited(variant.price_override, precision: 2)}",
                          else: "" %>
                      </option>
                    <% end %>
                  </select>
                </div>
              <% end %>
              <div class="flex items-center space-x-4">
                <span class="text-gray-400 line-through text-xl">
                  ₹<%= Number.Delimit.number_to_delimited(
                    display_price(@product, @variants, @selected_variant_id, :original),
                    precision: 2
                  ) %>
                </span>
                <span class="text-4xl font-bold text-purple-400">
                  ₹<%= Number.Delimit.number_to_delimited(
                    display_price(@product, @variants, @selected_variant_id, :selling),
                    precision: 2
                  ) %>
                </span>
                <span class="bg-red-500/20 text-red-400 px-3 py-1 rounded-full text-sm font-semibold border border-red-500/30">
                  <%= calculate_discount(
                    display_price(@product, @variants, @selected_variant_id, :original),
                    display_price(@product, @variants, @selected_variant_id, :selling)
                  ) %>% OFF
                </span>
              </div>
            </div>
            <!-- Product Details -->
            <div class="space-y-4">
              <div class="grid grid-cols-2 gap-4">
                <div class="bg-gray-800 p-4 rounded-2xl">
                  <span class="text-gray-400 text-sm">Brand</span>
                  <p class="text-white font-semibold"><%= @product.brand %></p>
                </div>
                <div class="bg-gray-800 p-4 rounded-2xl">
                  <span class="text-gray-400 text-sm">Category</span>
                  <p class="text-white font-semibold">
                    <%= get_category_name(@product.category_id) %>
                  </p>
                </div>
              </div>
            </div>
            <!-- Quantity and Add to Cart -->
            <div class="space-y-6">
              <div class="flex items-center space-x-4">
                <label class="text-gray-300 font-semibold">Quantity:</label>
                <div class="flex items-center space-x-2 bg-gray-800 rounded-2xl p-2">
                  <button
                    phx-click="decrease_quantity"
                    class="w-8 h-8 flex items-center justify-center bg-gray-700 hover:bg-gray-600 rounded-xl transition-colors"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M20 12H4"
                      >
                      </path>
                    </svg>
                  </button>
                  <span class="w-12 text-center font-semibold text-white"><%= @quantity %></span>
                  <button
                    phx-click="increase_quantity"
                    class="w-8 h-8 flex items-center justify-center bg-gray-700 hover:bg-gray-600 rounded-xl transition-colors"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 4v16m8-8H4"
                      >
                      </path>
                    </svg>
                  </button>
                </div>
              </div>

              <div class="flex items-center space-x-4">
                <button
                  phx-click="add_to_cart"
                  phx-value-product-id={@product.id}
                  phx-value-variant-id={@selected_variant_id}
                  phx-value-quantity={@quantity}
                  class="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-8 py-4 rounded-2xl font-bold text-lg hover:from-purple-600 hover:to-pink-600 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-purple-500/25"
                >
                  <div class="flex items-center justify-center space-x-2">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m8 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                      >
                      </path>
                    </svg>
                    <span>Add to Cart</span>
                  </div>
                </button>
                <button
                  phx-click="add_to_wishlist"
                  phx-value-product-id={@product.id}
                  class="w-12 h-12 flex items-center justify-center bg-gray-800 hover:bg-gray-700 rounded-2xl transition-colors border border-gray-700"
                >
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                    >
                    </path>
                  </svg>
                </button>
              </div>
            </div>
            <!-- Additional Info -->
            <div class="space-y-4">
              <div class="flex items-center space-x-4 text-sm text-gray-400">
                <div class="flex items-center space-x-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                    >
                    </path>
                  </svg>
                  <span>Free Shipping</span>
                </div>
                <div class="flex items-center space-x-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                    >
                    </path>
                  </svg>
                  <span>30 Day Returns</span>
                </div>
                <div class="flex items-center space-x-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                    >
                    </path>
                  </svg>
                  <span>Secure Payment</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- Related Products -->
        <%= if length(@related_products) > 0 do %>
          <div class="mb-16">
            <h2 class="text-3xl font-bold text-white mb-8">Related Products</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <%= for product <- @related_products do %>
                <div
                  class="group relative bg-gray-800 rounded-2xl p-4 hover:bg-gray-700 transition-all duration-500 transform hover:-translate-y-2 cursor-pointer"
                  phx-click="navigate_to_product"
                  phx-value-product-id={product.id}
                >
                  <div class="relative overflow-hidden rounded-xl mb-4">
                    <img
                      src={product.featured_image}
                      class="w-full h-48 object-cover rounded-xl group-hover:scale-110 transition-transform duration-700"
                      alt={product.name}
                    />
                    <div class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                    </div>
                    <%= if product.is_featured do %>
                      <div class="absolute top-2 right-2 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-2 py-1 rounded-full text-xs font-bold shadow-lg">
                        Featured
                      </div>
                    <% end %>
                  </div>
                  <h3 class="text-lg font-bold mb-2 text-white group-hover:text-purple-400 transition-colors">
                    <%= product.name %>
                  </h3>
                  <p class="text-gray-400 text-sm mb-3 line-clamp-2">
                    <%= product.description %>
                  </p>
                  <div class="flex items-center justify-between">
                    <div class="flex items-center space-x-2">
                      <span class="text-gray-400 line-through text-sm">
                        ₹<%= Number.Delimit.number_to_delimited(product.price, precision: 2) %>
                      </span>
                      <span class="text-lg font-bold text-purple-400">
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
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("increase_quantity", _params, socket) do
    {:noreply, assign(socket, quantity: socket.assigns.quantity + 1)}
  end

  @impl true
  def handle_event("decrease_quantity", _params, socket) do
    quantity = max(1, socket.assigns.quantity - 1)
    {:noreply, assign(socket, quantity: quantity)}
  end

  @impl true
  def handle_event(
        "add_to_cart",
        %{"product-id" => product_id, "variant-id" => variant_id, "quantity" => quantity},
        socket
      ) do
    user = Map.get(socket.assigns, :current_user)

    cond do
      is_nil(user) ->
        {:noreply,
         socket
         |> put_flash(:error, "You must be logged in to add items to your cart.")
         |> push_navigate(to: "/users/log_in")}

      true ->
        CartItems.add_to_cart(user.id, product_id, variant_id, String.to_integer(quantity))
        {:noreply, put_flash(socket, :info, "Added to cart!")}
    end
  end

  @impl true
  def handle_event("select_variant", %{"variant" => variant_id}, socket) do
    {:noreply, assign(socket, selected_variant_id: variant_id)}
  end

  @impl true
  def handle_event("add_to_wishlist", %{"product-id" => _product_id}, socket) do
    # TODO: Implement add to wishlist functionality
    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate_to_product", %{"product-id" => product_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/products/#{product_id}")}
  end

  defp calculate_discount(original_price, selling_price) do
    original = Decimal.new(original_price)
    selling = Decimal.new(selling_price)
    diff = Decimal.sub(original, selling)
    percent = Decimal.div(diff, original) |> Decimal.mult(Decimal.new(100))
    percent |> Decimal.round(0) |> Decimal.to_integer()
  end

  defp get_category_name(category_id) do
    category = Repo.get(Category, category_id)
    if category, do: category.name, else: "Unknown"
  end

  defp display_price(product, variants, selected_variant_id, type) do
    case Enum.find(variants, &(&1.id == selected_variant_id)) do
      nil ->
        case type do
          :original -> product.price
          :selling -> product.selling_price
        end

      variant ->
        case type do
          :original -> variant.price_override || product.price
          :selling -> variant.price_override || product.selling_price
        end
    end
  end

  defp get_user_from_session(session) do
    token = session["user_token"]

    case token do
      nil ->
        nil

      token ->
        case Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> user
          {:error, _reason} -> nil
        end
    end
  end
end
