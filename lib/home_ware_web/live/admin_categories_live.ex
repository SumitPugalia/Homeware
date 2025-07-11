defmodule HomeWareWeb.AdminCategoriesLive do
  use HomeWareWeb, :live_view

  alias HomeWare.Categories
  alias HomeWare.Categories.Category

  @impl true
  def mount(_params, _session, socket) do
    categories = Categories.list_categories()

    {:ok,
     assign(socket,
       categories: categories,
       show_form: false,
       editing_category: nil,
       category_changeset: Category.changeset(%Category{}, %{})
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex">
              <div class="flex-shrink-0 flex items-center">
                <a href="/" class="text-xl font-bold text-gray-900">HomeWare</a>
              </div>
            </div>
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <a href="/cart" class="relative p-2 text-gray-400 hover:text-gray-500">
                  <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3 3h2l.4 2M7 13h10l4-8H5.4m0 0L7 13m0 0l-2.5 5M7 13l2.5 5m6-5v6a2 2 0 01-2 2H9a2 2 0 01-2-2v-6m6 0V9a2 2 0 00-2-2H9a2 2 0 00-2 2v4.01"
                    />
                  </svg>
                </a>
              </div>
              <div class="ml-4 flex items-center md:ml-6">
                <%= if @current_user do %>
                  <div class="ml-3 relative">
                    <div class="flex items-center">
                      <span class="text-sm text-gray-700 mr-4">
                        Welcome, <%= @current_user.first_name %>
                      </span>
                      <a href="/profile" class="text-sm text-gray-700 hover:text-gray-900 mr-4">
                        Profile
                      </a>
                      <a href="/orders" class="text-sm text-gray-700 hover:text-gray-900 mr-4">
                        Orders
                      </a>
                      <form action="/users/log_out" method="post" class="inline">
                        <button type="submit" class="text-sm text-gray-700 hover:text-gray-900">
                          Logout
                        </button>
                      </form>
                    </div>
                  </div>
                <% else %>
                  <div class="flex items-center space-x-4">
                    <a href="/users/log_in" class="text-sm text-gray-700 hover:text-gray-900">
                      Sign in
                    </a>
                    <a
                      href="/users/register"
                      class="bg-indigo-600 text-white px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-700"
                    >
                      Sign up
                    </a>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </nav>
      <!-- Admin Header -->
      <div class="bg-white border-b border-gray-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between py-4">
            <h1 class="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
            <nav class="flex space-x-4">
              <a href="/admin/dashboard" class="text-gray-500 hover:text-gray-700">Dashboard</a>
              <a href="/admin/products" class="text-gray-500 hover:text-gray-700">Products</a>
              <a href="/admin/categories" class="text-indigo-600 font-medium">Categories</a>
              <a href="/admin/orders" class="text-gray-500 hover:text-gray-700">Orders</a>
              <a href="/admin/users" class="text-gray-500 hover:text-gray-700">Users</a>
            </nav>
          </div>
        </div>
      </div>
      <!-- Content -->
      <div class="max-w-7xl mx-auto py-8 px-4 sm:py-12 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center mb-8">
          <h2 class="text-3xl font-bold text-gray-900">Categories</h2>
          <button
            phx-click="show_form"
            class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700"
          >
            Add Category
          </button>
        </div>
        <!-- Category Form -->
        <%= if @show_form do %>
          <div class="bg-white rounded-lg shadow p-6 mb-8">
            <h3 class="text-lg font-medium text-gray-900 mb-4">
              <%= if @editing_category, do: "Edit Category", else: "Add New Category" %>
            </h3>

            <form phx-submit="save_category" phx-change="validate_category">
              <div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
                <div>
                  <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
                  <input
                    type="text"
                    name="category[name]"
                    id="name"
                    value={@category_changeset.changes[:name] || @category_changeset.data.name || ""}
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label for="slug" class="block text-sm font-medium text-gray-700">Slug</label>
                  <input
                    type="text"
                    name="category[slug]"
                    id="slug"
                    value={@category_changeset.changes[:slug] || @category_changeset.data.slug || ""}
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  />
                </div>
              </div>

              <div class="mt-6">
                <label for="description" class="block text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  name="category[description]"
                  id="description"
                  rows="3"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                ><%= @category_changeset.changes[:description] || @category_changeset.data.description || "" %></textarea>
              </div>

              <div class="mt-6">
                <label for="image_url" class="block text-sm font-medium text-gray-700">
                  Image URL
                </label>
                <input
                  type="text"
                  name="category[image_url]"
                  id="image_url"
                  value={
                    @category_changeset.changes[:image_url] || @category_changeset.data.image_url ||
                      ""
                  }
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>

              <div class="mt-6 flex items-center">
                <input
                  type="checkbox"
                  name="category[is_active]"
                  id="is_active"
                  value="true"
                  checked={
                    @category_changeset.changes[:is_active] != false &&
                      @category_changeset.data.is_active != false
                  }
                  class="rounded border-gray-300 text-indigo-600 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
                <label for="is_active" class="ml-2 block text-sm text-gray-900">Active</label>
              </div>

              <div class="mt-6 flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="cancel_form"
                  class="bg-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700"
                >
                  <%= if @editing_category, do: "Update Category", else: "Create Category" %>
                </button>
              </div>
            </form>
          </div>
        <% end %>
        <!-- Categories Table -->
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Slug
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Description
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
              <%= for category <- @categories do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                      <div class="flex-shrink-0 h-10 w-10">
                        <img
                          class="h-10 w-10 rounded-full"
                          src="https://via.placeholder.com/40x40"
                          alt=""
                        />
                      </div>
                      <div class="ml-4">
                        <div class="text-sm font-medium text-gray-900"><%= category.name %></div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    <%= category.slug %>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-500">
                    <%= String.slice(category.description || "", 0, 50) %><%= if String.length(
                                                                                   category.description ||
                                                                                     ""
                                                                                 ) > 50,
                                                                                 do: "...",
                                                                                 else: "" %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={
                      if category.is_active,
                        do:
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800",
                        else:
                          "inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800"
                    }>
                      <%= if category.is_active, do: "Active", else: "Inactive" %>
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button
                      phx-click="edit_category"
                      phx-value-id={category.id}
                      class="text-indigo-600 hover:text-indigo-900 mr-3"
                    >
                      Edit
                    </button>
                    <button
                      phx-click="delete_category"
                      phx-value-id={category.id}
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
    </div>
    """
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    categories = Categories.list_categories()
    changeset = Category.changeset(%Category{}, %{})

    {:noreply,
     assign(socket,
       show_form: true,
       editing_category: nil,
       category_changeset: changeset,
       categories: categories
     )}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply,
     assign(socket,
       show_form: false,
       editing_category: nil,
       category_changeset: Category.changeset(%Category{}, %{})
     )}
  end

  @impl true
  def handle_event("edit_category", %{"id" => id}, socket) do
    category = Categories.get_category!(id)
    categories = Categories.list_categories()
    changeset = Category.changeset(category, %{})

    {:noreply,
     assign(socket,
       show_form: true,
       editing_category: category,
       category_changeset: changeset,
       categories: categories
     )}
  end

  @impl true
  def handle_event("validate_category", %{"category" => category_params}, socket) do
    changeset =
      socket.assigns.editing_category ||
        %Category{}
        |> Category.changeset(category_params)
        |> Map.put(:action, :validate)

    {:noreply, assign(socket, category_changeset: changeset)}
  end

  @impl true
  def handle_event("save_category", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.editing_category, category_params)
  end

  @impl true
  def handle_event("delete_category", %{"id" => id}, socket) do
    category = Categories.get_category!(id)
    {:ok, _} = Categories.delete_category(category)

    socket
    |> put_flash(:info, "Category deleted successfully")
    |> assign(categories: Categories.list_categories())
    |> then(&{:noreply, &1})
  end

  defp save_category(socket, editing_category, category_params) do
    case Categories.create_or_update_category(editing_category, category_params) do
      {:ok, _category} ->
        socket
        |> put_flash(
          :info,
          if(editing_category,
            do: "Category updated successfully",
            else: "Category created successfully"
          )
        )
        |> assign(
          show_form: false,
          editing_category: nil,
          category_changeset: Category.changeset(%Category{}, %{}),
          categories: Categories.list_categories()
        )
        |> then(&{:noreply, &1})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, category_changeset: changeset)}
    end
  end
end
