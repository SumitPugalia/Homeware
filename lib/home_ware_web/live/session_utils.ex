defmodule HomeWareWeb.SessionUtils do
  @moduledoc """
  Utility functions for session management in LiveViews.
  """

  @doc """
  Assigns the current user from session to the socket.
  """
  def assign_current_user(socket, session) do
    if Map.has_key?(socket.assigns, :current_user) do
      socket
    else
      %{socket | assigns: Map.put(socket.assigns, :current_user, get_user_from_session(session))}
    end
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
