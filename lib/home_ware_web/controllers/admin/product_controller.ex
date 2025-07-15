defmodule HomeWareWeb.Admin.ProductController do
  use HomeWareWeb, :controller
  import Phoenix.Component, only: [to_form: 1]

  alias HomeWare.Products
  alias HomeWare.Categories

  @per_page 12

  def index(conn, params) do
    page = params["page"] |> to_int() |> max(1)
    products = Products.paginated_products(page, @per_page)
    total_entries = Products.count_products()
    total_pages = ceil(total_entries / @per_page)
    categories = Categories.list_categories_with_counts()

    render(conn, "index.html",
      products: products,
      categories: categories,
      page: page,
      total_pages: total_pages,
      total_entries: total_entries
    )
  end

  def new(conn, _params) do
    changeset = HomeWare.Products.change_product(%HomeWare.Products.Product{})
    categories = HomeWare.Categories.list_categories()
    brands = HomeWare.Products.list_brands()
    form = to_form(changeset)
    render(conn, "new.html", form: form, categories: categories, brands: brands)
  end

  def create(conn, %{"product" => product_params}) do
    case Products.create_product(product_params) do
      {:ok, _product} ->
        conn
        |> put_flash(:info, "Product created!")
        |> redirect(to: ~p"/admin/products")

      {:error, changeset} ->
        categories = HomeWare.Categories.list_categories()
        brands = HomeWare.Products.list_brands()
        form = to_form(changeset)
        render(conn, "new.html", form: form, categories: categories, brands: brands)
    end
  end

  def edit(conn, _params) do
    # stub for edit product form
    render(conn, "edit.html")
  end

  def update(conn, _params) do
    # stub for product update
    conn |> put_flash(:info, "Product updated!") |> redirect(to: ~p"/admin/products")
  end

  def delete(conn, _params) do
    # stub for product deletion
    conn |> put_flash(:info, "Product deleted!") |> redirect(to: ~p"/admin/products")
  end

  defp to_int(nil), do: 1
  defp to_int(str) when is_binary(str), do: String.to_integer(str)
  defp to_int(int) when is_integer(int), do: int
end
