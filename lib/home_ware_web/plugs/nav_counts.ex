defmodule HomeWareWeb.Plugs.NavCounts do
  @moduledoc """
  Plug to assign cart_count and wishlist_count for navigation.
  """
  import Plug.Conn
  alias HomeWare.CartItems
  alias HomeWare.WishlistItems

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    cart_count =
      if user, do: CartItems.get_user_cart_count(user.id), else: 0

    wishlist_count =
      if user, do: WishlistItems.get_user_wishlist_count(user.id), else: 0

    conn
    |> assign(:cart_count, cart_count)
    |> assign(:wishlist_count, wishlist_count)
  end
end
