defmodule HomeWare.CartItemsTest do
  use HomeWare.DataCase

  alias HomeWare.CartItems
  alias HomeWare.Products
  alias HomeWare.Accounts
  alias HomeWare.Categories

  describe "cart items" do
    test "list_user_cart_items sets availability correctly" do
      # Create a user
      user =
        Accounts.register_user(%{
          email: "test@example.com",
          password: "password123",
          first_name: "Test",
          last_name: "User"
        })

      # Create a category first
      {:ok, category} =
        Categories.create_category(%{
          name: "Test Category",
          description: "Test category description",
          image_url: "test.jpg",
          is_active: true
        })

      # Create a product that is out of stock
      {:ok, product} =
        Products.create_product(%{
          name: "Test Product",
          brand: "Test Brand",
          product_type: "test",
          product_category: "test",
          description: "Test description",
          price: Decimal.new("100.00"),
          selling_price: Decimal.new("80.00"),
          # Out of stock
          inventory_quantity: 0,
          is_active: true,
          is_featured: false,
          category_id: category.id,
          dimensions: %{},
          specifications: %{}
        })

      # Add the out-of-stock product to cart
      {:ok, _cart_item} =
        CartItems.create_cart_item(%{
          user_id: user.id,
          product_id: product.id,
          quantity: 1
        })

      # Get cart items - should have availability set
      cart_items = CartItems.list_user_cart_items(user.id)

      assert length(cart_items) == 1
      cart_item = List.first(cart_items)

      # The product should have availability set
      assert cart_item.product.available? == false
    end

    test "cart items with available products have correct availability" do
      # Create a user
      user =
        Accounts.register_user(%{
          email: "test2@example.com",
          password: "password123",
          first_name: "Test",
          last_name: "User"
        })

      # Create a category first
      {:ok, category} =
        Categories.create_category(%{
          name: "Test Category 2",
          description: "Test category description",
          image_url: "test.jpg",
          is_active: true
        })

      # Create a product that is in stock
      {:ok, product} =
        Products.create_product(%{
          name: "Available Product",
          brand: "Test Brand",
          product_type: "test",
          product_category: "test",
          description: "Test description",
          price: Decimal.new("100.00"),
          selling_price: Decimal.new("80.00"),
          # In stock
          inventory_quantity: 10,
          is_active: true,
          is_featured: false,
          category_id: category.id,
          dimensions: %{},
          specifications: %{}
        })

      # Add the in-stock product to cart
      {:ok, _cart_item} =
        CartItems.create_cart_item(%{
          user_id: user.id,
          product_id: product.id,
          quantity: 1
        })

      # Get cart items - should have availability set
      cart_items = CartItems.list_user_cart_items(user.id)

      assert length(cart_items) == 1
      cart_item = List.first(cart_items)

      # The product should have availability set
      assert cart_item.product.available? == true
    end
  end
end
