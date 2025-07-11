defmodule HomeWare.Products.ProductTest do
  use HomeWare.DataCase

  alias HomeWare.Products.Product

  describe "product changeset" do
    test "changeset with valid attributes" do
      valid_attrs = %{
        name: "Test Product",
        slug: "test-product",
        description: "Test description",
        price: 100.0,
        brand: "Test Brand",
        is_active: true,
        is_featured: false,
        inventory_quantity: 10,
        average_rating: 4.5,
        review_count: 5
      }

      changeset = Product.changeset(%Product{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      invalid_attrs = %{
        name: nil,
        price: -10.0,
        inventory_quantity: -5
      }

      changeset = Product.changeset(%Product{}, invalid_attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
      assert "must be greater than 0" in errors_on(changeset).price
      assert "must be greater than or equal to 0" in errors_on(changeset).inventory_quantity
    end

    test "changeset with invalid price" do
      changeset = Product.changeset(%Product{}, %{price: -1.0})
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).price
    end

    test "changeset with invalid inventory quantity" do
      changeset = Product.changeset(%Product{}, %{inventory_quantity: -1})
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).inventory_quantity
    end

    test "changeset with invalid average rating" do
      changeset = Product.changeset(%Product{}, %{average_rating: 6.0})
      refute changeset.valid?
      assert "must be less than or equal to 5" in errors_on(changeset).average_rating
    end

    test "changeset with invalid review count" do
      changeset = Product.changeset(%Product{}, %{review_count: -1})
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).review_count
    end
  end
end
