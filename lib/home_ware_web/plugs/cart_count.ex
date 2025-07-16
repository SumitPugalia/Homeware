defmodule HomeWareWeb.Plugs.CartCount do
  @moduledoc """
  Plug to fetch cart count for the current user and add it to assigns.
  """
  import Plug.Conn
  alias HomeWare.CartItems

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      nil ->
        assign(conn, :cart_count, 0)

      user ->
        cart_count = CartItems.get_user_cart_count(user.id)
        assign(conn, :cart_count, cart_count)
    end
  end
end
