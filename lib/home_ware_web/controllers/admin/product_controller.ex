defmodule HomeWareWeb.Admin.ProductController do
  use HomeWareWeb, :admin_controller
  import Phoenix.Component, only: [to_form: 1]
  require Logger

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
    Logger.info("Creating product with params: #{inspect(product_params)}")

    case Products.create_product(product_params) do
      {:ok, product} ->
        Logger.info("Product created successfully with ID: #{inspect(product.id)}")

        conn
        |> put_flash(:info, "Product created!")
        |> redirect(to: ~p"/admin/products")

      {:error, changeset} ->
        Logger.error("Error creating product: #{inspect(changeset)}")
        categories = HomeWare.Categories.list_categories()
        brands = HomeWare.Products.list_brands()
        form = to_form(changeset)
        render(conn, "new.html", form: form, categories: categories, brands: brands)
    end
  end

  def edit(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)
    categories = Categories.list_categories()
    brands = Products.list_brands()
    form = to_form(changeset)

    render(conn, "edit.html",
      product: product,
      form: form,
      categories: categories,
      brands: brands
    )
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Products.get_product!(id)

    case Products.update_product(product, product_params) do
      {:ok, _product} ->
        conn
        |> put_flash(:info, "Product updated!")
        |> redirect(to: ~p"/admin/products")

      {:error, changeset} ->
        categories = Categories.list_categories()
        brands = Products.list_brands()
        form = to_form(changeset)

        render(conn, "edit.html",
          product: product,
          form: form,
          categories: categories,
          brands: brands
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    product = Products.get_product!(id)

    case Products.delete_product(product) do
      {:ok, _product} ->
        conn |> put_flash(:info, "Product deleted!") |> redirect(to: ~p"/admin/products")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to delete product.")
        |> redirect(to: ~p"/admin/products")
    end
  end

  def confirm_delete(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    render(conn, "confirm_delete.html", product: product)
  end

  defp to_int(nil), do: 1
  defp to_int(str) when is_binary(str), do: String.to_integer(str)
  defp to_int(int) when is_integer(int), do: int
end
