defmodule HomeWareWeb.WishlistLive do
  use HomeWareWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, wishlist_items: [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">
          <h1 class="text-2xl font-bold text-gray-900 mb-6">Wishlist</h1>

          <%= if Enum.empty?(@wishlist_items) do %>
            <div class="text-center py-12">
              <p class="text-gray-500">Your wishlist is empty.</p>
            </div>
          <% else %>
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              <%= for item <- @wishlist_items do %>
                <div class="bg-white shadow rounded-lg p-6">
                  <h3 class="text-lg font-medium text-gray-900"><%= item.name %></h3>
                  <p class="text-gray-500 mt-2"><%= item.description %></p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
