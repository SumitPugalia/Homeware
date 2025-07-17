defmodule HomeWareWeb.ProductDetailLiveTest do
  use HomeWareWeb.ConnCase

  alias HomeWare.Factory
  alias HomeWare.Guardian

  setup do
    user = Factory.insert(:user)
    {:ok, token, _claims} = Guardian.encode_and_sign(user)

    %{user: user, token: token}
  end

  describe "product availability" do
    test "shows enabled Add to Cart button when product has available variants", %{
      conn: conn,
      token: token
    } do
      # Create a product with zero inventory
      product = Factory.insert(:product, %{inventory_quantity: 0})

      # Create an available variant
      _variant =
        Factory.insert(:product_variant, %{
          product_id: product.id,
          quantity: 5,
          is_active: true
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/products/#{product.id}")

      html = html_response(conn, 200)

      # Should show "In Stock" badge
      assert html =~ "In Stock"
      # Should show enabled "Add to Cart" button (not disabled)
      assert html =~ "Add to Cart"
      refute html =~ "disabled"
      # Should not show disabled "Out of Stock" button
      refute html =~ "Out of Stock</span>"
    end

    test "shows disabled Out of Stock button when product has no available variants", %{
      conn: conn,
      token: token
    } do
      # Create a product with zero inventory
      product = Factory.insert(:product, %{inventory_quantity: 0})

      # Create an unavailable variant
      _variant =
        Factory.insert(:product_variant, %{
          product_id: product.id,
          quantity: 0,
          is_active: true
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/products/#{product.id}")

      html = html_response(conn, 200)

      # Should show "Out of Stock" badge
      assert html =~ "Out of Stock"
      # Should show disabled "Out of Stock" button
      assert html =~ "Out of Stock</span>"
      assert html =~ "disabled"
      # Should not show enabled "Add to Cart" button
      refute html =~ "phx-click=\"add_to_cart\""
    end
  end
end
