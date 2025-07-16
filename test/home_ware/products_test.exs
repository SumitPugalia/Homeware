defmodule HomeWare.ProductsTest do
  use HomeWare.DataCase

  alias HomeWare.Products
  alias HomeWare.Factory

  describe "products" do
    alias HomeWare.Products.Product

    test "list_products/0 returns all products" do
      product = Factory.insert(:product)
      products = Products.list_products()
      assert length(products) == 1
      assert hd(products).id == product.id
    end

    test "list_featured_products/0 returns featured products" do
      product = Factory.insert(:product, %{is_featured: true})
      products = Products.list_featured_products()
      assert length(products) == 1
      assert hd(products).id == product.id
    end

    test "get_product!/1 returns the product with given id" do
      product = Factory.insert(:product)
      retrieved_product = Products.get_product!(product.id)
      assert retrieved_product.id == product.id
      assert retrieved_product.name == product.name
    end

    test "create_product/1 with valid data creates a product" do
      category = Factory.insert(:category)

      valid_attrs = %{
        name: "Test Product",
        description: "Test description",
        price: 100.0,
        brand: "Test Brand",
        model: "Test Model",
        product_type: "Test Type",
        product_category: "Test Category",
        is_active: true,
        is_featured: false,
        inventory_quantity: 10,
        category_id: category.id,
        images: ["https://via.placeholder.com/150"],
        selling_price: 100.0,
        featured_image: "https://via.placeholder.com/300",
        dimensions: %{"length" => 10, "width" => 5, "height" => 3},
        specifications: %{"color" => "White", "material" => "Stainless Steel"}
      }

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.name == "Test Product"
      assert Decimal.compare(product.price, Decimal.new("100.0")) == :eq
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(%{name: nil})
    end

    test "update_product/2 with valid data updates the product" do
      product = Factory.insert(:product)
      update_attrs = %{name: "Updated Product", price: 150.0}

      assert {:ok, %Product{} = updated_product} = Products.update_product(product, update_attrs)
      assert updated_product.name == "Updated Product"
      assert Decimal.compare(updated_product.price, Decimal.new("150.0")) == :eq
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = Factory.insert(:product)
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, %{name: nil})
      retrieved_product = Products.get_product!(product.id)
      assert retrieved_product.id == product.id
      assert retrieved_product.name == product.name
    end

    test "delete_product/1 deactivates the product" do
      product = Factory.insert(:product)
      assert {:ok, %Product{} = deleted_product} = Products.delete_product(product)
      assert deleted_product.is_active == false

      # Product should still exist but be inactive
      retrieved_product = Products.get_product!(product.id)
      assert retrieved_product.id == product.id
      assert retrieved_product.is_active == false
    end

    test "change_product/1 returns a product changeset" do
      product = Factory.insert(:product)
      assert %Ecto.Changeset{} = Products.change_product(product)
    end

    test "list_categories/0 returns all categories" do
      assert Products.list_categories() == []
    end

    test "list_brands/0 returns all brands" do
      _product1 = Factory.insert(:product, %{brand: "Brand A"})
      _product2 = Factory.insert(:product, %{brand: "Brand B"})

      brands = Products.list_brands()
      assert "Brand A" in brands
      assert "Brand B" in brands
    end

    test "min_price/0 returns minimum price" do
      _product1 = Factory.insert(:product, %{price: Decimal.new("50.0")})
      _product2 = Factory.insert(:product, %{price: Decimal.new("100.0")})

      min_price = Products.min_price()
      assert Decimal.compare(min_price, Decimal.new("50.0")) == :eq
    end

    test "max_price/0 returns maximum price" do
      _product1 = Factory.insert(:product, %{price: Decimal.new("50.0")})
      _product2 = Factory.insert(:product, %{price: Decimal.new("100.0")})

      max_price = Products.max_price()
      assert Decimal.compare(max_price, Decimal.new("100.0")) == :eq
    end

    test "paginated_products/3 returns paginated results" do
      for i <- 1..15 do
        Factory.insert(:product, %{name: "Product #{i}", price: Decimal.new("#{100.0 + i}")})
      end

      page = Products.paginated_products(1, 10)
      assert length(page.entries) == 10
      assert page.total_entries >= 15
    end

    test "paginated_products/3 with filters applies filters correctly" do
      _product1 =
        Factory.insert(:product, %{
          brand: "Brand A",
          price: Decimal.new("50.0"),
          selling_price: Decimal.new("50.0")
        })

      _product2 =
        Factory.insert(:product, %{
          brand: "Brand B",
          price: Decimal.new("100.0"),
          selling_price: Decimal.new("100.0")
        })

      filtered_page = Products.paginated_products(1, 10, %{brand: "Brand A"})
      assert length(filtered_page.entries) == 1
      assert hd(filtered_page.entries).brand == "Brand A"

      price_filtered = Products.paginated_products(1, 10, %{min_price: "75.0"})
      assert length(price_filtered.entries) == 1
      assert Decimal.compare(hd(price_filtered.entries).price, Decimal.new("75.0")) != :lt
    end
  end
end
