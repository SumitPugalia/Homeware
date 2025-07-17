defmodule HomeWareWeb.Admin.Shared do
  @moduledoc """
  Shared helpers for admin views.
  """

  def render_admin_sidebar(assigns) do
    current_path = assigns[:current_path] || "/admin/dashboard"

    sidebar = """
    <div class="hidden md:fixed md:inset-y-0 md:left-0 md:z-50 md:w-64 md:bg-white md:dark:bg-gray-800 md:shadow-lg md:block border-r border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-center h-16 bg-gradient-to-r from-blue-600 to-purple-600">
        <h1 class="text-xl font-bold text-white">Vibe Needs</h1>
      </div>
      <nav class="mt-8">
        <div class="px-4 space-y-2">
          #{sidebar_links(current_path, [vertical: true], assigns)}
        </div>
      </nav>
    </div>
    """

    topbar = """
    <div class="md:hidden fixed top-0 left-0 right-0 z-50 bg-white/90 dark:bg-gray-800/90 backdrop-blur-md shadow-lg flex items-center px-4 h-16 border-b border-gray-200 dark:border-gray-700">
      <div class="flex items-center space-x-4">
        <h1 class="text-lg font-bold text-blue-600 dark:text-blue-400">Admin</h1>
        <nav class="flex space-x-1">
          #{sidebar_links(current_path, [vertical: false], assigns)}
        </nav>
      </div>
    </div>
    <div class="h-16 md:hidden"></div> <!-- Spacer for mobile topbar -->
    """

    Phoenix.HTML.raw(sidebar <> topbar)
  end

  defp sidebar_links(current_path, opts, assigns) do
    vertical = Keyword.get(opts, :vertical, true)

    link_class = fn active ->
      base =
        if vertical do
          "flex items-center px-4 py-3 rounded-lg transition-all duration-200"
        else
          "flex items-center px-3 py-2 rounded-lg transition-all duration-200"
        end

      if active do
        base <>
          " text-blue-700 dark:text-blue-300 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700"
      else
        base <>
          " text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 hover:text-gray-900 dark:hover:text-white"
      end
    end

    links = [
      {"/admin/dashboard", "Dashboard",
       "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"},
      {"/admin/products", "Products",
       "M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"},
      {"/admin/orders", "Orders", "M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"},
      {"#", "Customers",
       "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"},
      {"#", "Analytics",
       "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"}
    ]

    link_html =
      links
      |> Enum.map(fn {href, label, svg_path} ->
        active = String.contains?(current_path, href) and href != "#"

        """
        <a href=\"#{href}\" class=\"#{link_class.(active)} interactive-hover\">
          <svg class=\"w-5 h-5 mr-3\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"#{svg_path}\"></path></svg>
          <span class=\"#{if vertical, do: "", else: "hidden sm:inline"}\">#{label}</span>
        </a>
        """
      end)
      |> Enum.join("")

    logout_html = """
    <div class=\"#{if vertical, do: "pt-4 mt-4 border-t border-gray-200 dark:border-gray-700", else: "ml-2"}\">
      <form action=\"/users/log_out\" method=\"post\" style=\"display: inline;\">
        <input type=\"hidden\" name=\"_method\" value=\"delete\" />
        <input type=\"hidden\" name=\"_csrf_token\" value=\"#{assigns[:csrf_token] || ""}\" />
        <button type=\"submit\" class=\"flex items-center px-4 py-3 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg w-full text-left transition-all duration-200 interactive-hover\">
          <svg class=\"w-5 h-5 mr-3\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a2 2 0 01-2 2H7a2 2 0 01-2-2V7a2 2 0 012-2h4a2 2 0 012 2v1\"></path></svg>
          <span class=\"#{if vertical, do: "", else: "hidden sm:inline"}\">Logout</span>
        </button>
      </form>
    </div>
    """

    link_html <> logout_html
  end
end
