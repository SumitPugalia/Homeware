defmodule HomeWare.Products.ProductVariantTest do
  use HomeWare.DataCase

  alias HomeWare.Products.ProductVariant
  alias HomeWare.Factory

  describe "product_variant changeset" do
    test "changeset with valid attributes" do
      product = Factory.insert(:product)

      changeset =
        ProductVariant.changeset(%ProductVariant{}, %{
          option_name: "Test Variant",
          sku: "SKU-001",
          price_override: Decimal.new("99.99"),
          quantity: 10,
          is_active: true,
          product_id: product.id
        })

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = ProductVariant.changeset(%ProductVariant{}, %{})
      refute changeset.valid?
    end

    test "changeset with negative quantity" do
      product = Factory.insert(:product)

      changeset =
        ProductVariant.changeset(%ProductVariant{}, %{
          option_name: "Test Variant",
          sku: "SKU-001",
          quantity: -5,
          product_id: product.id
        })

      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).quantity
    end

    test "changeset with invalid price_override" do
      product = Factory.insert(:product)

      changeset =
        ProductVariant.changeset(%ProductVariant{}, %{
          option_name: "Test Variant",
          sku: "SKU-001",
          price_override: Decimal.new("-10.00"),
          quantity: 10,
          product_id: product.id
        })

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).price_override
    end
  end

  describe "availability" do
    test "set_availability returns true for active variant with inventory" do
      variant = Factory.build(:product_variant, %{is_active: true, quantity: 10})
      variant_with_availability = ProductVariant.set_availability(variant)
      assert variant_with_availability.available? == true
    end

    test "set_availability returns false for inactive variant" do
      variant = Factory.build(:product_variant, %{is_active: false, quantity: 10})
      variant_with_availability = ProductVariant.set_availability(variant)
      assert variant_with_availability.available? == false
    end

    test "set_availability returns false for active variant with zero inventory" do
      variant = Factory.build(:product_variant, %{is_active: true, quantity: 0})
      variant_with_availability = ProductVariant.set_availability(variant)
      assert variant_with_availability.available? == false
    end

    test "set_availability returns false for active variant with negative inventory" do
      variant = Factory.build(:product_variant, %{is_active: true, quantity: -5})
      variant_with_availability = ProductVariant.set_availability(variant)
      assert variant_with_availability.available? == false
    end

    test "set_availability handles list of variants" do
      variant1 = Factory.build(:product_variant, %{is_active: true, quantity: 10})
      variant2 = Factory.build(:product_variant, %{is_active: false, quantity: 5})
      variant3 = Factory.build(:product_variant, %{is_active: true, quantity: 0})

      variants = [variant1, variant2, variant3]
      variants_with_availability = ProductVariant.set_availability(variants)

      assert length(variants_with_availability) == 3
      assert Enum.at(variants_with_availability, 0).available? == true
      assert Enum.at(variants_with_availability, 1).available? == false
      assert Enum.at(variants_with_availability, 2).available? == false
    end

    test "set_availability handles empty list" do
      result = ProductVariant.set_availability([])
      assert result == []
    end

    test "set_availability handles map with string keys" do
      variant_map = %{
        "is_active" => true,
        "quantity" => 10,
        "option_name" => "Test Variant"
      }

      result = ProductVariant.set_availability(variant_map)
      assert result.available? == true
    end

    test "set_availability handles map with atom keys" do
      variant_map = %{
        is_active: false,
        quantity: 0,
        option_name: "Test Variant"
      }

      result = ProductVariant.set_availability(variant_map)
      assert result.available? == false
    end
  end
end
