defmodule HomeWareWeb.CartController do
  use HomeWareWeb, :controller
  alias HomeWare.CartItems
  alias HomeWare.Products

  def add_to_cart(conn, %{"product_id" => product_id, "quantity" => quantity}) do
    user = conn.assigns[:current_user]

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:error, "You must be logged in to add items to your cart.")
        |> redirect(to: ~p"/users/log_in")

      true ->
        # Check if product exists and is available
        case Products.get_product!(product_id) do
          nil ->
            conn
            |> put_flash(:error, "Product not found.")
            |> redirect(to: ~p"/")

          product ->
            if product.available? do
              case CartItems.add_to_cart(user.id, product_id, nil, String.to_integer(quantity)) do
                {:ok, _cart_item} ->
                  conn
                  |> put_flash(:info, "Added to cart!")
                  |> redirect(to: ~p"/")

                {:error, :product_not_found} ->
                  conn
                  |> put_flash(:error, "Product not found.")
                  |> redirect(to: ~p"/")

                {:error, _reason} ->
                  conn
                  |> put_flash(:error, "Failed to add item to cart.")
                  |> redirect(to: ~p"/")
              end
            else
              conn
              |> put_flash(:error, "This product is currently out of stock.")
              |> redirect(to: ~p"/")
            end
        end
    end
  end

  def add_to_cart(conn, %{"product_id" => product_id}) do
    add_to_cart(conn, %{"product_id" => product_id, "quantity" => "1"})
  end
end
