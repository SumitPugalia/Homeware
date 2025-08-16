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
    <div class="min-h-screen bg-brand-neutral-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Breadcrumb -->
        <nav class="mb-8">
          <ol class="flex items-center space-x-2 text-sm text-text-secondary">
            <li>
              <a href="/" class="hover:text-brand-primary transition-colors">Home</a>
            </li>
            <li class="flex items-center space-x-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7">
                </path>
              </svg>
              <a href="/products" class="hover:text-brand-primary transition-colors">Products</a>
            </li>
            <li class="flex items-center space-x-2">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7">
                </path>
              </svg>
              <span class="text-text-primary font-medium"><%= @product.name %></span>
            </li>
          </ol>
        </nav>
        <!-- Product Details -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 mb-16">
          <!-- Product Images -->
          <div class="space-y-4">
            <div class="relative overflow-hidden rounded-lg bg-white shadow-card border border-brand-neutral-200">
              <img
                src={@product.featured_image}
                class="w-full h-80 lg:h-96 object-cover"
                alt={@product.name}
              />
              <%= if @product.is_featured do %>
                <div class="absolute top-4 right-4 bg-brand-accent text-white px-3 py-1 rounded-full text-xs font-bold shadow-sm">
                  Featured
                </div>
              <% end %>
              <!-- Availability Badge -->
              <div class="absolute top-4 left-4">
                <span class={"px-3 py-1 rounded-full text-xs font-bold shadow-sm #{HomeWare.Products.Product.availability_color(@product)}"}>
                  <%= HomeWare.Products.Product.availability_status(@product) %>
                </span>
              </div>
              <!-- Out of Stock Overlay -->
              <%= if !@product.available? do %>
                <div class="absolute inset-0 bg-brand-neutral-900/50 flex items-center justify-center">
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
          <div class="space-y-8">
            <div>
              <h1 class="text-3xl font-bold text-text-primary mb-4"><%= @product.name %></h1>
              <p class="text-text-secondary text-base leading-relaxed">
                <%= @product.description %>
              </p>
            </div>
            <!-- Price Section -->
            <div class="space-y-4">
              <%= if @variants != [] do %>
                <div class="mb-6">
                  <label class="block text-text-primary font-semibold mb-3 text-sm">
                    Select Variant:
                  </label>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <%= for variant <- @variants do %>
                      <button
                        phx-click="select_variant"
                        phx-value-variant={variant.id}
                        phx-value-product-id={@product.id}
                        class={"relative p-4 rounded-lg border transition-all duration-200 text-left #{if @selected_variant_id == variant.id, do: "border-brand-primary bg-brand-primary/5", else: "border-brand-neutral-300 bg-white hover:border-brand-neutral-400 hover:bg-brand-neutral-50"} #{unless variant.available?, do: "opacity-50 cursor-not-allowed"} #{unless variant.available?, do: "disabled"}"}
                      >
                        <div class="flex items-center justify-between mb-2">
                          <span class="font-semibold text-text-primary text-sm">
                            <%= variant.option_name %>
                          </span>
                          <%= if @selected_variant_id == variant.id do %>
                            <svg
                              class="w-4 h-4 text-brand-primary"
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
                        <div class="text-xs text-text-secondary mb-2">SKU: <%= variant.sku %></div>
                        <%= if variant.price_override do %>
                          <div class="text-brand-primary font-semibold text-sm">
                            <%= Formatters.format_currency(variant.price_override) %>
                          </div>
                        <% end %>
                        <%= unless variant.available? do %>
                          <div class="absolute top-2 right-2 bg-red-600 text-white text-xs font-bold px-2 py-1 rounded">
                            Out of Stock
                          </div>
                        <% end %>
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <div class="flex items-center space-x-4">
                <span class="text-brand-neutral-400 line-through text-lg">
                  <%= Formatters.format_currency(
                    display_price(@product, @variants, @selected_variant_id, :original)
                  ) %>
                </span>
                <span class="text-3xl font-bold text-brand-primary">
                  <%= Formatters.format_currency(
                    display_price(@product, @variants, @selected_variant_id, :selling)
                  ) %>
                </span>
                <span class="bg-red-100 text-red-800 px-3 py-1 rounded-full text-xs font-semibold border border-red-200">
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
                <div class="bg-white p-4 rounded-lg shadow-card border border-brand-neutral-200">
                  <span class="text-text-secondary text-xs font-medium">Brand</span>
                  <p class="text-text-primary font-semibold text-sm mt-1"><%= @product.brand %></p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow-card border border-brand-neutral-200">
                  <span class="text-text-secondary text-xs font-medium">Category</span>
                  <p class="text-text-primary font-semibold text-sm mt-1">
                    <%= get_category_name(@product.category_id) %>
                  </p>
                </div>
              </div>
            </div>
            <!-- Quantity and Add to Cart -->
            <div class="space-y-6">
              <div class="flex items-center space-x-4">
                <label class="text-text-primary font-semibold text-sm">Quantity:</label>
                <div class="flex items-center space-x-2 bg-white border border-brand-neutral-300 rounded-lg p-1">
                  <button
                    phx-click="decrease_quantity"
                    class="w-8 h-8 flex items-center justify-center bg-brand-neutral-100 hover:bg-brand-neutral-200 rounded transition-colors"
                    aria-label="Decrease quantity"
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
                  <span class="w-12 text-center font-semibold text-text-primary text-sm">
                    <%= @quantity %>
                  </span>
                  <button
                    phx-click="increase_quantity"
                    class="w-8 h-8 flex items-center justify-center bg-brand-neutral-100 hover:bg-brand-neutral-200 rounded transition-colors"
                    aria-label="Increase quantity"
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
                <% selected_variant = Enum.find(@variants, &(&1.id == @selected_variant_id)) %>

                <%= if @variants && is_list(@variants) && length(@variants) > 0 do %>
                  <%= if selected_variant && selected_variant.available? do %>
                    <button
                      phx-click="add_to_cart"
                      phx-value-product-id={@product.id}
                      phx-value-variant-id={@selected_variant_id}
                      phx-value-quantity={@quantity}
                      class="flex-1 bg-brand-primary hover:bg-brand-primary-hover text-white px-6 py-3 rounded-lg font-semibold text-base transition-colors duration-200 shadow-sm hover:shadow-md"
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
                      class="flex-1 bg-brand-neutral-200 text-brand-neutral-400 px-6 py-3 rounded-lg font-semibold text-base cursor-not-allowed"
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
                      class="flex-1 bg-brand-primary hover:bg-brand-primary-hover text-white px-6 py-3 rounded-lg font-semibold text-base transition-colors duration-200 shadow-sm hover:shadow-md"
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
                      class="flex-1 bg-brand-neutral-200 text-brand-neutral-400 px-6 py-3 rounded-lg font-semibold text-base cursor-not-allowed"
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
                  class={"w-12 h-12 flex items-center justify-center rounded-lg transition-colors border #{if @is_in_wishlist, do: "bg-brand-accent hover:bg-brand-accent/80 border-brand-accent", else: "bg-white hover:bg-brand-neutral-50 border-brand-neutral-300"}"}
                  title={if @is_in_wishlist, do: "Remove from wishlist", else: "Add to wishlist"}
                  aria-label={if @is_in_wishlist, do: "Remove from wishlist", else: "Add to wishlist"}
                >
                  <svg
                    class={"w-5 h-5 #{if @is_in_wishlist, do: "text-white", else: "text-brand-neutral-400"}"}
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
            <div class="space-y-4">
              <div class="flex items-center space-x-6 text-xs text-text-secondary">
                <div class="flex items-center space-x-2">
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
                <div class="flex items-center space-x-2">
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
                <div class="flex items-center space-x-2">
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
            <h2 class="text-2xl font-bold text-text-primary mb-8">Related Products</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
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
