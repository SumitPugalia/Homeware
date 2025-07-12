defmodule HomeWareWeb.ProductDetailLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Products

  @impl true
  def mount(%{"id" => product_id}, _session, socket) do
    product = Products.get_product!(product_id)
    related_products = Products.list_related_products(product)
    reviews = Products.list_product_reviews(product_id)

    {:ok,
     assign(socket,
       product: product,
       related_products: related_products,
       reviews: reviews,
       quantity: 1,
       selected_image: 0,
       show_review_form: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-white">
      <main class="flex-1 w-full max-w-7xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8 py-8">
        <!-- Breadcrumb -->
        <nav class="text-sm text-gray-400 mb-6" aria-label="Breadcrumb">
          <ol class="list-reset flex">
            <li><a href="/" class="hover:text-black">Account</a></li>
            <li><span class="mx-2">/</span></li>
            <li><a href="/products" class="hover:text-black">Gaming</a></li>
            <li><span class="mx-2">/</span></li>
            <li class="text-black"><%= @product.name %></li>
          </ol>
        </nav>
        <!-- Product Detail Section -->
        <div class="flex flex-col lg:flex-row gap-12 mb-12">
          <!-- Left: Image Gallery -->
          <div class="flex flex-col lg:w-1/2">
            <div class="flex flex-row lg:flex-col gap-4 mb-4 lg:mb-0 lg:mr-4">
              <%= for i <- 0..3 do %>
                <button class="border-2 border-gray-200 rounded-lg p-1 hover:border-red-500">
                  <img
                    src="https://via.placeholder.com/80x80"
                    alt="Product thumbnail"
                    class="w-16 h-16 object-cover rounded"
                  />
                </button>
              <% end %>
            </div>
            <div class="flex-1 flex items-center justify-center">
              <img
                src="https://via.placeholder.com/400x400"
                alt={@product.name}
                class="rounded-xl w-full max-w-md object-cover shadow-lg"
              />
            </div>
          </div>
          <!-- Right: Product Info -->
          <div class="flex-1 flex flex-col">
            <h1 class="text-2xl font-bold mb-2"><%= @product.name %></h1>
            <div class="flex items-center mb-2">
              <span class="text-yellow-400 mr-1">★★★★★</span>
              <span class="text-gray-500 text-sm">(150 Reviews)</span>
              <span class="ml-2 text-green-600 text-sm font-semibold">In Stock</span>
            </div>
            <div class="text-2xl font-bold mb-2">$<%= @product.price %></div>
            <div class="mb-4 text-gray-600"><%= @product.description %></div>
            <!-- Colours -->
            <div class="mb-4">
              <div class="font-semibold mb-1">Colours:</div>
              <div class="flex space-x-2">
                <span class="w-6 h-6 rounded-full bg-red-700 border-2 border-gray-300 inline-block">
                </span>
                <span class="w-6 h-6 rounded-full bg-gray-700 border-2 border-gray-300 inline-block">
                </span>
              </div>
            </div>
            <!-- Sizes -->
            <div class="mb-4">
              <div class="font-semibold mb-1">Size:</div>
              <div class="flex space-x-2">
                <%= for size <- ["XS", "S", "M", "L", "XL"] do %>
                  <button class="px-3 py-1 border rounded hover:bg-red-500 hover:text-white">
                    <%= size %>
                  </button>
                <% end %>
              </div>
            </div>
            <!-- Quantity and Buy Now -->
            <div class="flex items-center space-x-4 mb-4">
              <div class="flex items-center border border-gray-300 rounded-md">
                <button
                  phx-click="decrease_quantity"
                  class="px-3 py-2 text-gray-600 hover:text-gray-900"
                >
                  -
                </button>
                <input
                  type="number"
                  value={@quantity}
                  min="1"
                  class="w-12 text-center border-0 focus:ring-0"
                  readonly
                />
                <button
                  phx-click="increase_quantity"
                  class="px-3 py-2 text-gray-600 hover:text-gray-900"
                >
                  +
                </button>
              </div>
              <button
                phx-click="add_to_cart"
                class="bg-red-500 text-white px-8 py-3 rounded-md font-semibold hover:bg-red-600 transition"
              >
                Buy Now
              </button>
              <button class="border border-gray-300 rounded-full p-2 hover:bg-gray-100">
                <svg
                  class="w-6 h-6 text-gray-500"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4.318 6.318a4.5 4.5 0 0 1 6.364 0L12 7.636l1.318-1.318a4.5 4.5 0 1 1 6.364 6.364L12 21.364l-7.682-7.682a4.5 4.5 0 0 1 0-6.364z"
                  />
                </svg>
              </button>
            </div>
            <!-- Delivery & Return -->
            <div class="flex flex-col md:flex-row gap-4 mb-4">
              <div class="flex-1 flex items-center border rounded-lg p-4">
                <svg
                  class="w-8 h-8 text-black mr-3"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 10h1l2 7h13l2-7h1"
                  />
                </svg>
                <div>
                  <div class="font-semibold">Free Delivery</div>
                  <div class="text-xs text-gray-500">
                    Enter your postal code for Delivery Availability
                  </div>
                </div>
              </div>
              <div class="flex-1 flex items-center border rounded-lg p-4">
                <svg
                  class="w-8 h-8 text-black mr-3"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M5 13l4 4L19 7"
                  />
                </svg>
                <div>
                  <div class="font-semibold">Return Delivery</div>
                  <div class="text-xs text-gray-500">
                    Free 30 Days Delivery Returns. <a href="#" class="underline">Details</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- Related Items -->
        <div class="mt-16">
          <div class="mb-4 flex items-center">
            <span class="text-red-500 font-bold mr-2">Related Item</span>
          </div>
          <div class="flex space-x-6 overflow-x-auto pb-4">
            <%= for product <- @related_products do %>
              <div class="min-w-[220px] bg-white rounded-lg shadow p-4 flex flex-col items-center border">
                <img src="https://via.placeholder.com/150" class="w-32 h-32 object-cover mb-2" />
                <div class="text-center">
                  <div class="font-bold text-sm mb-1"><%= product.name %></div>
                  <div class="text-xs text-gray-500 mb-1">$<%= product.price %></div>
                  <button class="bg-black text-white px-3 py-1 rounded text-xs mt-2">
                    Add To Cart
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("add_to_cart", _params, socket) do
    # TODO: Implement add to cart functionality
    {:noreply, put_flash(socket, :info, "Product added to cart!")}
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
end
