defmodule HomeWareWeb.UserAuth do
  @moduledoc """
  Provides authentication and authorization for users.
  """
  use HomeWareWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  alias HomeWare.Accounts

  def log_in_user(conn, user, _params \\ %{}) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_token, generate_user_session_token(user))
    |> configure_session(renew: true)
    |> redirect(to: ~p"/")
  end

  def log_out_user(conn) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  def fetch_current_user(conn, _opts) do
    user_token = get_session(conn, :user_token)
    user_token && get_user_by_session_token(user_token)
    |> case do
      nil -> assign(conn, :current_user, nil)
      user -> assign(conn, :current_user, user)
    end
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: ~p"/")
      |> halt()
    else
      conn
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp generate_user_session_token(user) do
    Phoenix.Token.sign(HomeWareWeb.Endpoint, "user auth", user.id)
  end

  defp get_user_by_session_token(token) do
    case Phoenix.Token.verify(HomeWareWeb.Endpoint, "user auth", token, max_age: 2_592_000) do
      {:ok, user_id} -> Accounts.get_user!(user_id)
      :error -> nil
    end
  end
end
