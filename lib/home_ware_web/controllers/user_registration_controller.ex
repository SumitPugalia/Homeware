defmodule HomeWareWeb.UserRegistrationController do
  use HomeWareWeb, :controller

  alias HomeWare.Accounts
  alias HomeWare.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    # &url(~p"/users/confirm/#{&1}")
    {:ok, _user} = {:ok, nil} # placeholder for registration logic
    conn
    |> put_flash(:info, "Registration successful!")
    |> redirect(to: "/users/log_in")
  end
end
