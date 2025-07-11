defmodule HomeWareWeb.ProductCatalogLive do
  use HomeWareWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page: 1,
       per_page: 9,
       filters: %{},
       products: [],
       total_count: 0,
       categories: [],
       brands: []
     )}
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
  def handle_event("filter", %{"category" => category, "brand" => brand, "min_price" => min_price, "max_price" => max_price, "rating" => rating, "availability" => availability}, socket) do
    filters = %{}
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
    filters = %{}
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
  defp maybe_add_filter(filters, key, value) when is_binary(value) and value != "", do: Map.put(filters, key, value)
  defp maybe_add_filter(filters, key, value) when is_integer(value), do: Map.put(filters, key, value)
  defp maybe_add_filter(filters, _key, _value), do: filters
end
