defmodule HomeWareWeb.AdminProductDetailLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Products
  alias HomeWare.Categories
  alias ExAws.S3

  @bucket "DO_SPACES_BUCKET"
  @region "DO_SPACES_REGION"
  @endpoint "https://DO_SPACES_BUCKET.DO_SPACES_REGION.digitaloceanspaces.com"

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    product = Products.get_product!(id)
    categories = Categories.list_categories()
    brands = Products.list_brands()

    sidebar_categories =
      Enum.map(categories, fn cat -> %{name: cat.name, count: Map.get(cat, :product_count, 0)} end)

    changeset = Products.change_product(product)

    socket =
      socket
      |> assign(
        product: product,
        categories: categories,
        brands: brands,
        sidebar_categories: sidebar_categories,
        changeset: changeset,
        uploaded_files: [],
        uploading: false
      )
      |> allow_upload(:images,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 5,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => params}, socket) do
    changeset =
      socket.assigns.product
      |> Products.change_product(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"product" => params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        key = "products/#{entry.uuid}-#{entry.client_name}"

        {:ok, _resp} =
          path
          |> File.read!()
          |> S3.put_object(@bucket, key)
          |> ExAws.request(region: @region)

        url = "#{@endpoint}/#{key}"
        {url, nil}
      end)

    images = (socket.assigns.product.images || []) ++ uploaded_files
    params = Map.put(params, "images", images)

    case Products.update_product(socket.assigns.product, params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully.")
         |> assign(
           product: product,
           changeset: Products.change_product(product),
           uploaded_files: [],
           uploading: false
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, uploading: false)}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Products.delete_product(socket.assigns.product)

    {:noreply,
     socket |> put_flash(:info, "Product deleted.") |> push_navigate(to: "/admin/products")}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: "/admin/products")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <.admin_sidebar current="products" categories={@sidebar_categories} />
      <main class="flex-1 bg-[#f9f9f9] p-8">
        <!-- Header & Breadcrumbs -->
        <div class="mb-6">
          <h1 class="text-xl font-bold text-gray-900">Product Details</h1>
          <p class="text-xs text-gray-500">Home &gt; All Products &gt; Product Details</p>
        </div>
        <.form
          for={@changeset}
          id="product-form"
          phx-change="validate"
          phx-submit="save"
          class="bg-white rounded-lg shadow p-8 flex flex-col lg:flex-row gap-8"
        >
          <!-- Product Form -->
          <div class="flex-1 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="flex flex-col gap-4">
              <div>
                <label class="font-semibold text-sm">Product Name</label>
                <input
                  type="text"
                  name="product[name]"
                  value={@changeset.changes[:name] || @changeset.data.name}
                  class="w-full border rounded px-3 py-2 text-sm mt-1"
                />
              </div>
              <div>
                <label class="font-semibold text-sm">Description</label>
                <textarea
                  name="product[description]"
                  rows="4"
                  class="w-full border rounded px-3 py-2 text-sm mt-1"
                ><%= @changeset.changes[:description] || @changeset.data.description %></textarea>
              </div>
              <div>
                <label class="font-semibold text-sm">Category</label>
                <select
                  name="product[category_id]"
                  class="w-full border rounded px-3 py-2 text-sm mt-1"
                >
                  <%= for cat <- @categories do %>
                    <option value={cat.id} selected={@product.category_id == cat.id}>
                      <%= cat.name %>
                    </option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="font-semibold text-sm">Brand Name</label>
                <input
                  type="text"
                  name="product[brand]"
                  value={@changeset.changes[:brand] || @changeset.data.brand}
                  class="w-full border rounded px-3 py-2 text-sm mt-1"
                />
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="font-semibold text-sm">SKU</label>
                  <input
                    type="text"
                    name="product[sku]"
                    value={@changeset.changes[:sku] || @changeset.data.sku}
                    class="w-full border rounded px-3 py-2 text-sm mt-1"
                  />
                </div>
                <div>
                  <label class="font-semibold text-sm">Stock Quantity</label>
                  <input
                    type="number"
                    name="product[inventory_quantity]"
                    value={
                      @changeset.changes[:inventory_quantity] || @changeset.data.inventory_quantity ||
                        0
                    }
                    class="w-full border rounded px-3 py-2 text-sm mt-1"
                  />
                </div>
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="font-semibold text-sm">Regular Price</label>
                  <input
                    type="number"
                    step="0.01"
                    name="product[price]"
                    value={@changeset.changes[:price] || @changeset.data.price}
                    class="w-full border rounded px-3 py-2 text-sm mt-1"
                  />
                </div>
                <div>
                  <label class="font-semibold text-sm">Sale Price</label>
                  <input
                    type="number"
                    step="0.01"
                    name="product[compare_at_price]"
                    value={@changeset.changes[:compare_at_price] || @changeset.data.compare_at_price}
                    class="w-full border rounded px-3 py-2 text-sm mt-1"
                  />
                </div>
              </div>
              <div>
                <label class="font-semibold text-sm">Tag</label>
                <div class="flex gap-2 flex-wrap mt-1">
                  <span class="bg-gray-800 text-white rounded-full px-3 py-1 text-xs">Lorem</span>
                  <span class="bg-gray-800 text-white rounded-full px-3 py-1 text-xs">Lorem</span>
                </div>
              </div>
            </div>
          </div>
          <!-- Product Gallery -->
          <div class="w-full lg:w-1/3 flex flex-col gap-4">
            <div class="bg-gray-100 rounded flex items-center justify-center h-48 mb-4">
              <%= if @product.featured_image do %>
                <img src={@product.featured_image} alt="Product" class="object-contain h-44" />
              <% else %>
                <span class="text-gray-400">No Image</span>
              <% end %>
            </div>
            <div class="bg-white border-dashed border-2 border-gray-300 rounded flex flex-col items-center justify-center h-32 mb-4">
              <.live_file_input upload={@uploads.images} class="mt-2" />
              <span class="text-xs text-gray-500">
                Drop your image here, or browse<br />Jpeg, png are allowed
              </span>
            </div>
            <div class="flex flex-col gap-2">
              <%= for img <- @product.images || [] do %>
                <div class="flex items-center gap-2 bg-gray-100 rounded p-2">
                  <div class="w-10 h-10 bg-gray-300 rounded flex items-center justify-center">
                    <img src={img} alt="Product thumbnail" class="object-contain h-8" />
                  </div>
                  <span class="flex-1 text-xs text-gray-700">Product thumbnail.png</span>
                  <span class="material-icons text-green-600">check_circle</span>
                </div>
              <% end %>
            </div>
          </div>
          <!-- Action Buttons -->
          <div class="flex flex-col gap-2 justify-end mt-6">
            <button type="submit" class="bg-[#0a3d62] text-white rounded px-6 py-2 font-semibold">
              UPDATE
            </button>
            <button
              type="button"
              phx-click="delete"
              class="bg-red-600 text-white rounded px-6 py-2 font-semibold"
            >
              DELETE
            </button>
            <button
              type="button"
              phx-click="cancel"
              class="bg-gray-200 text-gray-700 rounded px-6 py-2 font-semibold"
            >
              CANCEL
            </button>
          </div>
        </.form>
      </main>
    </div>
    """
  end
end
