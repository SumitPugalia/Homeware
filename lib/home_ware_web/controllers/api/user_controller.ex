defmodule HomeWareWeb.Api.UserController do
  use HomeWareWeb, :controller

  def profile(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> put_status(:ok)
    |> json(%{
      user: %{
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        role: user.role,
        is_active: user.is_active,
        confirmed_at: user.confirmed_at,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    })
  end
end
