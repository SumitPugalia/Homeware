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
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex">
              <div class="flex-shrink-0 flex items-center">
                <a href="/" class="text-xl font-bold text-gray-900">HomeWare</a>
              </div>
            </div>
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <a href="/cart" class="relative p-2 text-gray-400 hover:text-gray-500">
                  <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m6 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                    />
                  </svg>
                </a>
              </div>
              <div class="ml-4 flex items-center md:ml-6">
                <%= if @current_user do %>
                  <div class="ml-3 relative">
                    <div class="flex items-center">
                      <span class="text-sm text-gray-700 mr-4">
                        Welcome, <%= @current_user.first_name %>
                      </span>
                      <a href="/profile" class="text-sm text-gray-700 hover:text-gray-900 mr-4">
                        Profile
                      </a>
                      <a href="/orders" class="text-sm text-gray-700 hover:text-gray-900 mr-4">
                        Orders
                      </a>
                      <form action="/users/log_out" method="post" class="inline">
                        <button type="submit" class="text-sm text-gray-700 hover:text-gray-900">
                          Logout
                        </button>
                      </form>
                    </div>
                  </div>
                <% else %>
                  <div class="flex items-center space-x-4">
                    <a href="/users/log_in" class="text-sm text-gray-700 hover:text-gray-900">
                      Sign in
                    </a>
                    <a
                      href="/users/register"
                      class="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700"
                    >
                      Sign up
                    </a>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </nav>
      <!-- Product Detail -->
      <div class="bg-white">
        <div class="max-w-7xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
          <!-- Breadcrumb -->
          <nav class="flex mb-8" aria-label="Breadcrumb">
            <ol class="flex items-center space-x-4">
              <li>
                <a href="/" class="text-gray-400 hover:text-gray-500">Home</a>
              </li>
              <li>
                <div class="flex items-center">
                  <svg
                    class="flex-shrink-0 h-5 w-5 text-gray-300"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <a href="/products" class="ml-4 text-gray-400 hover:text-gray-500">Products</a>
                </div>
              </li>
              <li>
                <div class="flex items-center">
                  <svg
                    class="flex-shrink-0 h-5 w-5 text-gray-300"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <span class="ml-4 text-gray-500"><%= @product.name %></span>
                </div>
              </li>
            </ol>
          </nav>

          <div class="lg:grid lg:grid-cols-2 lg:gap-x-8 lg:gap-y-8">
            <!-- Product Images -->
            <div class="lg:col-span-1">
              <div class="aspect-w-1 aspect-h-1 w-full">
                <img
                  src="https://via.placeholder.com/600x600"
                  alt={@product.name}
                  class="w-full h-full object-center object-cover rounded-lg"
                />
              </div>
              <!-- Thumbnail Images -->
              <div class="mt-4 grid grid-cols-4 gap-4">
                <%= for _i <- 0..3 do %>
                  <button class="aspect-w-1 aspect-h-1 w-full">
                    <img
                      src="https://via.placeholder.com/150x150"
                      alt="Product thumbnail"
                      class="w-full h-full object-center object-cover rounded-lg border-2 border-gray-200 hover:border-indigo-500"
                    />
                  </button>
                <% end %>
              </div>
            </div>
            <!-- Product Info -->
            <div class="lg:col-span-1 lg:pl-8">
              <h1 class="text-3xl font-extrabold text-gray-900"><%= @product.name %></h1>
              <p class="mt-2 text-lg text-gray-500"><%= @product.brand %></p>
              <!-- Price -->
              <div class="mt-4">
                <span class="text-3xl font-bold text-gray-900">$<%= @product.price %></span>
                <%= if @product.original_price && @product.original_price > @product.price do %>
                  <span class="ml-2 text-lg text-gray-500 line-through">
                    $<%= @product.original_price %>
                  </span>
                <% end %>
              </div>
              <!-- Rating -->
              <div class="mt-4 flex items-center">
                <div class="flex items-center">
                  <%= for _ <- 1..5 do %>
                    <svg class="text-yellow-400 h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  <% end %>
                </div>
                <span class="ml-2 text-sm text-gray-500">(4.5 out of 5)</span>
                <span class="ml-2 text-sm text-gray-500">• 128 reviews</span>
              </div>
              <!-- Description -->
              <div class="mt-6">
                <h3 class="text-lg font-medium text-gray-900">Description</h3>
                <p class="mt-2 text-gray-600"><%= @product.description %></p>
              </div>
              <!-- Features -->
              <div class="mt-6">
                <h3 class="text-lg font-medium text-gray-900">Key Features</h3>
                <ul class="mt-2 text-gray-600 space-y-2">
                  <li>• Energy efficient design</li>
                  <li>• Quiet operation</li>
                  <li>• Easy to clean</li>
                  <li>• 2-year warranty</li>
                </ul>
              </div>
              <!-- Add to Cart -->
              <div class="mt-8">
                <div class="flex items-center space-x-4">
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
                      class="w-16 text-center border-0 focus:ring-0"
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
                    class="flex-1 bg-indigo-600 text-white py-3 px-6 rounded-md hover:bg-indigo-700 transition-colors"
                  >
                    Add to Cart
                  </button>
                </div>
              </div>
              <!-- Stock Status -->
              <div class="mt-4">
                <%= if @product.inventory_quantity > 0 do %>
                  <span class="text-green-600 text-sm">
                    ✓ In Stock (<%= @product.inventory_quantity %> available)
                  </span>
                <% else %>
                  <span class="text-red-600 text-sm">✗ Out of Stock</span>
                <% end %>
              </div>
            </div>
          </div>
          <!-- Product Tabs -->
          <div class="mt-16">
            <div class="border-b border-gray-200">
              <nav class="-mb-px flex space-x-8">
                <button class="border-indigo-500 text-indigo-600 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm">
                  Specifications
                </button>
                <button class="border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm">
                  Reviews
                </button>
                <button class="border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm">
                  Shipping
                </button>
              </nav>
            </div>
            <!-- Tab Content -->
            <div class="mt-8">
              <div class="prose prose-lg max-w-none">
                <h3>Product Specifications</h3>
                <table class="w-full">
                  <tbody class="divide-y divide-gray-200">
                    <tr>
                      <td class="py-2 font-medium text-gray-900">Brand</td>
                      <td class="py-2 text-gray-600"><%= @product.brand %></td>
                    </tr>
                    <tr>
                      <td class="py-2 font-medium text-gray-900">Model</td>
                      <td class="py-2 text-gray-600"><%= @product.model %></td>
                    </tr>
                    <tr>
                      <td class="py-2 font-medium text-gray-900">Dimensions</td>
                      <td class="py-2 text-gray-600">24" W x 24" D x 36" H</td>
                    </tr>
                    <tr>
                      <td class="py-2 font-medium text-gray-900">Weight</td>
                      <td class="py-2 text-gray-600">45 lbs</td>
                    </tr>
                    <tr>
                      <td class="py-2 font-medium text-gray-900">Warranty</td>
                      <td class="py-2 text-gray-600">2 years</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <!-- Related Products -->
          <div class="mt-16">
            <h2 class="text-2xl font-bold text-gray-900 mb-8">Related Products</h2>
            <div class="grid grid-cols-1 gap-y-10 gap-x-6 sm:grid-cols-2 lg:grid-cols-4 xl:gap-x-8">
              <%= for product <- @related_products do %>
                <div class="group relative">
                  <div class="w-full min-h-80 bg-gray-200 aspect-w-1 aspect-h-1 rounded-md overflow-hidden group-hover:opacity-75 lg:h-80 lg:aspect-none">
                    <img
                      src="https://via.placeholder.com/300x300"
                      alt={product.name}
                      class="w-full h-full object-center object-cover lg:w-full lg:h-full"
                    />
                  </div>
                  <div class="mt-4 flex justify-between">
                    <div>
                      <h3 class="text-sm text-gray-700">
                        <a href={~p"/products/#{product.id}"}>
                          <span aria-hidden="true" class="absolute inset-0"></span>
                          <%= product.name %>
                        </a>
                      </h3>
                      <p class="mt-1 text-sm text-gray-500"><%= product.brand %></p>
                    </div>
                    <p class="text-sm font-medium text-gray-900">$<%= product.price %></p>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
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
