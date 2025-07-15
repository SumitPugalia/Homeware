defmodule HomeWareWeb.Admin.ProductController do
  use HomeWareWeb, :admin_controller
  import Phoenix.Component, only: [to_form: 1]
  require Logger

  alias HomeWare.Products
  alias HomeWare.Categories

  @per_page 12

  @brands ["Elf Bar", "Other"]

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
      total_entries: total_entries,
      per_page: @per_page,
      current_path: conn.request_path
    )
  end

  def new(conn, _params) do
    changeset = HomeWare.Products.change_product(%HomeWare.Products.Product{})
    categories = HomeWare.Categories.list_categories()
    brands = HomeWare.Products.list_brands()
    form = to_form(changeset)

    render(conn, "new.html",
      form: form,
      categories: categories,
      brands: brands,
      current_path: conn.request_path
    )
  end

  def create(conn, %{"product" => product_params}) do
    Logger.info("Creating product with params: #{inspect(product_params)}")

    # Transform the parameters to match the database structure
    transformed_params = transform_product_params(product_params)

    case Products.create_product(transformed_params) do
      {:ok, product} ->
        Logger.info("Product created successfully with ID: #{inspect(product.id)}")

        conn
        |> put_flash(:info, "Product created!")
        |> redirect(to: ~p"/admin/products")

      {:error, changeset} ->
        Logger.error("Error creating product: #{inspect(changeset)}")
        categories = HomeWare.Categories.list_categories()
        brands = @brands
        form = to_form(changeset)

        render(conn, "new.html",
          form: form,
          categories: categories,
          brands: brands,
          current_path: conn.request_path
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)
    categories = Categories.list_categories()
    brands = @brands
    form = to_form(changeset)

    render(conn, "edit.html",
      product: product,
      form: form,
      categories: categories,
      brands: brands,
      current_path: conn.request_path
    )
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    product = Products.get_product!(id)

    # Transform the parameters to match the database structure
    transformed_params = transform_product_params(product_params)

    case Products.update_product(product, transformed_params) do
      {:ok, _product} ->
        conn
        |> put_flash(:info, "Product updated!")
        |> redirect(to: ~p"/admin/products")

      {:error, changeset} ->
        categories = Categories.list_categories()
        brands = @brands
        form = to_form(changeset)

        render(conn, "edit.html",
          product: product,
          form: form,
          categories: categories,
          brands: brands,
          current_path: conn.request_path
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

    render(conn, "confirm_delete.html",
      product: product,
      current_path: conn.request_path
    )
  end

  # Transform product parameters to match database structure
  defp transform_product_params(params) do
    params
    |> transform_dimensions()
    |> transform_specifications()
    |> transform_images()
    |> transform_boolean_fields()
  end

  # Transform dimensions from separate fields to a map
  defp transform_dimensions(%{"dimensions" => dimensions} = params) when is_map(dimensions) do
    dimensions_map = %{
      "length" => dimensions["length"] || "",
      "width" => dimensions["width"] || "",
      "height" => dimensions["height"] || ""
    }

    # Only include dimensions if at least one field has a value
    if Enum.any?(dimensions_map, fn {_k, v} -> v != "" end) do
      Map.put(params, "dimensions", dimensions_map)
    else
      Map.put(params, "dimensions", %{})
    end
  end

  defp transform_dimensions(params), do: params

  # Transform specifications from separate fields to a map
  defp transform_specifications(%{"specifications" => specs} = params) when is_map(specs) do
    specs_map = %{
      "color" => specs["color"] || "",
      "material" => specs["material"] || ""
    }

    # Only include specifications if at least one field has a value
    if Enum.any?(specs_map, fn {_k, v} -> v != "" end) do
      Map.put(params, "specifications", specs_map)
    else
      Map.put(params, "specifications", %{})
    end
  end

  defp transform_specifications(params), do: params

  # Transform images from comma-separated string to array
  defp transform_images(%{"images" => images} = params) when is_binary(images) do
    images_array =
      images
      |> String.trim()
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))

    Map.put(params, "images", images_array)
  end

  defp transform_images(params), do: params

  # Transform boolean fields
  defp transform_boolean_fields(%{"is_active" => "true"} = params) do
    Map.put(params, "is_active", true)
  end

  defp transform_boolean_fields(%{"is_featured" => "true"} = params) do
    Map.put(params, "is_featured", true)
  end

  defp transform_boolean_fields(params), do: params

  defp to_int(nil), do: 1
  defp to_int(str) when is_binary(str), do: String.to_integer(str)
  defp to_int(int) when is_integer(int), do: int
end
