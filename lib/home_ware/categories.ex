defmodule HomeWare.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false
  alias HomeWare.Repo
  alias HomeWare.Categories.Category

  def list_categories do
    Category
    |> where(is_active: true)
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get!(Category, id)

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  def list_categories_with_products do
    Category
    |> where(is_active: true)
    |> preload(:products)
    |> Repo.all()
  end

  def create_or_update_category(category, attrs) do
    case category do
      nil -> create_category(attrs)
      category -> update_category(category, attrs)
    end
  end

  def list_categories_with_counts do
    import Ecto.Query
    alias HomeWare.Categories.Category
    alias HomeWare.Repo

    query =
      from c in Category,
        left_join: p in assoc(c, :products),
        group_by: c.id,
        select: %{
          id: c.id,
          name: c.name,
          product_count: count(p.id)
        }

    Repo.all(query)
  end
end
