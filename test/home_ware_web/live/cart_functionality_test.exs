defmodule HomeWareWeb.CartFunctionalityTest do
  use HomeWareWeb.ConnCase
  import Phoenix.LiveViewTest
  alias HomeWare.Factory
  alias HomeWare.CartItems

  setup do
    # Product without variants: available if is_active and inventory_quantity > 0
    product = Factory.insert(:product, %{inventory_quantity: 10, is_active: true})
    # Do NOT create any variants for this product

    # Product with variants: available if at least one variant is active and in stock
    # Set inventory_quantity to 0 since availability is determined by variants
    product_with_variants = Factory.insert(:product, %{inventory_quantity: 0, is_active: true})

    variant1 =
      Factory.insert(:product_variant, %{
        product_id: product_with_variants.id,
        quantity: 5,
        is_active: true
      })

    variant2 =
      Factory.insert(:product_variant, %{
        product_id: product_with_variants.id,
        quantity: 0,
        is_active: true
      })

    user = Factory.insert(:user)

    {:ok,
     %{
       user: user,
       product: product,
       product_with_variants: product_with_variants,
       variant1: variant1,
       variant2: variant2
     }}
  end

  describe "add_to_cart from product detail page" do
    test "adds product without variants to cart successfully", context do
      user = context.user
      product = context.product

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      # Set quantity to 3
      for _ <- 1..2 do
        view
        |> element("button[phx-click=increase_quantity]")
        |> render_click()
      end

      # Add to cart
      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Verify cart item was created
      cart_items = CartItems.list_user_cart_items(user.id)
      assert length(cart_items) == 1
      cart_item = hd(cart_items)
      assert cart_item.product_id == product.id
      assert cart_item.quantity == 3
      assert is_nil(cart_item.product_variant_id)
    end

    test "adds product with variants to cart successfully", context do
      user = context.user
      product = context.product_with_variants
      variant = context.variant1

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      # Select the available variant
      view
      |> element("button[phx-click=select_variant][phx-value-variant='#{variant.id}']")
      |> render_click()

      # Set quantity to 2
      view
      |> element("button[phx-click=increase_quantity]")
      |> render_click()

      # Add to cart
      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Verify cart item was created
      cart_items = CartItems.list_user_cart_items(user.id)
      assert length(cart_items) == 1
      cart_item = hd(cart_items)
      assert cart_item.product_id == product.id
      assert cart_item.product_variant_id == variant.id
      assert cart_item.quantity == 2
    end

    test "increments quantity when adding same product again", context do
      user = context.user
      product = context.product

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      # Add to cart first time
      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Add to cart second time
      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Verify cart item quantity was incremented
      cart_items = CartItems.list_user_cart_items(user.id)
      assert length(cart_items) == 1
      cart_item = hd(cart_items)
      assert cart_item.quantity == 2
    end

    test "redirects to login when user is not authenticated", _context do
      # Try to access checkout without being logged in
      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               build_conn()
               |> live(~p"/checkout")
    end

    test "handles quantity changes correctly", context do
      user = context.user
      product = context.product

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      # Increase quantity to 3
      for _ <- 1..2 do
        view
        |> element("button[phx-click=increase_quantity]")
        |> render_click()
      end

      # Verify quantity is 3
      assert has_element?(view, "span", "3")

      # Decrease quantity to 2
      view
      |> element("button[phx-click=decrease_quantity]")
      |> render_click()

      # Verify quantity is 2
      assert has_element?(view, "span", "2")

      # Try to decrease below 1
      view
      |> element("button[phx-click=decrease_quantity]")
      |> render_click()

      # Verify quantity stays at 1
      assert has_element?(view, "span", "1")
    end
  end

  describe "add_to_cart from checkout page" do
    test "updates cart item quantity in checkout", context do
      user = context.user
      product = context.product

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Navigate to checkout
      {:ok, checkout_view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      # Verify item is in checkout
      assert has_element?(checkout_view, "a", product.name)

      # Increase quantity in checkout
      checkout_view
      |> element("button[phx-click=increase_quantity]")
      |> render_click()

      # Verify quantity was updated
      cart_items = CartItems.list_user_cart_items(user.id)
      cart_item = hd(cart_items)
      assert cart_item.quantity == 2
    end

    test "removes item from cart in checkout", context do
      user = context.user
      product = context.product

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Navigate to checkout
      {:ok, checkout_view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      # Remove item from cart - use the correct button selector
      checkout_view
      |> element("button[phx-click=remove_from_cart]")
      |> render_click()

      # Verify item was removed
      cart_items = CartItems.list_user_cart_items(user.id)
      assert length(cart_items) == 0
    end

    test "updates totals when quantity changes", context do
      user = context.user
      product = context.product

      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Navigate to checkout
      {:ok, checkout_view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      # Get initial total
      initial_total =
        checkout_view
        |> element("[data-testid=subtotal]")
        |> render()
        |> extract_text()

      # Increase quantity
      checkout_view
      |> element("button[phx-click=increase_quantity]")
      |> render_click()

      # Get updated total
      updated_total =
        checkout_view
        |> element("[data-testid=subtotal]")
        |> render()
        |> extract_text()

      # Verify total increased
      assert updated_total != initial_total
    end

    test "handles multiple items in cart", context do
      user = context.user
      product = context.product
      product2 = context.product_with_variants
      variant = context.variant1

      # Add first product to cart
      {:ok, view1, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      view1
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Debug: Check cart after first product
      cart_items_after_first = CartItems.list_user_cart_items(user.id)

      Enum.each(cart_items_after_first, fn item ->
        IO.puts("  - Product: #{item.product.name}, Quantity: #{item.quantity}")
      end)

      # Add second product with variant to cart
      {:ok, view2, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product2.id}")

      # Debug: Check product and variant availability

      # Debug: Check what buttons are rendered
      _product_html = render(view2)

      view2
      |> element("button[phx-click=select_variant][phx-value-variant='#{variant.id}']")
      |> render_click()

      view2
      |> element("button[phx-click=add_to_cart][phx-value-variant-id='#{variant.id}']")
      |> render_click()

      # Debug: Check cart after second product
      cart_items_after_second = CartItems.list_user_cart_items(user.id)

      Enum.each(cart_items_after_second, fn item ->
        IO.puts(
          "  - Product: #{item.product.name}, Quantity: #{item.quantity}, Variant: #{if item.product_variant, do: item.product_variant.sku, else: "none"}"
        )
      end)

      # Navigate to checkout
      {:ok, checkout_view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      # Debug: Print checkout HTML
      _checkout_html = render(checkout_view)

      # Verify both items are in checkout
      assert has_element?(checkout_view, "a", product.name)
      assert has_element?(checkout_view, "a", product2.name)
      assert has_element?(checkout_view, "div", "SKU: #{variant.sku}")

      # Verify cart count
      cart_items = CartItems.list_user_cart_items(user.id)
      assert length(cart_items) == 2
    end
  end

  describe "cart integration tests" do
    test "cart persists across sessions", context do
      user = context.user
      product = context.product
      # Add item to cart in first session
      {:ok, view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/products/#{product.id}")

      view
      |> element("button[phx-click=add_to_cart]")
      |> render_click()

      # Verify item is in cart
      cart_items = CartItems.list_user_cart_items(user.id)
      assert length(cart_items) == 1

      # Start new session and verify cart is still there
      {:ok, checkout_view, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/checkout")

      assert has_element?(checkout_view, "a", product.name)
    end
  end

  describe "direct cart functionality tests" do
    test "add_to_cart function works correctly", context do
      user = context.user
      product = context.product
      variant = context.variant1

      # Test adding product without variant
      {:ok, cart_item1} = CartItems.add_to_cart(user.id, product.id, nil, 1)
      assert cart_item1.user_id == user.id
      assert cart_item1.product_id == product.id
      assert cart_item1.quantity == 1

      # Test adding product with variant
      {:ok, cart_item2} = CartItems.add_to_cart(user.id, product.id, variant.id, 1)
      assert cart_item2.user_id == user.id
      assert cart_item2.product_id == product.id
      assert cart_item2.product_variant_id == variant.id
      assert cart_item2.quantity == 1

      # Test incrementing quantity
      {:ok, cart_item3} = CartItems.add_to_cart(user.id, product.id, nil, 2)
      # 1 + 2
      assert cart_item3.quantity == 3

      # Verify cart items
      cart_items = CartItems.list_user_cart_items(user.id)
      # One without variant, one with variant
      assert length(cart_items) == 2
    end
  end

  # Helper functions
  defp log_in_user(conn, user) do
    {:ok, token, _claims} = HomeWare.Guardian.encode_and_sign(user)

    conn
    |> Plug.Test.init_test_session(%{})
    |> Plug.Conn.put_session("user_token", token)
  end

  defp extract_text(element_html) do
    element_html
    |> Floki.parse_fragment!()
    |> Floki.text()
    |> String.trim()
  end
end
