defmodule HomeWareWeb.UserRegistrationController do
  use HomeWareWeb, :controller

  alias HomeWare.Accounts
  alias HomeWare.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => _user_params}) do
    # &url(~p"/users/confirm/#{&1}")
    # placeholder for registration logic
    {:ok, _user} = {:ok, nil}

    conn
    |> put_flash(:info, "Registration successful!")
    |> redirect(to: "/users/log_in")
  end
end
