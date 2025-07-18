defmodule HomeWareWeb.ProductDetailLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.NavCountsLive, :default}

  alias HomeWare.Repo
  alias HomeWare.Products
  alias HomeWare.Categories.Category
  alias Decimal
  alias HomeWare.CartItems
  alias HomeWare.WishlistItems
  alias HomeWareWeb.SessionUtils
  alias HomeWareWeb.Formatters
  require Logger

  # Import components
  import HomeWareWeb.ProductCard, only: [product_card: 1]

  # Product detail pages should be publicly accessible
  # on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket = SessionUtils.assign_current_user(socket, session)

    product = Products.get_product_with_variants!(id)
    variants = product.variants || []
    selected_variant_id = if variants != [], do: hd(variants).id, else: nil

    # Get related products from the same category
    related_products = Products.list_related_products(product)

    # Check if product is in user's wishlist
    is_in_wishlist =
      if socket.assigns[:current_user] do
        WishlistItems.is_in_wishlist?(socket.assigns[:current_user].id, product.id)
      else
        false
      end

    {:ok,
     assign(socket,
       product: product,
       variants: variants,
       selected_variant_id: selected_variant_id,
       related_products: related_products,
       quantity: 1,
       is_in_wishlist: is_in_wishlist
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
      <div class="container mx-auto px-4 py-6">
        <!-- Breadcrumb -->
        <nav class="mb-6">
          <ol class="flex items-center space-x-1 text-xs text-gray-400">
            <li>
              <a href="/" class="hover:text-purple-400 transition-colors">Home</a>
            </li>
            <li class="flex items-center space-x-1">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7">
                </path>
              </svg>
              <a href="/products" class="hover:text-purple-400 transition-colors">Products</a>
            </li>
            <li class="flex items-center space-x-1">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7">
                </path>
              </svg>
              <span class="text-white"><%= @product.name %></span>
            </li>
          </ol>
        </nav>
        <!-- Product Details -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-12">
          <!-- Product Images -->
          <div class="space-y-4">
            <div class="relative overflow-hidden rounded-xl bg-gray-800">
              <img
                src={@product.featured_image}
                class="w-full h-80 lg:h-96 object-cover"
                alt={@product.name}
              />
              <%= if @product.is_featured do %>
                <div class="absolute top-4 right-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-3 py-1 rounded-full text-xs font-bold shadow-lg">
                  Featured
                </div>
              <% end %>
              <!-- Availability Badge -->
              <div class="absolute top-4 left-4">
                <span class={"px-3 py-1 rounded-full text-xs font-bold shadow-lg #{HomeWare.Products.Product.availability_color(@product)}"}>
                  <%= HomeWare.Products.Product.availability_status(@product) %>
                </span>
              </div>
              <!-- Out of Stock Overlay -->
              <%= if !@product.available? do %>
                <div class="absolute inset-0 bg-black/60 flex items-center justify-center rounded-xl">
                  <div class="text-center">
                    <svg
                      class="w-12 h-12 text-white mx-auto mb-3"
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
                    <span class="text-white font-bold text-xl">Out of Stock</span>
                    <p class="text-white/80 text-sm mt-1">This item is currently unavailable</p>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          <!-- Product Info -->
          <div class="space-y-6">
            <div>
              <h1 class="text-3xl font-bold text-white mb-3"><%= @product.name %></h1>
              <p class="text-gray-400 text-base leading-relaxed mb-4">
                <%= @product.description %>
              </p>
            </div>
            <!-- Price Section -->
            <div class="space-y-3">
              <%= if @variants != [] do %>
                <div class="mb-4">
                  <label class="block text-gray-300 font-semibold mb-2 text-sm">
                    Select Variant:
                  </label>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    <%= for variant <- @variants do %>
                      <button
                        phx-click="select_variant"
                        phx-value-variant={variant.id}
                        phx-value-product-id={@product.id}
                        class={"relative p-3 rounded-lg border transition-all duration-300 text-left #{if @selected_variant_id == variant.id, do: "border-purple-500 bg-purple-500/10", else: "border-gray-600 bg-gray-700 hover:border-gray-500 hover:bg-gray-600"} #{unless variant.available?, do: "opacity-50 cursor-not-allowed"} #{unless variant.available?, do: "disabled"}"}
                      >
                        <div class="flex items-center justify-between mb-1">
                          <span class="font-semibold text-white text-sm">
                            <%= variant.option_name %>
                          </span>
                          <%= if @selected_variant_id == variant.id do %>
                            <svg
                              class="w-4 h-4 text-purple-400"
                              fill="currentColor"
                              viewBox="0 0 20 20"
                            >
                              <path
                                fill-rule="evenodd"
                                d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                clip-rule="evenodd"
                              />
                            </svg>
                          <% end %>
                        </div>
                        <div class="text-xs text-gray-400 mb-1">SKU: <%= variant.sku %></div>
                        <%= if variant.price_override do %>
                          <div class="text-purple-400 font-semibold text-sm">
                            ₹<%= Formatters.format_currency(variant.price_override) %>
                          </div>
                        <% end %>
                        <%= unless variant.available? do %>
                          <div class="absolute top-1 right-1 bg-red-600 text-white text-xs font-bold px-1 py-0.5 rounded">
                            Out of Stock
                          </div>
                        <% end %>
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <div class="flex items-center space-x-3">
                <span class="text-gray-400 line-through text-lg">
                  ₹<%= Formatters.format_currency(
                    display_price(@product, @variants, @selected_variant_id, :original)
                  ) %>
                </span>
                <span class="text-3xl font-bold text-purple-400">
                  ₹<%= Formatters.format_currency(
                    display_price(@product, @variants, @selected_variant_id, :selling)
                  ) %>
                </span>
                <span class="bg-red-500/20 text-red-400 px-2 py-1 rounded-full text-xs font-semibold border border-red-500/30">
                  <%= calculate_discount(
                    display_price(@product, @variants, @selected_variant_id, :original),
                    display_price(@product, @variants, @selected_variant_id, :selling)
                  ) %>% OFF
                </span>
              </div>
            </div>
            <!-- Product Details -->
            <div class="space-y-3">
              <div class="grid grid-cols-2 gap-3">
                <div class="bg-gray-800 p-3 rounded-lg">
                  <span class="text-gray-400 text-xs">Brand</span>
                  <p class="text-white font-semibold text-sm"><%= @product.brand %></p>
                </div>
                <div class="bg-gray-800 p-3 rounded-lg">
                  <span class="text-gray-400 text-xs">Category</span>
                  <p class="text-white font-semibold text-sm">
                    <%= get_category_name(@product.category_id) %>
                  </p>
                </div>
              </div>
            </div>
            <!-- Quantity and Add to Cart -->
            <div class="space-y-4">
              <div class="flex items-center space-x-3">
                <label class="text-gray-300 font-semibold text-sm">Quantity:</label>
                <div class="flex items-center space-x-2 bg-gray-800 rounded-lg p-1">
                  <button
                    phx-click="decrease_quantity"
                    class="w-6 h-6 flex items-center justify-center bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                  >
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M20 12H4"
                      >
                      </path>
                    </svg>
                  </button>
                  <span class="w-8 text-center font-semibold text-white text-sm">
                    <%= @quantity %>
                  </span>
                  <button
                    phx-click="increase_quantity"
                    class="w-6 h-6 flex items-center justify-center bg-gray-700 hover:bg-gray-600 rounded transition-colors"
                  >
                    <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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

              <div class="flex items-center space-x-3">
                <% selected_variant = Enum.find(@variants, &(&1.id == @selected_variant_id)) %>

                <%= if @variants && is_list(@variants) && length(@variants) > 0 do %>
                  <%= if selected_variant && selected_variant.available? do %>
                    <button
                      phx-click="add_to_cart"
                      phx-value-product-id={@product.id}
                      phx-value-variant-id={@selected_variant_id}
                      phx-value-quantity={@quantity}
                      class="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-bold text-base hover:from-purple-600 hover:to-pink-600 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-purple-500/25"
                    >
                      <div class="flex items-center justify-center space-x-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
                  <% else %>
                    <button
                      disabled
                      class="flex-1 bg-gray-500 text-gray-300 px-6 py-3 rounded-lg font-bold text-base cursor-not-allowed"
                    >
                      <div class="flex items-center justify-center space-x-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                          >
                          </path>
                        </svg>
                        <span>Out of Stock</span>
                      </div>
                    </button>
                  <% end %>
                <% else %>
                  <%= if @product.available? do %>
                    <button
                      phx-click="add_to_cart"
                      phx-value-product-id={@product.id}
                      phx-value-quantity={@quantity}
                      class="flex-1 bg-gradient-to-r from-purple-500 to-pink-500 text-white px-6 py-3 rounded-lg font-bold text-base hover:from-purple-600 hover:to-pink-600 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-purple-500/25"
                    >
                      <div class="flex items-center justify-center space-x-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
                  <% else %>
                    <button
                      disabled
                      class="flex-1 bg-gray-500 text-gray-300 px-6 py-3 rounded-lg font-bold text-base cursor-not-allowed"
                    >
                      <div class="flex items-center justify-center space-x-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                          >
                          </path>
                        </svg>
                        <span>Out of Stock</span>
                      </div>
                    </button>
                  <% end %>
                <% end %>
                <button
                  phx-click={if @is_in_wishlist, do: "remove_from_wishlist", else: "add_to_wishlist"}
                  phx-value-product-id={@product.id}
                  class={"w-10 h-10 flex items-center justify-center rounded-lg transition-colors border #{if @is_in_wishlist, do: "bg-pink-600 hover:bg-pink-700 border-pink-500", else: "bg-gray-800 hover:bg-gray-700 border-gray-700"}"}
                  title={if @is_in_wishlist, do: "Remove from wishlist", else: "Add to wishlist"}
                >
                  <svg
                    class={"w-5 h-5 #{if @is_in_wishlist, do: "text-white", else: "text-gray-400"}"}
                    fill={if @is_in_wishlist, do: "currentColor", else: "none"}
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
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
            <div class="space-y-3">
              <div class="flex items-center space-x-4 text-xs text-gray-400">
                <div class="flex items-center space-x-1">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
                <div class="flex items-center space-x-1">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
                <div class="flex items-center space-x-1">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
          <div class="mb-12">
            <h2 class="text-2xl font-bold text-white mb-6">Related Products</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <%= for product <- @related_products do %>
                <.product_card product={product} />
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
        %{"product-id" => product_id, "variant-id" => variant_id, "quantity" => quantity} =
          params,
        socket
      ) do
    Logger.debug(
      "[add_to_cart] With variant: params=#{inspect(params)}, assigns=#{inspect(socket.assigns)}"
    )

    user = Map.get(socket.assigns, :current_user)

    cond do
      is_nil(user) ->
        {:noreply,
         socket
         |> put_flash(:error, "You must be logged in to add items to your cart.")
         |> push_navigate(to: "/users/log_in")}

      true ->
        # Check if product exists and is available
        product = HomeWare.Products.get_product_with_variants!(product_id)

        if product.available? do
          case CartItems.add_to_cart(
                 user.id,
                 product_id,
                 variant_id,
                 String.to_integer(quantity)
               ) do
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
  def handle_event(
        "add_to_cart",
        %{"product-id" => product_id, "quantity" => quantity} = params,
        socket
      ) do
    Logger.debug(
      "[add_to_cart] No variant: params=#{inspect(params)}, assigns=#{inspect(socket.assigns)}"
    )

    user = Map.get(socket.assigns, :current_user)

    cond do
      is_nil(user) ->
        {:noreply,
         socket
         |> put_flash(:error, "You must be logged in to add items to your cart.")
         |> push_navigate(to: "/users/log_in")}

      true ->
        # Check if product exists and is available
        product = HomeWare.Products.get_product_with_variants!(product_id)

        if product.available? do
          case CartItems.add_to_cart(user.id, product_id, nil, String.to_integer(quantity)) do
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
  def handle_event("add_to_cart", %{"product-id" => product_id} = params, socket) do
    Logger.debug(
      "[add_to_cart] Fallback: params=#{inspect(params)}, assigns=#{inspect(socket.assigns)}"
    )

    handle_event(
      "add_to_cart",
      %{"product-id" => product_id, "quantity" => socket.assigns.quantity},
      socket
    )
  end

  @impl true
  def handle_event("select_variant", %{"variant" => variant_id}, socket) do
    {:noreply, assign(socket, selected_variant_id: variant_id)}
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
            {:noreply,
             socket
             |> assign(is_in_wishlist: true)
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
            {:noreply,
             socket
             |> assign(is_in_wishlist: false)
             |> put_flash(:info, "Removed from wishlist!")}

          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Item not found in wishlist.")}
        end
    end
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
end
