defmodule HomeWareWeb.Api.ProductController do
  use HomeWareWeb, :controller

  alias HomeWare.Products

  def index(conn, params) do
    page = Products.list_products(params)

    conn
    |> put_status(:ok)
    |> json(%{
      products: Enum.map(page.entries, &product_to_json/1),
      pagination: %{
        page_number: page.page_number,
        page_size: page.page_size,
        total_entries: page.total_entries,
        total_pages: page.total_pages
      }
    })
  end

  def show(conn, %{"id" => id}) do
    product = Products.get_product!(id)

    conn
    |> put_status(:ok)
    |> json(product_to_json(product))
  rescue
    Ecto.NoResultsError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "Product not found"})
  end

  defp product_to_json(product) do
    %{
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      sku: product.sku,
      inventory_count: product.inventory_count,
      status: product.status,
      category_id: product.category_id,
      inserted_at: product.inserted_at,
      updated_at: product.updated_at
    }
  end
end
