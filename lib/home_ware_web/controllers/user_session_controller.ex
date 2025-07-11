defmodule HomeWareWeb.UserSessionController do
  use HomeWareWeb, :controller

  alias HomeWare.Accounts
  alias HomeWareWeb.UserAuthGuardian

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuthGuardian.log_in_user(user, user_params)

      {:error, :invalid_credentials} ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        render(conn, :new, error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuthGuardian.log_out_user()
  end
end
