defmodule HomeWareWeb.ProductCatalogLive do
  alias HomeWare.Repo
  alias HomeWare.Products.Product
  alias HomeWare.Categories.Category

  use HomeWareWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    products = Repo.all(Product)
    categories = Repo.all(Category)

    {:ok,
     assign(socket,
       page: 1,
       per_page: 9,
       filters: %{},
       products: products,
       total_count: 0,
       categories: categories,
       brands: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Product Catalog</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for product <- @products do %>
          <div class="bg-white rounded-lg shadow-md overflow-hidden">
            <div class="p-4">
              <h3 class="text-lg font-semibold text-gray-900"><%= product.name %></h3>
              <p class="text-gray-600 mt-2"><%= product.short_description %></p>
              <div class="mt-4 flex justify-between items-center">
                <span class="text-xl font-bold text-gray-900">$<%= product.price %></span>
                <button class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
                  Add to Cart
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @total_count > 0 do %>
        <div class="mt-8 flex justify-center">
          <nav class="flex items-center space-x-2">
            <%= if @page > 1 do %>
              <a
                href={~p"/products?page=#{@page - 1}"}
                class="px-3 py-2 text-gray-500 hover:text-gray-700"
              >
                Previous
              </a>
            <% end %>

            <span class="px-3 py-2 text-gray-700">
              Page <%= @page %> of <%= ceil(@total_count / @per_page) %>
            </span>

            <%= if @page < ceil(@total_count / @per_page) do %>
              <a
                href={~p"/products?page=#{@page + 1}"}
                class="px-3 py-2 text-gray-500 hover:text-gray-700"
              >
                Next
              </a>
            <% end %>
          </nav>
        </div>
      <% end %>
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
          "rating" => rating,
          "availability" => availability
        },
        socket
      ) do
    filters =
      %{}
      |> maybe_add_filter(:category, category)
      |> maybe_add_filter(:brand, brand)
      |> maybe_add_filter(:min_price, min_price)
      |> maybe_add_filter(:max_price, max_price)
      |> maybe_add_filter(:rating, rating)
      |> maybe_add_filter(:availability, availability)

    {:noreply, assign(socket, filters: filters, page: 1)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters =
      %{}
      |> maybe_add_filter(:category, params["category"])
      |> maybe_add_filter(:brand, params["brand"])
      |> maybe_add_filter(:min_price, params["min_price"])
      |> maybe_add_filter(:max_price, params["max_price"])
      |> maybe_add_filter(:rating, params["rating"])
      |> maybe_add_filter(:availability, params["availability"])

    {:noreply, assign(socket, filters: filters, page: 1)}
  end

  @impl true
  def handle_event("add_to_cart", %{"product-id" => _product_id}, socket) do
    # TODO: Implement add to cart functionality
    {:noreply, socket}
  end

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, _key, ""), do: filters

  defp maybe_add_filter(filters, key, value) when is_binary(value) and value != "",
    do: Map.put(filters, key, value)

  defp maybe_add_filter(filters, key, value) when is_integer(value),
    do: Map.put(filters, key, value)

  defp maybe_add_filter(filters, _key, _value), do: filters
end
