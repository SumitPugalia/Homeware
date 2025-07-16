defmodule HomeWareWeb.NavCountsLive do
  import Phoenix.Component
  alias HomeWare.CartItems
  alias HomeWare.WishlistItems

  def on_mount(:default, _params, session, socket) do
    user = socket.assigns[:current_user] || get_user_from_session(session)

    cart_count =
      if user, do: CartItems.get_user_cart_count(user.id), else: 0

    wishlist_count =
      if user, do: WishlistItems.get_user_wishlist_count(user.id), else: 0

    {:cont, assign(socket, cart_count: cart_count, wishlist_count: wishlist_count)}
  end

  defp get_user_from_session(session) do
    token = session["user_token"]

    case token do
      nil ->
        nil

      token ->
        case HomeWare.Guardian.resource_from_token(token) do
          {:ok, user, _claims} -> user
          _ -> nil
        end
    end
  end
end
