defmodule HomeWareWeb.LiveAuth do
  @moduledoc """
  Provides authentication for LiveView routes.
  """
  use HomeWareWeb, :verified_routes
  import Phoenix.Component
  import Phoenix.LiveView
  alias HomeWare.Guardian

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/users/log_in")}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)

    if socket.assigns.current_user do
      {:halt, redirect(socket, to: ~p"/")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:ensure_admin, _params, session, socket) do
    socket = assign_new(socket, :current_user, fn -> get_user_from_session(session) end)

    if socket.assigns.current_user && socket.assigns.current_user.role == :admin do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/")}
    end
  end

  defp get_user_from_session(session) do
    token = session["user_token"]

    case token do
      nil ->
        nil

      token ->
        case Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> user
          {:error, _reason} -> nil
        end
    end
  end
end
