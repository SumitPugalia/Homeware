defmodule HomeWareWeb.WishlistLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}
  on_mount {HomeWareWeb.NavCountsLive, :default}

  alias HomeWare.WishlistItems
  alias HomeWareWeb.SessionUtils

  # Import the product_card component for consistent UI
  import HomeWareWeb.ProductCard, only: [product_card: 1]

  @impl true
  def mount(_params, session, socket) do
    # Assign current_user for layout compatibility
    socket = SessionUtils.assign_current_user(socket, session)

    wishlist_items = WishlistItems.list_user_wishlist_items(socket.assigns.current_user.id)
    wishlist_count = WishlistItems.get_user_wishlist_count(socket.assigns.current_user.id)

    {:ok,
     assign(socket,
       wishlist_items: wishlist_items,
       wishlist_count: wishlist_count
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white py-8">
      <div class="max-w-7xl mx-auto px-4 sm:px-6">
        <div class="px-4 py-6 sm:px-0">
          <div class="flex items-center justify-between mb-6">
            <h1 class="text-3xl md:text-4xl font-bold text-white mb-4">
              My
              <span class="bg-gradient-to-r from-purple-400 to-pink-400 bg-clip-text text-transparent">
                Wishlist
              </span>
            </h1>
            <span class="text-sm text-gray-400">
              <%= @wishlist_count %> item<%= if @wishlist_count != 1, do: "s", else: "" %>
            </span>
          </div>

          <%= if Enum.empty?(@wishlist_items) do %>
            <div class="text-center py-12">
              <div class="w-24 h-24 bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-6">
                <svg
                  class="w-12 h-12 text-gray-400"
                  fill="none"
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
              </div>
              <h3 class="text-lg font-medium text-white mb-2">Your wishlist is empty</h3>
              <p class="text-gray-400 mb-6">
                Start adding products to your wishlist to save them for later.
              </p>
              <a
                href="/products"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600"
              >
                Browse Products
              </a>
            </div>
          <% else %>
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              <%= for item <- @wishlist_items do %>
                <.product_card
                  product={item.product}
                  remove_from_wishlist={true}
                  add_to_cart_event="add_to_cart"
                  remove_from_wishlist_event="remove_from_wishlist"
                />
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("remove_from_wishlist", %{"product-id" => product_id}, socket) do
    case WishlistItems.remove_from_wishlist(socket.assigns.current_user.id, product_id) do
      {:ok, :deleted} ->
        wishlist_items = WishlistItems.list_user_wishlist_items(socket.assigns.current_user.id)
        wishlist_count = WishlistItems.get_user_wishlist_count(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(wishlist_items: wishlist_items, wishlist_count: wishlist_count)
         |> put_flash(:info, "Product removed from wishlist")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Product not found in wishlist")}
    end
  end

  @impl true
  def handle_event("add_to_cart", %{"product-id" => _product_id}, socket) do
    # TODO: Implement add to cart functionality
    {:noreply, put_flash(socket, :info, "Product added to cart")}
  end
end
