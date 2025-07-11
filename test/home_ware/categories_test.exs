defmodule HomeWare.CategoriesTest do
  use HomeWare.DataCase

  alias HomeWare.Categories
  alias HomeWare.Factory

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
        slug: "kitchen-appliances",
        description: "All kitchen related appliances",
        image_url: "https://example.com/kitchen.jpg"
      }

      assert {:ok, %Category{} = category} = Categories.create_category(valid_attrs)
      assert category.name == "Kitchen Appliances"
      assert category.slug == "kitchen-appliances"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Categories.create_category(%{name: nil})
    end

    test "update_category/2 with valid data updates the category" do
      category = Factory.insert(:category)
      update_attrs = %{name: "Updated Category", description: "Updated description"}

      assert {:ok, %Category{} = updated_category} = Categories.update_category(category, update_attrs)
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
end
