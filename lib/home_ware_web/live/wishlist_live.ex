defmodule HomeWareWeb.WishlistLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}
  on_mount {HomeWareWeb.NavCountsLive, :default}

  alias HomeWare.WishlistItems

  @impl true
  def mount(_params, session, socket) do
    # Assign current_user for layout compatibility
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)

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
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-14xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">
          <div class="flex items-center justify-between mb-6">
            <h1 class="text-2xl font-bold text-gray-900">My Wishlist</h1>
            <span class="text-sm text-gray-500">
              <%= @wishlist_count %> item<%= if @wishlist_count != 1, do: "s", else: "" %>
            </span>
          </div>

          <%= if Enum.empty?(@wishlist_items) do %>
            <div class="text-center py-12">
              <div class="w-24 h-24 bg-gray-200 rounded-full flex items-center justify-center mx-auto mb-6">
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
              <h3 class="text-lg font-medium text-gray-900 mb-2">Your wishlist is empty</h3>
              <p class="text-gray-500 mb-6">
                Start adding products to your wishlist to save them for later.
              </p>
              <a
                href="/products"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Browse Products
              </a>
            </div>
          <% else %>
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              <%= for item <- @wishlist_items do %>
                <div class="bg-white shadow rounded-lg overflow-hidden">
                  <div class="relative">
                    <img
                      src={item.product.featured_image || "https://via.placeholder.com/300x200"}
                      alt={item.product.name}
                      class="w-full h-48 object-cover"
                    />
                    <button
                      phx-click="remove_from_wishlist"
                      phx-value-product-id={item.product.id}
                      class="absolute top-2 right-2 w-8 h-8 bg-white rounded-full shadow-md flex items-center justify-center hover:bg-red-50 transition-colors"
                      title="Remove from wishlist"
                    >
                      <svg class="w-4 h-4 text-red-500" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" />
                      </svg>
                    </button>
                    <%= unless item.product.available? do %>
                      <div class="absolute top-2 left-2">
                        <span class="bg-red-100 text-red-800 text-xs font-medium px-2 py-1 rounded">
                          Out of Stock
                        </span>
                      </div>
                    <% end %>
                  </div>
                  <div class="p-4">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                      <a href={~p"/products/#{item.product.id}"} class="hover:text-indigo-600">
                        <%= item.product.name %>
                      </a>
                    </h3>
                    <p class="text-sm text-gray-500 mb-2"><%= item.product.brand %></p>
                    <div class="flex items-center justify-between">
                      <span class="text-lg font-bold text-gray-900">
                        ₹<%= Number.Delimit.number_to_delimited(item.product.selling_price,
                          precision: 2
                        ) %>
                      </span>
                      <button
                        phx-click="add_to_cart"
                        phx-value-product-id={item.product.id}
                        disabled={!item.product.available?}
                        class="px-3 py-1 text-sm font-medium text-white bg-indigo-600 rounded hover:bg-indigo-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
                      >
                        Add to Cart
                      </button>
                    </div>
                  </div>
                </div>
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
