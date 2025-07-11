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
end
