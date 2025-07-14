defmodule HomeWareWeb.UserRegistrationController do
  use HomeWareWeb, :controller

  alias HomeWare.Accounts

  def new(conn, _params) do
    changeset = HomeWare.Accounts.change_user_registration(%HomeWare.Accounts.User{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Registration successful! Please log in.")
        |> redirect(to: ~p"/users/log_in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
