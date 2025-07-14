defmodule HomeWareWeb.AdminProductsLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Products
  alias HomeWare.Categories
  alias HomeWare.Products.Product

  @impl true
  def mount(_params, _session, socket) do
    categories = Categories.list_categories()

    sidebar_categories =
      Enum.map(categories, fn cat -> %{name: cat.name, count: Map.get(cat, :product_count, 0)} end)

    products = Products.list_all_products()

    {:ok,
     assign(socket,
       products: products,
       categories: categories,
       page: 1,
       per_page: 20,
       total_pages: 0,
       total_entries: 0,
       show_form: false,
       editing_product: nil,
       product_changeset: Product.changeset(%Product{}, %{}),
       sidebar_categories: sidebar_categories
     )}
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    page = String.to_integer(page)
    load_products(socket, page)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    load_products(socket, 1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <.admin_sidebar current="products" categories={@sidebar_categories} />
      <main class="flex-1 bg-[#f9f9f9] p-8">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-3xl font-bold text-gray-900">Product Management</h1>
          <button
            phx-click="show_add_form"
            class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
          >
            Add Product
          </button>
        </div>
        <%= if @show_form do %>
          <div class="bg-white rounded-lg shadow p-6 mb-8">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">
              <%= if @editing_product, do: "Edit Product", else: "Add New Product" %>
            </h2>
            <.form
              for={@product_changeset}
              phx-submit="save_product"
              phx-change="validate_product"
              id="product-form"
              class="space-y-4"
            >
              <!-- form fields here (unchanged) -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <.input
                    field={@product_changeset[:name]}
                    type="text"
                    label="Name"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <.input
                    field={@product_changeset[:slug]}
                    type="text"
                    label="Slug"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <.input
                    field={@product_changeset[:price]}
                    type="number"
                    step="0.01"
                    label="Price"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Category</label>
                  <select
                    name="product[category_id]"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  >
                    <option value="">Select Category</option>
                    <%= for category <- @categories do %>
                      <option
                        value={category.id}
                        selected={
                          @product_changeset.changes[:category_id] == category.id ||
                            @product_changeset.data.category_id == category.id
                        }
                      >
                        <%= category.name %>
                      </option>
                    <% end %>
                  </select>
                </div>
              </div>
              <div>
                <.input
                  field={@product_changeset[:description]}
                  type="textarea"
                  label="Description"
                  rows="3"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <.input
                    field={@product_changeset[:sku]}
                    type="text"
                    label="SKU"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <.input
                    field={@product_changeset[:brand]}
                    type="text"
                    label="Brand"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <.input
                    field={@product_changeset[:inventory_quantity]}
                    type="number"
                    label="Inventory Quantity"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div class="flex items-center space-x-4">
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    name="product[is_featured]"
                    value="true"
                    checked={
                      @product_changeset.changes[:is_featured] || @product_changeset.data.is_featured
                    }
                    class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                  <span class="ml-2 text-sm text-gray-700">Featured Product</span>
                </label>
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    name="product[is_active]"
                    value="true"
                    checked={
                      @product_changeset.changes[:is_active] != false &&
                        @product_changeset.data.is_active != false
                    }
                    class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                  <span class="ml-2 text-sm text-gray-700">Active</span>
                </label>
              </div>
              <div class="flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="cancel_form"
                  class="bg-gray-300 text-gray-700 px-4 py-2 rounded hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                >
                  <%= if @editing_product, do: "Update Product", else: "Create Product" %>
                </button>
              </div>
            </.form>
          </div>
        <% end %>
        <div class="bg-white rounded-lg shadow overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-900">Products</h3>
          </div>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Product
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Category
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Price
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Inventory
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for product <- @products do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="ml-4">
                          <div class="text-sm font-medium text-gray-900"><%= product.name %></div>
                          <div class="text-sm text-gray-500"><%= product.sku %></div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= if product.category, do: product.category.name, else: "No Category" %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      $<%= product.price %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <%= product.inventory_quantity %>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class={
                        if product.is_active,
                          do:
                            "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800",
                          else:
                            "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800"
                      }>
                        <%= if product.is_active, do: "Active", else: "Inactive" %>
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button
                        phx-click="edit_product"
                        phx-value-id={product.id}
                        class="text-blue-600 hover:text-blue-900 mr-3"
                      >
                        Edit
                      </button>
                      <button
                        phx-click="delete_product"
                        phx-value-id={product.id}
                        data-confirm="Are you sure you want to delete this product?"
                        class="text-red-600 hover:text-red-900"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("show_add_form", _params, socket) do
    categories = Categories.list_categories()
    changeset = Product.changeset(%Product{}, %{})

    {:noreply,
     assign(socket,
       show_form: true,
       editing_product: nil,
       product_changeset: changeset,
       categories: categories
     )}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     assign(socket,
       show_form: false,
       editing_product: nil,
       product_changeset: Product.changeset(%Product{}, %{})
     )}
  end

  @impl true
  def handle_event("edit_product", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    categories = Categories.list_categories()
    changeset = Product.changeset(product, %{})

    {:noreply,
     assign(socket,
       show_form: true,
       editing_product: product,
       product_changeset: changeset,
       categories: categories
     )}
  end

  @impl true
  def handle_event("validate_product", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.editing_product ||
        %Product{}
        |> Product.changeset(product_params)
        |> Map.put(:action, :validate)

    {:noreply, assign(socket, product_changeset: changeset)}
  end

  @impl true
  def handle_event("save_product", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.editing_product, product_params)
  end

  @impl true
  def handle_event("delete_product", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)
    load_products(socket, socket.assigns.page)
  end

  defp save_product(socket, editing_product, product_params) do
    case editing_product do
      nil ->
        # Creating new product
        case Products.create_product(product_params) do
          {:ok, _product} ->
            socket
            |> put_flash(:info, "Product created successfully")
            |> assign(
              show_form: false,
              editing_product: nil,
              product_changeset: Product.changeset(%Product{}, %{})
            )
            |> load_products(1)

          {:error, %Ecto.Changeset{} = changeset} ->
            categories = Categories.list_categories()
            {:noreply, assign(socket, product_changeset: changeset, categories: categories)}
        end

      product ->
        # Updating existing product
        case Products.update_product(product, product_params) do
          {:ok, _product} ->
            socket
            |> put_flash(:info, "Product updated successfully")
            |> assign(
              show_form: false,
              editing_product: nil,
              product_changeset: Product.changeset(%Product{}, %{})
            )
            |> load_products(socket.assigns.page)

          {:error, %Ecto.Changeset{} = changeset} ->
            categories = Categories.list_categories()
            {:noreply, assign(socket, product_changeset: changeset, categories: categories)}
        end
    end
  end

  defp load_products(socket, page) do
    # For admin, show all products (including inactive ones)
    products = Products.list_all_products()
    {:noreply, assign(socket, products: products, page: page)}
  end
end
