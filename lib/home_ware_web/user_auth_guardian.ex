defmodule HomeWareWeb.UserAuthGuardian do
  @moduledoc """
  Provides authentication and authorization for users using Guardian.
  """
  use HomeWareWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller
  alias HomeWare.Guardian

  def log_in_user(conn, user, _params \\ %{}) do
    case Guardian.encode_and_sign(user) do
      {:ok, token, _claims} ->
        redirect_path = if user.role == :admin, do: ~p"/admin/dashboard", else: ~p"/"

        conn
        |> assign(:current_user, user)
        |> put_resp_header("authorization", "Bearer #{token}")
        |> put_session(:user_token, token)
        |> redirect(to: redirect_path)

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)

    if user_token do
      Guardian.revoke(user_token)
    end

    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  def fetch_current_user(conn, _opts) do
    # Try to get token from Authorization header first
    token = get_token_from_header(conn) || get_session(conn, :user_token)

    case token do
      nil ->
        assign(conn, :current_user, nil)

      token ->
        case Guardian.resource_from_token(token) do
          {:ok, user, _claims} ->
            assign(conn, :current_user, user)

          {:error, _reason} ->
            assign(conn, :current_user, nil)
        end
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

  def require_admin_user(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.role == :admin do
      conn
    else
      conn
      |> put_flash(:error, "You must be an admin to access this page.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp get_token_from_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
