defmodule HomeWareWeb.AdminProductsLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Products
  alias HomeWare.Categories
  alias HomeWare.Products.Product

  require Logger

  @tabs [
    {"basic", "Basic Info"},
    {"inventory", "Inventory"},
    {"media", "Media"},
    {"advanced", "Advanced"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    categories = Categories.list_categories()

    sidebar_categories =
      Enum.map(categories, fn cat -> %{name: cat.name, count: Map.get(cat, :product_count, 0)} end)

    products = Products.list_all_products()
    total_entries = length(products)
    total_pages = ceil(total_entries / 20)

    {:ok,
     assign(socket,
       products: products,
       categories: categories,
       page: 1,
       per_page: 20,
       total_pages: total_pages,
       total_entries: total_entries,
       product_changeset: Product.changeset(%Product{}, %{}),
       sidebar_categories: sidebar_categories,
       active_tab: "basic",
       tabs: @tabs
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
    <div class="flex min-h-screen bg-[#f5f6f8]">
      <!-- Sidebar -->
      <aside class="w-64 min-h-screen bg-white flex flex-col py-6 px-4 border-r border-gray-200">
        <div class="flex items-center mb-10">
          <img src="/images/logo.svg" alt="Arik Logo" class="h-10 mr-2" />
          <span class="text-3xl font-bold text-[#1a2a3a] tracking-tight">Arik</span>
        </div>
        <nav class="flex flex-col gap-2 mb-8">
          <a
            href="/admin/dashboard"
            class="flex items-center gap-2 px-4 py-2 rounded transition font-medium text-sm hover:bg-gray-100 text-gray-700"
          >
            <span class="material-icons text-base">DASHBOARD</span>
          </a>
          <a
            href="/admin/products"
            class="flex items-center gap-2 px-4 py-2 rounded transition font-medium text-sm bg-[#0a3d62] text-white"
          >
            <span class="material-icons text-base">ALL PRODUCTS</span>
          </a>
          <a
            href="/admin/orders"
            class="flex items-center gap-2 px-4 py-2 rounded transition font-medium text-sm hover:bg-gray-100 text-gray-700"
          >
            <span class="material-icons text-base">ORDER LIST</span>
          </a>
        </nav>
        <div class="mt-4">
          <div class="flex items-center justify-between mb-2">
            <span class="font-bold text-lg text-gray-900">Categories</span>
            <span class="material-icons text-base">expand_more</span>
          </div>
          <ul class="flex flex-col gap-2">
            <%!-- <%= for cat <- @categories do %>
              <li class="flex items-center justify-between px-2 py-1 rounded hover:bg-gray-100">
                <span><%= cat.name %></span>
                <span class="bg-gray-200 text-xs rounded px-2 py-0.5 font-semibold"><%= cat.product_count || 0 %></span>
              </li>
            <% end %> --%>
          </ul>
        </div>
      </aside>
      <!-- Main Content -->
      <main class="flex-1 p-8">
        <div class="mb-8">
          <div class="text-xs text-gray-500 mb-1">Home &gt; All Products &gt; Product Details</div>
          <h1 class="text-2xl font-bold text-gray-900 mb-6">Product Details</h1>
          <div class="mb-6">
            <nav class="flex space-x-2 border-b border-gray-200 text-xs">
              <%= for {tab, label} <- @tabs do %>
                <button
                  type="button"
                  phx-click="switch_tab"
                  phx-value-tab={tab}
                  class={"px-3 py-1 border-b-2 " <> if @active_tab == tab, do: "border-blue-600 text-blue-700 font-semibold", else: "border-transparent text-gray-500 hover:text-blue-600"}
                >
                  <%= label %>
                </button>
              <% end %>
            </nav>
          </div>
          <.form
            :let={f}
            for={@product_changeset}
            id="product-form"
            phx-change="validate_product"
            phx-submit="save_product"
            class="bg-white rounded shadow p-4 text-xs grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
          >
            <%= if @active_tab == "basic" do %>
              <.input field={f[:name]} label="Name" class="mb-2" />
              <.input
                field={f[:description]}
                type="textarea"
                label="Description"
                rows="2"
                class="mb-2"
              />
              <div>
                <label class="block mb-1 text-xs font-medium text-gray-700">Category</label>
                <select
                  name="product[category_id]"
                  class="w-full border rounded px-2 py-1 text-xs"
                  value={f[:category_id].value}
                >
                  <option value="">Select category</option>
                  <%= for cat <- @categories do %>
                    <option value={cat.id} selected={f[:category_id].value == cat.id}>
                      <%= cat.name %>
                    </option>
                  <% end %>
                </select>
              </div>
              <.input field={f[:brand]} label="Brand" class="mb-2" />
              <.input field={f[:model]} label="Model" class="mb-2" />
              <.input field={f[:product_type]} label="Product Type" class="mb-2" />
              <.input field={f[:product_category]} label="Product Category" class="mb-2" />
              <.input field={f[:price]} type="number" step="0.01" label="Price" class="mb-2" />
              <.input
                field={f[:selling_price]}
                type="number"
                step="0.01"
                label="Selling Price"
                class="mb-2"
              />
            <% end %>
            <%= if @active_tab == "inventory" do %>
              <.input field={f[:inventory_quantity]} type="number" label="Inventory Qty" class="mb-2" />
              <.input field={f[:dimensions]} type="text" label="Dimensions (JSON)" class="mb-2" />
              <.input field={f[:is_active]} type="checkbox" label="Active" class="mb-2" />
              <.input field={f[:is_featured]} type="checkbox" label="Featured" class="mb-2" />
            <% end %>
            <%= if @active_tab == "media" do %>
              <.input field={f[:featured_image]} label="Featured Image URL" class="mb-2" />
              <.input field={f[:images]} type="text" label="Images (comma separated)" class="mb-2" />
            <% end %>
            <%= if @active_tab == "advanced" do %>
              <.input
                field={f[:specifications]}
                type="text"
                label="Specifications (JSON)"
                class="mb-2"
              />
            <% end %>
            <div class="col-span-full flex gap-2 mt-2">
              <button type="submit" class="bg-blue-600 text-white px-4 py-1 rounded text-xs">
                Save
              </button>
              <button type="reset" class="bg-gray-200 text-gray-700 px-4 py-1 rounded text-xs">
                Reset
              </button>
            </div>
          </.form>
        </div>
        <!-- Product Card Grid and Pagination remain below -->
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <%= for product <- @products do %>
            <div class="bg-white rounded-lg shadow p-4 flex flex-col">
              <img
                src={product.featured_image || "/images/placeholder.png"}
                alt={product.name}
                class="h-32 w-full object-cover rounded"
              />
              <div class="mt-2 font-bold"><%= product.name %></div>
              <div class="text-sm text-gray-500">
                <%= product.category && product.category.name %>
              </div>
              <div class="font-semibold mt-1">₹<%= product.price %></div>
              <div class="text-xs text-gray-600 mt-2"><%= product.description %></div>
              <div class="flex justify-between mt-4 text-xs">
                <div>Sales<br /><span class="font-bold text-orange-500">1269</span></div>
                <div>Remaining Products<br /><span class="font-bold text-gray-700">1269</span></div>
              </div>
              <div class="flex justify-end mt-2">
                <button class="p-2 rounded hover:bg-gray-100">
                  <span class="material-icons">more_horiz</span>
                </button>
              </div>
            </div>
          <% end %>
        </div>
        <!-- Pagination -->
        <div class="flex justify-center mt-8">
          <nav class="inline-flex -space-x-px">
            <button
              phx-click="go_to_page"
              phx-value-page={@page - 1}
              disabled={@page <= 1}
              class={"px-3 py-1 rounded-l border border-gray-300 bg-white text-gray-500 hover:bg-gray-100 " <> if @page <= 1, do: "opacity-50 cursor-not-allowed", else: "hover:bg-gray-100"}
            >
              &lt; Prev
            </button>
            <div class="px-4 py-1 border-t border-b border-gray-300 bg-white text-gray-700 font-medium">
              Page <%= @page %>
            </div>
            <button
              phx-click="go_to_page"
              phx-value-page={@page + 1}
              disabled={@page >= @total_pages}
              class={"px-3 py-1 rounded-r border border-gray-300 bg-white text-gray-500 " <> if @page >= @total_pages, do: "opacity-50 cursor-not-allowed", else: "hover:bg-gray-100"}
            >
              Next &gt;
            </button>
          </nav>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     assign(socket,
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
       product_changeset: changeset,
       categories: categories
     )}
  end

  @impl true
  def handle_event("validate_product", %{"product" => product_params}, socket) do
    changeset =
      %Product{}
      |> Product.changeset(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, product_changeset: changeset)}
  end

  @impl true
  def handle_event("save_product", %{"product" => product_params}, socket) do
    case Products.create_product(product_params) do
      {:ok, _product} ->
        socket
        |> put_flash(:info, "Product created successfully")
        |> assign(product_changeset: Product.changeset(%Product{}, %{}))
        |> load_products(1)

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Error creating product: #{inspect(changeset)}")
        categories = Categories.list_categories()
        {:noreply, assign(socket, product_changeset: changeset, categories: categories)}
    end
  end

  @impl true
  def handle_event("delete_product", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)
    load_products(socket, socket.assigns.page)
  end

  @impl true
  def handle_event("go_to_page", %{"page" => page}, socket) do
    page = String.to_integer(page)
    load_products(socket, page)
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp load_products(socket, page) do
    # For admin, show all products (including inactive ones)
    all_products = Products.list_all_products()
    total_entries = length(all_products)
    total_pages = ceil(total_entries / 20)

    # Ensure page is within valid range
    page = max(1, min(page, total_pages))

    # Simple pagination - in a real app you'd use Ecto's limit/offset
    start_index = (page - 1) * 20
    end_index = start_index + 20 - 1
    products = Enum.slice(all_products, start_index..end_index)

    {:noreply,
     assign(socket,
       products: products,
       page: page,
       total_pages: total_pages,
       total_entries: total_entries
     )}
  end
end
