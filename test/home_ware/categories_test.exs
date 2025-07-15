defmodule HomeWare.CategoriesTest do
  use HomeWare.DataCase

  alias HomeWare.Categories
  alias HomeWare.Factory
  alias HomeWare.Products

  describe "categories" do
    alias HomeWare.Categories.Category

    test "list_categories/0 returns all categories" do
      category = Factory.insert(:category)
      assert Categories.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = Factory.insert(:category)
      assert Categories.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{
        name: "Kitchen Appliances",
        description: "All kitchen related appliances",
        image_url: "https://example.com/kitchen.jpg"
      }

      assert {:ok, %Category{} = category} = Categories.create_category(valid_attrs)
      assert category.name == "Kitchen Appliances"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Categories.create_category(%{name: nil})
    end

    test "update_category/2 with valid data updates the category" do
      category = Factory.insert(:category)
      update_attrs = %{name: "Updated Category", description: "Updated description"}

      assert {:ok, %Category{} = updated_category} =
               Categories.update_category(category, update_attrs)

      assert updated_category.name == "Updated Category"
      assert updated_category.description == "Updated description"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = Factory.insert(:category)
      assert {:error, %Ecto.Changeset{}} = Categories.update_category(category, %{name: nil})
      assert category == Categories.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = Factory.insert(:category)
      assert {:ok, %Category{}} = Categories.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Categories.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = Factory.insert(:category)
      assert %Ecto.Changeset{} = Categories.change_category(category)
    end
  end

  describe "list_categories_with_counts/0" do
    test "returns categories with correct product counts" do
      {:ok, cat1} = Categories.create_category(%{name: "Cat1"})
      {:ok, cat2} = Categories.create_category(%{name: "Cat2"})

      {:ok, _p1} =
        Products.create_product(%{
          name: "P1",
          description: "desc",
          price: 10,
          brand: "Brand1",
          model: "Model1",
          product_type: "Type1",
          product_category: "CatType1",
          inventory_quantity: 1,
          category_id: cat1.id,
          images: ["https://via.placeholder.com/150"],
          selling_price: 100.0,
          featured_image: "https://via.placeholder.com/300",
          dimensions: %{"length" => 10, "width" => 5, "height" => 3},
          specifications: %{"color" => "White", "material" => "Stainless Steel"},
          is_active: true,
          is_featured: false
        })

      {:ok, _p2} =
        Products.create_product(%{
          name: "P2",
          description: "desc",
          price: 20,
          brand: "Brand2",
          model: "Model2",
          product_type: "Type2",
          product_category: "CatType2",
          inventory_quantity: 2,
          category_id: cat1.id,
          images: ["https://via.placeholder.com/150"],
          selling_price: 200.0,
          featured_image: "https://via.placeholder.com/300",
          dimensions: %{"length" => 20, "width" => 10, "height" => 6},
          specifications: %{"color" => "Black", "material" => "Plastic"},
          is_active: true,
          is_featured: false
        })

      {:ok, _p3} =
        Products.create_product(%{
          name: "P3",
          description: "desc",
          price: 30,
          brand: "Brand3",
          model: "Model3",
          product_type: "Type3",
          product_category: "CatType3",
          inventory_quantity: 3,
          category_id: cat2.id,
          images: ["https://via.placeholder.com/150"],
          selling_price: 300.0,
          featured_image: "https://via.placeholder.com/300",
          dimensions: %{"length" => 30, "width" => 15, "height" => 9},
          specifications: %{"color" => "Red", "material" => "Metal"},
          is_active: true,
          is_featured: false
        })

      result = Categories.list_categories_with_counts()
      cat1_count = Enum.find(result, &(&1.id == cat1.id)).product_count
      cat2_count = Enum.find(result, &(&1.id == cat2.id)).product_count

      assert cat1_count == 2
      assert cat2_count == 1
    end
  end
end
