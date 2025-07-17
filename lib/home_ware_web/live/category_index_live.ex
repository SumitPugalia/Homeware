defmodule HomeWareWeb.CategoryIndexLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.NavCountsLive, :default}

  alias HomeWare.Categories

  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  @impl true
  def mount(_params, session, socket) do
    socket =
      if Map.has_key?(socket.assigns, :current_user),
        do: socket,
        else: %{
          socket
          | assigns: Map.put(socket.assigns, :current_user, get_user_from_session(session))
        }

    categories = Categories.list_categories_with_products()

    {:ok, assign(socket, categories: categories)}
  end

  defp get_user_from_session(session) do
    token = session["user_token"]

    case token do
      nil ->
        nil

      token ->
        case HomeWare.Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> user
          {:error, _reason} -> nil
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow">
        <div class="max-w-14xl mx-auto px-4 sm:px-6 lg:px-8">
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
      <!-- Hero Section -->
      <div class="relative bg-white overflow-hidden">
        <div class="max-w-14xl mx-auto">
          <div class="relative z-10 pb-8 bg-white sm:pb-16 md:pb-20 lg:max-w-14xl-2xl lg:w-full lg:pb-28 xl:pb-32">
            <main class="mt-10 mx-auto max-w-14xl px-4 sm:mt-12 sm:px-6 md:mt-16 lg:mt-20 lg:px-8 xl:mt-28">
              <div class="sm:text-center lg:text-left">
                <h1 class="text-4xl tracking-tight font-extrabold text-gray-900 sm:text-5xl md:text-6xl">
                  <span class="block xl:inline">Shop by</span>
                  <span class="block text-indigo-600 xl:inline">Category</span>
                </h1>
                <p class="mt-3 text-base text-gray-500 sm:mt-5 sm:text-lg sm:max-w-14xl-xl sm:mx-auto md:mt-5 md:text-xl lg:mx-0">
                  Discover our wide range of household appliances organized by category.
                </p>
              </div>
            </main>
          </div>
        </div>
      </div>
      <!-- Categories Grid -->
      <div class="bg-white">
        <div class="max-w-14xl mx-auto py-16 px-4 sm:py-24 sm:px-6 lg:px-8">
          <div class="grid grid-cols-1 gap-y-10 gap-x-6 sm:grid-cols-2 lg:grid-cols-3 xl:gap-x-8">
            <%= for category <- @categories do %>
              <div class="group relative">
                <div class="w-full min-h-80 bg-gray-200 aspect-w-1 aspect-h-1 rounded-md overflow-hidden group-hover:opacity-75 lg:h-80 lg:aspect-none">
                  <img
                    src="https://via.placeholder.com/400x400"
                    alt={category.name}
                    class="w-full h-full object-center object-cover lg:w-full lg:h-full"
                  />
                </div>
                <div class="mt-4 flex justify-between">
                  <div>
                    <h3 class="text-lg font-medium text-gray-900">
                      <a href={~p"/categories/#{category.id}"}>
                        <span aria-hidden="true" class="absolute inset-0"></span>
                        <%= category.name %>
                      </a>
                    </h3>
                    <p class="mt-1 text-sm text-gray-500"><%= category.description %></p>
                    <p class="mt-1 text-sm text-gray-500">
                      <%= length(category.products) %> products
                    </p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
