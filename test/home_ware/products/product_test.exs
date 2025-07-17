defmodule HomeWare.Products.ProductTest do
  use HomeWare.DataCase

  alias HomeWare.Products.Product
  alias HomeWare.Products
  alias HomeWare.Factory

  describe "product changeset" do
    test "changeset with valid attributes" do
      changeset =
        Product.changeset(%Product{}, %{
          name: "Test Product",
          brand: "Test Brand",
          product_type: "Test Type",
          product_category: "Test Category",
          description: "Test description",
          price: Decimal.new("100.00"),
          selling_price: Decimal.new("90.00"),
          inventory_quantity: 10,
          is_active: true,
          is_featured: false,
          category_id: Ecto.UUID.generate(),
          dimensions: %{"length" => 10, "width" => 5},
          specifications: %{"color" => "Red"}
        })

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Product.changeset(%Product{}, %{})
      refute changeset.valid?
    end
  end

  describe "availability" do
    test "available? returns true for active product with inventory" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 10})
      product_with_availability = Products.set_availability(product)
      assert product_with_availability.available? == true
    end

    test "available? returns false for inactive product" do
      product = Factory.insert(:product, %{is_active: false, inventory_quantity: 10})
      product_with_availability = Products.set_availability(product)
      assert product_with_availability.available? == false
    end

    test "available? returns false for active product with zero inventory" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})
      product_with_availability = Products.set_availability(product)
      assert product_with_availability.available? == false
    end

    test "available? returns false for active product with negative inventory" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: -5})
      product_with_availability = Products.set_availability(product)
      assert product_with_availability.available? == false
    end

    test "out_of_stock? returns true for unavailable product" do
      product = Factory.insert(:product, %{is_active: false, inventory_quantity: 10})
      product_with_availability = Products.set_availability(product)
      assert Product.out_of_stock?(product_with_availability) == true
    end

    test "out_of_stock? returns false for available product" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 10})
      product_with_availability = Products.set_availability(product)
      assert Product.out_of_stock?(product_with_availability) == false
    end

    test "low_stock? returns true for product with 5 or fewer items" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 5})
      product_with_availability = Products.set_availability(product)
      assert Product.low_stock?(product_with_availability) == true
    end

    test "low_stock? returns false for product with more than 5 items" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 10})
      product_with_availability = Products.set_availability(product)
      assert Product.low_stock?(product_with_availability) == false
    end

    test "low_stock? returns false for unavailable product" do
      product = Factory.insert(:product, %{is_active: false, inventory_quantity: 3})
      product_with_availability = Products.set_availability(product)
      assert Product.low_stock?(product_with_availability) == false
    end

    test "availability_status/1 returns correct status for different scenarios" do
      inactive_product = Factory.insert(:product, %{is_active: false, inventory_quantity: 10})
      out_of_stock_product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})
      low_stock_product = Factory.insert(:product, %{is_active: true, inventory_quantity: 3})
      in_stock_product = Factory.insert(:product, %{is_active: true, inventory_quantity: 20})

      inactive_product_with_availability = Products.set_availability(inactive_product)
      out_of_stock_product_with_availability = Products.set_availability(out_of_stock_product)
      low_stock_product_with_availability = Products.set_availability(low_stock_product)
      in_stock_product_with_availability = Products.set_availability(in_stock_product)

      assert Product.availability_status(inactive_product_with_availability) == "Inactive"
      assert Product.availability_status(out_of_stock_product_with_availability) == "Out of Stock"
      assert Product.availability_status(low_stock_product_with_availability) == "Low Stock"
      assert Product.availability_status(in_stock_product_with_availability) == "In Stock"
    end

    test "availability_color/1 returns correct color classes" do
      inactive_product = Factory.insert(:product, %{is_active: false, inventory_quantity: 10})
      out_of_stock_product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})
      low_stock_product = Factory.insert(:product, %{is_active: true, inventory_quantity: 3})
      in_stock_product = Factory.insert(:product, %{is_active: true, inventory_quantity: 20})

      inactive_product_with_availability = Products.set_availability(inactive_product)
      out_of_stock_product_with_availability = Products.set_availability(out_of_stock_product)
      low_stock_product_with_availability = Products.set_availability(low_stock_product)
      in_stock_product_with_availability = Products.set_availability(in_stock_product)

      assert Product.availability_color(inactive_product_with_availability) == "bg-gray-500"
      assert Product.availability_color(out_of_stock_product_with_availability) == "bg-red-500"
      assert Product.availability_color(low_stock_product_with_availability) == "bg-yellow-500"
      assert Product.availability_color(in_stock_product_with_availability) == "bg-green-500"
    end

    test "total_available_quantity/1 returns correct quantity for products without variants" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 15})
      assert Product.total_available_quantity(product) == 15
    end

    test "total_available_quantity/1 returns 0 for inactive products" do
      product = Factory.insert(:product, %{is_active: false, inventory_quantity: 15})
      assert Product.total_available_quantity(product) == 0
    end
  end

  describe "debug availability logic" do
    test "debug: available? logic for active/inactive and inventory" do
      active_in_stock = Factory.insert(:product, %{is_active: true, inventory_quantity: 10})
      active_out_stock = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})
      inactive_in_stock = Factory.insert(:product, %{is_active: false, inventory_quantity: 10})

      assert Products.set_availability(active_in_stock).available? == true
      assert Products.set_availability(active_out_stock).available? == false
      assert Products.set_availability(inactive_in_stock).available? == false
    end
  end

  describe "products context with availability" do
    test "get_product! sets available? field correctly" do
      # Create a product with inventory
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 10})

      # Get the product through the context
      loaded_product = Products.get_product!(product.id)

      assert loaded_product.available? == true
    end

    test "get_product! sets available? to false for out of stock product" do
      # Create a product without inventory
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})

      # Get the product through the context
      loaded_product = Products.get_product!(product.id)

      assert loaded_product.available? == false
    end

    test "list_products sets available? field for all products" do
      # Create products with different availability statuses
      Factory.insert(:product, %{is_active: true, inventory_quantity: 10})
      Factory.insert(:product, %{is_active: true, inventory_quantity: 0})
      Factory.insert(:product, %{is_active: false, inventory_quantity: 5})

      # Get products through the context
      products = Products.list_products()

      # Check that available? is set correctly
      available_products = Enum.filter(products, & &1.available?)
      assert length(available_products) == 1
    end
  end

  describe "products with variants availability" do
    test "product with available variants is available" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})

      # Create available variants
      Factory.insert(:product_variant, %{product_id: product.id, is_active: true, quantity: 10})
      Factory.insert(:product_variant, %{product_id: product.id, is_active: true, quantity: 5})

      # Get product with variants
      product_with_variants = Products.get_product_with_variants!(product.id)

      assert product_with_variants.available? == true
      assert length(product_with_variants.variants) == 2
      assert Enum.all?(product_with_variants.variants, & &1.available?)
    end

    test "product with no available variants is not available" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})

      # Create unavailable variants
      Factory.insert(:product_variant, %{product_id: product.id, is_active: false, quantity: 10})
      Factory.insert(:product_variant, %{product_id: product.id, is_active: true, quantity: 0})

      # Get product with variants
      product_with_variants = Products.get_product_with_variants!(product.id)

      assert product_with_variants.available? == false
      # Only active variants are loaded
      assert length(product_with_variants.variants) == 1
      assert Enum.all?(product_with_variants.variants, &(&1.available? == false))
    end

    test "product with mixed variant availability is available if any variant is available" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 0})

      # Create variants with mixed availability
      Factory.insert(:product_variant, %{product_id: product.id, is_active: true, quantity: 0})
      Factory.insert(:product_variant, %{product_id: product.id, is_active: true, quantity: 10})
      Factory.insert(:product_variant, %{product_id: product.id, is_active: false, quantity: 5})

      # Get product with variants
      product_with_variants = Products.get_product_with_variants!(product.id)

      assert product_with_variants.available? == true
      # Only active variants are loaded
      assert length(product_with_variants.variants) == 2

      # Check that at least one variant is available
      available_variants = Enum.filter(product_with_variants.variants, & &1.available?)
      assert length(available_variants) == 1
    end

    test "product without variants uses inventory_quantity for availability" do
      product = Factory.insert(:product, %{is_active: true, inventory_quantity: 10})

      # Get product without variants
      product_without_variants = Products.get_product!(product.id)

      assert product_without_variants.available? == true
      # Variants are not loaded when using get_product!
      assert Ecto.assoc_loaded?(product_without_variants.variants) == false
    end

    test "product with variants but inactive product is not available" do
      product = Factory.insert(:product, %{is_active: false, inventory_quantity: 0})

      # Create available variants
      Factory.insert(:product_variant, %{product_id: product.id, is_active: true, quantity: 10})

      # Get product with variants
      product_with_variants = Products.get_product_with_variants!(product.id)

      assert product_with_variants.available? == false
    end
  end
end
