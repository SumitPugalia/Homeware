defmodule HomeWareWeb.Admin.ProductController do
  use HomeWareWeb, :admin_controller
  import Phoenix.Component, only: [to_form: 1]
  require Logger

  alias HomeWare.Products
  alias HomeWare.Categories
  alias HomeWare.UploadService

  @per_page 12

  @brands [
    "HomeWare Premium",
    "Elite Living",
    "Modern Essentials",
    "Lifestyle Pro",
    "Quality Home"
  ]

  defp upload_impl, do: Application.get_env(:home_ware, :upload_impl, HomeWare.UploadService)

  def index(conn, params) do
    page = params["page"] |> to_int() |> max(1)
    search = params["search"]
    filters = %{}
    filters = if search, do: Map.put(filters, :search, search), else: filters
    products = Products.paginated_products(page, @per_page, filters)
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
      current_path: conn.request_path,
      search: search
    )
  end

  def new(conn, _params) do
    changeset = HomeWare.Products.change_product(%HomeWare.Products.Product{})
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

  def create(conn, %{"product" => product_params}) do
    Logger.info("Creating product with params: #{inspect(product_params)}")

    # Handle file uploads
    case handle_file_uploads(conn, product_params) do
      {:ok, updated_params} ->
        # Transform the parameters to match the database structure
        transformed_params = transform_product_params(updated_params)

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

      {:error, reason} ->
        Logger.error("Error uploading files: #{inspect(reason)}")
        categories = HomeWare.Categories.list_categories()
        brands = @brands
        changeset = HomeWare.Products.change_product(%HomeWare.Products.Product{})
        form = to_form(changeset)

        conn
        |> put_flash(:error, "Error uploading images: #{reason}")
        |> render("new.html",
          form: form,
          categories: categories,
          brands: brands,
          current_path: conn.request_path
        )
    end
  end

  def show(conn, %{"id" => id}) do
    product = Products.get_product!(id) |> HomeWare.Repo.preload(:category)
    render(conn, "show.html", product: product, current_path: conn.request_path)
  end

  def edit(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    changeset = Products.change_product(product)
    categories = HomeWare.Categories.list_categories()
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

    # Handle file uploads
    case handle_file_uploads(conn, product_params) do
      {:ok, updated_params} ->
        # Transform the parameters to match the database structure
        transformed_params = transform_product_params(updated_params)

        case Products.update_product(product, transformed_params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product updated!")
            |> redirect(to: ~p"/admin/products/#{product}")

          {:error, changeset} ->
            categories = HomeWare.Categories.list_categories()
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

      {:error, reason} ->
        categories = HomeWare.Categories.list_categories()
        brands = @brands
        changeset = Products.change_product(product)
        form = to_form(changeset)

        conn
        |> put_flash(:error, "Error uploading images: #{reason}")
        |> render("edit.html",
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
    {:ok, _product} = Products.delete_product(product)

    conn
    |> put_flash(:info, "Product deleted!")
    |> redirect(to: ~p"/admin/products")
  end

  def confirm_delete(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    render(conn, "confirm_delete.html", product: product, current_path: conn.request_path)
  end

  def toggle_active(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    new_status = !product.is_active
    {:ok, _product} = Products.update_product(product, %{is_active: new_status})

    conn
    |> put_flash(:info, "Product status updated!")
    |> redirect(to: ~p"/admin/products")
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

  # Transform images - now handled by file upload, just ensure it's an array
  defp transform_images(%{"images" => images} = params) when is_list(images) do
    # Images are already processed as URLs from file upload
    params
  end

  defp transform_images(params), do: params

  # Transform boolean fields
  defp transform_boolean_fields(%{"is_active" => "true"} = params) do
    Map.put(params, "is_active", true)
  end

  defp transform_boolean_fields(%{"is_active" => "false"} = params) do
    Map.put(params, "is_active", false)
  end

  defp transform_boolean_fields(%{"is_featured" => "true"} = params) do
    Map.put(params, "is_featured", true)
  end

  defp transform_boolean_fields(%{"is_featured" => "false"} = params) do
    Map.put(params, "is_featured", false)
  end

  # Handle case when boolean fields are not present (unchecked checkboxes)
  defp transform_boolean_fields(%{"is_active" => _} = params), do: params
  defp transform_boolean_fields(%{"is_featured" => _} = params), do: params

  # When boolean fields are missing (unchecked checkboxes), set them to false
  defp transform_boolean_fields(params) do
    params
    |> Map.put_new("is_active", false)
    |> Map.put_new("is_featured", false)
  end

  # Handle file uploads for product images
  defp handle_file_uploads(conn, params) do
    try do
      # Get category slug for upload path
      category_slug = get_category_slug(params["category_id"])

      # Handle featured image upload
      featured_image_url =
        case conn.body_params["product"]["featured_image"] do
          %Plug.Upload{} = upload ->
            case upload_single_image(upload, category_slug) do
              {:ok, url} ->
                url

              {:error, reason} ->
                Logger.error("Error uploading featured image: #{inspect(reason)}")
                nil
            end

          _ ->
            nil
        end

      # Handle additional images upload
      additional_images =
        case conn.body_params["product"]["images"] do
          uploads when is_list(uploads) ->
            uploads
            |> Enum.filter(&valid_upload?/1)
            |> Enum.map(&upload_single_image(&1, category_slug))
            |> Enum.filter(fn
              {:ok, _url} ->
                true

              {:error, reason} ->
                Logger.error("Error uploading additional image: #{inspect(reason)}")
                false
            end)
            |> Enum.map(fn {:ok, url} -> url end)

          _ ->
            []
        end

      # For updates, preserve existing images if no new ones are uploaded
      updated_params =
        case {featured_image_url, additional_images} do
          {nil, []} ->
            # No new images uploaded, keep existing ones
            params

          {new_featured, []} ->
            # Only new featured image
            params |> Map.put("featured_image", new_featured)

          {nil, new_additional} ->
            # Only new additional images
            params |> Map.put("images", new_additional)

          {new_featured, new_additional} ->
            # Both new featured and additional images
            all_images = [new_featured | new_additional]

            params
            |> Map.put("featured_image", new_featured)
            |> Map.put("images", all_images)
        end

      {:ok, updated_params}
    rescue
      e ->
        Logger.error("Error in file upload handling: #{inspect(e)}")
        {:error, "File upload failed"}
    end
  end

  defp valid_upload?(%Plug.Upload{} = upload) do
    upload.filename && upload.path && File.exists?(upload.path)
  end

  defp valid_upload?(_), do: false

  defp upload_single_image(%Plug.Upload{} = upload, category_slug) do
    Logger.info("Uploading single image: #{inspect(upload.filename)}")
    filename = UploadService.generate_filename(upload.filename)
    category_path = if category_slug, do: "#{category_slug}", else: "uncategorized"
    destination_path = "products/#{category_path}/#{filename}"

    case upload_impl().upload_file(upload.path, destination_path) do
      {:ok, url} -> {:ok, url}
      {:error, reason} -> {:error, reason}
    end
  end

  defp to_int(nil), do: 1
  defp to_int(str) when is_binary(str), do: String.to_integer(str)
  defp to_int(int) when is_integer(int), do: int

  # Get category name from category ID
  defp get_category_slug(nil), do: "uncategorized"

  defp get_category_slug(category_id) when is_binary(category_id) do
    case HomeWare.Categories.get_category(category_id) do
      nil -> "uncategorized"
      category -> category.name || "uncategorized"
    end
  end

  defp get_category_slug(_), do: "uncategorized"
end
