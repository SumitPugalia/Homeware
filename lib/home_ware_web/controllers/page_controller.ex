defmodule HomeWareWeb.PageController do
  use HomeWareWeb, :controller

  alias HomeWare.Products
  alias HomeWare.Categories

  def home(conn, params) do
    # Extract search and filter parameters
    search_query = params["search"] || ""
    category_id = params["category_id"]
    min_price = parse_price(params["min_price"])
    max_price = parse_price(params["max_price"])

    # Build filters map for database query
    filters =
      %{}
      |> maybe_add_filter(:search, search_query)
      |> maybe_add_filter(:category_id, category_id)
      |> maybe_add_filter(:min_price, min_price)
      |> maybe_add_filter(:max_price, max_price)

    # Get filtered products from database
    filtered_products = Products.list_products_with_filters(filters)
    categories = Categories.list_categories()

    # Get featured products (first 8 for display)
    featured_products = Enum.filter(filtered_products, fn product -> product.is_featured end)

    # Get a featured product from each category for category cards
    categories_with_featured_products =
      Enum.map(categories, fn category ->
        featured_product = Products.list_featured_products_by_category(category.id, 1)
        featured_product = if featured_product != [], do: List.first(featured_product), else: nil
        Map.put(category, :featured_product, featured_product)
      end)

    render(conn, :home,
      featured_products: featured_products,
      products: filtered_products,
      categories: categories_with_featured_products,
      search_query: search_query,
      selected_category_id: category_id,
      min_price: params["min_price"] || "",
      max_price: params["max_price"] || "",
      total_products: length(filtered_products)
    )
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def contact(conn, _params) do
    render(conn, :contact)
  end

  def shipping(conn, _params) do
    render(conn, :shipping)
  end

  def returns(conn, _params) do
    render(conn, :returns)
  end

  def privacy(conn, _params) do
    render(conn, :privacy)
  end

  def terms(conn, _params) do
    render(conn, :terms)
  end

  # Private helper functions
  defp parse_price(price_string) when is_binary(price_string) and price_string != "" do
    case Float.parse(price_string) do
      {price, _} -> price
      :error -> nil
    end
  end

  defp parse_price(_), do: nil

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, _key, ""), do: filters
  defp maybe_add_filter(filters, key, value), do: Map.put(filters, key, value)
end
