defmodule HomeWareWeb.AccountLive do
  use HomeWareWeb, :live_view
  on_mount {HomeWareWeb.NavCountsLive, :default}

  on_mount {HomeWareWeb.LiveAuth, :ensure_authenticated}

  @impl true
  def mount(_params, session, socket) do
    # Assign current_user for layout compatibility
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)
    {:ok, assign(socket, user: socket.assigns.current_user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-14xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">
          <h1 class="text-2xl font-bold text-gray-900 mb-6">Account Settings</h1>

          <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Profile Information</h3>
              <div class="mt-5 space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Email</label>
                  <p class="mt-1 text-sm text-gray-900"><%= @user.email %></p>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Name</label>
                  <p class="mt-1 text-sm text-gray-900">
                    <%= @user.first_name %> <%= @user.last_name %>
                  </p>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Role</label>
                  <p class="mt-1 text-sm text-gray-900"><%= @user.role %></p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
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
end
