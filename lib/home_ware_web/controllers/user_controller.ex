defmodule HomeWareWeb.UserController do
  use HomeWareWeb, :controller

  alias HomeWare.Addresses
  alias HomeWare.Accounts

  def profile(conn, _params) do
    user = conn.assigns.current_user
    addresses = Addresses.list_user_addresses(user.id)

    render(conn, :profile, addresses: addresses)
  end

  def edit(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user(user)
    render(conn, :edit, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _updated_user} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: ~p"/profile")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end
end
