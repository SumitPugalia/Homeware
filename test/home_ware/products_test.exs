defmodule HomeWare.ProductsTest do
  use HomeWare.DataCase

  alias HomeWare.Products
  alias HomeWare.Factory

  describe "products" do
    alias HomeWare.Products.Product

    test "list_products/0 returns all products" do
      product = Factory.insert(:product)
      assert Products.list_products() == [product]
    end

    test "list_featured_products/0 returns featured products" do
      product = Factory.insert(:product, %{is_featured: true})
      assert Products.list_featured_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = Factory.insert(:product)
      assert Products.get_product!(product.id) == product
    end

    test "get_product_by_slug!/1 returns the product with given slug" do
      product = Factory.insert(:product, %{slug: "test-product"})
      assert Products.get_product_by_slug!("test-product") == product
    end

    test "create_product/1 with valid data creates a product" do
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

      assert {:ok, %Product{} = product} = Products.create_product(valid_attrs)
      assert product.name == "Test Product"
      assert product.slug == "test-product"
      assert product.price == 100.0
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Products.create_product(%{name: nil})
    end

    test "update_product/2 with valid data updates the product" do
      product = Factory.insert(:product)
      update_attrs = %{name: "Updated Product", price: 150.0}

      assert {:ok, %Product{} = updated_product} = Products.update_product(product, update_attrs)
      assert updated_product.name == "Updated Product"
      assert updated_product.price == 150.0
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = Factory.insert(:product)
      assert {:error, %Ecto.Changeset{}} = Products.update_product(product, %{name: nil})
      assert product == Products.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = Factory.insert(:product)
      assert {:ok, %Product{}} = Products.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = Factory.insert(:product)
      assert %Ecto.Changeset{} = Products.change_product(product)
    end

    test "list_categories/0 returns all categories" do
      # This will be implemented when Categories context is created
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

      assert Products.min_price() == Decimal.new("50.0")
    end

    test "max_price/0 returns maximum price" do
      _product1 = Factory.insert(:product, %{price: Decimal.new("50.0")})
      _product2 = Factory.insert(:product, %{price: Decimal.new("100.0")})

      assert Products.max_price() == Decimal.new("100.0")
    end

    test "paginated_products/3 returns paginated results" do
      # Create multiple products
      for i <- 1..15 do
        Factory.insert(:product, %{name: "Product #{i}", price: Decimal.new("#{100.0 + i}")})
      end

      page = Products.paginated_products(1, 10)
      assert length(page.entries) == 10
      assert page.total_entries >= 15
    end

    test "paginated_products/3 with filters applies filters correctly" do
      _product1 = Factory.insert(:product, %{brand: "Brand A", price: Decimal.new("50.0")})
      _product2 = Factory.insert(:product, %{brand: "Brand B", price: Decimal.new("100.0")})

      # Filter by brand
      filtered_page = Products.paginated_products(1, 10, %{brand: "Brand A"})
      assert length(filtered_page.entries) == 1
      assert hd(filtered_page.entries).brand == "Brand A"

      # Filter by price range
      price_filtered = Products.paginated_products(1, 10, %{min_price: "75.0"})
      assert length(price_filtered.entries) == 1
      assert Decimal.compare(hd(price_filtered.entries).price, Decimal.new("75.0")) != :lt
    end
  end
end
