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
    <div class="flex min-h-screen bg-[#f5f6f8]">
      <!-- Sidebar -->
      <aside class="w-64 min-h-screen bg-white flex flex-col py-6 px-4 border-r border-gray-200">
        <div class="flex items-center mb-10">
          <img src="/images/logo.svg" alt="Arik Logo" class="h-10 mr-2"/>
          <span class="text-3xl font-bold text-[#1a2a3a] tracking-tight">Arik</span>
        </div>
        <nav class="flex flex-col gap-2 mb-8">
          <a href="/admin/dashboard" class="flex items-center gap-2 px-4 py-2 rounded transition font-medium text-sm hover:bg-gray-100 text-gray-700">
            <span class="material-icons text-base">dashboard</span> DASHBOARD
          </a>
          <a href="/admin/products" class="flex items-center gap-2 px-4 py-2 rounded transition font-medium text-sm bg-[#0a3d62] text-white">
            <span class="material-icons text-base">inventory_2</span> ALL PRODUCTS
          </a>
          <a href="/admin/orders" class="flex items-center gap-2 px-4 py-2 rounded transition font-medium text-sm hover:bg-gray-100 text-gray-700">
            <span class="material-icons text-base">list_alt</span> ORDER LIST
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
        <div class="flex justify-between items-center mb-6">
          <div>
            <div class="text-xs text-gray-500 mb-1">Home &gt; All Products</div>
            <h1 class="text-2xl font-bold text-gray-900">All Products</h1>
          </div>
          <button phx-click="show_add_form" class="bg-black text-white px-5 py-2 rounded flex items-center gap-2 hover:bg-gray-800">
            <span class="material-icons">add</span> ADD NEW PRODUCT
          </button>
        </div>
        <!-- Product Card Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <%= for product <- @products do %>
            <div class="bg-white rounded-lg shadow p-4 flex flex-col">
              <img src={product.featured_image || "/images/placeholder.png"} alt={product.name} class="h-32 w-full object-cover rounded" />
              <div class="mt-2 font-bold"><%= product.name %></div>
              <div class="text-sm text-gray-500"><%= product.category && product.category.name %></div>
              <div class="font-semibold mt-1">₹<%= product.price %></div>
              <div class="text-xs text-gray-600 mt-2"><%= product.description %></div>
              <div class="flex justify-between mt-4 text-xs">
                <div>Sales<br/><span class="font-bold text-orange-500">1269</span></div>
                <div>Remaining Products<br/><span class="font-bold text-gray-700">1269</span></div>
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
            <button class="px-3 py-1 rounded-l border border-gray-300 bg-white text-gray-500 hover:bg-gray-100">&lt;</button>
            <%= for page <- 1..10 do %>
              <button class={"px-3 py-1 border border-gray-300 bg-white text-gray-700 hover:bg-gray-100 " <> if page == @page, do: "font-bold bg-gray-200", else: ""}><%= page %></button>
            <% end %>
            <button class="px-3 py-1 rounded-r border border-gray-300 bg-white text-gray-500 hover:bg-gray-100">NEXT &gt;</button>
          </nav>
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
