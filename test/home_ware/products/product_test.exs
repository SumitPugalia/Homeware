defmodule HomeWare.Products.ProductTest do
  use HomeWare.DataCase

  alias HomeWare.Products.Product

  describe "product changeset" do
    test "changeset with valid attributes" do
      category = HomeWare.Factory.insert(:category)

      valid_attrs = %{
        name: "Test Product",
        description: "Test description",
        price: 100.0,
        selling_price: 90.0,
        brand: "Test Brand",
        model: "Test Model",
        product_type: "Test Type",
        product_category: "Test Category",
        is_active: true,
        is_featured: false,
        inventory_quantity: 10,
        category_id: category.id,
        images: ["https://example.com/image1.jpg"],
        featured_image: "https://example.com/featured.jpg",
        dimensions: %{"length" => 10, "width" => 5, "height" => 3},
        specifications: %{"color" => "White", "material" => "Stainless Steel"}
      }

      changeset = Product.changeset(%Product{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      category = HomeWare.Factory.insert(:category)

      invalid_attrs = %{
        name: nil,
        price: -10.0,
        selling_price: -5.0,
        inventory_quantity: -5,
        category_id: category.id,
        images: ["https://example.com/image1.jpg"],
        featured_image: "https://example.com/featured.jpg",
        dimensions: %{"length" => 10, "width" => 5, "height" => 3},
        specifications: %{"color" => "White", "material" => "Stainless Steel"},
        brand: "Test Brand",
        model: "Test Model",
        product_type: "Test Type",
        product_category: "Test Category",
        description: "Test description",
        is_active: true,
        is_featured: false
      }

      changeset = Product.changeset(%Product{}, invalid_attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
      assert "must be greater than 0" in errors_on(changeset).price
      assert "must be greater than 0" in errors_on(changeset).selling_price
      assert "must be greater than or equal to 0" in errors_on(changeset).inventory_quantity
    end

    test "changeset with invalid price" do
      category = HomeWare.Factory.insert(:category)

      invalid_attrs = %{
        price: -1.0,
        selling_price: 90.0,
        name: "Test Product",
        description: "Test description",
        brand: "Test Brand",
        model: "Test Model",
        product_type: "Test Type",
        product_category: "Test Category",
        inventory_quantity: 10,
        category_id: category.id,
        images: ["https://example.com/image1.jpg"],
        featured_image: "https://example.com/featured.jpg",
        dimensions: %{"length" => 10, "width" => 5, "height" => 3},
        specifications: %{"color" => "White", "material" => "Stainless Steel"},
        is_active: true,
        is_featured: false
      }

      changeset = Product.changeset(%Product{}, invalid_attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).price
    end

    test "changeset with invalid inventory quantity" do
      category = HomeWare.Factory.insert(:category)

      invalid_attrs = %{
        inventory_quantity: -1,
        name: "Test Product",
        description: "Test description",
        price: 100.0,
        selling_price: 90.0,
        brand: "Test Brand",
        model: "Test Model",
        product_type: "Test Type",
        product_category: "Test Category",
        category_id: category.id,
        images: ["https://example.com/image1.jpg"],
        featured_image: "https://example.com/featured.jpg",
        dimensions: %{"length" => 10, "width" => 5, "height" => 3},
        specifications: %{"color" => "White", "material" => "Stainless Steel"},
        is_active: true,
        is_featured: false
      }

      changeset = Product.changeset(%Product{}, invalid_attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).inventory_quantity
    end

    test "changeset with invalid selling price" do
      category = HomeWare.Factory.insert(:category)

      invalid_attrs = %{
        selling_price: -1.0,
        name: "Test Product",
        description: "Test description",
        price: 100.0,
        brand: "Test Brand",
        model: "Test Model",
        product_type: "Test Type",
        product_category: "Test Category",
        inventory_quantity: 10,
        category_id: category.id,
        images: ["https://example.com/image1.jpg"],
        featured_image: "https://example.com/featured.jpg",
        dimensions: %{"length" => 10, "width" => 5, "height" => 3},
        specifications: %{"color" => "White", "material" => "Stainless Steel"},
        is_active: true,
        is_featured: false
      }

      changeset = Product.changeset(%Product{}, invalid_attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).selling_price
    end
  end
end
