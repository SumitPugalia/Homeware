defmodule HomeWareWeb.SearchLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Products
  alias HomeWare.Categories

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       query: "",
       results: [],
       categories: Categories.list_categories(),
       filters: %{},
       sort_by: "relevance",
       page: 1,
       per_page: 12
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
      <!-- Search Header -->
      <div class="bg-white">
        <div class="max-w-7xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
          <div class="text-center">
            <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
              Search Products
            </h1>
            <p class="mt-4 text-lg text-gray-500">
              Find the perfect appliance for your home
            </p>
          </div>
          <!-- Search Form -->
          <div class="mt-8 max-w-2xl mx-auto">
            <form phx-submit="search" class="relative">
              <div class="relative">
                <input
                  type="text"
                  name="query"
                  value={@query}
                  placeholder="Search for products, brands, or categories..."
                  class="w-full px-4 py-3 pl-12 pr-4 text-gray-900 placeholder-gray-500 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                />
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg
                    class="h-5 w-5 text-gray-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                    />
                  </svg>
                </div>
                <button
                  type="submit"
                  class="absolute inset-y-0 right-0 px-4 py-2 bg-indigo-600 text-white rounded-r-lg hover:bg-indigo-700"
                >
                  Search
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
      <!-- Search Results -->
      <%= if @query != "" do %>
        <div class="bg-white">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="lg:grid lg:grid-cols-4 lg:gap-x-8 lg:items-start">
              <!-- Filters -->
              <div class="lg:col-span-1">
                <div class="bg-gray-50 rounded-lg p-6">
                  <h3 class="text-lg font-medium text-gray-900 mb-4">Filters</h3>
                  <!-- Category Filter -->
                  <div class="mb-6">
                    <h4 class="text-sm font-medium text-gray-900 mb-2">Category</h4>
                    <div class="space-y-2">
                      <%= for category <- @categories do %>
                        <label class="flex items-center">
                          <input
                            type="checkbox"
                            phx-click="toggle_category"
                            phx-value-category={category.id}
                            class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                          />
                          <span class="ml-2 text-sm text-gray-700"><%= category.name %></span>
                        </label>
                      <% end %>
                    </div>
                  </div>
                  <!-- Price Filter -->
                  <div class="mb-6">
                    <h4 class="text-sm font-medium text-gray-900 mb-2">Price Range</h4>
                    <div class="space-y-2">
                      <label class="flex items-center">
                        <input
                          type="radio"
                          name="price_range"
                          value="0-100"
                          phx-click="filter_by_price"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                        />
                        <span class="ml-2 text-sm text-gray-700">$0 - $100</span>
                      </label>
                      <label class="flex items-center">
                        <input
                          type="radio"
                          name="price_range"
                          value="100-500"
                          phx-click="filter_by_price"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                        />
                        <span class="ml-2 text-sm text-gray-700">$100 - $500</span>
                      </label>
                      <label class="flex items-center">
                        <input
                          type="radio"
                          name="price_range"
                          value="500+"
                          phx-click="filter_by_price"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                        />
                        <span class="ml-2 text-sm text-gray-700">$500+</span>
                      </label>
                    </div>
                  </div>
                  <!-- Clear Filters -->
                  <button
                    phx-click="clear_filters"
                    class="w-full bg-gray-300 text-gray-700 py-2 px-4 rounded-md hover:bg-gray-400"
                  >
                    Clear Filters
                  </button>
                </div>
              </div>
              <!-- Results -->
              <div class="lg:col-span-3">
                <!-- Results Header -->
                <div class="flex items-center justify-between mb-6">
                  <p class="text-sm text-gray-700">
                    Found <%= length(@results) %> results for "<%= @query %>"
                  </p>
                  <div class="flex items-center">
                    <label for="sort" class="text-sm font-medium text-gray-700 mr-2">Sort by:</label>
                    <select
                      id="sort"
                      phx-change="sort_results"
                      class="rounded-md border-gray-300 py-1 px-2 text-sm focus:border-indigo-500 focus:ring-indigo-500"
                    >
                      <option value="relevance" selected={@sort_by == "relevance"}>Relevance</option>
                      <option value="price_low" selected={@sort_by == "price_low"}>
                        Price: Low to High
                      </option>
                      <option value="price_high" selected={@sort_by == "price_high"}>
                        Price: High to Low
                      </option>
                      <option value="rating" selected={@sort_by == "rating"}>Rating</option>
                      <option value="newest" selected={@sort_by == "newest"}>Newest</option>
                    </select>
                  </div>
                </div>
                <!-- Results Grid -->
                <%= if Enum.empty?(@results) do %>
                  <div class="text-center py-12">
                    <svg
                      class="mx-auto h-12 w-12 text-gray-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                      />
                    </svg>
                    <h3 class="mt-2 text-sm font-medium text-gray-900">No results found</h3>
                    <p class="mt-1 text-sm text-gray-500">
                      Try adjusting your search terms or filters.
                    </p>
                  </div>
                <% else %>
                  <div class="grid grid-cols-1 gap-y-10 gap-x-6 sm:grid-cols-2 lg:grid-cols-3 xl:gap-x-8">
                    <%= for product <- @results do %>
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
                        <div class="mt-4">
                          <button
                            phx-click="add_to_cart"
                            phx-value-product-id={product.id}
                            class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 transition-colors"
                          >
                            Add to Cart
                          </button>
                        </div>
                      </div>
                    <% end %>
                  </div>
                  <!-- Pagination -->
                  <%= if length(@results) > @per_page do %>
                    <div class="mt-8 flex justify-center">
                      <nav class="flex items-center space-x-2">
                        <%= if @page > 1 do %>
                          <a
                            href={~p"/search?q=#{@query}&page=#{@page - 1}"}
                            class="px-3 py-2 text-gray-500 hover:text-gray-700"
                          >
                            Previous
                          </a>
                        <% end %>

                        <span class="px-3 py-2 text-gray-700">
                          Page <%= @page %> of <%= ceil(length(@results) / @per_page) %>
                        </span>

                        <%= if @page < ceil(length(@results) / @per_page) do %>
                          <a
                            href={~p"/search?q=#{@query}&page=#{@page + 1}"}
                            class="px-3 py-2 text-gray-500 hover:text-gray-700"
                          >
                            Next
                          </a>
                        <% end %>
                      </nav>
                    </div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    results = Products.search_products(query)
    {:noreply, assign(socket, query: query, results: results, page: 1)}
  end

  @impl true
  def handle_event("toggle_category", %{"value" => _category_id}, socket) do
    # TODO: Toggle category filter
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_by_price", %{"value" => _price_range}, socket) do
    # TODO: Filter by price range
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    # TODO: Clear all filters
    {:noreply, socket}
  end

  @impl true
  def handle_event("sort_results", %{"value" => sort_by}, socket) do
    # TODO: Sort results
    {:noreply, assign(socket, sort_by: sort_by)}
  end

  @impl true
  def handle_event("add_to_cart", %{"product-id" => _product_id}, socket) do
    # TODO: Add to cart
    {:noreply, put_flash(socket, :info, "Product added to cart!")}
  end
end
