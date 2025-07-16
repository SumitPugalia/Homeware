defmodule HomeWareWeb.CheckoutLiveTest do
  use HomeWareWeb.ConnCase
  import Phoenix.LiveViewTest
  alias HomeWare.Factory

  setup do
    user = Factory.insert(:user)
    product = Factory.insert(:product)

    product_variant =
      Factory.insert(:product_variant, %{product_id: product.id, sku: "TEST-SKU-123"})

    cart_item =
      Factory.insert(:cart_item, %{
        user_id: user.id,
        product_id: product.id,
        product_variant_id: product_variant.id,
        quantity: 2
      })

    {:ok, %{user: user, product: product, product_variant: product_variant, cart_item: cart_item}}
  end

  describe "checkout page" do
    test "displays product variant SKU in cart items", %{
      user: user,
      product: product,
      product_variant: product_variant
    } do
      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      assert has_element?(view, "div", "SKU: #{product_variant.sku}")
      assert has_element?(view, "a", product.name)
      assert has_element?(view, "div", product.brand)
    end

    test "handles cart items without product variants gracefully", %{user: user} do
      # Clear existing cart items for this user
      HomeWare.CartItems.clear_user_cart(user.id)

      # Use a different product to avoid unique constraint
      product2 = Factory.insert(:product)

      _cart_item =
        Factory.insert(:cart_item, %{
          user_id: user.id,
          product_id: product2.id,
          product_variant_id: nil,
          quantity: 1
        })

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      assert has_element?(view, "a", product2.name)
      assert has_element?(view, "div", product2.brand)
      refute has_element?(view, "div", "SKU:")
    end

    test "updates cart item quantity when changed in UI", %{
      user: user,
      cart_item: cart_item,
      product: _product,
      product_variant: _product_variant
    } do
      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      # Simulate changing the quantity to 5
      view
      |> element("select[phx-change=update_quantity][phx-value-cart-item-id='#{cart_item.id}']")
      |> render_change(%{"value" => "5", "cart-item-id" => cart_item.id})

      # Reload cart item from DB
      updated_cart_item = HomeWare.CartItems.get_cart_item!(cart_item.id)
      assert updated_cart_item.quantity == 5

      # Assert UI reflects new quantity
      assert has_element?(view, "option[selected][value='5']")
    end
  end

  defp log_in_user(conn, user) do
    {:ok, token, _claims} = HomeWare.Guardian.encode_and_sign(user)

    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session("user_token", token)
  end
end
