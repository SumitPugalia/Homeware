defmodule HomeWare.FactoryTest do
  use ExUnit.Case

  alias HomeWare.Factory

  describe "factory" do
    test "builds user with valid attributes" do
      user = Factory.build(:user)
      assert user.email =~ "@example.com"
      assert user.role == :customer
      assert user.is_active == true
    end

    test "builds category with valid attributes" do
      category = Factory.build(:category)
      assert category.name == "Test Category"
      assert category.slug == "test-category"
      assert category.is_active == true
    end

    test "builds product with valid attributes" do
      product = Factory.build(:product)
      assert product.name == "Test Product"
      assert product.price == Decimal.new("99.99")
      assert product.is_active == true
    end

    test "builds address with valid attributes" do
      address = Factory.build(:address)
      assert address.address_type == :shipping
      assert address.first_name == "John"
      assert address.last_name == "Doe"
    end

    test "builds order with valid attributes" do
      order = Factory.build(:order)
      assert order.status == :pending
      assert order.total_amount == Decimal.new("118.00")
      assert order.currency == "USD"
    end

    test "builds order_item with valid attributes" do
      order_item = Factory.build(:order_item)
      assert order_item.quantity == 2
      assert order_item.unit_price == Decimal.new("49.99")
      assert order_item.total_price == Decimal.new("99.98")
    end

    test "builds product_review with valid attributes" do
      product_review = Factory.build(:product_review)
      assert product_review.rating == 5
      assert product_review.status == :approved
      assert product_review.title == "Great Product!"
    end

    test "builds cart_item with valid attributes" do
      cart_item = Factory.build(:cart_item)
      assert cart_item.quantity == 3
      assert cart_item.unit_price == Decimal.new("49.99")
      assert cart_item.total_price == Decimal.new("149.97")
    end

    test "allows overriding attributes" do
      user = Factory.build(:user, %{role: :admin, email: "admin@example.com"})
      assert user.role == :admin
      assert user.email == "admin@example.com"
    end
  end
end
