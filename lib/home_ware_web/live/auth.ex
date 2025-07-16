defmodule HomeWareWeb.LiveAuth do
  @moduledoc """
  Authentication helpers for LiveViews.
  """

  import Phoenix.LiveView

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket =
      if Map.has_key?(socket.assigns, :current_user),
        do: socket,
        else: %{
          socket
          | assigns: Map.put(socket.assigns, :current_user, get_user_from_session(session))
        }

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/users/log_in")}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket =
      if Map.has_key?(socket.assigns, :current_user),
        do: socket,
        else: %{
          socket
          | assigns: Map.put(socket.assigns, :current_user, get_user_from_session(session))
        }

    if socket.assigns.current_user do
      {:halt, redirect(socket, to: "/")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:ensure_admin, _params, session, socket) do
    socket =
      if Map.has_key?(socket.assigns, :current_user),
        do: socket,
        else: %{
          socket
          | assigns: Map.put(socket.assigns, :current_user, get_user_from_session(session))
        }

    if socket.assigns.current_user && socket.assigns.current_user.role == :admin do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
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
