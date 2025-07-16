defmodule HomeWareWeb.UserController do
  use HomeWareWeb, :controller

  alias HomeWare.Addresses

  def profile(conn, _params) do
    user = conn.assigns.current_user
    addresses = Addresses.list_user_addresses(user.id)

    render(conn, :profile, addresses: addresses)
  end
end
