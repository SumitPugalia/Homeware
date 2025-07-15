defmodule HomeWareWeb.Admin.Shared do
  @moduledoc """
  Shared helpers for admin views.
  """

  def render_admin_sidebar(_assigns) do
    """
    <div class="fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg">
      <div class="flex items-center justify-center h-16 bg-blue-600">
        <h1 class="text-xl font-bold text-white">Admin Dashboard</h1>
      </div>
      <nav class="mt-8">
        <div class="px-4 space-y-2">
          <a
            href="/admin/dashboard"
            class="flex items-center px-4 py-2 text-gray-700 bg-blue-50 rounded-lg"
          >
            <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"
              >
              </path>
            </svg>
            Dashboard
          </a>
          <a
            href="/admin/products"
            class="flex items-center px-4 py-2 text-gray-600 hover:bg-gray-50 rounded-lg"
          >
            <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
              >
              </path>
            </svg>
            Products
          </a>
          <a href="#" class="flex items-center px-4 py-2 text-gray-600 hover:bg-gray-50 rounded-lg">
            <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
              >
              </path>
            </svg>
            Orders
          </a>
          <a href="#" class="flex items-center px-4 py-2 text-gray-600 hover:bg-gray-50 rounded-lg">
            <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"
              >
              </path>
            </svg>
            Customers
          </a>
          <a href="#" class="flex items-center px-4 py-2 text-gray-600 hover:bg-gray-50 rounded-lg">
            <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
              >
              </path>
            </svg>
            Analytics
          </a>
        </div>
      </nav>
    </div>
    """
    |> Phoenix.HTML.raw()
  end
end
